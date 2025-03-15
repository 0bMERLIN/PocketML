import os
import sys
from editor.editor import Editor
from kivy.config import Config

Config.set("kivy", "exit_on_escape", "0")
from kivy.app import App
from kivy import platform


class EditorApp(App):

    def build(self):
        self.editor = Editor()
        return self.editor


if __name__ == "__main__":
    try:
        if platform != "android":
            from kivy.core.window import Window

            Window.size = (500, 800)

        e = EditorApp()
        e.run()
        e.editor.save_current_files()

    except KeyboardInterrupt:
        e.editor.save_current_files()

        try:
            sys.exit(130)
        except SystemExit:
            os._exit(130)
