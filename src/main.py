#!/usr/bin/env python3
"""
main.py - Entry point for HyprSnipper Qt UI
"""
import sys

from PySide6.QtWidgets import QApplication
from ui.snipper_window import SnipperWindow
from ui.palette import Palette

def main():
    app = QApplication(sys.argv)
    palette = Palette()
    # Set custom tooltip style globally
    tooltip_style = f"""
        QToolTip {{
            background-color: {palette['tooltip_bg']};
            color: {palette['tooltip_fg']};
            border: 1px solid {palette['primary']};
            padding: 6px 10px;
            border-radius: 6px;
            font-size: 13px;
        }}
    """
    app.setStyleSheet(tooltip_style)
    window = SnipperWindow()
    window.show()
    sys.exit(app.exec())

if __name__ == "__main__":
    main()
