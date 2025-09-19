
from PySide6.QtCore import Qt, QRect, QTimer
from PySide6.QtGui import QPainter, QColor, QPen, QFont
from PySide6.QtWidgets import QWidget

class WindowSelectorOverlay(QWidget):
    def __init__(self, parent, windows, on_select, monitor_rect=None):
        super().__init__(parent)
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setCursor(Qt.PointingHandCursor)
        self.windows = windows
        self.on_select = on_select
        self.selected_idx = None
        self.monitor_rect = monitor_rect or self._get_monitor_rect()
        # Set preview size
        self.PREVIEW_W, self.PREVIEW_H = 600, 350
        self._scale_x, self._scale_y = self._calc_scale()
        # Center the window on the screen
        screen = self.screen() or self.parent().screen() if self.parent() else None
        if screen:
            scr_geo = screen.geometry()
            x = scr_geo.x() + (scr_geo.width() - self.PREVIEW_W) // 2
            y = scr_geo.y() + (scr_geo.height() - self.PREVIEW_H) // 2
        else:
            x, y = 100, 100
        self.setGeometry(x, y, self.PREVIEW_W, self.PREVIEW_H)
        self.setWindowTitle("HyprSnipperSelector")
        self.show()

    def _get_monitor_rect(self):
        # fallback: use bounding box of all windows
        if not self.windows:
            return (0, 0, 800, 600)
        min_x = min(w['at'][0] for w in self.windows)
        min_y = min(w['at'][1] for w in self.windows)
        max_x = max(w['at'][0] + w['size'][0] for w in self.windows)
        max_y = max(w['at'][1] + w['size'][1] for w in self.windows)
        return (min_x, min_y, max_x - min_x, max_y - min_y)

    def _calc_scale(self):
        # scale to fit preview window
        mon_w, mon_h = self.monitor_rect[2], self.monitor_rect[3]
        scale_x = self.PREVIEW_W / mon_w if mon_w else 1
        scale_y = self.PREVIEW_H / mon_h if mon_h else 1
        return scale_x, scale_y

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.fillRect(self.rect(), QColor(25, 25, 25, 220))

        # Sort: tiled first, floating last (drawn on top)
        def is_floating(win):
            return win.get('floating', False)
        windows_sorted = sorted(self.windows, key=lambda w: (not is_floating(w), w.get('creationTimestamp', 0)))

        for idx, win in enumerate(windows_sorted):
            x = int((win['at'][0] - self.monitor_rect[0]) * self._scale_x)
            y = int((win['at'][1] - self.monitor_rect[1]) * self._scale_y)
            w = int(win['size'][0] * self._scale_x)
            h = int(win['size'][1] * self._scale_y)
            color = QColor(230, 150, 40, 180) if win.get('floating', False) else QColor(50, 150, 230, 140)
            if idx == self.selected_idx:
                color.setAlpha(255)
            painter.setBrush(color)
            painter.setPen(QPen(QColor(255,255,255), 2))
            painter.drawRect(x, y, w, h)
            # Draw title
            painter.setPen(QColor(255,255,255))
            font = QFont('Sans', 10)
            painter.setFont(font)
            painter.drawText(x+6, y+22, win.get('title', '')[:32])

    def mousePressEvent(self, event):
        # Find which window was clicked
        for idx, win in enumerate(sorted(self.windows, key=lambda w: (not w.get('floating', False), w.get('creationTimestamp', 0)))):
            x = int((win['at'][0] - self.monitor_rect[0]) * self._scale_x)
            y = int((win['at'][1] - self.monitor_rect[1]) * self._scale_y)
            w = int(win['size'][0] * self._scale_x)
            h = int(win['size'][1] * self._scale_y)
            if x <= event.x() <= x+w and y <= event.y() <= y+h:
                self.selected_idx = idx
                self.update()
                geo = win['at']
                size = win['size']
                geom_str = f"{geo[0]},{geo[1]} {size[0]}x{size[1]}"
                QTimer.singleShot(1, lambda: self._select(geom_str))
                break

    def _select(self, geom_str):
        # Hide immediately, then call snip after delay
        self.hide()
        if self.on_select:
            QTimer.singleShot(320, lambda: (self.close(), self.on_select(geom_str)))

    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Escape:
            self.close()
            # Show parent (main snipper) window if available
            if self.parent() is not None:
                QTimer.singleShot(100, self.parent().show)
        else:
            super().keyPressEvent(event)
