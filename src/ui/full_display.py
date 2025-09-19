from PySide6.QtCore import QTimer, QCursor
from PySide6.QtWidgets import QApplication
import os
import datetime
import shutil
import tempfile
import subprocess
import shlex
import yaml

SETTINGS_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../config/settings.yaml'))

class FullDisplayCapture:
    @staticmethod
    def capture(snipper_window):
        snipper_window.hide()
        QTimer.singleShot(100, lambda: FullDisplayCapture._do_capture(snipper_window))

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
