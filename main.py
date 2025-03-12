import os
import sys
import traceback
from kivy.app import App
from kivy.uix.widget import Widget
from kivy.clock import Clock
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.codeinput import CodeInput
from kivy.uix.textinput import TextInput
from kivy.uix.filechooser import FileChooserListView
from kivy.uix.popup import Popup
from kivy.core.window import Window, Keyboard
from kivy.uix.tabbedpanel import TabbedPanel, TabbedPanelItem
from kivy.graphics import Ellipse, Canvas, Rectangle, Color
from pocketml import run_file
from kivy import platform
from lexer import Lexer
from pygments.lexers.c_cpp import CppLexer
from kivy.core.window import Window
from kivy.metrics import dp

from parser import get_imports
from utils import *

import path
import shutil

from typecheck import ModuleData, load_file

with open("current_file.txt") as f:
    current_files = f.read().split("\n")


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
    def circle(pos: dict, rad: int):
        Ellipse(pos=pos.values(), size=(rad,) * 2)

    @curry
    def rect(pos: dict, size: dict):
        Rectangle(pos=pos.values(), size=size.values())

    def color(color: dict):
        Color(*color.values())

    def clear(self, _):
        self.canvas.clear()

    def clearUpdate(self):
        Clock.unschedule(self.update_event)

    @curry
    def setUpdate(self, state, f):
        self.enable_kb()
        if self.update_event != None:
            Clock.unschedule(self.update_event)
        self.state = state

        def helper(_):
            self.canvas.__enter__()
            self.state = f(self.state)(list(map(lambda k: k[0], self.pressed_keys)))
            self.canvas.__exit__()

        self.update_event = Clock.schedule_interval(helper, 1 / 60)

    def button(self, text):
        @curry
        def helper(pos, size):
            btn = Button(
                text=text,
                pos=pos.values(),
                size=size.values(),
            )
            self.add_widget(btn)
            return btn

        return helper

    def execute(self, f):
        return f(self)


# TODO: rename
class InputField(Widget):
    def save(self):
        with open(self.filename, "w+") as f:
            f.write(self.code_input.text)

    def run_file(self):
        self.save()

        def inner(*xs):
            self.editor.terminalout.text += " ".join(map(str, xs))
            self.editor.terminalout.text += "\n"

        try:
            self.editor.terminalout.text = "Compiled successfully.\n"
            self.editor.graphicalout.clear_widgets()
            run_file(
                self.filename,
                inner,
                {
                    "button": self.editor.graphicalout.button,
                    "circle": GraphicalOut.circle,
                    "rect": GraphicalOut.rect,
                    "color": GraphicalOut.color,
                    "clear": self.editor.graphicalout.clear,
                    "execute": self.editor.graphicalout.execute,
                    "setUpdate": self.editor.graphicalout.setUpdate,
                    "editor": self.editor,
                },
            )
        except Exception as e:
            self.editor.terminalout.text = traceback.format_exc() + "\n"

    def close(self):
        tab = self.editor.file_tabs[self.filename]
        self.editor.files_tab_panel.remove_widget(tab)
        self.editor.files_tab_panel.remove_widget(self)
        del self.editor.file_tabs[self.filename]
        self.editor.save_current_files()

    def stop_program(self):
        self.editor.graphicalout.clearUpdate()

    def find_type(self, nm, filename):
        """
        Try to find the type of `nm` in the
        given file or any of the ones it imports
        """
        _, typ = load_file(filename)
        if isinstance(typ, ModuleData):
            self.cached_names[filename] = typ.get_all_types_and_kinds()
            t = typ.get_type_or_kind(nm)
            if t != None:
                return t

        res = [self.find_type(nm, fname) for fname in get_imports(filename)]
        return res[0] if res != [] else None

    def get_type(self):

        self.save()

        current_symbol = word_at_index(
            self.code_input.text, self.code_input.cursor_index()
        )

        t = "Variable not found. Might not be a global variable.\nIntellisense also only works on modules!"

        # see if name is in cache.
        for _, names in self.cached_names.items():
            if current_symbol in names:
                t = current_symbol + " : " + str(names[current_symbol])
                break

        try:
            t0 = self.find_type(current_symbol, self.filename)
            if t0 != None: t = t0
            self.gettype_button.text = current_symbol + " : " + (
                " -> ".join(["*"] * (t + 1))
                if type(t) == int
                else str(t)
            )
        except:
            self.gettype_button.text = "[ERROR]"

    def __init__(self, filename, editor: "Editor", **kwargs):
        super().__init__(**kwargs)

        ############### Intellisense
        # Type: Dict[str (MODULE NAME), Dict[str, Typ]]
        self.cached_names = {}

        ############### UI
        self.editor = editor
        self.filename = filename

        BTN_H = Window.height/15
        BTN_W = Window.width/5

        self.gettype_button = Button(
            text="type ?",
            size_hint=(1, 1),
            size=(Window.width, BTN_H),
            pos=(0, (Window.height - BTN_H) / 2 - BTN_H),
            text_size=(Window.width, BTN_H),
            halign="center",
            valign="middle"
        )
        self.save_button = Button(
            text="Save", size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(Window.width - BTN_W, 0)
        )
        self.run_button = Button(
            text="Run", size_hint=(1, 1), size=(BTN_W, BTN_H),
            pos=(Window.width - BTN_W, BTN_H)
        )
        self.close_button = Button(
            text="Close Tab",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(Window.width - BTN_W, 2*BTN_H)
        )
        self.stop_button = Button(
            text="Stop",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(Window.width - BTN_W, 3*BTN_H)
        )
        self.code_input = CodeInput(
            pos=(0, (Window.height - BTN_W) / 2),
            size=(Window.width, (Window.height - BTN_W) / 2),
            background_color=(0.01, 0.01, 0.01),
            foreground_color=(0.9, 0.9, 0.9),
            auto_indent=True,
            lexer=Lexer(),
        )
        if os.path.exists(filename):
            self.code_input.text = open(filename).read()
        else:
            self.code_input.text = ""

        self.run_button.on_press = self.run_file
        self.save_button.on_press = self.save
        self.close_button.on_press = self.close
        self.stop_button.on_press = self.stop_program
        self.gettype_button.on_press = self.get_type
        self.add_widget(self.code_input)
        self.add_widget(self.run_button)
        self.add_widget(self.save_button)
        self.add_widget(self.close_button)
        self.add_widget(self.stop_button)
        self.add_widget(self.gettype_button)


class FileManager(FloatLayout):
    def new_item(self, create):
        path = self.file_chooser.path

        content = BoxLayout(orientation="vertical")
        filename_input = TextInput()
        close_btn = Button(text="done")
        content.add_widget(filename_input)
        content.add_widget(close_btn)

        popup = Popup(
            title="Test popup", content=content, size_hint=(None, None), size=(400, 400)
        )
        popup.open()

        close_btn.on_press = popup.dismiss

        def helper():
            if filename_input.text.strip() == "":
                return
            create(path + "/" + os.path.normpath(filename_input.text))
            self.file_chooser._update_files()

        popup.on_dismiss = helper

    def new_file(self):
        def f(p):
            self.editor.create_new_file_tab(p).save()

        self.new_item(f)

    def new_folder(self):
        self.new_item(os.mkdir)

    def open_file(self):
        if len(self.file_chooser.selection) == 0:
            return
        path = self.file_chooser.selection[0]
        if os.path.isdir(path):
            return
        self.editor.create_new_file_tab(path)

    def delete_file(self):
        if len(self.file_chooser.selection) == 0:
            return
        path = self.file_chooser.selection[0]

        layout = BoxLayout(orientation="vertical")
        yesbtn = Button(text="Yes")
        nobtn = Button(text="No")
        layout.add_widget(yesbtn)
        layout.add_widget(nobtn)

        file = path.split("\n")[-1]
        popup = Popup(
            title=f"Delete {file}?",
            content=layout,
            size_hint=(None, None),
            size=(800, 800),
        )
        popup.open()

        def helper():
            if os.path.isdir(path):
                shutil.rmtree(path + "/")
            else:
                os.remove(path)
            popup.dismiss()
            self.file_chooser._update_files()

        yesbtn.on_press = helper
        nobtn.on_press = popup.dismiss

    def __init__(self, editor, **kwargs):
        super().__init__(**kwargs)
        self.editor = editor

        self.file_chooser = FileChooserListView(size_hint=(1, 1), dirselect=True)
        self.file_chooser.path = path.storage_path
        layout = FloatLayout()
        self.new_file_button = Button(
            text="New File", pos_hint={"x": 0.8, "y": 0}, size_hint=(0.2, 0.1)
        )
        self.new_folder_button = Button(
            text="New Folder", pos_hint={"x": 0.8, "y": 0.1}, size_hint=(0.2, 0.1)
        )
        self.open_file_button = Button(
            text="Open", pos_hint={"x": 0.8, "y": 0.2}, size_hint=(0.2, 0.1)
        )
        self.delete_file_button = Button(
            text="Delete", pos_hint={"x": 0.8, "y": 0.3}, size_hint=(0.2, 0.1)
        )

        self.new_file_button.on_press = self.new_file
        self.new_folder_button.on_press = self.new_folder
        self.open_file_button.on_press = self.open_file
        self.delete_file_button.on_press = self.delete_file

        self.add_widget(self.file_chooser)
        layout.add_widget(self.open_file_button)
        layout.add_widget(self.delete_file_button)
        layout.add_widget(self.new_folder_button)
        layout.add_widget(self.new_file_button)
        self.add_widget(layout)


class Editor(Widget):

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.file_tabs = {}
        self.files_tab_panel = TabbedPanel(
            size=(Window.width, Window.height - 50), tab_height=100, tab_width=400
        )
        self.files_tab_panel.do_default_tab = False
        for f in current_files:
            self.create_new_file_tab(f)

        self.tab_panel = TabbedPanel(
            size=(Window.width, Window.height), tab_height=100, tab_width=200
        )
        self.tab_panel.default_tab = self.create_editor_tab()
        self.create_run_tab()
        self.create_term_tab()
        self.create_file_mngr_tab()

        self.add_widget(self.tab_panel)

    def create_file_mngr_tab(self):
        tab = TabbedPanelItem(text="Files")
        self.file_manager = FileManager(self)
        tab.add_widget(self.file_manager)
        self.file_manager.size_hint = (1, 1)
        self.tab_panel.add_widget(tab)
        return tab

    def create_editor_tab(self):
        tab = TabbedPanelItem(text="Editor")
        tab.add_widget(self.files_tab_panel)
        self.tab_panel.add_widget(tab)
        return tab

    def create_run_tab(self):
        tab = TabbedPanelItem(text="Program")
        self.graphicalout = GraphicalOut()
        tab.add_widget(self.graphicalout)
        self.tab_panel.add_widget(tab)
        return tab

    def create_term_tab(self):
        self.terminalout = TextInput()
        tab = TabbedPanelItem(text="Text Out")
        tab.add_widget(self.terminalout)
        self.tab_panel.add_widget(tab)
        return tab

    def create_new_file_tab(self, filename):
        # Create a new tab with a CodeInput widget
        tab = TabbedPanelItem(text=filename.split("/")[-1])
        i = InputField(filename, self)
        tab.add_widget(i)
        self.files_tab_panel.add_widget(tab)
        self.file_tabs[filename] = tab
        self.save_current_files()
        return i

    def save_current_files(self):
        with open("current_file.txt", "w+") as f:
            f.write("\n".join(self.file_tabs.keys()))


class EditorApp(App):
    def build(self):
        return Editor()


if __name__ == "__main__":
    if platform != "android":
        from kivy.core.window import Window
        Window.size = (500, 800)
    EditorApp().run()
