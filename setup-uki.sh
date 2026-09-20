#!/usr/bin/env bash
set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run as root: sudo ./setup-uki.sh"
    exit 1
fi

echo "==> 1. Setting up /etc/cmdline.d/root.conf..."
mkdir -p /etc/cmdline.d
LUKS_UUID=$(cryptsetup luksUUID /dev/nvme0n1p6)
echo "loglevel=3 quiet rd.luks.name=${LUKS_UUID}=cryptroot root=/dev/mapper/cryptroot rw" > /etc/cmdline.d/root.conf
echo "Kernel parameters set to: $(cat /etc/cmdline.d/root.conf)"

echo "==> 2. Ensuring /boot/EFI/Linux directory exists..."
mkdir -p /boot/EFI/Linux

echo "==> 3. Configuring /etc/mkinitcpio.d/linux-zen.preset for UKI..."
sed -i 's/^default_image=/#default_image=/' /etc/mkinitcpio.d/linux-zen.preset
sed -i 's/^#default_uki=/default_uki=/' /etc/mkinitcpio.d/linux-zen.preset

echo "==> 4. Building Unified Kernel Image (arch-linux-zen.efi)..."
mkinitcpio -P

echo "==> 5. Signing UKI binary with sbctl..."
sbctl sign -s /boot/EFI/Linux/arch-linux-zen.efi

echo "==> 5b. Updating universal UEFI fallback (/boot/EFI/BOOT/BOOTX64.EFI)..."
cp /boot/EFI/Linux/arch-linux-zen.efi /boot/EFI/BOOT/BOOTX64.EFI
sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI

sbctl verify

echo "==> 6. Adding direct Arch Linux entry to UEFI boot manager..."
CURRENT_BOOTNUM=$(efibootmgr | grep -i "Arch Linux" | grep -v -i "GRUB" | cut -c5-8 || true)
if [ -n "$CURRENT_BOOTNUM" ]; then
    echo "Removing older Arch Linux direct entry Boot${CURRENT_BOOTNUM}..."
    efibootmgr -b "$CURRENT_BOOTNUM" -B || true
fi

efibootmgr --create --disk /dev/nvme0n1 --part 5 --label "Arch Linux" --loader '\EFI\Linux\arch-linux-zen.efi'

echo ""
echo "==> SUCCESS: UKI setup complete! Current boot entries:"
efibootmgr
