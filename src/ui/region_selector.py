from PySide6.QtCore import Qt, QRect, QPoint, Signal
from PySide6.QtGui import QPainter, QColor, QPen, QCursor
from PySide6.QtWidgets import QWidget, QApplication

class RegionSelectorOverlay(QWidget):
    regionSelected = Signal(QRect)

    def __init__(self, palette):
        super().__init__()
        self.palette = palette
        self.setWindowFlags(Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool)
        self.setAttribute(Qt.WA_TranslucentBackground)
        self.setWindowState(Qt.WindowFullScreen)
        self.setCursor(QCursor(Qt.CrossCursor))
        self.start = None
        self.end = None
        self.dragging = False
        self.click_mode = False
        self.selection_rect = QRect()
        self.setMouseTracking(True)

    def paintEvent(self, event):
        if self.start and self.end:
            painter = QPainter(self)
            painter.setRenderHint(QPainter.Antialiasing)
            # Dim background
            painter.fillRect(self.rect(), QColor(0, 0, 0, 64))
            # Draw selection rectangle
            pen = QPen(QColor(self.palette['primary']), 2, Qt.SolidLine)
            painter.setPen(pen)
            painter.setBrush(QColor(self.palette['primary'], 64))
            painter.drawRect(self.selection_rect.normalized())

    def mousePressEvent(self, event):
        if event.button() == Qt.LeftButton:
            if not self.start:
                self.start = event.pos()
                self.end = event.pos()
                self.dragging = True
                self.click_mode = False
            elif self.click_mode:
                self.end = event.pos()
                self.selection_rect = QRect(self.start, self.end)
                self.regionSelected.emit(self.selection_rect.normalized())
                self.close()
        self.update()

    def mouseMoveEvent(self, event):
        if self.dragging:
            self.end = event.pos()
            self.selection_rect = QRect(self.start, self.end)
            self.update()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.LeftButton and self.dragging:
            self.end = event.pos()
            self.selection_rect = QRect(self.start, self.end)
            self.regionSelected.emit(self.selection_rect.normalized())
            self.dragging = False
            self.close()
        elif event.button() == Qt.LeftButton and not self.dragging and not self.click_mode:
            # Switch to click-move-click mode
            self.click_mode = True
        self.update()

    def keyPressEvent(self, event):
        if event.key() == Qt.Key_Escape:
            self.close()

    def showEvent(self, event):
        self.raise_()
        self.activateWindow()
        super().showEvent(event)
