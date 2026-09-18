#!/usr/bin/env bash
# ==============================================================================
# Caelestia Shell Update Script (Conflict-Safe)
# Fetches latest updates from upstream, protects local edits with auto-stash,
# rebuilds, installs, and restarts the shell.
# ==============================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
cd "${SCRIPT_DIR}"

GREEN="\033[1;32m"
CYAN="\033[1;36m"
YELLOW="\033[1;33m"
RED="\033[1;31m"
RESET="\033[0m"

info()    { echo -e "${CYAN}[INFO]${RESET} $1"; }
success() { echo -e "${GREEN}[OK]${RESET} $1"; }
warn()    { echo -e "${YELLOW}[WARN]${RESET} $1"; }
error()   { echo -e "${RED}[ERROR]${RESET} $1"; }

echo -e "${CYAN}======================================================${RESET}"
echo -e "${CYAN}          Updating Caelestia Shell (Safe Mode)        ${RESET}"
echo -e "${CYAN}======================================================${RESET}"

# 1. Safety: Check for uncommitted changes and stash them
STASHED=false
if ! git diff --quiet || ! git diff --cached --quiet; then
    info "Detected uncommitted local modifications."
    info "Safely stashing your working tree..."
    git stash push -m "Auto-stash before update $(date +'%Y-%m-%d %H:%M:%S')"
    STASHED=true
fi

# 2. Fetch and merge upstream
if git remote | grep -q "upstream"; then
    info "Fetching updates from upstream (caelestia-dots/shell)..."
    git fetch upstream

    info "Merging upstream/main into local branch..."
    if ! git merge upstream/main --no-edit; then
        error "Merge conflict detected with upstream changes!"
        warn "Aborting merge immediately so your code remains 100% intact..."
        git merge --abort || true

        if [ "$STASHED" = true ]; then
            info "Restoring your stashed local modifications..."
            git stash pop || true
        fi

        echo -e "${RED}======================================================${RESET}"
        echo -e "${RED}   Update paused due to conflicting code changes!     ${RESET}"
        echo -e "${RED}======================================================${RESET}"
        echo "No files were corrupted or overwritten. Your shell remains functional."
        echo "To inspect or resolve conflicts manually, run:"
        echo "  cd ~/Desktop/Github/shell"
        echo "  git merge upstream/main"
        exit 1
    fi
else
    info "Pulling updates from origin..."
    git pull
fi

# 3. Restore stashed changes if any were saved
if [ "$STASHED" = true ]; then
    info "Restoring your stashed local modifications..."
    if ! git stash pop; then
        warn "Your stashed changes had conflicts with incoming upstream files."
        warn "They are safely saved in 'git stash list' and were NOT lost."
    else
        success "Local modifications restored cleanly."
    fi
fi

# 4. Build with Ninja
info "Building shell with CMake & Ninja..."
cmake --build build

# 5. Install to system and user quickshell config
info "Installing updated modules (sudo required)..."
sudo cmake --install build

# Ensure correct permissions on user quickshell directory
sudo chown -R "${USER}:${USER}" "${HOME}/.config/quickshell/caelestia" 2>/dev/null || true

# 6. Restart Caelestia Shell daemon
info "Restarting Caelestia Shell daemon..."
caelestia shell -k 2>/dev/null || true
caelestia shell -d

success "Caelestia Shell updated and restarted successfully!"

if command -v notify-send >/dev/null 2>&1; then
    notify-send -u normal -i software-update-available "Caelestia Shell" "Shell updated and reloaded successfully!"
fi
