#!/bin/bash
# HyprSnipper install script (using bundled wrapper)
set -e

RESET=0
if [[ "$1" == "--reset" ]]; then
    RESET=1
    echo "[HyprSnipper] Reset mode: user config and icons will be overwritten with defaults."
fi

# Detect distro
if [ -f /etc/os-release ]; then
    . /etc/os-release
    DISTRO=${ID:-unknown}
    ID_LIKE=${ID_LIKE:-}
else
    DISTRO="unknown"
    ID_LIKE=""
fi

APP_NAME="hyprsnipper"
CONFIG_DIR="$HOME/.config/$APP_NAME"
SRC_DIR="$(dirname "$(realpath "$0")")"
DEFAULT_ICONS_DIR="$SRC_DIR/resources/icons"

DESKTOP_FILE="$APP_NAME.desktop"
SYSTEM_REQS=(grim slurp wl-clipboard pyside6)
PYTHON_REQS=(pyyaml configparser)

# 1. Create config dir and copy defaults, unless they already exist, or --reset is given.
create_config_files() {
    mkdir -p "$CONFIG_DIR"
    # Only create or overwrite if --reset is given or files/icons don't exist
    if [[ $RESET -eq 1 || ! -f "$CONFIG_DIR/settings.yaml" ]]; then
        cp -f "$SRC_DIR/config/settings.yaml" "$CONFIG_DIR/settings.yaml"
    fi
    if [[ $RESET -eq 1 || ! -f "$CONFIG_DIR/palette.ini" ]]; then
        cp -f "$SRC_DIR/config/palette.ini" "$CONFIG_DIR/palette.ini"
    fi
    if [[ $RESET -eq 1 || ! -d "$CONFIG_DIR/icons" ]]; then
        rm -rf "$CONFIG_DIR/icons"
        mkdir -p "$CONFIG_DIR/icons"
        cp -r "$DEFAULT_ICONS_DIR/"* "$CONFIG_DIR/icons/"
    fi
}

# 2. Copy files to system or user install dir
install_as_app() {
    while true; do
        read -p "Install as user app (u) or system app (s)? [u/s]: " USYS
        if [[ "$USYS" == "u" || "$USYS" == "s" ]]; then
            break
        else
            echo "Please enter 'u' for user or 's' for system."
        fi
    done

    if [[ "$USYS" == "s" ]]; then
        INSTALL_DIR="/usr/local/share/$APP_NAME"
        BIN_PATH="/usr/local/bin/$APP_NAME"
        DESKTOP_PATH="/usr/share/applications/$DESKTOP_FILE"
        SUDO=sudo
    else
        INSTALL_DIR="$HOME/.local/share/$APP_NAME"
        BIN_PATH="$HOME/.local/bin/$APP_NAME"
        DESKTOP_PATH="$HOME/.local/share/applications/$DESKTOP_FILE"
        SUDO=""
        mkdir -p "$HOME/.local/bin"
    fi

    # Copy source files
    $SUDO mkdir -p "$INSTALL_DIR"
    $SUDO rsync -a --delete \
        --exclude='.git' \
        --exclude='.vscode' \
        --exclude='test' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        "$SRC_DIR/" "$INSTALL_DIR/"
    APP_ENTRY="$INSTALL_DIR/$APP_NAME"
    $SUDO tee "$APP_ENTRY" > /dev/null <<EOF
#!/bin/bash
# HyprSnipper launcher script
cd "$INSTALL_DIR/src"
exec python3 main.py "\$@"
EOF
    $SUDO chmod +x "$APP_ENTRY"

    # Symlink wrapper into PATH
    $SUDO ln -sf "$APP_ENTRY" "$BIN_PATH"
}

# 3. Write .desktop file
create_desktop_entry() {
    cat > /tmp/$DESKTOP_FILE <<EOF
[Desktop Entry]
Type=Application
Name=HyprSnipper
Exec=$APP_NAME
Icon=$CONFIG_DIR/icons/full.svg
Terminal=false
Categories=Utility;
EOF
    $SUDO mkdir -p "$(dirname "$DESKTOP_PATH")"
    $SUDO cp /tmp/$DESKTOP_FILE "$DESKTOP_PATH"
    echo "Desktop entry installed to $DESKTOP_PATH"
}

# 4. Install required packages
filter_installed_packages() {
    local -n arr=$1
    local pkgtype=$2
    local filtered=()
    for pkg in "${arr[@]}"; do
        if [[ "$pkgtype" == "arch" ]]; then
            if ! pacman -Qq "$pkg" &>/dev/null; then
                filtered+=("$pkg")
            fi
        elif [[ "$pkgtype" == "debian" ]]; then
            if ! dpkg -s "$pkg" &>/dev/null; then
                filtered+=("$pkg")
            fi
        fi
    done
    arr=("${filtered[@]}")
}

install_required_packages() {
    # Treat common Arch derivatives as Arch
    if [[ "$DISTRO" == "arch" || "$DISTRO" == "manjaro" || "$DISTRO" == "endeavouros" || "$DISTRO" == "garuda" || "$DISTRO" == "artix" || "$DISTRO" == "cachyos" || "$ID_LIKE" == *"arch"* ]]; then
        NEW_PYTHON_REQS=()
        for REQ in "${PYTHON_REQS[@]}"; do
            NEW_PYTHON_REQS+=("python-$REQ")
        done
        PYTHON_REQS=("${NEW_PYTHON_REQS[@]}")
        filter_installed_packages PYTHON_REQS arch
        filter_installed_packages SYSTEM_REQS arch
        if [[ ${#PYTHON_REQS[@]} -gt 0 || ${#SYSTEM_REQS[@]} -gt 0 ]]; then
            if command -v yay >/dev/null 2>&1; then
                yay -S --needed "${SYSTEM_REQS[@]}" "${PYTHON_REQS[@]}" || sudo pacman -S --needed "${SYSTEM_REQS[@]}" "${PYTHON_REQS[@]}"
            else
                sudo pacman -S --needed "${SYSTEM_REQS[@]}" "${PYTHON_REQS[@]}"
            fi
        else
            echo "All required packages are already installed."
        fi
    elif [[ "$DISTRO" == "debian" || "$DISTRO" == "ubuntu" || "$ID_LIKE" == *"debian"* ]]; then
        NEW_PYTHON_REQS=()
        for REQ in "${PYTHON_REQS[@]}"; do
            NEW_PYTHON_REQS+=("python3-$REQ")
        done
        PYTHON_REQS=("${NEW_PYTHON_REQS[@]}")
        filter_installed_packages PYTHON_REQS debian
        filter_installed_packages SYSTEM_REQS debian
        if [[ ${#PYTHON_REQS[@]} -gt 0 || ${#SYSTEM_REQS[@]} -gt 0 ]]; then
            sudo apt update
            sudo apt install -y "${PYTHON_REQS[@]}" "${SYSTEM_REQS[@]}"
        else
            echo "All required packages are already installed."
        fi
    elif [[ "$DISTRO" == "fedora" || "$DISTRO" == "rhel" || "$DISTRO" == "centos" || "$ID_LIKE" == *"rhel"* || "$ID_LIKE" == *"fedora"* ]]; then
        # Fedora family
        PY_PKGS=(python3-pyyaml python3-configparser python3-pyside6)
        SYS_PKGS=(grim slurp wl-clipboard libnotify)
        sudo dnf install -y "${PY_PKGS[@]}" "${SYS_PKGS[@]}" || sudo yum install -y "${PY_PKGS[@]}" "${SYS_PKGS[@]}"
    elif [[ "$DISTRO" == "opensuse-tumbleweed" || "$DISTRO" == "opensuse-leap" || "$ID_LIKE" == *"suse"* ]]; then
        PY_PKGS=(python3-PyYAML python3-configparser python3-PySide6)
        SYS_PKGS=(grim slurp wl-clipboard libnotify-tools)
        sudo zypper install -y "${PY_PKGS[@]}" "${SYS_PKGS[@]}"
    else
        echo "Please install Python 3 and the following packages manually:"
        echo "Python packages: ${PYTHON_REQS[*]}"
        echo "System packages: ${SYSTEM_REQS[*]}"
    fi
}

# Run steps
install_as_app
create_desktop_entry
create_config_files
install_required_packages

echo "✅ Install complete! Launch with: $APP_NAME"
