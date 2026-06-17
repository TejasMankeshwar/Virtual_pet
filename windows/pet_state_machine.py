import time
import random
import threading
from typing import List

class Direction:
    UP = "up"
    DOWN = "down"
    LEFT = "left"
    RIGHT = "right"
    UP_LEFT = "upLeft"
    UP_RIGHT = "upRight"
    DOWN_LEFT = "downLeft"
    DOWN_RIGHT = "downRight"
    CENTER = "center"

class PawSide:
    LEFT = "left"
    RIGHT = "right"

class PetState:
    IDLE = "idle"
    LOOKING = "looking"
    DRAGGING = "dragging"
    TYPING = "typing"
    PETTING = "petting"
    STRETCHING = "stretching"
    STRETCH_REMINDER = "stretchReminder"
    WATER_REMINDER = "waterReminder"

def get_state_priority(state: str) -> int:
    priorities = {
        PetState.DRAGGING: 100,
        PetState.STRETCH_REMINDER: 90,
        PetState.WATER_REMINDER: 80,
        PetState.PETTING: 70,
        PetState.TYPING: 60,
        PetState.LOOKING: 50,
        PetState.STRETCHING: 40,
        PetState.IDLE: 0
    }
    return priorities.get(state, 0)

class PetStateMachine:
    def __init__(self, update_callback=None):
        self.update_callback = update_callback
        self.current_state = PetState.IDLE
        self.looking_direction = Direction.CENTER
        self.is_hiding = False
        self.is_blipping = False
        self.typing_heat = 0.0
        self.stretch_color_amount = 0.0
        self.water_color_amount = 0.0
        self.wag_tick = False
        self.last_typed_paw = PawSide.LEFT

        self.base_purr_message = ""
        self.base_show_purr_message = False
        self.purr_message = ""
        self.show_purr_message = False

        self.is_pomodoro_active = False
        self.pomodoro_time_remaining = 0
        self.pomodoro_duration = 25 * 60

        self.stretch_interval = 45 * 60  # seconds, 0 = off
        self.time_until_stretch = self.stretch_interval
        self.water_interval = 60 * 60  # seconds, 0 = off
        self.time_until_water = self.water_interval

        self.last_direction_change = time.time()
        self.keystrokes: List[float] = []
        self.last_interaction_time = time.time()

        self.petting_accumulator = 0.0
        self.petting_start_time = None
        self.petting_timer = None

        self.is_currently_typing = False
        self.typing_timer = None

        self._start_timers()

    def _notify(self):
        if self.update_callback:
            self.update_callback()

    def set_state(self, new_state, force=False):
        if force or get_state_priority(new_state) >= get_state_priority(self.current_state):
            old_state = self.current_state
            self.current_state = new_state
            
            # handle stretch color amount
            is_stretching = (self.current_state == PetState.STRETCH_REMINDER)
            self.stretch_color_amount = 1.0 if is_stretching else 0.0
            
            # handle water color amount
            is_watering = (self.current_state == PetState.WATER_REMINDER)
            self.water_color_amount = 1.0 if is_watering else 0.0
            
            self._notify()
            return True
        return False

    def register_interaction(self):
        self.last_interaction_time = time.time()

    def register_petting(self, delta: float):
        self.register_interaction()
        self.petting_accumulator += delta
        
        if self.petting_timer:
            self.petting_timer.cancel()
            
        def stop_pet():
            self.stop_petting()
        self.petting_timer = threading.Timer(0.5, stop_pet)
        self.petting_timer.start()

        if self.petting_start_time is None:
            self.petting_start_time = time.time()

        if time.time() - self.petting_start_time >= 1.2:
            if self.petting_accumulator > 30:
                self.set_state(PetState.PETTING)

    def stop_petting(self):
        self.petting_accumulator = 0
        self.petting_start_time = None
        if self.current_state == PetState.PETTING:
            self.set_state(PetState.IDLE, force=True)

    def wake_up_if_needed(self):
        if self.is_hiding:
            self.is_hiding = False
            if self.current_state not in [PetState.STRETCH_REMINDER, PetState.WATER_REMINDER]:
                self.set_state(PetState.IDLE)
            self._notify()

    def start_pomodoro(self):
        self.is_pomodoro_active = True
        self.pomodoro_time_remaining = self.pomodoro_duration
        self._notify()

    def stop_pomodoro(self):
        self.is_pomodoro_active = False
        self._notify()

    def acknowledge_stretch(self):
        if self.current_state == PetState.STRETCH_REMINDER:
            self.time_until_stretch = self.stretch_interval
            self.set_state(PetState.IDLE, force=True)
            self.purr_message = self.base_purr_message
            self.show_purr_message = self.base_show_purr_message
            self._notify()

    def acknowledge_water(self):
        if self.current_state == PetState.WATER_REMINDER:
            self.time_until_water = self.water_interval
            self.set_state(PetState.IDLE, force=True)
            self.purr_message = self.base_purr_message
            self.show_purr_message = self.base_show_purr_message
            self._notify()

    def acknowledge_pomodoro(self):
        if self.purr_message == "Pomodoro Done! 🐾":
            self.purr_message = self.base_purr_message
            self.show_purr_message = self.base_show_purr_message
            self._notify()

    def update_direction(self, new_direction):
        self.register_interaction()
        now = time.time()
        if now - self.last_direction_change > 0.05:
            if self.set_state(PetState.LOOKING):
                self.looking_direction = new_direction
                self.last_direction_change = now

    def start_dragging(self):
        self.register_interaction()
        self.set_state(PetState.DRAGGING, force=True)
        self.is_hiding = False
        self.typing_heat = 0.0
        self._notify()

    def stop_dragging(self):
        if self.current_state == PetState.DRAGGING:
            self.set_state(PetState.IDLE, force=True)

    def register_keystroke(self):
        self.register_interaction()
        self.wake_up_if_needed()
        self.keystrokes.append(time.time())

        self.last_typed_paw = PawSide.RIGHT if self.last_typed_paw == PawSide.LEFT else PawSide.LEFT
        self.is_currently_typing = True

        if self.typing_timer:
            self.typing_timer.cancel()
            
        def stop_typing():
            self.is_currently_typing = False
            self.update_typing_state()
        self.typing_timer = threading.Timer(0.5, stop_typing)
        self.typing_timer.start()
        
        self.update_typing_heat()

    def update_typing_heat(self):
        now = time.time()
        self.keystrokes = [t for t in self.keystrokes if now - t <= 3.0]
        
        kps = len(self.keystrokes) / 3.0
        min_kps = 1.25  # 15 WPM
        max_kps = 5.83  # 70 WPM

        if kps < min_kps:
            self.typing_heat = 0.0
        elif kps >= max_kps:
            self.typing_heat = 1.0
        else:
            self.typing_heat = (kps - min_kps) / (max_kps - min_kps)

        self.update_typing_state()

        if now - self.last_interaction_time > 15.0:
            if not self.is_hiding and self.current_state not in [PetState.DRAGGING, PetState.STRETCH_REMINDER, PetState.WATER_REMINDER]:
                self.is_hiding = True
                self._notify()

    def update_typing_state(self):
        if self.is_currently_typing:
            self.set_state(PetState.TYPING)
        else:
            if self.current_state == PetState.TYPING:
                self.set_state(PetState.IDLE, force=True)
        self._notify()

    def _tick_1s(self):
        self.update_typing_heat()
        
        if self.is_pomodoro_active:
            if self.pomodoro_time_remaining > 0:
                self.pomodoro_time_remaining -= 1
            elif self.pomodoro_time_remaining == 0:
                self.is_pomodoro_active = False
                self.purr_message = "Pomodoro Done! 🐾"
                self.show_purr_message = True
                self._notify()

        if self.stretch_interval > 0:
            if self.time_until_stretch > 0:
                self.time_until_stretch -= 1
            else:
                if self.set_state(PetState.STRETCH_REMINDER):
                    self.wake_up_if_needed()
                    self.purr_message = "Time to stretch! 🐾"
                    self.show_purr_message = True

        if self.water_interval > 0:
            if self.time_until_water > 0:
                self.time_until_water -= 1
            else:
                if self.set_state(PetState.WATER_REMINDER):
                    self.wake_up_if_needed()
                    self.purr_message = "Drink Water!"
                    self.show_purr_message = True

        if self.current_state == PetState.IDLE and not self.is_hiding and not self.is_blipping:
            if random.randint(1, 5) == 1:
                if random.random() < 0.05:
                    if self.set_state(PetState.STRETCHING):
                        def end_stretch():
                            if self.current_state == PetState.STRETCHING:
                                self.set_state(PetState.IDLE, force=True)
                        threading.Timer(1.5, end_stretch).start()

        threading.Timer(1.0, self._tick_1s).start()

    def _tick_0_15s(self):
        self.wag_tick = not self.wag_tick
        self._notify()
        threading.Timer(0.15, self._tick_0_15s).start()

    def _start_timers(self):
        threading.Timer(1.0, self._tick_1s).start()
        threading.Timer(0.15, self._tick_0_15s).start()
