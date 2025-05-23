from kivy.uix.widget import Widget
from kivy.uix.textinput import TextInput
from kivy.core.window import Window
from kivy.uix.tabbedpanel import TabbedPanel, TabbedPanelItem, TabbedPanelHeader
from kivy.clock import Clock

from editor.filemanager import FileManager
from editor.graphicalout import GraphicalOut
from editor.inputfield import InputField
from kivy.core.window import Window

from utils import BTN_H, BTN_W, relpath

with open("current_file.txt") as f:
    current_files = f.read().strip("\n").split("\n")


class LongPressTabHeader(TabbedPanelHeader):
    """A tab header that does something when long pressed"""

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.hold_event = None  # Event to track long press
        self.action = lambda: None

    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            # Schedule long press detection
            self.hold_event = Clock.schedule_once(
                self.long_press, 0.8
            )  # Adjust duration as needed
        return super().on_touch_down(touch)

    def on_touch_up(self, touch):
        if self.hold_event:
            self.hold_event.cancel()  # Cancel long press if released early
        return super().on_touch_up(touch)

    def long_press(self, _dt):
        self.action()


class Editor(Widget):
    """
    The main editor widget. Contains tabs for code
    editing, file management etc.
    """

    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.file_tabs = {}
        self.files_tab_panel = TabbedPanel(
            size=(Window.width, Window.height - 50),
            tab_height=BTN_H,
            tab_width=BTN_W,
        )

        self.files_tab_panel.do_default_tab = False
        for f in current_files:
            if f.endswith("[OPEN]"):
                f = f.removesuffix("[OPEN]")
                self.create_new_file_tab(f)
                Clock.schedule_once(
                    lambda _: self.files_tab_panel.switch_to(self.file_tabs[f]), 0
                )

            self.create_new_file_tab(f)

        self.tab_panel = TabbedPanel(
            size=(Window.width, Window.height),
            tab_height=BTN_H,
            tab_width=BTN_W,
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
        tab = TabbedPanelItem(text="Graphics")
        self.graphicalout = GraphicalOut(self)
        tab.add_widget(self.graphicalout)
        self.tab_panel.add_widget(tab)
        return tab

    def create_term_tab(self):
        self.terminalout = TextInput(
            background_color=(0.01, 0.01, 0.01),
            foreground_color=(0.9, 0.9, 0.9),
        )
        tab = TabbedPanelItem(text="Text Out")
        tab.add_widget(self.terminalout)
        self.tab_panel.add_widget(tab)
        return tab

    def create_new_file_tab(self, filename):
        if filename in self.file_tabs:
            return

        i = InputField(filename, self)

        tab = LongPressTabHeader(text=filename.split("/")[-1])
        tab.action = i.close
        self.files_tab_panel.add_widget(tab)
        self.file_tabs[relpath(filename)] = tab
        tab.content = i

        self.save_current_files()

        return i

    def save_current_files(self):
        current_filename = self.files_tab_panel.current_tab.text
        with open("current_file.txt", "w+") as f:
            for fname in self.file_tabs:
                f.write(
                    fname
                    + ("[OPEN]" if fname.endswith(current_filename) else "")
                    + "\n"
                )

    def save_all(self):
        for f in self.file_tabs.values():
            f.content.save()
