# Run the given file in a simplified editor environment.
# Use for testing or running PocketML programs on desktop.

import os
from interpreter.interpreter import run_file
import interpreter.typecheck as typecheck
import interpreter.path as path
import sys

from kivy.app import App

from kivy.uix.widget import Widget
from kivy.uix.textinput import TextInput
from kivy.core.window import Window
from kivy.uix.tabbedpanel import TabbedPanel, TabbedPanelItem

from editor.graphicalout import GraphicalOut
from kivy.core.window import Window
from utils import BTN_H

import pickle

class Editor(Widget):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.tab_panel = TabbedPanel(
            size=(Window.width, Window.height),
            tab_height=BTN_H,
            tab_width=Window.width/5,
        )
        self.run_tab = self.create_run_tab()
        self.tab_panel.default_tab = self.run_tab
        self.create_term_tab()
        self.add_widget(self.tab_panel)

        if os.path.exists("cache.pkl"):
            with open("cache.pkl", "rb") as f:
                typecheck.global_module_cache = pickle.load(f)

        def output(*xs):
            self.terminalout.text += " ".join(map(str, xs))
            self.terminalout.text += "\n"

        path.cwd = "/".join(sys.argv[-1].split("/")[:-1])
        run_file(sys.argv[-1], lambda *xs: (print(*xs), output(*xs)), env={"editor": self})

        with open("cache.pkl", "wb") as f:
            pickle.dump(typecheck.global_module_cache, f)

    def create_run_tab(self):
        tab = TabbedPanelItem(text="Graphics")
        self.graphicalout = GraphicalOut(self)
        tab.add_widget(self.graphicalout)
        self.tab_panel.add_widget(tab)
        return tab

    def create_term_tab(self):
        self.terminalout = TextInput(
            background_color=(0.01, 0.01, 0.01),
            foreground_color=(0.9, 0.9, 0.9),
            font_name="RobotoMono-Regular.ttf",
        )
        tab = TabbedPanelItem(text="Text Out")
        tab.add_widget(self.terminalout)
        self.tab_panel.add_widget(tab)
        return tab

editor = None
class EditorApp(App):
    def build(self):
        global editor
        editor = Editor()
        return editor

Window.size = (500, 800)
EditorApp().run()
