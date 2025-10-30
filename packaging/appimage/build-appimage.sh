#!/usr/bin/env bash
set -euo pipefail

# Simple AppImage build script using linuxdeploy and its python plugin
# Requires: wget, chmod, linuxdeploy, linuxdeploy-plugin-python
# Output: HyprSnipper-${ARCH}.AppImage in the project root

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APPDIR="$PROJECT_ROOT/HyprSnipper.AppDir"
APPNAME="HyprSnipper"
BIN_NAME="hyprsnipper"
ARCH=${ARCH:-x86_64}

# Tools
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage"
PYPLUGIN_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-python/releases/download/continuous/linuxdeploy-plugin-python-${ARCH}.AppImage"

mkdir -p "$PROJECT_ROOT/packaging/appimage/tools"
TOOLS_DIR="$PROJECT_ROOT/packaging/appimage/tools"

fetch() {
  local url="$1" out="$2"
  if [ ! -f "$out" ]; then
    wget -O "$out" "$url"
    chmod +x "$out"
  fi
}

fetch "$LINUXDEPLOY_URL" "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage"
fetch "$PYPLUGIN_URL" "$TOOLS_DIR/linuxdeploy-plugin-python-${ARCH}.AppImage"

# Clean AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/$BIN_NAME" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/scalable/apps"

# Copy application files
cp -r "$PROJECT_ROOT/src" "$APPDIR/usr/share/$BIN_NAME/"
cp -r "$PROJECT_ROOT/config" "$APPDIR/usr/share/$BIN_NAME/"
cp -r "$PROJECT_ROOT/resources" "$APPDIR/usr/share/$BIN_NAME/"

# Create launcher wrapper
cat > "$APPDIR/usr/bin/$BIN_NAME" <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../share/hyprsnipper/src"
exec python3 main.py "$@"
EOF
chmod +x "$APPDIR/usr/bin/$BIN_NAME"

# Desktop entry (adjust Icon to name-only for AppImage)
sed 's|^Icon=.*$|Icon=hyprsnipper|g' "$PROJECT_ROOT/resources/desktop/hyprsnipper.desktop" > "$APPDIR/usr/share/applications/hyprsnipper.desktop"

# Install icon (use shipped svg)
cp "$PROJECT_ROOT/resources/icons/full.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg"

# Environment for linuxdeploy
export OUTPUT="${APPNAME}-${ARCH}.AppImage"
export VERSION="${VERSION:-v1.0.1}"

# Use linuxdeploy with python plugin to bundle Python + deps from requirements.txt
"$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage" \
    --appdir "$APPDIR" \
    --executable "$APPDIR/usr/bin/$BIN_NAME" \
    --desktop-file "$APPDIR/usr/share/applications/hyprsnipper.desktop" \
    --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg" \
    --output appimage \
    --plugin python \
    -- \
    --python-include "$(cat "$PROJECT_ROOT/requirements.txt" | tr '\n' ' ')"

mv "$OUTPUT" "$PROJECT_ROOT/$OUTPUT"
echo "Created $PROJECT_ROOT/$OUTPUT"
