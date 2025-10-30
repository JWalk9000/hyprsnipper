# AppImage packaging

This repo includes a lightweight script to build an AppImage for HyprSnipper using linuxdeploy and its Python plugin.

## Requirements
- Linux host
- `wget`, `bash`
- Internet access to fetch linuxdeploy and plugin

## Build steps
```bash
# From repo root
chmod +x packaging/appimage/build-appimage.sh
ARCH=x86_64 VERSION=v1.0.1 packaging/appimage/build-appimage.sh
# Output: HyprSnipper-x86_64.AppImage in repo root
```

## Notes
- The script first tries `linuxdeploy` + `linuxdeploy-plugin-python` (bundles Python), but if the plugin is unavailable it automatically falls back to bundling with **PyInstaller** and then wraps with `linuxdeploy`.
- The AppImage bundles Python and Python dependencies from `requirements.txt` (via plugin) or via PyInstaller fallback.
- HyprSnipper relies on host Wayland tools (grim, slurp, wl-clipboard) and Hyprland's hyprctl for window info.
  Users still need these installed on the host.
- The AppImage integrates a desktop entry and icon internally.
