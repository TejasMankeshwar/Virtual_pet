from pynput import mouse, keyboard
import math
import time
from pet_state_machine import PetStateMachine, Direction

class GlobalEventTracker:
    def __init__(self, state_machine: PetStateMachine, window):
        self.state_machine = state_machine
        self.window = window
        self.last_mouse_loc = None
        self.mouse_listener = None
        self.keyboard_listener = None

    def start_tracking(self):
        self.mouse_listener = mouse.Listener(
            on_move=self.on_move,
            on_click=self.on_click
        )
        self.keyboard_listener = keyboard.Listener(
            on_press=self.on_press
        )
        self.mouse_listener.start()
        self.keyboard_listener.start()

    def stop_tracking(self):
        if self.mouse_listener:
            self.mouse_listener.stop()
        if self.keyboard_listener:
            self.keyboard_listener.stop()

    def on_press(self, key):
        self.state_machine.register_keystroke()

    def on_click(self, x, y, button, pressed):
        if button == mouse.Button.left and not pressed:
            self.state_machine.stop_dragging()

    def on_move(self, x, y):
        # We need the center of our panel.
        # Note: on Windows, geometry might be returned with scaling in mind,
        # but pynput x, y are screen coordinates.
        if not self.window.isVisible():
            return

        geo = self.window.geometry()
        center_x = geo.x() + geo.width() / 2.0
        center_y = geo.y() + geo.height() / 2.0

        dx = x - center_x
        dy = y - center_y

        distance = math.sqrt(dx*dx + dy*dy)

        delta = 0
        if self.last_mouse_loc:
            delta = math.sqrt((x - self.last_mouse_loc[0])**2 + (y - self.last_mouse_loc[1])**2)
        self.last_mouse_loc = (x, y)

        if distance < 60:
            if delta > 0:
                self.state_machine.register_petting(delta)
            self.state_machine.update_direction(Direction.CENTER)
            return
        else:
            self.state_machine.stop_petting()

        angle = math.atan2(dy, dx)
        direction = self.angle_to_direction(angle)
        self.state_machine.update_direction(direction)

    def angle_to_direction(self, angle: float) -> str:
        pi = math.pi
        octant = round(8 * angle / (2 * pi) + 8) % 8

        # y goes down on screens, so atan2 returns:
        # >0 for bottom half, <0 for top half
        if octant == 0: return Direction.RIGHT
        elif octant == 1: return Direction.DOWN_RIGHT
        elif octant == 2: return Direction.DOWN
        elif octant == 3: return Direction.DOWN_LEFT
        elif octant == 4: return Direction.LEFT
        elif octant == 5: return Direction.UP_LEFT
        elif octant == 6: return Direction.UP
        elif octant == 7: return Direction.UP_RIGHT
        return Direction.CENTER
