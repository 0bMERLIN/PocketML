from kivy.uix.codeinput import CodeInput
from kivy.clock import Clock
from kivy.uix.boxlayout import BoxLayout
from kivy.core.window import Window
from kivy.uix.button import Button
from kivy.uix.popup import Popup

from interpreter.lexer import Lexer


class NoScrollCodeInput(CodeInput):
    def on_touch_down(self, *args):
        pass


def custom_on_parent(self, *args):
    if len(args) != 2:
        instance = args[0]
        value = None
    else:
        instance, value = args

    parent = self.textinput
    mode = self.mode

    if parent:
        self.content.clear_widgets()
        if mode == "paste":
            # show only paste on long touch
            self.but_selectall.opacity = 1
            widget_list = [
                self.but_selectall,
            ]
            if not parent.readonly:
                widget_list.append(self.but_paste)
        elif parent.readonly:
            # show only copy for read only text input
            widget_list = (self.but_copy,)
        else:
            # normal mode
            widget_list = (
                self.but_cut,
                self.but_copy,
                self.but_paste,
            )

        for widget in widget_list:
            self.content.add_widget(widget)


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

        showccp = self.code_input._show_cut_copy_paste

        def helper(*_1, **_2):
            self.code_input.use_bubble = True
            showccp(*_1, **_2)
            self.code_input._bubble.but_comment = Button(
                text="#",
                size=(Window.width / 10, Window.height / 20),
                background_color=(0, 0, 0, 0),
            )

            def comment():
                """comment current selection or line"""

                # get the current selection indices
                start = self.code_input.selection_from
                end = self.code_input.selection_to

                if start > end:
                    start, end = end, start

                if start == end:
                    # if no selection, comment the current line
                    start = (
                        self.code_input.text.rfind("\n", 0, start) + 1
                        if start > 0
                        else 0
                    )
                    end = self.code_input.text.find("\n", start)
                    if end == -1:
                        end = len(self.code_input.text)

                # find the line starts and check if all lines are commented
                all_commented = True
                for i in range(start, end):
                    line_start = self.code_input.text.rfind("\n", 0, i) + 1
                    line_end = self.code_input.text.find("\n", line_start)
                    if line_end == -1:
                        line_end = len(self.code_input.text)
                    line_text = self.code_input.text[line_start:line_end]
                    if not line_text.strip().startswith("#"):
                        all_commented = False
                        break

                # find line start
                while start > 0 and self.code_input.text[start - 1] != "\n":
                    start -= 1
                
                # find line end
                if not all_commented:
                    while end < len(self.code_input.text) and self.code_input.text[end] != "\n":
                        end += 1
                    end += 1

                # comment or uncomment the lines
                i = start
                while i <= end and i < len(self.code_input.text):
                    if not all_commented:
                        self.code_input.cursor = self.code_input.get_cursor_from_index(i)
                        self.code_input.insert_text("# ")
                    else:
                        c,r = self.code_input.get_cursor_from_index(i)
                        self.code_input.cursor = (c + 2, r)
                        self.code_input.do_backspace()
                        self.code_input.do_backspace()

                    j = i
                    i = self.code_input.text.find("\n", i) + 1
                    if i < j:
                        break

            self.code_input._bubble.but_comment.bind(on_release=lambda x: comment())
            self.code_input._bubble.on_parent = custom_on_parent
            self.code_input._bubble.content.add_widget(
                self.code_input._bubble.but_comment
            )
            self.code_input._bubble.content.size_hint = (1.5, 1)

        self.code_input._show_cut_copy_paste = helper

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
        if chr(keycode) in "zZ" and "ctrl" in modifiers:
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

    def get_wrapped_line_num(self, l):
        """Get the actual line number in the text from the
        wrapped one"""
        lines = self.code_input.text.split("\n")
        max_width = self.code_input.width - self.line_numbers.width

        line_num = 0

        for i, line in enumerate(lines[: l + 1]):

            # Create a temporary label to measure text width
            text_width = self.code_input._get_text_width(
                line[: len(line) - 4] if len(line) > 10 else line, 4, None
            )

            # Calculate how many visual lines this logical line takes
            line_num += max(1, 1 + int(text_width // max_width))

        return line_num

    def update_line_numbers(self, *args):
        self.line_numbers.text = self.get_visual_line_numbers()

    def sync_scroll(self, *args):
        self.line_numbers.scroll_y = self.code_input.scroll_y
        self.line_numbers._update_graphics()
