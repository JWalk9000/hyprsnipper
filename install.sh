#!/bin/bash
# HyprSnipper install script
set -e

RESET=0
if [[ "$1" == "--reset" ]]; then
    RESET=1
    echo "[HyprSnipper] Reset mode: user config and icons will be overwritten with defaults."
fi

APP_NAME="hyprsnipper"
CONFIG_DIR="$HOME/.config/$APP_NAME"
SRC_DIR="$(dirname "$(realpath "$0")")"
ICONS_DIR="$CONFIG_DIR/icons"
DEFAULT_ICONS_DIR="$SRC_DIR/resources/icons"
DESKTOP_FILE="$APP_NAME.desktop"

# 1. Create config dir and copy defaults
mkdir -p "$CONFIG_DIR"
mkdir -p "$ICONS_DIR"
if [[ $RESET -eq 1 ]]; then
    cp -f "$SRC_DIR/config/settings.yaml" "$CONFIG_DIR/settings.yaml"
    cp -f "$SRC_DIR/config/palette.ini" "$CONFIG_DIR/palette.ini"
else
    cp -n "$SRC_DIR/config/settings.yaml" "$CONFIG_DIR/settings.yaml"
    cp -n "$SRC_DIR/config/palette.ini" "$CONFIG_DIR/palette.ini"
fi
# Copy default icons
for icon in "$DEFAULT_ICONS_DIR"/*; do
    fname="$(basename "$icon")"
    if [[ $RESET -eq 1 ]]; then
        cp -f "$icon" "$ICONS_DIR/$fname"
    else
        if [ ! -f "$ICONS_DIR/$fname" ]; then
            cp "$icon" "$ICONS_DIR/"
        fi
    fi
    # Support .svg and .png
    if [[ "$fname" == *.svg ]]; then
        png="${fname%.svg}.png"
        if [[ $RESET -eq 1 ]]; then
            [ -f "$DEFAULT_ICONS_DIR/$png" ] && cp -f "$DEFAULT_ICONS_DIR/$png" "$ICONS_DIR/$png"
        else
            [ -f "$DEFAULT_ICONS_DIR/$png" ] && [ ! -f "$ICONS_DIR/$png" ] && cp "$DEFAULT_ICONS_DIR/$png" "$ICONS_DIR/"
        fi
    fi
    if [[ "$fname" == *.png ]]; then
        svg="${fname%.png}.svg"
        if [[ $RESET -eq 1 ]]; then
            [ -f "$DEFAULT_ICONS_DIR/$svg" ] && cp -f "$DEFAULT_ICONS_DIR/$svg" "$ICONS_DIR/$svg"
        else
            [ -f "$DEFAULT_ICONS_DIR/$svg" ] && [ ! -f "$ICONS_DIR/$svg" ] && cp "$DEFAULT_ICONS_DIR/$svg" "$ICONS_DIR/"
        fi
    fi
    # User icons in $ICONS_DIR override defaults unless --reset
    # (no action needed, just don't overwrite unless reset)
done

# 2. .desktop entry
read -p "Install as user app (u) or system app (s)? [u/s]: " USYS
if [[ "$USYS" == "s" ]]; then
    DESKTOP_PATH="/usr/share/applications/$DESKTOP_FILE"
    BIN_PATH="/usr/local/bin/$APP_NAME"
    SUDO=sudo
    # Copy all app files to /usr/local/bin/hyprsnipper
    $SUDO mkdir -p "/usr/local/bin/$APP_NAME"
    $SUDO cp -r "$SRC_DIR"/* "/usr/local/bin/$APP_NAME/"
    APP_LAUNCH_PATH="/usr/local/bin/$APP_NAME/bin/snip.sh"
else
    DESKTOP_PATH="$HOME/.local/share/applications/$DESKTOP_FILE"
    BIN_PATH="$HOME/.local/bin/$APP_NAME"
    SUDO=""
    mkdir -p "$HOME/.local/bin/$APP_NAME"
    cp -r "$SRC_DIR"/* "$HOME/.local/bin/$APP_NAME/"
    APP_LAUNCH_PATH="$HOME/.local/bin/$APP_NAME/bin/snip.sh"
    mkdir -p "$HOME/.local/bin"
fi

# Write .desktop file
cat > /tmp/$DESKTOP_FILE <<EOF
[Desktop Entry]
Type=Application
Name=HyprSnipper
Exec=$APP_LAUNCH_PATH
Icon=$ICONS_DIR/full.svg
Terminal=false
Categories=Utility;
EOF
$SUDO cp /tmp/$DESKTOP_FILE "$DESKTOP_PATH"

# 3. Install requirements
# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=$ID
else
    DISTRO="unknown"
fi

install_python_packages() {
    if [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" ]]; then
        yay -S --needed python-pyside6 python-pyyaml python-configparser grim slurp wl-clipboard || \
        sudo pacman -S --needed python-pyside6 python-pyyaml python-configparser grim slurp wl-clipboard
    elif [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" ]]; then
        sudo apt update
        sudo apt install -y python3-pyside6.qtcore python3-pyside6.qtwidgets python3-pyside6.qtgui python3-yaml python3-configparser grim slurp wl-clipboard
    else
        echo "Please install Python 3, PySide6, PyYAML, configparser, grim, slurp, wl-clipboard manually."
    fi
}

install_python_packages

# 4. Add to PATH
if [[ "$USYS" == "s" ]]; then
    $SUDO ln -sf "$APP_LAUNCH_PATH" "$BIN_PATH"
else
    ln -sf "$APP_LAUNCH_PATH" "$BIN_PATH"
    if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
        export PATH="$HOME/.local/bin:$PATH"
    fi
fi

echo "Install complete! Launch with: $APP_NAME"
