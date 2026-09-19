# Arch main setup

## Main apps

```sh
sudo pacman -S --needed git gcc nano os-prober fastfetch man jq noto-fonts-emoji iptables unzip dnsmasq wget nftables linux-zen linux-zen-headers nvidia-open-dkms nvidia-utils dkms noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-dejavu hyprmod gnome-desktop-4
```

## Grub (zen kernel)

```sh
# 1. Install necessary boot packages
sudo pacman -S --needed grub efibootmgr os-prober intel-ucode

# 2. Fix mkinitcpio preset: enable traditional initramfs and disable UKI
sudo sed -i 's/^#default_image=/default_image=/' /etc/mkinitcpio.d/linux-zen.preset
sudo sed -i 's/^default_uki=/#default_uki=/' /etc/mkinitcpio.d/linux-zen.preset
sudo sed -i 's/^#fallback_image=/fallback_image=/' /etc/mkinitcpio.d/linux-zen.preset
sudo sed -i 's/^fallback_uki=/#fallback_uki=/' /etc/mkinitcpio.d/linux-zen.preset

# 3. Build the missing initramfs-linux.img
sudo mkinitcpio -p linux-zen

# 4. Remove leftover UKI binary so GRUB stops creating the duplicate entry
sudo rm -f /boot/EFI/Linux/arch-linux.efi

# 5. Enable os-prober to detect Windows 11
echo "GRUB_DISABLE_OS_PROBER=false" | sudo tee -a /etc/default/grub

# 6. Make a file executable
chmod +x /etc/grub.d/10_linux

# 7. Regenerate the GRUB config
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

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