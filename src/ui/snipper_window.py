from .window_selector import WindowSelectorOverlay
from .full_display import FullDisplayCapture
from .all_displays import AllDisplaysCapture

from PySide6.QtCore import Qt, QTimer
from PySide6.QtGui import QIcon, QCursor
from PySide6.QtWidgets import (
    QWidget, QHBoxLayout, QVBoxLayout, QPushButton, QCheckBox, QApplication
)

import os
import subprocess
import tempfile
import shlex
import datetime
import shutil


from .palette import Palette




ICON_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../resources/icons'))
USER_ICON_PATH = os.path.expanduser('~/.config/hyprsnipper/icons')

def get_icon_path(icon_base):
    """
    icon_base: e.g. 'region' (no extension)
    Returns the best icon path, preferring user .svg/.png, then default .svg/.png.
    """
    for ext in ('.svg', '.png'):
        user_icon = os.path.join(USER_ICON_PATH, icon_base + ext)
        if os.path.isfile(user_icon):
            return user_icon
    for ext in ('.svg', '.png'):
        default_icon = os.path.join(ICON_PATH, icon_base + ext)
        if os.path.isfile(default_icon):
            return default_icon
    return ''  # fallback: empty


import yaml


def get_user_or_default_config(filename):
    user_path = os.path.expanduser(f'~/.config/hyprsnipper/{filename}')
    default_path = os.path.abspath(os.path.join(os.path.dirname(__file__), f'../../config/{filename}'))
    return user_path if os.path.isfile(user_path) else default_path

SETTINGS_PATH = get_user_or_default_config('settings.yaml')
PALETTE_PATH = get_user_or_default_config('palette.ini')

class SnipperWindow(QWidget):
    def closeEvent(self, event):
        super().closeEvent(event)
    def __init__(self):
        super().__init__()
        self.palette = Palette()
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setFixedSize(420, 120)
        self.setStyleSheet(self._main_style())
        self.option_checks = []  # Ensure this is always defined before any logic
        self._setup_ui()
        self._center_top()
        self._setup_transparency()


    def _setup_ui(self):
        # Icon buttons
        icons = [
            ("region", "Region"),
            ("window", "Window"),
            ("full", "Full Display"),
            ("alldisplays", "All Displays")
        ]
        btn_layout = QHBoxLayout()
        self.mode_buttons = []
        self.mode_names = [tooltip for _, tooltip in icons]
        for idx, (icon_base, tooltip) in enumerate(icons):
            btn = QPushButton()
            icon_path = get_icon_path(icon_base)
            if icon_path:
                btn.setIcon(QIcon(icon_path))
            btn.setIconSize(QApplication.primaryScreen().availableGeometry().size() / 16)
            btn.setToolTip(tooltip)
            btn.setCheckable(True)
            btn.setStyleSheet(self._button_style())
            btn.clicked.connect(lambda checked, i=idx: self._select_mode(i))
            btn_layout.addWidget(btn)
            self.mode_buttons.append(btn)
        # Do not select any mode here; selection happens after UI setup

        # Output toggles, read initial state from settings.yaml using YAML
        save_enabled = True
        copy_enabled = True
        edit_enabled = False
        try:
            with open(SETTINGS_PATH) as f:
                settings = yaml.safe_load(f) or {}
                save_enabled = bool(settings.get('SAVE_ENABLED', True))
                copy_enabled = bool(settings.get('COPY_ENABLED', True))
                edit_enabled = bool(settings.get('EDIT_ENABLED', False))
        except Exception:
            pass
        options = [
            ("Save", save_enabled),
            ("Copy", copy_enabled),
            ("Edit", edit_enabled)
        ]
        opt_layout = QHBoxLayout()
        self.option_checks = []
        for label, checked in options:
            cb = QCheckBox(label)
            cb.setChecked(checked)
            cb.setStyleSheet(self._checkbox_style())
            opt_layout.addWidget(cb)
            self.option_checks.append(cb)

        # Main layout
        layout = QVBoxLayout()
        layout.addLayout(btn_layout)
        layout.addLayout(opt_layout)
        layout.setContentsMargins(12, 8, 12, 8)
        self.setLayout(layout)

    def _center_top(self):
        # Use the screen where the mouse pointer is (active screen)
        cursor_pos = QCursor.pos()
        screen = QApplication.screenAt(cursor_pos)
        if screen is None:
            screen = QApplication.primaryScreen()
        geo = screen.availableGeometry()
        x = geo.x() + (geo.width() - self.width()) // 2
        y = geo.y() + 24  # 24px offset from top for aesthetics
        self.move(x, y)

    def _select_mode(self, idx, save=True):
        for i, btn in enumerate(self.mode_buttons):
            btn.setChecked(i == idx)
        self._current_mode = self.mode_names[idx]
        if self._current_mode == "Region":
            self._launch_region_slurp()
        elif self._current_mode == "Window":
            self._launch_window_capture()
        elif self._current_mode == "Full Display":
            self._launch_full_display_capture()
        elif self._current_mode == "All Displays":
            self._launch_all_displays_capture()

    def _launch_window_capture(self):
        self.hide()
        QTimer.singleShot(150, self._show_window_selector_overlay)

    def _show_window_selector_overlay(self):
        import json
        try:
            ws_result = subprocess.run(['hyprctl', 'activeworkspace', '-j'], capture_output=True, text=True, check=True)
            ws = json.loads(ws_result.stdout)
            ws_id = ws['id']
            result = subprocess.run(['hyprctl', 'clients', '-j'], capture_output=True, text=True, check=True)
            clients = json.loads(result.stdout)
            windows = [c for c in clients if c.get('mapped', True) and c.get('workspace', {}).get('id') == ws_id]
            if not windows:
                self._notify("No windows found for selection.")
                self.show()
                return
            def on_select(geom):
                # Delay screenshot until all selector windows are closed
                QTimer.singleShot(100, lambda: self._on_region_slurp(geom))
            self._window_selector_overlay = WindowSelectorOverlay(self, windows, on_select)
        except Exception as e:
            self._notify(f"Window selector failed: {e}")
            self.show()

    def _launch_full_display_capture(self):
        FullDisplayCapture.capture(self)

    def _launch_all_displays_capture(self):
        AllDisplaysCapture.capture(self)
    def _launch_region_slurp(self):
        self.hide()
        # Call slurp to get region
        try:
            result = subprocess.run(['slurp'], capture_output=True, text=True, check=True)
            geom = result.stdout.strip()
            if not geom:
                self.show()
                return
            # geom is "x,y w×h"
            # Pass to screenshot logic
            self._on_region_slurp(geom)
        except Exception as e:
            print(f"slurp failed: {e}")
            self.show()

    def _on_region_slurp(self, geom):
        # Get config using YAML
        save_dir = os.getenv('SNIP_SAVE_DIR', '~/Pictures/Screenshots')
        editor = os.getenv('SNIP_EDITOR', 'swappy')
        copy_clip = True
        try:
            with open(SETTINGS_PATH) as f:
                settings = yaml.safe_load(f) or {}
                save_dir = settings.get('SAVE_DIR', save_dir)
                editor = settings.get('EDITOR', editor)
                copy_clip = bool(settings.get('COPY_TO_CLIPBOARD', True))
        except Exception:
            pass
        save_dir = os.path.expanduser(save_dir)
        # Get toggles
        save_opt = self.option_checks[0].isChecked()
        copy_opt = self.option_checks[1].isChecked()
        edit_opt = self.option_checks[2].isChecked()
        # Screenshot to temp file in ~/.cache/hyprsnipper
        cache_dir = os.path.expanduser('~/.cache/hyprsnipper')
        os.makedirs(cache_dir, exist_ok=True)
        with tempfile.NamedTemporaryFile(suffix='.png', dir=cache_dir, delete=False) as tmp:
            tmp_path = tmp.name
        try:
            subprocess.run(['grim', '-g', geom, tmp_path], check=True)
        except Exception as e:
            self._notify(f"Screenshot failed: {e}")
            QTimer.singleShot(100, self.show)
            return
        # Save
        if save_opt:
            os.makedirs(save_dir, exist_ok=True)
            now = datetime.datetime.now()
            fname = f"hyprsnip_{now.month}.{now.day}.{now.year}_{now.hour:02d}.{now.minute:02d}.{now.second:02d}.png"
            out_path = os.path.join(save_dir, fname)
            try:
                shutil.move(tmp_path, out_path)
                tmp_path = out_path
                self._notify(f"Saved: {out_path}")
            except Exception as e:
                self._notify(f"Save failed: {e}")
        # Copy
        if copy_opt or (copy_clip and not save_opt and not edit_opt):
            try:
                subprocess.run(f'wl-copy < {shlex.quote(tmp_path)}', shell=True)
                self._notify("Copied to clipboard")
            except Exception as e:
                self._notify(f"Copy failed: {e}")
        # Edit
        if edit_opt:
            try:
                # Use -f for swappy, fallback to default for others
                if editor.strip() == 'swappy':
                    subprocess.Popen([editor, '-f', tmp_path])
                else:
                    subprocess.Popen([editor, tmp_path])
                self._notify(f"Opened in {editor}")
            except Exception as e:
                self._notify(f"Edit failed: {e}")
        QTimer.singleShot(100, self.show)

    def _notify(self, msg):
        print(f"[HyprSnipper] {msg}")
        try:
            subprocess.Popen(['notify-send', 'HyprSnipper', msg])
        except Exception:
            pass



    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Escape:
            self.close()
        else:
            super().keyPressEvent(event)

    def _setup_transparency(self):
        # self.setWindowOpacity(1.0)  # Disabled: not supported on Wayland
        self.setMouseTracking(True)
        self.leave_timer = QTimer(self)
        self.leave_timer.setSingleShot(True)
        # self.leave_timer.timeout.connect(lambda: self.setWindowOpacity(0.3))
        self.leave_timer.timeout.connect(lambda: None)

    def enterEvent(self, event):
        # self.setWindowOpacity(1.0)  # Disabled: not supported on Wayland
        self.leave_timer.stop()
        super().enterEvent(event)

    def leaveEvent(self, event):
        self.leave_timer.start(200)
        super().leaveEvent(event)

    def _main_style(self):
        return f"""
            background: {self.palette['background']};
            border-radius: 12px;
        """

    def _button_style(self):
        return f"""
            QPushButton {{
                background: {self.palette['button_bg']};
                border: none;
                margin: 0 8px;
            }}
            QPushButton:checked {{
                background: {self.palette['button_checked']};
                border-radius: 6px;
            }}
            QPushButton:hover {{
                background: {self.palette['button_hover']};
            }}
        """

    def _checkbox_style(self):
        return f"""
            QCheckBox {{
                color: {self.palette['checkbox_fg']};
                font-size: 14px;
                padding: 2px 8px;
            }}
            QCheckBox::indicator {{
                width: 16px;
                height: 16px;
            }}
        """
