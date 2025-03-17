from kivy.core.window import Window, Keyboard
from kivy.uix.widget import Widget
from kivy.graphics import Ellipse, Rectangle, Color
from kivy.clock import Clock
from kivy.uix.button import Button

from utils import curry


class GraphicalOut(Widget):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.screen = Widget()
        self.update_event = None
        self.pressed_keys = []

    def enable_kb(self):
        self._keyboard = Window.request_keyboard(self._keyboard_closed, self)
        self._keyboard.bind(on_key_down=self._on_keyboard_down)
        self._keyboard.bind(on_key_up=self._on_keyboard_rel)
        self.on_kb_down = lambda *_: None
        self.on_kb_up = lambda *_: None
        self.pressed_keys = []

    def _keyboard_closed(self):
        self._keyboard.unbind(on_key_down=self._on_keyboard_down)
        self._keyboard = None
        self.pressed_keys = []

    def _on_keyboard_down(self, keyboard: Keyboard, keycode, text, modifiers):
        self.on_kb_down(keyboard, keycode, text, modifiers)
        if (text, keycode) not in self.pressed_keys:
            self.pressed_keys += [(text, keycode)]

    def _on_keyboard_rel(self, keyboard: Keyboard, keycode):
        self.on_kb_up(keyboard, keycode)
        self.pressed_keys = list(filter(lambda k: k[1] != keycode, self.pressed_keys))

    @curry
    def circle(pos, rad: int):
        Ellipse(pos=pos, size=(rad,) * 2)

    @curry
    def rect(pos, size):
        Rectangle(pos=pos, size=size)

    def color(color):
        Color(*color)

    def clear(self, _):
        self.canvas.clear()

    def clearUpdate(self):
        Clock.unschedule(self.update_event)

    @curry
    def setUpdate(self, state, f):
        #self.enable_kb()
        if self.update_event != None:
            Clock.unschedule(self.update_event)
        self.state = state

        def helper(_):
            self.canvas.__enter__()
            self.state = f(self.state)(list(map(lambda k: k[0], self.pressed_keys)))
            self.canvas.__exit__()

        self.update_event = Clock.schedule_interval(helper, 1 / 60)

    def button(self, text, pos, size):
        btn = Button(
            text=text,
            pos=pos,
            size=size,
        )
        self.add_widget(btn)
        return btn

    def execute(self, f):
        return f(self)
