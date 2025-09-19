import os
import datetime
import shutil
import tempfile
import subprocess
import shlex
import yaml
from PySide6.QtCore import QTimer

SETTINGS_PATH = os.path.abspath(os.path.join(os.path.dirname(__file__), '../../../config/settings.yaml'))

class AllDisplaysCapture:
    @staticmethod
    def capture(snipper_window):
        snipper_window.hide()
        QTimer.singleShot(100, lambda: AllDisplaysCapture._do_capture(snipper_window))

    @staticmethod
    def _do_capture(snipper_window):
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
        save_opt = snipper_window.option_checks[0].isChecked()
        copy_opt = snipper_window.option_checks[1].isChecked()
        edit_opt = snipper_window.option_checks[2].isChecked()
        cache_dir = os.path.expanduser('~/.cache/hyprsnipper')
        os.makedirs(cache_dir, exist_ok=True)
        with tempfile.NamedTemporaryFile(suffix='.png', dir=cache_dir, delete=False) as tmp:
            tmp_path = tmp.name
        try:
            subprocess.run(['grim', tmp_path], check=True)
        except Exception as e:
            snipper_window._notify(f"Screenshot failed: {e}")
            snipper_window.show()
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
                snipper_window._notify(f"Saved: {out_path}")
            except Exception as e:
                snipper_window._notify(f"Save failed: {e}")
        # Copy
        if copy_opt or (copy_clip and not save_opt and not edit_opt):
            try:
                subprocess.run(f'wl-copy < {shlex.quote(tmp_path)}', shell=True)
                snipper_window._notify("Copied to clipboard")
            except Exception as e:
                snipper_window._notify(f"Copy failed: {e}")
        # Edit
        if edit_opt:
            try:
                if editor.strip() == 'swappy':
                    subprocess.Popen([editor, '-f', tmp_path])
                else:
                    subprocess.Popen([editor, tmp_path])
                snipper_window._notify(f"Opened in {editor}")
            except Exception as e:
                snipper_window._notify(f"Edit failed: {e}")
        snipper_window.show()
