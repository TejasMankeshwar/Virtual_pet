from PyQt6.QtWidgets import QWidget
from PyQt6.QtGui import QPainter, QColor, QPen, QBrush
from PyQt6.QtCore import Qt, QRectF, QTimer
import random
from pet_state_machine import PetStateMachine, PetState, Direction, PawSide

class SteamParticle:
    def __init__(self, x_offset, height, delay, duration):
        self.x_offset = x_offset
        self.height = height
        self.delay = delay
        self.duration = duration
        self.y_offset = 0.0
        self.opacity = 0.8
        self.start_time = time.time()

import time

class SpriteView(QWidget):
    def __init__(self, state_machine: PetStateMachine):
        super().__init__()
        self.state_machine = state_machine
        self.state_machine.update_callback = self.on_state_changed
        self.pixel_size = 4.0
        self.setFixedSize(int(30 * self.pixel_size), int(30 * self.pixel_size))
        
        self.steam_particles = []
        self.heart_particles = []
        
        self.timer = QTimer(self)
        self.timer.timeout.connect(self.update_animation)
        self.timer.start(1000 // 60) # 60 FPS
        
        self.last_state = None
        self.heart_spawn_timer = 0
        
    def on_state_changed(self):
        # Trigger repaint immediately when state changes
        self.update()

    def update_animation(self):
        # Update particles
        current_time = time.time()
        
        if self.state_machine.typing_heat >= 0.9:
            if not self.steam_particles:
                self.steam_particles = [
                    SteamParticle(-20, 12, 0.0, 1.0),
                    SteamParticle(-10, 16, 0.4, 1.2),
                    SteamParticle(0, 10, 0.2, 0.9),
                    SteamParticle(10, 14, 0.6, 1.1),
                    SteamParticle(20, 8, 0.8, 1.0),
                ]
        else:
            self.steam_particles.clear()
            
        for p in self.steam_particles:
            elapsed = current_time - p.start_time - p.delay
            if elapsed > 0:
                cycle = (elapsed % p.duration) / p.duration
                p.y_offset = -30 * cycle
                p.opacity = 0.8 * (1.0 - cycle)
                
        # Heart spawning
        if self.state_machine.current_state == PetState.PETTING:
            if current_time - self.heart_spawn_timer > 0.6:
                self.spawn_heart()
                self.heart_spawn_timer = current_time
        
        # Update hearts
        alive_hearts = []
        for h in self.heart_particles:
            elapsed = current_time - h['start_time']
            if elapsed < 1.5:
                cycle = elapsed / 1.5
                # ease out
                ease = 1.0 - (1.0 - cycle)**2
                h['y_offset'] = -22 * ease
                h['opacity'] = 1.0 - ease
                alive_hearts.append(h)
        self.heart_particles = alive_hearts
            
        self.update()
        
    def spawn_heart(self):
        self.heart_particles.append({
            'initial_x': random.uniform(-15, 15),
            'x_drift': random.uniform(-20, 20),
            'y_offset': 0.0,
            'opacity': 1.0,
            'start_time': time.time()
        })

    def get_pink_part_color(self) -> QColor:
        heat = self.state_machine.typing_heat
        r = 1.0 + (0.15 - 1.0) * heat
        g = 0.4 + (0.15 - 0.4) * heat
        b = 0.6 + (0.15 - 0.6) * heat
        return QColor.fromRgbF(r, g, b)

    def get_fur_color(self) -> QColor:
        heat = self.state_machine.typing_heat
        r = 0.15 + (0.98 - 0.15) * heat
        g = 0.15 + (0.165 - 0.15) * heat
        b = 0.15 + (0.333 - 0.15) * heat
        return QColor.fromRgbF(r, g, b)

    def get_stretch_color(self, y: int) -> QColor:
        ratio = y / 29.0
        r = 1.0
        g = 1.0 - (0.5 * ratio)
        b = 0.0
        return QColor.fromRgbF(r, g, b)

    def get_water_color(self, y: int) -> QColor:
        ratio = y / 29.0
        r = 0.0
        g = 0.5 * ratio
        b = 0.5 + 0.5 * ratio
        return QColor.fromRgbF(r, g, b)

    def blend_color(self, base: QColor, target: QColor, amount: float) -> QColor:
        if amount <= 0: return base
        if amount >= 1: return target
        
        r1, g1, b1, a1 = base.getRgbF()
        r2, g2, b2, a2 = target.getRgbF()
        
        r = r1 + (r2 - r1) * amount
        g = g1 + (g2 - g1) * amount
        b = b1 + (b2 - b1) * amount
        return QColor.fromRgbF(r, g, b)

    def get_pupil_offset(self):
        state = self.state_machine.current_state
        if state in [PetState.IDLE, PetState.DRAGGING, PetState.PETTING, PetState.STRETCHING, PetState.STRETCH_REMINDER, PetState.WATER_REMINDER]:
            return (0, 0)
        elif state == PetState.TYPING:
            return (0, 1)
        elif state == PetState.LOOKING:
            d = self.state_machine.looking_direction
            if d == Direction.UP: return (0, -1)
            if d == Direction.DOWN: return (0, 1)
            if d == Direction.LEFT: return (-1, 0)
            if d == Direction.RIGHT: return (1, 0)
            if d == Direction.UP_LEFT: return (-1, -1)
            if d == Direction.UP_RIGHT: return (1, -1)
            if d == Direction.DOWN_LEFT: return (-1, 1)
            if d == Direction.DOWN_RIGHT: return (1, 1)
        return (0, 0)

    def color_for(self, x: int, y: int) -> QColor:
        state = self.state_machine.current_state
        
        frame = base_frame
        if self.state_machine.is_hiding:
            frame = peek_right_frame
        else:
            if state == PetState.DRAGGING:
                frame = drag_frame
            elif state == PetState.TYPING:
                frame = type_left_frame if self.state_machine.last_typed_paw == PawSide.LEFT else type_right_frame
            elif state == PetState.STRETCHING or state == PetState.STRETCH_REMINDER:
                frame = stretch_wag_left_frame if self.state_machine.wag_tick else stretch_wag_right_frame
        
        if not (0 <= y < len(frame)): return None
        row = frame[y]
        if not (0 <= x < len(row)): return None
        char = row[x]
        
        if state == PetState.DRAGGING:
            if (x in (8, 9) and y in (8, 9)) or (x in (17, 18) and y in (8, 9)):
                return QColor(Qt.GlobalColor.black)
        elif state == PetState.PETTING:
            left_eye = [(7,8), (8,7), (9,8)]
            right_eye = [(16,8), (17,7), (18,8)]
            if (x, y) in left_eye or (x, y) in right_eye:
                return self.get_pink_part_color()
            if char == "3" and 7 <= y <= 9:
                return self.get_fur_color()
        elif state in [PetState.STRETCHING, PetState.STRETCH_REMINDER]:
            left_eye = [(7,8), (8,7), (9,8)]
            right_eye = [(16,8), (17,7), (18,8)]
            if (x, y) in left_eye or (x, y) in right_eye:
                return QColor(Qt.GlobalColor.black)
            if char == "3" and 7 <= y <= 9:
                return self.blend_color(QColor(Qt.GlobalColor.white), self.get_stretch_color(y), self.state_machine.stretch_color_amount)
        elif self.state_machine.is_hiding:
            ox, oy = self.get_pupil_offset()
            lx, ly = 14 + ox, 9 + oy
            rx, ry = 14 + ox, 16 + oy
            if (x in (lx, lx+1) and y in (ly, ly+1)) or (x in (rx, rx+1) and y in (ry, ry+1)):
                if char == "3": return QColor(Qt.GlobalColor.black)
        else:
            ox, oy = self.get_pupil_offset()
            lx, ly = 8 + ox, 8 + oy
            rx, ry = 17 + ox, 8 + oy
            if (x in (lx, lx+1) and y in (ly, ly+1)) or (x in (rx, rx+1) and y in (ry, ry+1)):
                if char == "3": return QColor(Qt.GlobalColor.black)

        if char == "1":
            c = self.blend_color(self.get_fur_color(), self.get_stretch_color(y), self.state_machine.stretch_color_amount)
            return self.blend_color(c, self.get_water_color(y), self.state_machine.water_color_amount)
        elif char == "5":
            c = self.blend_color(self.get_pink_part_color(), self.get_stretch_color(y), self.state_machine.stretch_color_amount)
            return self.blend_color(c, self.get_water_color(y), self.state_machine.water_color_amount)
        elif char == "3":
            return QColor(Qt.GlobalColor.white)
        elif char == "k":
            return QColor(128, 128, 128)
        elif char == "b":
            return QColor(204, 204, 204)
        elif char == "l":
            return QColor(255, 255, 255)
            
        return None

    def paintEvent(self, event):
        painter = QPainter(self)
        painter.setRenderHint(QPainter.RenderHint.Antialiasing, False)
        
        # Draw pixels
        for y in range(30):
            for x in range(30):
                color = self.color_for(x, y)
                if color:
                    painter.fillRect(
                        int(x * self.pixel_size), 
                        int(y * self.pixel_size), 
                        int(self.pixel_size), 
                        int(self.pixel_size), 
                        color
                    )
                    
        # Draw steam
        painter.setPen(Qt.PenStyle.NoPen)
        for p in self.steam_particles:
            c = QColor(255, 255, 255, int(255 * p.opacity))
            painter.setBrush(QBrush(c))
            rect = QRectF(
                self.width() / 2 + p.x_offset - 2,
                -20 + p.y_offset,
                4,
                p.height
            )
            painter.drawRect(rect)
            
        # Draw hearts
        for h in self.heart_particles:
            c = QColor(255, 0, 0, int(255 * h['opacity']))
            painter.setBrush(QBrush(c))
            
            hx = self.width() / 2 + h['initial_x'] + h['x_drift']
            hy = self.height() / 2 + h['y_offset'] - 32
            
            # Simple 5x5 heart pixel approximation
            hs = 3.0
            h_pixels = [
                (1,0), (3,0),
                (0,1), (1,1), (2,1), (3,1), (4,1),
                (0,2), (1,2), (2,2), (3,2), (4,2),
                (1,3), (2,3), (3,3),
                (2,4)
            ]
            for px, py in h_pixels:
                painter.fillRect(
                    int(hx + px * hs - (5 * hs)/2),
                    int(hy + py * hs - (5 * hs)/2),
                    int(hs), int(hs), c
                )

# --- Frames Data ---

base_frame = [
    "                              ",
    "        333      333          ",
    "       31113    31113         ",
    "      3111113  3111113        ",
    "     311111113311111113       ",
    "    31111111111111111113      ",
    "    31111111111111111113      ",
    "   3111333111111333111113     ",
    " 11311133311111133311111311   ",
    " 11311133311111133311111311   ",
    "   3111111111111111111113     ",
    " 11311111111111111111111311   ",
    "   3111111111111111111113     ",
    "    33111111111111111133      ",
    "      3111111111111113        ",
    "     311111111111111113       ",
    "    31111111111111111113      ",
    "   3111111111111111111113     ",
    "  311111111111111111111113    ",
    "  311111111111111111111113  33",
    "  311111111111111111111113 313",
    "  3111111111111111111111133113",
    "  3111111111111111111111111113",
    "  311111111111111111111111113 ",
    "   3111111111111111111111113  ",
    "    31111111111111111111133   ",
    "     33111133333311111333     ",
    "       3333      33333        ",
    "                              ",
    "                              "
]

type_left_frame = [
    "                              ",
    "        333      333          ",
    "       31113    31113         ",
    "      3111113  3111113        ",
    "     311111113311111113       ",
    "    31111111111111111113      ",
    "    31111111111111111113      ",
    "   3111333111111333111113     ",
    " 11311133311111133311111311   ",
    " 11311133311111133311111311   ",
    "   3111111111111111111113     ",
    " 11311111111111111111111311   ",
    "   3111111111111111111113     ",
    "    33111111111111111133      ",
    "      3111111111111113        ",
    "     311111111111111113       ",
    "    31111111111111111113      ",
    "   3111111111111111111113     ",
    "  311111111111111111111113    ",
    "  311111111111111111111113  33",
    "  311111111111111111111113 313",
    "  3111111111111111111111133113",
    "  3111111111111111111111111113",
    "  3111111  111111111111111113 ",
    "   31111   11111111111111113  ",
    "    3333   1111111111111133   ",
    "    bbbb   33333311111333     ",
    "  kllllllk       33333        ",
    "  kkkkkkkk                    ",
    "  kkkkkkkk                    "
]

type_right_frame = [
    "                              ",
    "        333      333          ",
    "       31113    31113         ",
    "      3111113  3111113        ",
    "     311111113311111113       ",
    "    31111111111111111113      ",
    "    31111111111111111113      ",
    "   3111333111111333111113     ",
    " 11311133311111133311111311   ",
    " 11311133311111133311111311   ",
    "   3111111111111111111113     ",
    " 11311111111111111111111311   ",
    "   3111111111111111111113     ",
    "    33111111111111111133      ",
    "      3111111111111113        ",
    "     311111111111111113       ",
    "    31111111111111111113      ",
    "   3111111111111111111113     ",
    "  311111111111111111111113    ",
    "  311111111111111111111113  33",
    "  311111111111111111111113 313",
    "  3111111111111111111111133113",
    "  3111111111111111111111111113",
    "  311111111111111  1111111113 ",
    "   31111111111111   11111113  ",
    "    3111111111111   3333333   ",
    "     331111333333   bbbbbbb   ",
    "       3333       klllllllllk ",
    "                  kkkkkkkkkkk ",
    "                  kkkkkkkkkkk "
]

drag_frame = [
    "                              ",
    "       333          333       ",
    "      31113        31113      ",
    "     31111133333333111113     ",
    "    3111111111111111111113    ",
    "   311111111111111111111113   ",
    "  31111111111111111111111113  ",
    "  31111333111111333111111113  ",
    " 3111113331111113331111111113 ",
    " 3111113331111113331111111113 ",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    "311111111111111111111111111113",
    " 3111111111111111111111111113 ",
    " 3111111111111111111111111113 ",
    "  31111111111111111111111113  ",
    "  31111111111111111111111113  ",
    "   311111111111111111111113   ",
    "    3111111111111111111113    ",
    "     33311111111111111133     ",
    "        333333333333333       ",
    "                              ",
    "                              ",
    "                              "
]

peek_right_frame = [
    "                              ",
    "                              ",
    "                              ",
    "               33             ",
    "              3113     11     ",
    "             311113    11     ",
    "            31111113          ",
    "           3111111113         ",
    "          311111111113        ",
    "         31111333111113       ",
    "         31111333111113       ",
    "         31111333111113       ",
    "          31111111111113      ",
    "         311111111111113      ",
    "         311111111111113      ",
    "          31111111111113      ",
    "         31111333111113       ",
    "         31111333111113       ",
    "         31111333111113       ",
    "          311111111113        ",
    "           3111111113         ",
    "            31111113          ",
    "             311113    11     ",
    "              3113     11     ",
    "               33             ",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              "
]

stretch_wag_right_frame = [
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "        333      333          ",
    "       31113    31113         ",
    "      3111113  3111113        ",
    "     311111113311111113       ",
    "    31111111111111111113      ",
    "    31111111111111111113      ",
    "   3111333111111333111113     ",
    "   3111333111111333111113     ",
    "   3111333111111333111113     ",
    "   3111111111111111111113     ",
    "   3111111111111111111113     ",
    "   3111111111111111111113     ",
    "    33111111111111111133      ",
    "      3111111111111113  33    ",
    "     3111111111111111133113   ",
    "    31111111111111111113113   ",
    "   333111111111111111113113   ",
    "  333 33333333333333333333    ",
    "  333                         ",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              "
]

stretch_wag_left_frame = [
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "        333      333          ",
    "       31113    31113         ",
    "      3111113  3111113        ",
    "     311111113311111113       ",
    "    31111111111111111113      ",
    "    31111111111111111113      ",
    "   3111333111111333111113     ",
    "   3111333111111333111113     ",
    "   3111333111111333111113     ",
    "   3111111111111111111113     ",
    "   3111111111111111111113     ",
    "   3111111111111111111113     ",
    "    33111111111111111133      ",
    "    33  3111111111111113      ",
    "   3113311111111111111113     ",
    "   31131111111111111111113    ",
    "   3113331111111111111111333  ",
    "   3333 333333333333333333 333",
    "                           333",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              ",
    "                              "
]
