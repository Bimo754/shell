#!/usr/bin/env bash
# ==============================================================================
# Matrix Morpheus GRUB Theme Installer
# Deploys the Red Pill vs Blue Pill Matrix theme for Arch Linux & Windows
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
THEME_SRC="${SCRIPT_DIR}/Matrix"
THEME_DEST="/boot/grub/themes/Matrix"
GRUB_DEFAULT="/etc/default/grub"
GRUB_CFG="/boot/grub/grub.cfg"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

if [ "$EUID" -ne 0 ]; then
    error "Please run this installer with sudo:"
    echo "  sudo ${0}"
    exit 1
fi

echo -e "${CYAN}======================================================${RESET}"
echo -e "${CYAN}   Installing Matrix Morpheus GRUB Theme (Red vs Blue) ${RESET}"
echo -e "${CYAN}======================================================${RESET}"

# 1. Ensure theme directory exists and copy files
info "Deploying theme assets to ${THEME_DEST}..."
mkdir -p "${THEME_DEST}"
cp -rf "${THEME_SRC}/"* "${THEME_DEST}/"
chmod -R 755 "${THEME_DEST}"
chown -R root:root "${THEME_DEST}"
success "Theme assets copied successfully."

# 2. Backup /etc/default/grub
if [ -f "${GRUB_DEFAULT}" ]; then
    cp -a "${GRUB_DEFAULT}" "${GRUB_DEFAULT}.bak.${TIMESTAMP}"
    warn "Existing ${GRUB_DEFAULT} backed up to ${GRUB_DEFAULT}.bak.${TIMESTAMP}"
fi

# 3. Configure GRUB_THEME
if grep -q "^GRUB_THEME=" "${GRUB_DEFAULT}"; then
    sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"${THEME_DEST}/theme.txt\"|" "${GRUB_DEFAULT}"
elif grep -q "^#GRUB_THEME=" "${GRUB_DEFAULT}"; then
    sed -i "s|^#GRUB_THEME=.*|GRUB_THEME=\"${THEME_DEST}/theme.txt\"|" "${GRUB_DEFAULT}"
else
    echo "GRUB_THEME=\"${THEME_DEST}/theme.txt\"" >> "${GRUB_DEFAULT}"
fi

# 4. Set resolution to 2560x1600 native resolution with auto fallback
DETECTED_RES=$(cat /sys/class/drm/card*-eDP-*/modes 2>/dev/null | head -n 1 || echo "2560x1600")
[ -z "$DETECTED_RES" ] && DETECTED_RES="2560x1600"
info "Setting GRUB_GFXMODE to ${DETECTED_RES},auto..."
if grep -q "^GRUB_GFXMODE=" "${GRUB_DEFAULT}"; then
    sed -i "s|^GRUB_GFXMODE=.*|GRUB_GFXMODE=${DETECTED_RES},auto|" "${GRUB_DEFAULT}"
else
    echo "GRUB_GFXMODE=${DETECTED_RES},auto" >> "${GRUB_DEFAULT}"
fi

# 5. Keep graphics payload for smooth transition
if grep -q "^#GRUB_GFXPAYLOAD_LINUX=" "${GRUB_DEFAULT}"; then
    sed -i 's|^#GRUB_GFXPAYLOAD_LINUX=.*|GRUB_GFXPAYLOAD_LINUX=keep|' "${GRUB_DEFAULT}"
elif ! grep -q "^GRUB_GFXPAYLOAD_LINUX=" "${GRUB_DEFAULT}"; then
    echo "GRUB_GFXPAYLOAD_LINUX=keep" >> "${GRUB_DEFAULT}"
fi

# 6. Disable submenus for clean 2-entry Red Pill vs Blue Pill toggle
if grep -q "^#GRUB_DISABLE_SUBMENU=" "${GRUB_DEFAULT}"; then
    sed -i 's|^#GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|' "${GRUB_DEFAULT}"
elif grep -q "^GRUB_DISABLE_SUBMENU=" "${GRUB_DEFAULT}"; then
    sed -i 's|^GRUB_DISABLE_SUBMENU=.*|GRUB_DISABLE_SUBMENU=y|' "${GRUB_DEFAULT}"
else
    echo "GRUB_DISABLE_SUBMENU=y" >> "${GRUB_DEFAULT}"
fi

# 7. Ensure OS-Prober is enabled for Windows detection
if grep -q "^#GRUB_DISABLE_OS_PROBER=" "${GRUB_DEFAULT}"; then
    sed -i 's|^#GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|' "${GRUB_DEFAULT}"
elif grep -q "^GRUB_DISABLE_OS_PROBER=" "${GRUB_DEFAULT}"; then
    sed -i 's|^GRUB_DISABLE_OS_PROBER=.*|GRUB_DISABLE_OS_PROBER=false|' "${GRUB_DEFAULT}"
else
    echo "GRUB_DISABLE_OS_PROBER=false" >> "${GRUB_DEFAULT}"
fi

# 8. Clean up extra menu entries (disable UEFI firmware script for pure 2-choice menu)
if [ -f /etc/grub.d/30_uefi-firmware ] && [ -x /etc/grub.d/30_uefi-firmware ]; then
    chmod -x /etc/grub.d/30_uefi-firmware
    info "Disabled UEFI Firmware Settings menu entry for clean 2-entry layout."
    info "(You can always access BIOS via 'systemctl reboot --firmware-setup' or pressing 'c' then 'fwsetup' in GRUB)."
fi

# 9. Regenerate GRUB config
info "Regenerating ${GRUB_CFG}..."
grub-mkconfig -o "${GRUB_CFG}"

success "Matrix Morpheus GRUB Theme installed and activated successfully!"
echo -e "${GREEN}======================================================${RESET}"
echo -e "${GREEN} Next time you boot, Morpheus will offer you:          ${RESET}"
echo -e "${RED}  - Red Pill:  Arch Linux                              ${RESET}"
echo -e "${CYAN}  - Blue Pill: Windows Boot Manager                    ${RESET}"
echo -e "${GREEN}======================================================${RESET}"
