# Arch main setup

## Main apps

```sh
sudo pacman -S --needed git gcc nano os-prober fastfetch man jq noto-fonts-emoji iptables unzip dnsmasq wget nftables linux-zen linux-zen-headers nvidia-open-dkms nvidia-utils dkms noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu hyprmod gnome-desktop-4 locate
```

## Bootloader: UKI (Unified Kernel Image - Zen kernel)

> Direct UEFI boot with Secure Boot & TPM 2.0 support (No GRUB needed!)
> Bundles Kernel + Microcode + Initramfs + Cmdline into a single signed EFI executable.

```sh
# 1. Install necessary boot packages
sudo pacman -S --needed efibootmgr intel-ucode sbctl

# 2. Configure kernel command line for UKI
sudo mkdir -p /etc/cmdline.d
echo "loglevel=3 quiet rd.luks.name=$(sudo cryptsetup luksUUID /dev/nvme0n1p6)=cryptroot root=/dev/mapper/cryptroot rw" | sudo tee /etc/cmdline.d/root.conf

# 3. Enable UKI generation in mkinitcpio preset
sudo sed -i 's/^default_image=/#default_image=/' /etc/mkinitcpio.d/linux-zen.preset
sudo sed -i 's/^#default_uki=/default_uki=/' /etc/mkinitcpio.d/linux-zen.preset
sudo mkdir -p /boot/EFI/Linux

# 4. Generate UKI
sudo mkinitcpio -P

# 5. Add direct UKI entry to motherboard UEFI boot manager
sudo efibootmgr --create --disk /dev/nvme0n1 --part 5 --label "Arch Linux" --loader '\EFI\Linux\arch-linux-zen.efi'
```

## Secure Boot & BitLocker

### Arch

```sh
sudo pacman -S sbctl
```

### UEFI

Enable "Setup Mode" (Clear/Delete Factory Keys in BIOS)

### Arch

```sh
# Verify you are in Setup Mode (should show: Setup Mode: Enabled)
sbctl status

# Create your private cryptographic keys:
sudo sbctl create-keys

# Enroll your keys AND Microsoft's OEM keys (essential for Windows 11 & BitLocker):
sudo sbctl enroll-keys -m

# ---

# Sign the Unified Kernel Image (automatically re-signed on every kernel update via pacman hook)
sudo sbctl sign -s /boot/EFI/Linux/arch-linux-zen.efi

# Verify signature
sudo sbctl verify
```

### UEFI

Turn secure boot ON

### Arch

```sh
# Verify secure boot is enabled and Microsoft is enrolled
sbctl status
```

### UEFI

Turn secure boot OFF (temp)

### USB Arch

```sh

## Phase 1: Encrypt the partition

# 1. Check filesystem integrity before touching it
e2fsck -f /dev/nvme0n1p6

# 2. Shrink the ext4 filesystem to 245G to safely leave room for the 32MB LUKS2 header
resize2fs /dev/nvme0n1p6 245G

# 3. Encrypt the existing ext4 partition in-place with LUKS2
cryptsetup reencrypt --encrypt --type luks2 --reduce-device-size 32M /dev/nvme0n1p6

# 4. Open the newly created encrypted container as "cryptroot"
cryptsetup open /dev/nvme0n1p6 cryptroot

# 5. Expand the ext4 filesystem back to fill the full container capacity
resize2fs /dev/mapper/cryptroot

## Phase 2: Mount the system and chroot

# 6. Mount the decrypted root to /mnt
mount /dev/mapper/cryptroot /mnt

# 7. Mount the EFI/boot partition
mount /dev/nvme0n1p5 /mnt/boot

# 8. Enter the installed Arch environment
arch-chroot /mnt

## Phase 3: Configure cryptroot and UKI

# 9. Get the UUID of the decrypted filesystem
lsblk -f /dev/mapper/cryptroot
nano /etc/fstab
#    UUID=<DECRYPTED_CRYPTROOT_UUID>    /    ext4    rw,relatime    0 1
# Mine came already configured

# 10. Update /etc/mkinitcpio.conf with systemd & sd-encrypt hooks:
nano /etc/mkinitcpio.conf
#     HOOKS=(base systemd autodetect microcode modconf kms keyboard sd-vconsole block sd-encrypt filesystems fsck)

# 11. Configure kernel command line for UKI
mkdir -p /etc/cmdline.d
echo "loglevel=3 quiet rd.luks.name=$(cryptsetup luksUUID /dev/nvme0n1p6)=cryptroot root=/dev/mapper/cryptroot rw" > /etc/cmdline.d/root.conf

# 12. Configure mkinitcpio preset to generate UKI
sed -i 's/^default_image=/#default_image=/' /etc/mkinitcpio.d/linux-zen.preset
sed -i 's/^#default_uki=/default_uki=/' /etc/mkinitcpio.d/linux-zen.preset
mkdir -p /boot/EFI/Linux

# 13. Generate UKI
mkinitcpio -P

# 14. Sign UKI with sbctl
sbctl sign -s /boot/EFI/Linux/arch-linux-zen.efi

# 15. Create direct UEFI boot entry for UKI (no GRUB needed!)
efibootmgr --create --disk /dev/nvme0n1 --part 5 --label "Arch Linux" --loader '\EFI\Linux\arch-linux-zen.efi'

## Phase 4: Clean exit and reboot

# 16. Exit chroot
exit

# 17. Unmount all partitions cleanly
umount -R /mnt

# 18. Close the encrypted mapper
cryptsetup close cryptroot

# 19. Shutdown and reboot to UEFI to enable Secure boot
shutdown now
```

### UEFI

Turn secure boot ON

### Arch

Enter passphrase on first boot and enroll TPM 2.0 to auto-unlock on all future boots:

```sh
# Bind LUKS key to TPM 2.0 sealed against firmware (PCR 0) and Secure Boot (PCR 7)
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p6
```

## Fallback Bootloader & Disaster Prevention

Ensure your Arch UKI is copied to the universal UEFI fallback path (`BOOTX64.EFI`) so your system remains bootable even if motherboard NVRAM boot entries are wiped:

```sh
# Copy UKI to universal fallback
sudo cp /boot/EFI/Linux/arch-linux-zen.efi /boot/EFI/BOOT/BOOTX64.EFI

# Sign fallback with sbctl
sudo sbctl sign -s /boot/EFI/BOOT/BOOTX64.EFI
```

## BIOS / UEFI Update Recovery Playbook

Updating motherboard BIOS resets NVRAM boot entries, replaces custom Secure Boot keys with factory keys, and changes PCR 0. Follow this procedure after any firmware update:

### 1. Before BIOS Update
- Save your **48-digit Windows BitLocker Recovery Key** on another device ([account.microsoft.com/devices/recoverykey](https://account.microsoft.com/devices/recoverykey)).
- Ensure you remember your **Arch LUKS passphrase**.

### 2. First Boot: Windows 11
- Windows will boot automatically and prompt for your **48-digit BitLocker Recovery Key** (due to PCR 0 firmware change).
- Enter the key. Windows will auto-reseal BitLocker to the new firmware.

### 3. Second Boot: Restore Arch Linux
1. Reboot into BIOS settings (`Del` / `F2`) -> go to **Secure Boot** -> set to **Setup Mode** (Clear Secure Boot keys).
2. Boot into Arch using your motherboard boot menu (`F11` / `F12` -> pick drive or "UEFI OS").
3. Type your **LUKS passphrase** to decrypt root (since PCR 0 changed).
4. In terminal, run:

```sh
# 1. Re-enroll custom keys + Microsoft OEM keys:
sudo sbctl enroll-keys -m

# 2. Re-create direct UEFI boot entry if wiped:
sudo efibootmgr --create --disk /dev/nvme0n1 --part 5 --label "Arch Linux" --loader '\EFI\Linux\arch-linux-zen.efi'

# 3. Re-seal TPM 2.0 to new BIOS firmware:
sudo systemd-cryptenroll --wipe-slot=tpm2 /dev/nvme0n1p6
sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p6

# 4. Set boot order (Windows -> Arch):
sudo efibootmgr -o 0004,0005,0003,0001,2001,2002,2003
```

5. Reboot into BIOS -> turn **Secure Boot: Enabled**. Everything is back to auto-unlocking.



# Caelestia

```sh
caelestia install
```

- Configure hypr-vars.lua & hyprland.lua with shortcut modifications (`Super + Return` for kitty)
- Custom Caelestia `shell.json` (audio status icon enabled in bar)
- Zsh (`~/.zshrc`) configured with cyber prompt, execution timer, case-insensitive tab completion, and Ctrl+Arrow word navigation
- Kitty configured (`font_size 13.0`, cyber theme)
- Set clock / timezone to Turkiye (`Europe/Istanbul`, UTC+3)
- Systemd user timer configured to rotate wallpapers every 15 minutes (`wallpaper-rotate.timer`)
- Wallpapers backed up from `~/Pictures/Wallpapers/`
- Fixed Spotify pixelation with Ozone Wayland flags (`~/.config/spotify-flags.conf`)

> Scheme default (dynamic)

## Backup & Restore

All configurations, wallpapers, and timers are backed up in `backup/`:
```sh
cd ~/Desktop/Github/shell/backup
./restore.sh
```

## Updating the Shell

To pull new features and updates from upstream Caelestia Shell, run:
```sh
update-shell
```
Or:
```sh
cd ~/Desktop/Github/shell
./update.sh
```

This automatically pulls upstream changes, rebuilds with Ninja, installs to your system, and reloads the shell while preserving all your custom settings and keybinds.


## Shortcuts

### Applications
- `SUPER + Return` : Open Kitty Terminal
- `SUPER + W` : Open Web Browser (Brave)
- `SUPER + E` : Open File Explorer (Dolphin)
- `SUPER + C` : Open Code Editor
- `CTRL + ALT + V` : Audio Mixer & Volume Control

### Desktop & Caelestia Shell
- `SUPER` : Open App Launcher & Command Palette
- `SUPER + D` : Open Dashboard (Stats & Widgets)
- `SUPER + N` : Toggle Sidebar & Notifications
- `SUPER + K` : Toggle Desktop Panels
- `SUPER + L` : Lock Screen
- `SUPER + SHIFT + L` : Sleep / Suspend System
- `CTRL + ALT + Delete` : Power & Session Menu
- `CTRL + ALT + C` : Clear All Notifications
- `CTRL + SUPER + ALT + R` : Restart Caelestia Shell
- `CTRL + SUPER + SHIFT + R` : Kill Caelestia Shell

### Window Management
- `SUPER + Q` : Close Active Window
- `SUPER + V` : Toggle Floating Window
- `SUPER + F` : Toggle Maximized Window
- `SUPER + ALT + F` : Toggle Fullscreen
- `SUPER + P` : Pin Window (Sticky across all workspaces)
- `SUPER + Left / Right / Up / Down` : Focus window in direction
- `SUPER + SHIFT + Left / Right / Up / Down` : Move window in direction
- `SUPER + Minus / Equal` : Decrease / Increase window width
- `SUPER + SHIFT + Minus / Equal` : Decrease / Increase window height
- `SUPER + ALT + Left / Right / Up / Down` : Resize active window
- `SUPER + Left Click + Drag` : Move floating window
- `SUPER + Right Click + Drag` : Resize floating window
- `CTRL + SUPER + Backslash` : Center active window
- `CTRL + SUPER + ALT + Backslash` : Reset/normalize window size
- `SUPER + ALT + Backslash` : Toggle Picture-in-Picture mode
- `ALT + Tab` / `SHIFT + ALT + Tab` : Cycle next / previous window

### Window Groups (Tabs)
- `SUPER + Comma` : Toggle window group (tabbed windows)
- `SUPER + U` : Remove window from group
- `SUPER + SHIFT + Comma` : Lock active group
- `CTRL + ALT + Tab` / `CTRL + SHIFT + ALT + Tab` : Switch group tabs

### Workspaces
- `SUPER + 1..9, 0` : Switch to Workspace 1–10
- `SUPER + SHIFT + 1..9, 0` : Move active window to Workspace 1–10
- `CTRL + SUPER + 1..9, 0` : Switch workspace group
- `CTRL + SUPER + SHIFT + 1..9, 0` : Move window to workspace group
- `SUPER + Scroll / PageUp / PageDown` : Previous / Next workspace
- `SUPER + ALT + Scroll / PageUp / PageDown` : Move window to Prev / Next workspace
- `SUPER + S` : Toggle Scratchpad Workspace
- `SUPER + ALT + S` : Send window to Scratchpad
- `CTRL + SUPER + SHIFT + Down` : Retrieve window from Scratchpad
- `CTRL + SHIFT + Escape` : System Monitor Workspace
- `SUPER + M` : Music Workspace
- `SUPER + R` : Tasks / Todo Workspace

### Screenshots & Recording
- `Print` : Fullscreen Screenshot
- `SUPER + SHIFT + S` : Region Screenshot (Freeze)
- `SUPER + SHIFT + ALT + S` : Interactive Region Screenshot
- `CTRL + ALT + R` : Screen Recording
- `SUPER + ALT + R` : Screen Recording with Audio
- `SUPER + SHIFT + ALT + R` : Record Selected Region
- `SUPER + SHIFT + C` : Color Picker (Hyprpicker)

### Clipboard & Emojis
- `SUPER + SHIFT + V` : Clipboard History
- `SUPER + ALT + V` : Delete Clipboard Entry
- `CTRL + SHIFT + ALT + V` : Paste Last Copied Item
- `SUPER + Period` : Emoji Picker

### Audio & Media Keys
- `XF86AudioRaiseVolume` / `LowerVolume` : Volume Up / Down
- `SUPER + SHIFT + M` / `XF86AudioMute` : Mute / Unmute Audio
- `XF86AudioMicMute` : Mute / Unmute Microphone
- `CTRL + SUPER + Space` / `XF86AudioPlay` : Play / Pause
- `CTRL + SUPER + Equal` / `XF86AudioNext` : Next Track
- `CTRL + SUPER + Minus` / `XF86AudioPrev` : Previous Track
- `CTRL + SUPER + Backspace` / `XF86AudioStop` : Stop Playback
- `XF86MonBrightnessUp` / `Down` : Screen Brightness Up / Down

### Terminal (Zsh & Kitty)
- `CTRL + Left / Right` : Jump words backward / forward
- `ALT + Left / Right` : Jump words backward / forward
- `CTRL + Backspace` : Delete word backward
- `CTRL + Delete` : Delete word forward
- `Tab` : Case-insensitive completion with arrow navigation


# User apps

## Yay
sudo pacman -S --needed base-devel
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si
cd ..
rm -dfr yay

## Brave
yay -S brave-browser

## Sublime
yay -S sublime-text

## Antigravity
yay -S antigravity

## Spotify
yay -S spotify

## Timeshift
yay -S timeshift

## GithubDesktop
yay -S github-desktop

## Windscribe
yay -S windscribe-v2-bin
sudo systemctl enable windscribe-helper.service
<!-- I don't know how to disable the app from starting, keep the helper enabled tho -->

## Warp
yay -S cloudflare-warp-bin

## CafeChameleon
<!-- You must modify the app to install.sh and use xorg-xhost -->

## Docker
sudo pacman -S docker docker-compose docker-buildx 

## Waydroid
sudo pacman -S waydroid
sudo systemctl enable --now waydroid-container

## Obsidian
yay -S obsidian

## BlackArch repo
curl -O https://blackarch.org/strap.sh
echo 00688950aaf5e5804d2abebb8d3d3ea1d28525ed strap.sh | sha1sum -c
chmod +x strap.sh
sudo ./strap.sh
sudo pacman -Syu
rm -f strap.sh
<!-- Install tools individually: sudo pacman -S <tool-name> -->

## Caido
sudo pacman -S fuse2
yay -S caido

# Hacking tools

yay -S seclists wireshark-qt feroxbuster dirsearch ffuf impacket bloodyad villian penelope

<!-- tar -xvf /usr/share/seclists/Passwords/Leaked-Databases/rockyou.txt.tar.gz -->

certipy bloodhound-ce

# Temp things to remove

nothing
