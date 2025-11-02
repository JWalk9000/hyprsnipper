#!/usr/bin/env bash
set -euo pipefail
export PYTHONNOUSERSITE=1

# Simple AppImage build script using linuxdeploy and its python plugin
# Requires: wget, chmod, linuxdeploy, linuxdeploy-plugin-python
# Output: HyprSnipper-${VERSION}-${ARCH}.AppImage in the project root and dist/

PROJECT_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
APPDIR="$PROJECT_ROOT/HyprSnipper.AppDir"
APPNAME="HyprSnipper"
BIN_NAME="hyprsnipper"
ARCH=${ARCH:-x86_64}

# Tools
LINUXDEPLOY_URL="https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage"
# linuxdeploy-plugin-python moved/varies; try to fetch, but fall back to PyInstaller bundling if unavailable
PYPLUGIN_URL="https://github.com/linuxdeploy/linuxdeploy-plugin-python/releases/download/continuous/linuxdeploy-plugin-python-${ARCH}.AppImage"
APPIMAGETOOL_URL="https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"

mkdir -p "$PROJECT_ROOT/packaging/appimage/tools"
TOOLS_DIR="$PROJECT_ROOT/packaging/appimage/tools"

fetch() {
  local url="$1" out="$2"
  if [ ! -f "$out" ]; then
    echo "[build] downloading $url"
    if command -v curl >/dev/null 2>&1; then
      curl -L "$url" -o "$out" || true
    elif command -v wget >/dev/null 2>&1; then
      wget -O "$out" "$url" || true
    else
      echo "[build] ERROR: neither curl nor wget is available to download $url" >&2
      return 1
    fi
  fi
  if [ -f "$out" ]; then
    chmod +x "$out" || true
    return 0
  else
    return 1
  fi
}

fetch "$LINUXDEPLOY_URL" "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage"
fetch "$APPIMAGETOOL_URL" "$TOOLS_DIR/appimagetool-${ARCH}.AppImage"
USE_PLUGIN=0
if fetch "$PYPLUGIN_URL" "$TOOLS_DIR/linuxdeploy-plugin-python-${ARCH}.AppImage"; then
  # Consider plugin valid only if the file seems non-empty (GitHub 404 can be tiny)
  if [ -s "$TOOLS_DIR/linuxdeploy-plugin-python-${ARCH}.AppImage" ] && [ $(stat -c%s "$TOOLS_DIR/linuxdeploy-plugin-python-${ARCH}.AppImage") -gt 100000 ]; then
    USE_PLUGIN=1
  else
    echo "[build] python plugin appears invalid/small; using PyInstaller fallback"
    rm -f "$TOOLS_DIR/linuxdeploy-plugin-python-${ARCH}.AppImage" || true
  fi
else
  echo "[build] python plugin not found; using PyInstaller fallback"
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
  # Ensure Python deps installed (pin PyInstaller for stability)
  VENV_DIR="$TOOLS_DIR/venv-build"
  rm -rf "$VENV_DIR"
  python3 -m venv "$VENV_DIR"
  # shellcheck disable=SC1090
  source "$VENV_DIR/bin/activate"
  pip install --upgrade pip setuptools wheel
  pip install -r "$PROJECT_ROOT/requirements.txt" "pyinstaller>=6.6"
  # Build onedir so libpython and all libs live beside the binary (more robust inside AppImage)
  cd "$PROJECT_ROOT"
  pyinstaller -y --noconsole --name "$BIN_NAME" --onedir \
    --paths src \
    --add-data "config:config" \
    --add-data "resources:resources" \
    src/main.py
  # Place the onedir bundle into AppDir and wrap it
  mkdir -p "$APPDIR/usr/lib/$BIN_NAME"
  cp -r "$PROJECT_ROOT/dist/$BIN_NAME"/* "$APPDIR/usr/lib/$BIN_NAME/"
  # Remove problematic/unused Qt imageformat plugins to reduce deps (e.g., libtiff)
  find "$APPDIR/usr/lib/$BIN_NAME" -type f -name 'libqtiff.so' -delete || true
  # Wrapper executes the bundled binary directly
  cat > "$APPDIR/usr/bin/$BIN_NAME" <<'EOF'
#!/usr/bin/env bash
set -e
exec "$(dirname "$0")/../lib/hyprsnipper/hyprsnipper" "$@"
EOF
  chmod +x "$APPDIR/usr/bin/$BIN_NAME"
  # Also ship the data alongside in share for non-PyInstaller path parity
  cp -r "$PROJECT_ROOT/config" "$APPDIR/usr/share/$BIN_NAME/"
  cp -r "$PROJECT_ROOT/resources" "$APPDIR/usr/share/$BIN_NAME/"
  deactivate || true
  # Create minimal AppRun for appimagetool
  cat > "$APPDIR/AppRun" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
HERE="$(dirname "$(readlink -f "$0")")"
export APPDIR="$HERE"
exec "$HERE/usr/bin/hyprsnipper" "$@"
EOF
  chmod +x "$APPDIR/AppRun"
fi

# Desktop entry (adjust Icon and Categories for AppImage)
sed -e 's|^Icon=.*$|Icon=hyprsnipper|g' \
  -e 's|^Categories=.*$|Categories=Graphics;|g' \
  "$PROJECT_ROOT/resources/desktop/hyprsnipper.desktop" > "$APPDIR/usr/share/applications/hyprsnipper.desktop"
# Also place a copy at the AppDir root for appimagetool
cp "$APPDIR/usr/share/applications/hyprsnipper.desktop" "$APPDIR/hyprsnipper.desktop"

# Install icon (use shipped svg)
cp "$PROJECT_ROOT/resources/icons/full.svg" "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg"
# Also place an icon at the AppDir root to satisfy appimagetool's desktop validation
cp "$PROJECT_ROOT/resources/icons/full.svg" "$APPDIR/hyprsnipper.svg"
# If ImageMagick's convert is available, create a 256x256 PNG as well for best compatibility
if command -v convert >/dev/null 2>&1; then
  convert -background none -resize 256x256 "$PROJECT_ROOT/resources/icons/full.svg" "$APPDIR/hyprsnipper.png" || true
  # Use .DirIcon to set the AppImage icon in some launchers
  cp "$APPDIR/hyprsnipper.png" "$APPDIR/.DirIcon" || true
fi

# Ensure no AppStream metadata is included (avoid strict validation failures for now)
rm -rf "$APPDIR/usr/share/metainfo" || true

# Environment for linuxdeploy
export VERSION="${VERSION:-v1.0.1}"
export OUTPUT="${APPNAME}-${VERSION}-${ARCH}.AppImage"
export PYTHONNOUSERSITE=1

# Use linuxdeploy with python plugin to bundle Python + deps from requirements.txt
if [ "$USE_PLUGIN" -eq 1 ]; then
  export PIP_REQUIREMENTS="$PROJECT_ROOT/requirements.txt"
  PATH="$TOOLS_DIR:$PATH" "$TOOLS_DIR/linuxdeploy-${ARCH}.AppImage" \
      --appdir "$APPDIR" \
      --executable "$APPDIR/usr/bin/$BIN_NAME" \
      --desktop-file "$APPDIR/usr/share/applications/hyprsnipper.desktop" \
      --icon-file "$APPDIR/usr/share/icons/hicolor/scalable/apps/hyprsnipper.svg" \
      --output appimage \
      --plugin python
else
  # Build AppImage directly from AppDir using appimagetool
  "$TOOLS_DIR/appimagetool-${ARCH}.AppImage" "$APPDIR" "$OUTPUT"
fi

  # Move output to project root if needed and stage in dist/
  if [ -f "$OUTPUT" ]; then
    SRC_PATH="$(realpath "$OUTPUT")"
    DST_PATH="$(realpath -m "$PROJECT_ROOT/$OUTPUT")"
    if [ "$SRC_PATH" != "$DST_PATH" ]; then
      mv "$OUTPUT" "$PROJECT_ROOT/$OUTPUT"
      echo "Created $PROJECT_ROOT/$OUTPUT"
    else
      echo "[build] Output already at $DST_PATH"
    fi
    # Stage to dist and write checksum
    mkdir -p "$PROJECT_ROOT/dist"
    cp -f "$PROJECT_ROOT/$OUTPUT" "$PROJECT_ROOT/dist/" 
    if command -v sha256sum >/dev/null 2>&1; then
      (cd "$PROJECT_ROOT/dist" && sha256sum "$OUTPUT" > "$OUTPUT.sha256")
      echo "[build] Checksum written to dist/$OUTPUT.sha256"
    fi
  else
    echo "[build] ERROR: Expected output $OUTPUT not found" >&2
    exit 1
  fi
