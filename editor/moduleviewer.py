from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.scrollview import ScrollView
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.widget import Widget
from kivy.core.window import Window

import os
import re
import difflib

from interpreter.path import storage_path
from utils import BTN_H, BTN_W


def list_files_recursive(path):
    acc = []
    for entry in os.listdir(path):
        full_path = os.path.join(path, entry)
        if os.path.isdir(full_path):
            acc += list_files_recursive(full_path)
        else:
            acc += [full_path]
    return list(set([p for p in acc if p.endswith(".ml")]))


def matches(line, query, threshold=0.8):
    if query in line:
        return True
    words = (
        line.replace("(", "").replace(")", "").replace(":", "").replace(",", "").split()
    )
    query = query.replace("(", "").replace(")", "").replace(":", "").replace(",", "")
    for word in words:
        ratio = difflib.SequenceMatcher(None, word.lower(), query.lower()).ratio()
        if ratio > threshold:
            return True
    return False


class ResultBox(BoxLayout):
    def __init__(self, definition: str, module: str, **kwargs):
        super().__init__(orientation="vertical", size_hint_y=None, padding=8, spacing=4, **kwargs)
        self.size_hint_x = 1

        # Calculate dynamic font sizes
        base_width, base_height = 800, 400  # Reference resolution
        scale_factor = min(Window.width / base_width, Window.height / base_height)
        large_font_size = int(32 * scale_factor)
        medium_font_size = int(24 * scale_factor)

        self.def_label = Label(
            text=definition,
            font_size=large_font_size,
            bold=True,
            halign="left",
            valign="top",
            pos_hint={"x": 0.01, "y": 0.2},
            font_name="RobotoMono-Regular",  # use default if missing
            color=(1, 1, 1, 1),
            text_size=(Window.width - 40, None),  # Wrap text based on window width
        )
        self.def_label.bind(texture_size=self._adjust_height)

        self.module_label = Label(
            text=module,
            font_size=medium_font_size,
            halign="left",
            valign="top",
            color=(0.7, 0.7, 0.7, 1),
            text_size=(Window.width - 40, None),
        )
        self.module_label.bind(texture_size=self.module_label.setter('size'))

        self.add_widget(self.def_label)
        self.add_widget(self.module_label)

        with self.canvas.before:
            from kivy.graphics import Color, RoundedRectangle
            Color(0.15, 0.15, 0.15, 1)
            self.bg = RoundedRectangle(radius=[8], pos=self.pos, size=self.size)
            self.bind(pos=self._update_bg, size=self._update_bg)

    def _adjust_height(self, instance, value):
        # Adjust height based on the number of lines the text wraps
        self.height = instance.texture_size[1] + Window.height / 8

    def _update_bg(self, *args):
        self.bg.pos = (self.pos[0], self.pos[1])
        self.bg.size = (self.size[0]*1.05, self.size[1])


class ModuleViewer(BoxLayout):
    def __init__(self, editor, **kwargs):
        super().__init__(**kwargs)
        self.editor = editor
        self.orientation = 'vertical'
        self.padding = 10
        self.spacing = 10

        # Calculate dynamic font sizes based on screen resolution
        base_width, base_height = 800, 400  # Reference resolution
        scale_factor = min(Window.width / base_width, Window.height / base_height)
        large_font_size = int(32 * scale_factor)
        medium_font_size = int(24 * scale_factor)

        # Search row
        search_row = BoxLayout(size_hint_y=None, height=BTN_H)
        self.search_box = TextInput(
            hint_text="Search (e.g. `let`, `type`, `data`)",
            size_hint_x=0.85,
            multiline=False,
            background_color=(0.1, 0.1, 0.1, 1),
            foreground_color=(1, 1, 1, 1),
            cursor_color=(1, 1, 1, 1),
            padding=[10, 10],
            font_size=large_font_size
        )
        self.search_btn = Button(
            text="Search",
            size_hint_x=0.15,
            background_color=(0.2, 0.4, 0.8, 1),
            color=(1, 1, 1, 1),
            font_size=medium_font_size
        )
        self.search_btn.bind(on_press=self.search)

        search_row.add_widget(self.search_box)
        search_row.add_widget(self.search_btn)

        # Result container
        self.results_layout = BoxLayout(
            orientation="vertical",
            size_hint_y=None,
            spacing=10,
            padding=5,
        )
        self.results_layout.bind(minimum_height=self.results_layout.setter('height'))

        self.scroll_view = ScrollView()
        self.scroll_view.add_widget(self.results_layout)

        self.add_widget(search_row)
        self.add_widget(self.scroll_view)

    def search(self, *args):
        query = self.search_box.text
        results = self.find_def(query)
        self.results_layout.clear_widgets()

        if not results:
            self.results_layout.add_widget(Label(
                text="No results found.",
                size_hint_y=None,
                height=30,
                color=(0.8, 0.8, 0.8, 1)
            ))
            return

        for path, lineno, line in results:
            short_path = os.path.relpath(path, storage_path)
            display_path = f"{short_path}:{lineno}"
            self.results_layout.add_widget(ResultBox(definition=line, module=display_path))

    def find_def(self, query: str):
        files = list_files_recursive(storage_path)
        definitions = self.find_definitions_in_files(files)
        acc = []
        for path, lineno, line in definitions:
            s = f"{path}:{lineno}: {line}"
            if matches(s, query):
                acc += [(path, lineno, line)]
        return acc

    def find_definitions_in_files(self, file_paths):
        pattern = re.compile(r"^\s*(type\s+\w+|let\s+\w+\s*:\s*|data(\s+\w+)+\s*)")
        matches = []
        for path in file_paths:
            try:
                with open(path, "r", encoding="utf-8") as f:
                    for lineno, line in enumerate(f, 1):
                        if pattern.match(line):
                            matches.append((path, lineno, line.strip().split("=")[0]))
            except Exception as e:
                print(f"Error reading {path}: {e}")
        return matches
