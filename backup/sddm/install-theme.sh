#!/usr/bin/env bash
# ==============================================================================
# SDDM Sugar Candy - DedSec Skull Customization Installer
# Deploys centered login form + randomized center skull animations to SDDM
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
THEME_SRC="${SCRIPT_DIR}/sugar-candy"
TARGET_DIR="/usr/share/sddm/themes/sugar-candy"

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

info "Deploying custom DedSec Skull theme to ${TARGET_DIR}..."

# 1. Ensure target theme directory exists
mkdir -p "${TARGET_DIR}"

# 2. Copy theme files and skull assets
cp -rf "${THEME_SRC}/"* "${TARGET_DIR}/"

# 3. Ensure proper permissions so sddm user can read all assets
chmod -R 755 "${TARGET_DIR}"
chown -R root:root "${TARGET_DIR}"

# 4. Configure SDDM to use sugar-candy
mkdir -p /etc/sddm.conf.d
cat << 'EOF' > /etc/sddm.conf.d/theme.conf
[Theme]
Current=sugar-candy
EOF
chmod 644 /etc/sddm.conf.d/theme.conf

success "SDDM Skull theme deployed successfully!"
echo -e "${GREEN}======================================================${RESET}"
echo -e "${GREEN} You can test your theme right now in a window via:   ${RESET}"
echo -e "${CYAN} sddm-greeter --test-mode --theme /usr/share/sddm/themes/sugar-candy${RESET}"
echo -e "${GREEN}======================================================${RESET}"
