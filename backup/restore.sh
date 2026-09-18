#!/usr/bin/env bash
# ==============================================================================
# Caelestia & Hyprdark User Configurations Restore Script
# Restores: ~/.zshrc, ~/.config/kitty, ~/.config/caelestia, ~/.config/hypr,
#           ~/Pictures/Wallpapers, ~/.config/systemd/user (15m wallpaper timer)
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
TIMESTAMP="$(date +%Y%m%d_%H%M%S)"

GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RESET="\033[0m"

info() {
    echo -e "${CYAN}[INFO]${RESET} $1"
}

success() {
    echo -e "${GREEN}[OK]${RESET} $1"
}

warn() {
    echo -e "${YELLOW}[BACKUP]${RESET} $1"
}

echo -e "${CYAN}======================================================${RESET}"
echo -e "${CYAN}   Restoring Custom User Configurations   ${RESET}"
echo -e "${CYAN}======================================================${RESET}"

# 0. Set Timezone to Turkiye (Europe/Istanbul)
info "Setting system timezone to Europe/Istanbul (Turkey UTC+3)..."
if command -v timedatectl >/dev/null 2>&1; then
    timedatectl set-timezone Europe/Istanbul 2>/dev/null || sudo timedatectl set-timezone Europe/Istanbul 2>/dev/null || true
    success "Timezone set to Europe/Istanbul."
fi

# 1. Restore Zsh Configuration
info "Restoring Zsh configuration (~/.zshrc)..."
if [ -f "${HOME}/.zshrc" ]; then
    cp "${HOME}/.zshrc" "${HOME}/.zshrc.bak.${TIMESTAMP}"
    warn "Existing ~/.zshrc backed up to ~/.zshrc.bak.${TIMESTAMP}"
fi
cp -f "${SCRIPT_DIR}/zsh/.zshrc" "${HOME}/.zshrc"
success "Restored ~/.zshrc"

# 2. Restore Kitty Configuration
info "Restoring Kitty configuration (~/.config/kitty)..."
mkdir -p "${HOME}/.config/kitty"
if [ -d "${HOME}/.config/kitty" ] && [ "$(ls -A "${HOME}/.config/kitty" 2>/dev/null)" ]; then
    mkdir -p "${HOME}/.config/kitty.bak.${TIMESTAMP}"
    cp -r "${HOME}/.config/kitty/"* "${HOME}/.config/kitty.bak.${TIMESTAMP}/" 2>/dev/null || true
    warn "Existing Kitty config backed up to ~/.config/kitty.bak.${TIMESTAMP}"
fi
cp -rf "${SCRIPT_DIR}/kitty/"* "${HOME}/.config/kitty/"
success "Restored ~/.config/kitty/ (kitty.conf, theme.conf)"

# 3. Restore Caelestia Configuration
info "Restoring Caelestia Shell configuration (~/.config/caelestia)..."
mkdir -p "${HOME}/.config/caelestia"
if [ -d "${HOME}/.config/caelestia" ] && [ "$(ls -A "${HOME}/.config/caelestia" 2>/dev/null)" ]; then
    mkdir -p "${HOME}/.config/caelestia.bak.${TIMESTAMP}"
    cp -r "${HOME}/.config/caelestia/"* "${HOME}/.config/caelestia.bak.${TIMESTAMP}/" 2>/dev/null || true
    warn "Existing Caelestia config backed up to ~/.config/caelestia.bak.${TIMESTAMP}"
fi
cp -rf "${SCRIPT_DIR}/caelestia/"* "${HOME}/.config/caelestia/"
success "Restored ~/.config/caelestia/ (shell.json, hypr-vars.lua, monitors/)"

# 4. Restore Hyprland Configuration
info "Restoring Hyprland configuration (~/.config/hypr)..."
mkdir -p "${HOME}/.config/hypr"
if [ -d "${HOME}/.config/hypr" ] && [ "$(ls -A "${HOME}/.config/hypr" 2>/dev/null)" ]; then
    mkdir -p "${HOME}/.config/hypr.bak.${TIMESTAMP}"
    cp -r "${HOME}/.config/hypr/"* "${HOME}/.config/hypr.bak.${TIMESTAMP}/" 2>/dev/null || true
    warn "Existing Hypr config backed up to ~/.config/hypr.bak.${TIMESTAMP}"
fi
cp -rf "${SCRIPT_DIR}/hypr/"* "${HOME}/.config/hypr/"
success "Restored ~/.config/hypr/ (hyprland.lua, hyprland-gui.lua, scheme/, etc.)"

# 5. Restore Wallpapers Directory
if [ -d "${SCRIPT_DIR}/wallpapers" ]; then
    info "Restoring Wallpapers (~/Pictures/Wallpapers)..."
    mkdir -p "${HOME}/Pictures/Wallpapers"
    cp -rf "${SCRIPT_DIR}/wallpapers/"* "${HOME}/Pictures/Wallpapers/"
    success "Restored ~/Pictures/Wallpapers/"
fi

# 6. Restore Spotify Ozone Wayland Flags
if [ -f "${SCRIPT_DIR}/spotify/spotify-flags.conf" ]; then
    info "Restoring Spotify Ozone Wayland flags (~/.config/spotify-flags.conf)..."
    mkdir -p "${HOME}/.config"
    cp -f "${SCRIPT_DIR}/spotify/spotify-flags.conf" "${HOME}/.config/spotify-flags.conf"
    success "Restored ~/.config/spotify-flags.conf (crisp native Wayland Spotify)"
fi

# 7. Restore 15m Wallpaper Rotation Service & Timer
if [ -d "${SCRIPT_DIR}/systemd/user" ]; then
    info "Restoring 15-minute Wallpaper Rotation systemd timer..."
    mkdir -p "${HOME}/.config/systemd/user"
    cp -rf "${SCRIPT_DIR}/systemd/user/"* "${HOME}/.config/systemd/user/"
    if command -v systemctl >/dev/null 2>&1; then
        systemctl --user daemon-reload
        systemctl --user enable --now wallpaper-rotate.timer 2>/dev/null || true
        success "Enabled & started wallpaper-rotate.timer (every 15 mins)."
    fi
fi

# 8. Live reload if in Hyprland
if pgrep -x "Hyprland" >/dev/null 2>&1; then
    info "Reloading Hyprland..."
    hyprctl reload 2>/dev/null || true
    success "Hyprland reloaded successfully."
fi

# 9. Live reload Caelestia Shell if running
if command -v caelestia >/dev/null 2>&1; then
    if pgrep -f "quickshell" >/dev/null 2>&1 || pgrep -f "caelestia shell" >/dev/null 2>&1; then
        info "Restarting Caelestia Shell daemon..."
        caelestia shell -k 2>/dev/null || true
        caelestia shell -d 2>/dev/null || true
        success "Caelestia Shell restarted."
    fi
fi

echo -e "${GREEN}======================================================${RESET}"
echo -e "${GREEN}   All configurations restored successfully!   ${RESET}"
echo -e "${GREEN}======================================================${RESET}"
