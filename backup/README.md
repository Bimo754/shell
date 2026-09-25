# System Configurations Backup

This folder contains a complete backup of all custom desktop, terminal, shell, wallpaper, and keybinding configurations configured for **Caelestia Shell** and **Hyprdark**.

---

## What is Backed Up

| Component | Path in Backup | Restores To | Details |
|---|---|---|---|
| **Wallpapers** | `wallpapers/*` | `~/Pictures/Wallpapers/` | Complete wallpaper collection (`bird1`, `eagle1`, `lara1`, `sadie1`, `spider1`, `ufc1`, `ufc2`) |
| **Wallpaper Timer** | `systemd/user/*` | `~/.config/systemd/user/` | Systemd service & timer automatically rotating wallpapers every 15 minutes (`caelestia wallpaper -r`) |
| **Zsh** | `zsh/.zshrc` | `~/.zshrc` | Cyber high-contrast prompt, execution timer, directory fill hairline, case-insensitive tab completion, Alt+Backspace path segment deletion (`WORDCHARS` without `/`), clean prompt newline spacing on Ctrl+C & command completion, word jumping, pentest aliases |
| **Kitty** | `kitty/kitty.conf`<br>`kitty/theme.conf` | `~/.config/kitty/` | Font size 13.0, padding, cursor, cyber colors, Zsh shell integration |
| **Caelestia** | `caelestia/shell.json`<br>`caelestia/cli.json`<br>`caelestia/hypr-vars.lua`<br>`caelestia/hypr-user.lua`<br>`caelestia/monitors/` | `~/.config/caelestia/` | Audio status icon enabled, bar settings, terminal dynamic color disable (`enableTerm: false`), context-aware terminal keybinds (`SUPER+Space` / `SUPER+Return` and `SUPER+T`), editor (`SUPER+C` -> Sublime `subl`), swapped browser (`SUPER+R`) & todo (`SUPER+W`), special workspace window movement (`SUPER+ALT+S/W/D/M`), user overrides (Windscribe autosizing float) |
| **Hyprland** | `hypr/*`<br>`hypr/scripts/launch-terminal.sh` | `~/.config/hypr/` | Full Hyprland setup, `hyprland.lua`, `hyprland-gui.lua`, `scheme/`, `keybinds.lua`, `rules.lua` (with floating app rules), `launch-terminal.sh` (inherits active terminal CWD), seamless direct switching between special workspaces |
| **Spotify** | `spotify/spotify-flags.conf` | `~/.config/spotify-flags.conf` | Ozone Wayland flags (`UseOzonePlatform`, `wayland`) for crisp, non-pixelated native rendering |
| **SDDM Login** | `sddm/sugar-candy/`<br>`sddm/install-theme.sh` | `/usr/share/sddm/themes/sugar-candy/`<br>`/etc/sddm.conf.d/theme.conf` | Centered login credentials, pure black background with randomized skull animations (inner 60% focus, 5s interval) |
| **GRUB Bootloader** | `grub/Matrix/`<br>`grub/install-theme.sh` | `/boot/grub/themes/Matrix/`<br>`/etc/default/grub` | Matrix Morpheus "Red Pill vs Blue Pill" theme (Arch Linux Red vs Windows Blue), 1080p graphics, clean 2-entry toggle |
| **Timezone** | *(Configured via script)* | `/etc/localtime` | Automatically sets system clock to **Turkiye Time** (`Europe/Istanbul`, UTC+3) |

---

## How to Restore on a Fresh Installation

After installing your base system and cloning this repository, simply run:

```bash
cd ~/Desktop/Github/shell/backup
./restore.sh
```

The restore script will:
1. Automatically set the system clock to Turkiye time (`Europe/Istanbul`).
2. Safely back up any existing files before replacing them (`*.bak.<timestamp>`).
3. Deploy all wallpapers and configuration files to their respective target paths in `~/.config/`, `~/Pictures/`, and `~/`.
4. Enable and start the 15-minute wallpaper rotation timer.
5. Reload Hyprland and Caelestia Shell if they are running.
