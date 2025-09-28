from PySide6.QtCore import QTimer
from PySide6.QtGui import QCursor
from PySide6.QtWidgets import QApplication
import os
import datetime
import shutil
import tempfile
import subprocess
import shlex
import yaml

SETTINGS_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../config/settings.yaml'))

def get_animation_delay():
    """Load window animation delay from settings.yaml, defaulting to 300ms"""
    try:
        with open(SETTINGS_PATH) as f:
            settings = yaml.safe_load(f) or {}
            return int(settings.get('WINDOW_ANIMATION_DELAY', 300))
    except (FileNotFoundError, ValueError, TypeError):
        return 300

class FullDisplayCapture:
    @staticmethod
    def capture(snipper_window):
        snipper_window.hide()
        # Get configurable delay for window close animation
        try:
            with open(SETTINGS_PATH) as f:
                settings = yaml.safe_load(f) or {}
                delay = int(settings.get('WINDOW_ANIMATION_DELAY', 300))
        except (FileNotFoundError, ValueError, TypeError, yaml.YAMLError):
            delay = 300
        QTimer.singleShot(delay, lambda: FullDisplayCapture._do_capture(snipper_window))

    @staticmethod
    def _do_capture(snipper_window):
        try:
            cursor_pos = QCursor.pos()
            screen = QApplication.screenAt(cursor_pos)
            if screen is None:
                screen = QApplication.primaryScreen()
            geo = screen.geometry()
            x, y, w, h = geo.x(), geo.y(), geo.width(), geo.height()
            geom = f"{x},{y} {w}x{h}"
            snipper_window._on_region_slurp(geom)
        except Exception as e:
            snipper_window._notify(f"Full display capture failed: {e}")
            snipper_window.show()
