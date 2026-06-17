import sys
import math
from PyQt6.QtWidgets import QApplication, QMainWindow, QVBoxLayout, QWidget, QLabel, QMenu, QInputDialog, QSystemTrayIcon, QStyle
from PyQt6.QtCore import Qt, QPoint, QTimer, QPropertyAnimation, QRect, QEasingCurve, QCoreApplication
from PyQt6.QtGui import QFont, QAction, QIcon
from pet_state_machine import PetStateMachine, PetState
from sprite_view import SpriteView
from global_tracker import GlobalEventTracker

class MainWindow(QMainWindow):
    def __init__(self):
        super().__init__()

        self.setWindowFlags(
            Qt.WindowType.FramelessWindowHint |
            Qt.WindowType.WindowStaysOnTopHint |
            Qt.WindowType.Tool
        )
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)

        self.state_machine = PetStateMachine()
        
        self.central_widget = QWidget()
        self.setCentralWidget(self.central_widget)
        self.layout = QVBoxLayout(self.central_widget)
        self.layout.setContentsMargins(0, 0, 0, 0)
        self.layout.setSpacing(0)
        self.layout.setAlignment(Qt.AlignmentFlag.AlignBottom | Qt.AlignmentFlag.AlignHCenter)

        self.msg_label = QLabel("")
        self.msg_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.msg_label.setStyleSheet("""
            QLabel {
                background-color: rgba(255, 255, 255, 240);
                color: black;
                font-family: monospace;
                font-size: 10pt;
                font-weight: bold;
                border: 1px solid black;
                border-radius: 6px;
                padding: 3px 6px;
            }
        """)
        self.msg_label.hide()

        self.pomodoro_label = QLabel("")
        self.pomodoro_label.setAlignment(Qt.AlignmentFlag.AlignCenter)
        self.pomodoro_label.setStyleSheet("""
            QLabel {
                background-color: rgba(255, 255, 255, 240);
                color: red;
                font-family: monospace;
                font-size: 12pt;
                font-weight: bold;
                border: 1px solid black;
                border-radius: 6px;
                padding: 3px 6px;
            }
        """)
        self.pomodoro_label.hide()

        self.layout.addWidget(self.msg_label)
        self.layout.addWidget(self.pomodoro_label)

        self.sprite_view = SpriteView(self.state_machine)
        self.layout.addWidget(self.sprite_view)

        # Set initial size
        self.resize(120, 160)
        
        # Position slightly offset from center
        screen = QApplication.primaryScreen().geometry()
        self.move(screen.width() // 2, screen.height() // 2)

        self.drag_pos = None

        self.tracker = GlobalEventTracker(self.state_machine, self)
        self.tracker.start_tracking()

        self.ui_update_timer = QTimer(self)
        self.ui_update_timer.timeout.connect(self.update_ui)
        self.ui_update_timer.start(100)
        
        self.blip_anim = None
        self.was_hiding = False

        self.setup_tray()

    def setup_tray(self):
        self.tray_icon = QSystemTrayIcon(self)
        icon = self.style().standardIcon(QStyle.StandardPixmap.SP_ComputerIcon)
        self.tray_icon.setIcon(icon)
        self.tray_icon.setToolTip("Comnyang")

        tray_menu = QMenu()
        quit_action = QAction("Quit Comnyang", self)
        quit_action.triggered.connect(self.quit_app)
        tray_menu.addAction(quit_action)

        self.tray_icon.setContextMenu(tray_menu)
        self.tray_icon.show()

    def update_ui(self):
        if not self.state_machine.is_hiding:
            if self.state_machine.show_purr_message and self.state_machine.purr_message:
                self.msg_label.setText(self.state_machine.purr_message)
                self.msg_label.show()
            else:
                self.msg_label.hide()

            if self.state_machine.is_pomodoro_active:
                mins = self.state_machine.pomodoro_time_remaining // 60
                secs = self.state_machine.pomodoro_time_remaining % 60
                self.pomodoro_label.setText(f"{mins:02d}:{secs:02d}")
                self.pomodoro_label.show()
            else:
                self.pomodoro_label.hide()
        else:
            self.msg_label.hide()
            self.pomodoro_label.hide()

        # Handle hiding teleportation
        if self.state_machine.is_hiding and not self.was_hiding:
            self.was_hiding = True
            self.blip_teleport(to_right=True)
        elif not self.state_machine.is_hiding and self.was_hiding:
            self.was_hiding = False
            screen = QApplication.primaryScreen().geometry()
            if self.x() >= screen.right() - 25:
                self.blip_teleport(to_right=False)

    def blip_teleport(self, to_right):
        self.state_machine.is_blipping = True
        self.sprite_view.update()
        
        screen = QApplication.primaryScreen().geometry()
        
        # In PyQt, we can simulate the scale blip by quickly shrinking height or width
        self.blip_anim = QPropertyAnimation(self.sprite_view, b"geometry")
        self.blip_anim.setDuration(500)
        rect = self.sprite_view.geometry()
        target_rect = QRect(rect.x(), rect.y() + rect.height()//2, rect.width(), 0)
        self.blip_anim.setStartValue(rect)
        self.blip_anim.setEndValue(target_rect)
        self.blip_anim.setEasingCurve(QEasingCurve.Type.InQuad)
        
        def on_blip_down():
            if to_right:
                new_x = screen.right() - self.width() + 10
            else:
                new_x = screen.right() - self.width() - 50
            self.move(new_x, self.y())
            
            # Animate back up
            self.blip_anim_up = QPropertyAnimation(self.sprite_view, b"geometry")
            self.blip_anim_up.setDuration(500)
            self.blip_anim_up.setStartValue(target_rect)
            self.blip_anim_up.setEndValue(rect)
            self.blip_anim_up.setEasingCurve(QEasingCurve.Type.OutQuad)
            def on_blip_up():
                self.state_machine.is_blipping = False
                self.sprite_view.update()
            self.blip_anim_up.finished.connect(on_blip_up)
            self.blip_anim_up.start()
            
        self.blip_anim.finished.connect(on_blip_down)
        self.blip_anim.start()

    def mousePressEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.state_machine.start_dragging()
            self.state_machine.acknowledge_stretch()
            self.state_machine.acknowledge_water()
            self.state_machine.acknowledge_pomodoro()
            self.drag_pos = event.globalPosition().toPoint() - self.frameGeometry().topLeft()
            event.accept()
        elif event.button() == Qt.MouseButton.RightButton:
            self.show_context_menu(event.globalPosition().toPoint())

    def mouseMoveEvent(self, event):
        if event.buttons() == Qt.MouseButton.LeftButton and self.drag_pos is not None:
            self.move(event.globalPosition().toPoint() - self.drag_pos)
            event.accept()

    def mouseReleaseEvent(self, event):
        if event.button() == Qt.MouseButton.LeftButton:
            self.drag_pos = None
            self.state_machine.stop_dragging()
            event.accept()

    def show_context_menu(self, pos):
        menu = QMenu(self)
        
        toggle_msg = "Hide Purr Message" if self.state_machine.base_show_purr_message else "Show Purr Message"
        toggle_msg_action = menu.addAction(toggle_msg)
        set_msg_action = menu.addAction("Set Purr Message...")
        menu.addSeparator()
        
        set_stretch_action = menu.addAction("Set Stretch Reminder...")
        turn_off_stretch_action = None
        if self.state_machine.stretch_interval > 0:
            turn_off_stretch_action = menu.addAction("Turn Off Stretch Reminder")
            
        menu.addSeparator()
        set_water_action = menu.addAction("Set Water Reminder...")
        turn_off_water_action = None
        if self.state_machine.water_interval > 0:
            turn_off_water_action = menu.addAction("Turn Off Water Reminder")
            
        menu.addSeparator()
        if self.state_machine.is_pomodoro_active:
            pomodoro_action = menu.addAction("Stop Pomodoro Timer")
        else:
            pomodoro_action = menu.addAction("Start Pomodoro Timer")
            
        menu.addSeparator()
        hide_action = menu.addAction("Hide")
        menu.addSeparator()
        quit_action = menu.addAction("Quit")

        action = menu.exec(pos)

        if action == toggle_msg_action:
            self.state_machine.base_show_purr_message = not self.state_machine.base_show_purr_message
            if self.state_machine.current_state not in [PetState.STRETCH_REMINDER, PetState.WATER_REMINDER]:
                self.state_machine.show_purr_message = self.state_machine.base_show_purr_message
        elif action == set_msg_action:
            text, ok = QInputDialog.getText(self, "Set Purr Message", "Enter a message (max 20 characters):", text=self.state_machine.base_purr_message)
            if ok:
                self.state_machine.base_purr_message = text[:20]
                self.state_machine.base_show_purr_message = True
        elif action == set_stretch_action:
            mins = self.state_machine.stretch_interval // 60
            secs = self.state_machine.stretch_interval % 60
            default_val = f"{mins}:{secs:02d}"
            text, ok = QInputDialog.getText(self, "Set Stretch Reminder", "Enter interval in MM:SS format:", text=default_val)
            if ok:
                parts = text.split(":")
                total = 0
                if len(parts) == 2:
                    total = int(parts[0]) * 60 + int(parts[1])
                elif len(parts) == 1:
                    total = int(parts[0]) * 60
                if total > 0:
                    self.state_machine.stretch_interval = total
                    self.state_machine.time_until_stretch = total
        elif turn_off_stretch_action and action == turn_off_stretch_action:
            self.state_machine.stretch_interval = 0
        elif action == set_water_action:
            mins = self.state_machine.water_interval // 60
            secs = self.state_machine.water_interval % 60
            default_val = f"{mins}:{secs:02d}"
            text, ok = QInputDialog.getText(self, "Set Water Reminder", "Enter interval in MM:SS format:", text=default_val)
            if ok:
                parts = text.split(":")
                total = 0
                if len(parts) == 2:
                    total = int(parts[0]) * 60 + int(parts[1])
                elif len(parts) == 1:
                    total = int(parts[0]) * 60
                if total > 0:
                    self.state_machine.water_interval = total
                    self.state_machine.time_until_water = total
        elif turn_off_water_action and action == turn_off_water_action:
            self.state_machine.water_interval = 0
        elif action == pomodoro_action:
            if self.state_machine.is_pomodoro_active:
                self.state_machine.stop_pomodoro()
            else:
                self.state_machine.start_pomodoro()
        elif action == hide_action:
            self.state_machine.is_hiding = True
            self.state_machine._notify()
        elif action == quit_action:
            self.quit_app()

    def quit_app(self):
        self.tracker.stop_tracking()
        QCoreApplication.quit()

if __name__ == "__main__":
    import os
    # For making PyQt headless on macOS if needed, but not required since it's a windowed app
    app = QApplication(sys.argv)
    
    # Ensure fonts look okay across platforms
    font = app.font()
    font.setFamily("monospace")
    app.setFont(font)

    window = MainWindow()
    window.show()

    sys.exit(app.exec())
