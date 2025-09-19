import configparser
import os


class Palette:
    def __init__(self, path=None):
        self.colors = {
            'background': '#1e1e1e',
            'foreground': '#eeeeee',
            'primary': '#2196f3',
            'accent': '#4caf50',
            'warning': '#ff9800',
            'highlight': '#9c27b0',
            'button_bg': '#23272e',
            'button_checked': '#2196f3',
            'button_hover': '#333333',
            'checkbox_fg': '#eeeeee',
            'tooltip_bg': '#23272e',
            'tooltip_fg': '#eeeeee',
        }
        # Load palette file path from settings.yaml if not provided
        if path is None:
            settings_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config/settings.yaml'))
            palette_file = None
            if os.path.exists(settings_path):
                with open(settings_path) as f:
                    for line in f:
                        if line.strip().startswith('PALETTE_FILE='):
                            palette_file = line.strip().split('=', 1)[1]
                            break
            if palette_file:
                if not os.path.isabs(palette_file):
                    path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config', palette_file))
                else:
                    path = palette_file
            else:
                path = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../config/palette.ini'))
        if os.path.exists(path):
            config = configparser.ConfigParser()
            config.read(path)
            if 'palette' in config:
                self.colors.update(config['palette'])

    def __getitem__(self, key):
        return self.colors.get(key, '#fff')
