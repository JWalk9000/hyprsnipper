# HyprSnipper - A Friendly Snipping Tool for Hyprland

None of the screen-shot tools that I've tried on Hyprland have quite been what I wanted, either multiple key-binds were needed, and/or certain functionality was just not available at all. 
My solution is a Qt-based screenshot tool designed specifically for Hyprland. HyprSnipper provides 4 capture modes, with intuitive window selection, simple integration with your system, and supports editing in your prefered annotation application.

## Features

- **Capture Modes**:
  - **Region**: Interactive area selection with slurp
  - **Window**: Visual window layout selector with resonably accurate respect to stacking
  - **Full Display**: Capture the entire active display
  - **All Displays**: Capture all connected displays at once

- **Intuitive Window Selection**: Uses a window selector that recreates the window layout on the active monitor for application window selection, this is my work-around for the Wayland input capture limitations.

- **Flexible Output Options**:
  - Save to your preferred directory
  - Copy to clipboard (wl-clipboard)
  - Open in external editor (swappy, gimp, etc.)

- **UI Features**:
  - Minimal design.
  - User-customizable icons and color palette.
  - Configurable window animation delays.

## Quick Start

### Download (AppImage)

If you prefer a portable binary, download the latest AppImage from the GitHub Releases page:

- Releases: https://github.com/JWalk9000/hyprsnipper/releases

Run it:
```bash
chmod +x HyprSnipper-*.AppImage
./HyprSnipper-*.AppImage
```

Note: The AppImage bundles Python and PySide6. You still need the host Wayland tools installed (grim, slurp, wl-clipboard) and Hyprland's `hyprctl` for window selection mode.

### Installation
```bash
git clone https://github.com/JWalk9000/hyprsnipper.git
cd hyprsnipper
./install.sh
```
Cloned directory can be deleted after install.

The installer will:
- Install system dependencies (grim, slurp, wl-clipboard, pyside6)
- Set up user configuration directory
- Create a desktop entry
- Add to PATH

### Manual Installation
1. Install dependencies:
   ```bash
   # Arch/Manjaro
   sudo pacman -S grim slurp wl-clipboard pyside6 python-pyyaml python-configparser
   
   # Ubuntu/Debian
   sudo apt install grim slurp wl-clipboard python3-pyside6 python3-yaml python3-configparser
   ```

2. Run directly:
   ```bash
   python3 src/main.py
   ```

## Configuration

HyprSnipper stores user configuration in `~/.config/hyprsnipper/`:

- `settings.yaml` - Main application settings
- `palette.ini` - Color theme configuration  
- `icons/` - Custom icon overrides (optional)

### Customizing

**settings.yaml**:

I have included (hopefully) clear notes in the settings file for customizing its behavior to fit your desires.

### Custom Icons

Place custom `.svg` or `.png` icons in `~/.config/hyprsnipper/icons/` to override defaults:
- `region.svg` - Region selection mode
- `window.svg` - Window selection mode
- `full.svg` - Full display mode
- `alldisplays.svg` - All displays mode

**Note**: HyprSnipper applies theme colors to ALL SVG icons, regardless of their original design. This works best with **monochrome icons** (simple single-color designs). Colorful, multi-color SVG icons will have all their colors replaced with the theme's `icon_color`. Support for preserving colorful icon designs may be supported in future versions if there is enough interest.

#### Icon format behavior

- SVG icons: automatically recolored to your palette's `icon_color` (best for monochrome SVGs)
- PNG icons: preserved as-is with their original colors (best for multi-color artwork)

Tip: Mix formats to taste—use SVG for themeable icons and PNG for colorful ones.

### Pywal Integration

HyprSnipper supports automatic theming with [pywal](https://github.com/dylanaraps/pywal):

1. **Install the template**:
   ```bash
   cp resources/wal/hyprsnipper.ini ~/.config/wal/templates/
   ```
   This template can be customized to use different generated colors if you desire.

2. **Update your settings** to use pywal colors:
   ```yaml
   # In ~/.config/hyprsnipper/settings.yaml
   PALETTE_FILE: ~/.cache/wal/hyprsnipper.ini
   ```

3. **Generate colors** with pywal:
   ```bash
   wal -i /path/to/your/wallpaper
   ```

The `PALETTE_FILE` setting supports both absolute paths and paths relative to `~/.config/hyprsnipper/`.

### Color System

HyprSnipper uses a simplified 8-color palette system for easy theming:

- `background` - Main window background 
- `primary` - Selection rectangles and accents  
- `button_bg` / `button_checked` / `button_hover` - Button states
- `checkbox_fg` - Checkbox text color
- `icon_color` - SVG icon color (**Note**: All SVG colors are replaced with this color - use monochrome icons for best results)
- `tooltip_bg` / `tooltip_fg` - Tooltip appearance

## Hyprland Integration

Add this to your `hyprland.conf` for so that it floats correctly.
```conf
windowrule = float, title:HyprSnipperSelector
```
Optional: Bind to a key for quick access
```conf
bind = $mainMod SHIFT, S, exec, hyprsnipper
```

## Architecture

```
hyprsnipper/
├── src/
│   ├── main.py                    # Application entry point
│   └── ui/
│       ├── snipper_window.py     # Main UI window
│       ├── window_selector.py    # Window layout overlay
│       ├── region_selector.py    # Region selection handler
│       ├── full_display.py       # Full display capture
│       ├── all_displays.py       # Multi-display capture
│       └── palette.py            # Color theme system
├── config/
│   ├── settings.yaml             # Default settings
│   └── palette.ini               # Default color theme
├── resources/icons/              # Default SVG icons
└── install.sh                    # Automated installer
```

## Advanced Usage

### Window Animation Delay
Different systems have varying window animation speeds. Adjust `WINDOW_ANIMATION_DELAY` in settings.yaml:
- Fast systems/no animations: `0`
- Default: `300` 
- Slow systems/heavy animations: `500+`

This prevents the HyprSnipper UI from appearing in screenshots.

### Custom Workflows
HyprSnipper integrates with any image editor or workflow tool:
```yaml
EDITOR: gimp              # Open in GIMP
EDITOR: krita             # Open in Krita  
EDITOR: swappy            # Default: swappy for quick annotation
```

### Reset Configuration
If, for any reason, you wish to return to a default configuration you can run this to reset the config. I primarily used this for testing, but there it is if you need it.
```bash
./install.sh --reset      # Restore default settings and icons
```

## Troubleshooting

**Window selector shows empty/wrong layout**: Ensure main Hyprsnipper UI is opened on workspace you want to take the snip of.

**Screenshots include HyprSnipper UI**: Increase `WINDOW_ANIMATION_DELAY` in settings.yaml.

**Permission errors during install**: Check that you have write access to install directories.

**Missing dependencies**: The installer should detect and install required packages automatically, if you find something missing please let me know.

## Dependencies

- **Python 3.7+** (uses `subprocess.run(capture_output=True)` - could be made 3.6+ compatible)
- **PySide6** - Qt bindings for Python
- **PyYAML** - Configuration file parsing
- **grim** - Wayland screenshot utility
- **slurp** - Wayland area selection  
- **wl-clipboard** - Wayland clipboard integration

### Python Version Compatibility

Currently requires **Python 3.7+** due to `subprocess.run(capture_output=True)` usage. However, the code could easily be made compatible with Python 3.6+ by replacing a few subprocess calls.

**Community testing welcome!** If you test with older Python versions or have compatibility issues, please [open an issue](https://github.com/JWalk9000/hyprsnipper/issues).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test on Hyprland/Wayland
5. Submit a pull request

## License

See [LICENSE](LICENSE) file for details.
