import configparser
import os


class Palette:
    def __init__(self, path=None):
        self.colors = {
            # Main UI
            'background': '#1e1e1e',
            'primary': '#2196f3',
            # Buttons
            'button_bg': '#23272e',
            'button_checked': '#2196f3',
            'button_hover': '#333333',
            # Text & Icons
            'checkbox_fg': '#eeeeee',
            'icon_color': '#eeeeee',
            # Tooltips
            'tooltip_bg': '#23272e',
            'tooltip_fg': '#eeeeee',
        }
        # Load palette file path from settings.yaml if not provided
        if path is None:
            # Try user config first, then fallback to default
            user_settings = os.path.expanduser('~/.config/hyprsnipper/settings.yaml')
            default_settings = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config/settings.yaml'))
            
            palette_file = None
            for settings_path in [user_settings, default_settings]:
                if os.path.exists(settings_path):
                    try:
                        import yaml
                        with open(settings_path) as f:
                            settings = yaml.safe_load(f) or {}
                            palette_file = settings.get('PALETTE_FILE')
                            if palette_file:
                                break
                    except (ImportError, Exception):
                        # Fallback to simple parsing if yaml not available or fails
                        with open(settings_path) as f:
                            for line in f:
                                if line.strip().startswith('PALETTE_FILE:'):
                                    palette_file = line.strip().split(':', 1)[1].strip()
                                    break
                        if palette_file:
                            break
            
            if palette_file:
                # Support both absolute and relative paths
                if os.path.isabs(palette_file):
                    path = palette_file
                else:
                    # Relative to user config directory
                    path = os.path.expanduser(f'~/.config/hyprsnipper/{palette_file}')
                    # If not found in user config, try relative to default config
                    if not os.path.exists(path):
                        path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config', palette_file))
            else:
                # Default fallback
                user_palette = os.path.expanduser('~/.config/hyprsnipper/palette.ini')
                if os.path.exists(user_palette):
                    path = user_palette
                else:
                    path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config/palette.ini'))
        if os.path.exists(path):
            config = configparser.ConfigParser()
            config.read(path)
            if 'palette' in config:
                self.colors.update(config['palette'])

    def __getitem__(self, key):
        return self.colors.get(key, '#fff')
