# HyprSnipper - Professional Qt-based Snipping Tool for Hyprland/Wayland

## Structure

- `src/` — Python source code (main.py, ui/)
- `resources/icons/` — SVG icons for UI
- `config/` — settings
- `docs/` — instructions

## Run

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```
2. Run the app:
   ```bash
   python3 src/main.py
   ```

## UI/UX
- Minimal, borderless, always-on-top window
- Four icon buttons (region, window, full, all displays)
- Toggle switches for Save, Copy, Edit
- Window is opaque on hover, transparent when mouse leaves
- Modern, professional style (customizable in `ui/snipper_window.py`)

## Extend
- Add logic for screenshot actions in `snipper_window.py`
- Replace SVGs in `resources/icons/` for custom look

## Hyprland Integration

To ensure the window selector overlays always float and are not tiled, add this to your `hyprland.conf`:

```
windowrule=float,title:HyprSnipperSelector
```

This will make all snipping selector overlays float above tiled windows for correct selection behavior.
