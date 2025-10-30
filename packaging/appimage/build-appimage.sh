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
# linuxdeploy-plugin-python moved/varies; try to fetch, but fall back to PyInstaller bundling if unavailable
PYPLUGIN_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-python/releases/download/continuous/linuxdeploy-plugin-python-${ARCH}.AppImage"

mkdir -p "$PROJECT_ROOT/packaging/appimage/tools"
TOOLS_DIR="$PROJECT_ROOT/packaging/appimage/tools"

fetch() {
  local url="$1" out="$2"
  if [ ! -f "$out" ]; then
    echo "[build] downloading $url"
    if ! wget -O "$out" "$url"; then
      return 1
    fi
    chmod +x "$out" || true
  fi
}

fetch "$LINUXDEPLOY_URL" "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage"
USE_PLUGIN=1
if ! fetch "$PYPLUGIN_URL" "$TOOLS_DIR/linuxdeploy-plugin-python-${ARCH}.AppImage"; then
  echo "[build] python plugin not found; will bundle via PyInstaller instead"
  USE_PLUGIN=0
fi

# Clean AppDir
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin" "$APPDIR/usr/share/$BIN_NAME" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/scalable/apps"

if [ "$USE_PLUGIN" -eq 1 ]; then
  echo "[build] Using linuxdeploy python plugin bundling"
  # Copy application files (python will be provided by plugin)
  cp -r "$PROJECT_ROOT/src" "$APPDIR/usr/share/$BIN_NAME/"
  cp -r "$PROJECT_ROOT/config" "$APPDIR/usr/share/$BIN_NAME/"
  cp -r "$PROJECT_ROOT/resources" "$APPDIR/usr/share/$BIN_NAME/"

  # Create launcher wrapper that invokes system python (bundled by plugin)
  cat > "$APPDIR/usr/bin/$BIN_NAME" <<'EOF'
#!/usr/bin/env bash
set -e
cd "$(dirname "$0")/../share/hyprsnipper/src"
exec python3 main.py "$@"
EOF
  chmod +x "$APPDIR/usr/bin/$BIN_NAME"
else
  echo "[build] Using PyInstaller bundling (fallback)"
  # Ensure Python deps installed
  python3 -m pip install --upgrade pip
  python3 -m pip install -r "$PROJECT_ROOT/requirements.txt" pyinstaller
  # Build binary with PyInstaller
  cd "$PROJECT_ROOT"
  pyinstaller -y --noconsole --name "$BIN_NAME" \
    --paths src \
    --add-data "config:config" \
    --add-data "resources:resources" \
    src/main.py
  # Place binary into AppDir
  install -m755 -D "$PROJECT_ROOT/dist/$BIN_NAME/$BIN_NAME" "$APPDIR/usr/bin/$BIN_NAME"
  # Also ship the data alongside in share
  cp -r "$PROJECT_ROOT/config" "$APPDIR/usr/share/$BIN_NAME/"
  cp -r "$PROJECT_ROOT/resources" "$APPDIR/usr/share/$BIN_NAME/"
fi

# Desktop entry (adjust Icon to name-only for AppImage)
sed 's|^Icon=.*$|Icon=hyprsnipper|g' "$PROJECT_ROOT/resources/desktop/hyprsnipper.desktop" > "$APPDIR/usr/share/applications/hyprsnipper.desktop"

# Install icon (use shipped svg)
cp "$PROJECT_ROOT/resources/icons/full.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg"

# Environment for linuxdeploy
export OUTPUT="${APPNAME}-${ARCH}.AppImage"
export VERSION="${VERSION:-v1.0.1}"

# Use linuxdeploy with python plugin to bundle Python + deps from requirements.txt
if [ "$USE_PLUGIN" -eq 1 ]; then
  "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage" \
      --appdir "$APPDIR" \
      --executable "$APPDIR/usr/bin/$BIN_NAME" \
      --desktop-file "$APPDIR/usr/share/applications/hyprsnipper.desktop" \
      --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg" \
      --output appimage \
      --plugin python \
      -- \
      --python-include "$(tr '\n' ' ' < "$PROJECT_ROOT/requirements.txt")"
else
  "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage" \
      --appdir "$APPDIR" \
      --executable "$APPDIR/usr/bin/$BIN_NAME" \
      --desktop-file "$APPDIR/usr/share/applications/hyprsnipper.desktop" \
      --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg" \
      --output appimage
fi

mv "$OUTPUT" "$PROJECT_ROOT/$OUTPUT"
echo "Created $PROJECT_ROOT/$OUTPUT"
