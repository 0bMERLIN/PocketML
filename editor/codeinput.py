
from kivy.uix.codeinput import CodeInput
from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.core.window import Window

from interpreter.lexer import Lexer


class NoScrollCodeInput(CodeInput):
    def on_touch_down(self, *args):
        pass


class LineNumCodeInput(BoxLayout):
    """combines CodeInput with line numbers."""

    def set_font_size(self, size):
        self.fontsize = size
        self.code_input.font_size = Window.width / size
        self.line_numbers.font_size = Window.width / size
        self.update_graphics()

    def update_graphics(self):
        self.line_numbers._update_graphics()
        self.code_input._update_graphics()
        self.update_line_numbers()
        self.sync_scroll()

    def __init__(self, code_input_y, code_input_h, **kwargs):
        super().__init__(orientation="horizontal", **kwargs)

        # Create line number label
        self.line_numbers = NoScrollCodeInput(
            pos=(0, code_input_y),
            size=(50, code_input_h),
            size_hint=(0.1, 1),
            background_color=(0.01, 0.01, 0.01),
            foreground_color=(0.9, 0.9, 0.9),
            readonly=True,
        )

        # Create code input field with Python syntax highlighting
        self.code_input = CodeInput(
            pos=(0, code_input_y),
            size=(Window.width, code_input_h),
            background_color=(0.01, 0.01, 0.01),
            foreground_color=(0.9, 0.9, 0.9),
            auto_indent=True,
            lexer=Lexer(),
        )

        # Bind updates to functions
        self.code_input.bind(text=self.update_line_numbers, scroll_y=self.sync_scroll)

        # Add widgets to layout
        self.add_widget(self.line_numbers)
        self.add_widget(self.code_input)

        # update graphics
        Clock.schedule_once(lambda _: self.set_font_size(32), 0.1)
        Clock.schedule_once(lambda _: self.update_graphics(), 0.3)

        # add the key down event handler
        Window.bind(on_key_down=self._on_key_down)
    
    def _on_key_down(self, window, keycode, scancode, codepoint, modifiers):
        if chr(keycode) in 'zZ' and 'ctrl' in modifiers:
            self.code_input.do_undo()
            return True  # prevent default if needed
        return False
    
    def get_line_numbers(self):
        line_count = self.code_input.text.count("\n") + 1
        return "\n".join(str(i) for i in range(1, line_count + 1))

    def get_visual_line_numbers(self):
        """Computes line numbers considering text wrapping."""
        lines = self.code_input.text.split("\n")
        font_size = self.code_input.font_size
        max_width = self.code_input.width - self.line_numbers.width

        visual_lines = []
        line_num = 1

        for i, line in enumerate(lines):

            # Create a temporary label to measure text width
            text_width = self.code_input._get_text_width(
                line[: len(line) - 4] if len(line) > 10 else line, 4, None
            )

            # Calculate how many visual lines this logical line takes
            wrapped_lines = max(1, 1 + int(text_width // max_width))
            visual_lines.append(str(line_num))
            visual_lines.extend([" "] * (wrapped_lines - 1))
            line_num += 1

        return "\n".join(visual_lines)

    def update_line_numbers(self, *args):
        self.line_numbers.text = self.get_visual_line_numbers()

    def sync_scroll(self, *args):
        self.line_numbers.scroll_y = self.code_input.scroll_y
        self.line_numbers._update_graphics()

