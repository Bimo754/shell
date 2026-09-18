# Dependencies

```sh
# 1. Official repositories
sudo pacman -S --needed \
    aubio \
    ddcutil \
    qt6-imageformats \
    ttf-material-symbols-variable \
    ttf-cascadia-code-nerd

# 2. AUR dependencies (Quickshell git build, libcava, fonts, & Material 3 shapes)
yay -S --needed \
    quickshell-git \
    qt6-m3shapes-git \
    ttf-rubik-vf \
    libcava \
    caelestia-cli
```

# Building

```sh
cd ~/Desktop/Github/shell
mkdir -p ~/.config/quickshell/caelestia
cmake -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/ -DINSTALL_QSCONFDIR="$HOME/.config/quickshell/caelestia"
cmake --build build
sudo cmake --install build
sudo chown -R $USER ~/.config/quickshell/caelestia
```

# Initialize user settings

```sh
mkdir -p ~/.config/caelestia
cat << 'EOF' > ~/.config/caelestia/shell.json
{
    "enabled": true
}
EOF
```

# Launch

```sh
caelestia shell -d
```