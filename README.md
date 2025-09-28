# HyprSnipper - Professional Snipping Tool for Hyprland/Wayland

A modern, Qt-based screenshot tool designed specifically for Hyprland and Wayland environments. HyprSnipper provides intuitive window selection, flexible capture modes, and seamless integration with your workflow.

## Features

- **Four Capture Modes**:
  - **Region**: Interactive area selection with slurp
  - **Window**: Visual window layout selector resonably accurate respect to stacking
  - **Full Display**: Capture the entire active display
  - **All Displays**: Capture all connected displays at once

- **Smart Window Selection**: Custom overlay that recreates your window layout for precise selection, working around Wayland input capture limitations

- **Flexible Output Options**:
  - Save to customizable directory
  - Copy to clipboard (wl-clipboard)
  - Open in external editor (swappy, gimp, etc.)

- **Configurable UI**:
  - Minimal, borderless design
  - Hover transparency effects
  - User-customizable icons and color palette
  - Configurable window animation delays

## Quick Start

### Automated Installation
```bash
git clone https://github.com/JWalk9000/hyprsnipper.git
cd hyprsnipper
./install.sh
```

The installer will:
- Install system dependencies (grim, slurp, wl-clipboard, pyside6)
- Set up user configuration directory
- Create desktop entry
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

### Key Settings

**settings.yaml**:
```yaml
SAVE_DIR: ~/Pictures/Screenshots          # Screenshot save location
EDITOR: swappy                            # External editor command
COPY_TO_CLIPBOARD: true                   # Auto-copy to clipboard
WINDOW_ANIMATION_DELAY: 300              # Delay for window close animations (ms)

# Default toggle states
SAVE_ENABLED: true
COPY_ENABLED: true  
EDIT_ENABLED: false
```

### Custom Icons

Place custom `.svg` or `.png` icons in `~/.config/hyprsnipper/icons/` to override defaults:
- `region.svg` - Region selection mode
- `window.svg` - Window selection mode
- `full.svg` - Full display mode
- `alldisplays.svg` - All displays mode

### Pywal Integration

HyprSnipper supports automatic theming with [pywal](https://github.com/dylanaraps/pywal):

1. **Install the template**:
   ```bash
   cp resources/wal/hyprsnipper.ini ~/.config/wal/templates/
   ```

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
- `icon_color` - SVG icon color (monochromatic icons are automatically recolored)
- `tooltip_bg` / `tooltip_fg` - Tooltip appearance

## Hyprland Integration

Add this to your `hyprland.conf` for optimal window selection:

```conf
# Float the window selector overlay
windowrule = float, title:HyprSnipperSelector

# Optional: Bind to a key for quick access
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
```bash
./install.sh --reset      # Restore default settings and icons
```

## Troubleshooting

**Window selector shows empty/wrong layout**: Ensure windows are mapped and visible in the current workspace.

**Screenshots include HyprSnipper UI**: Increase `WINDOW_ANIMATION_DELAY` in settings.yaml.

**Permission errors during install**: Check that you have write access to install directories.

**Missing dependencies**: The installer will detect and install required packages automatically.

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
