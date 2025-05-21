import os
import traceback
import threading

from kivy.uix.widget import Widget
from kivy.uix.button import Button
from kivy.core.window import Window
from kivy.uix.progressbar import ProgressBar
from kivy.clock import Clock

from editor.codeinput import LineNumCodeInput
from interpreter.interpreter import file_to_python, run_compiled, run_file
from interpreter.parser import get_imports
from interpreter.typ import PMLTypeError
from interpreter.typecheck import BUILTIN_KINDS, BUILTIN_TYPES, load_file

from utils import BTN_H, BTN_W, relpath, word_at_index


class InputField(Widget):
    """A code editor that can invoke the interpreter"""

    def save(self):
        with open(self.filename, "w+") as f:
            f.write(self.code_input.code_input.text)

    def run_file(self):
        self.save()

        def output(*xs):
            self.editor.terminalout.text += " ".join(map(str, xs))
            self.editor.terminalout.text += "\n"

        def report(msg):
            """Thread safe function for reporting to terminalout"""

            def helper(_):
                self.editor.terminalout.text = msg + "\n"

            Clock.schedule_once(helper)

        def clear():
            """Clear terminalout (not thread safe)"""
            self.editor.terminalout.text = ""

        def comp_done():
            self.editor.graphicalout.clear_widgets()
            self.editor.graphicalout.clearUpdate()
            self.run_button.disabled = False

        def run():
            try:
                run_compiled(output, env={"editor": self.editor})
            except Exception as e:
                report(e.args[0] + "\n" + traceback.format_exc())
                Clock.schedule_once(lambda _: comp_done())
                return

        def comp(*args, **kwargs):
            try:
                file_to_python(*args, **kwargs)
            except PMLTypeError as e:
                report(e.args[0])
                Clock.schedule_once(lambda _: comp_done())
                return
            except Exception as e:
                report(e.args[0] + "\n" + traceback.format_exc())
                Clock.schedule_once(lambda _: comp_done())
                return

            self.loading_bar.value = self.loading_bar.max
            Clock.schedule_once(lambda _: comp_done())
            Clock.schedule_once(
                lambda _: (
                    clear(),
                    output("Compiled successfully."),
                    run(),
                )
            )

        self.loading_bar.value = 0
        self.loading_bar.max = 5
        args = (self.filename,)
        kwargs = {
            "logger": lambda *x: (
                self.advance_loading_bar(float(" ".join(map(str, x)).split(" ")[-1])),
                print(*x),
            ),
        }
        run_file_thread = threading.Thread(target=comp, args=args, kwargs=kwargs)
        run_file_thread.start()
        self.run_button.disabled = True

    def advance_loading_bar(self, t: float):
        self.loading_bar.value += t

    def close(self):
        tab = self.editor.file_tabs[self.filename]
        self.editor.files_tab_panel.remove_widget(tab)
        self.editor.files_tab_panel.remove_widget(self)
        del self.editor.file_tabs[self.filename]
        self.editor.save_current_files()

    def stop_program(self):
        self.editor.graphicalout.clearUpdate()
        self.editor.graphicalout.clear_widgets()

    def find_type(self, nm, filename):
        """
        Try to find the type of `nm` in the
        given file or any of the ones it imports
        """
        typ = None
        try:
            typ = load_file(filename)[1]
        except PMLTypeError as e:
            return None

        t = typ.get_type_or_kind(nm)

        if t == None:
            res = [self.find_type(nm, fname) for fname in get_imports(filename)]
            return res[0] if res != [] else None
        else:
            return t

    def get_type(self):

        self.save()

        current_symbol = word_at_index(
            self.code_input.code_input.text, self.code_input.code_input.cursor_index()
        )

        if current_symbol in ["", None]:
            return

        t = "Variable not found. Might not be a global variable."

        # see if name is in builtins
        builtins = dict(list(BUILTIN_TYPES.items()) + list(BUILTIN_KINDS.items()))
        if current_symbol in builtins:
            t = current_symbol + " : " + str(builtins[current_symbol])

        # type check
        try:
            t0 = self.find_type(current_symbol, self.filename)
            if t0 != None:
                t = t0
            self.gettype_button.text = (
                current_symbol
                + " : "
                + (" -> ".join(["*"] * (t + 1)) if type(t) == int else str(t))
            )
        except Exception as e:
            self.gettype_button.text = str(e)

    def __init__(self, filename, editor, **kwargs):
        super().__init__(**kwargs)

        ############### UI
        self.editor = editor
        self.filename = relpath(filename)

        code_input_h = Window.height / 3 + BTN_H
        code_input_y = Window.height - code_input_h - BTN_H * 2

        self.stop_button = Button(
            text="Stop",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(0, code_input_y - 2 * BTN_H),
        )
        self.save_button = Button(
            text="Save",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(BTN_W, code_input_y - 2 * BTN_H),
        )
        self.run_button = Button(
            text="Run",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(2 * BTN_W, code_input_y - 2 * BTN_H),
        )

        self.code_input = LineNumCodeInput(
            code_input_y,
            code_input_h,
            pos=(0, code_input_y),
            size=(Window.width, code_input_h),
        )

        self.gettype_button = Button(
            text="type ?",
            size_hint=(1, 1),
            size=(Window.width - BTN_W, BTN_H),
            pos=(0, code_input_y - BTN_H),
            text_size=(Window.width - BTN_W, BTN_H),
            halign="center",
            valign="middle",
        )

        self.inc_font_size_button = Button(
            text="+",
            size_hint=(1, 1),
            size=(BTN_W / 2, BTN_H),
            pos=(Window.width - BTN_W, code_input_y - BTN_H),
        )

        self.dec_font_size_button = Button(
            text="-",
            size_hint=(1, 1),
            size=(BTN_W / 2, BTN_H),
            pos=(Window.width - BTN_W / 2, code_input_y - BTN_H),
        )

        self.redo_button = Button(
            text="Redo",
            size_hint=(1, 1),
            size=(BTN_W / 2, BTN_H),
            pos=(Window.width - BTN_W / 2, code_input_y - 2 * BTN_H),
        )

        self.undo_button = Button(
            text="Undo",
            size_hint=(1, 1),
            size=(BTN_W / 2, BTN_H),
            pos=(Window.width - BTN_W, code_input_y - 2 * BTN_H),
        )

        self.loading_bar = ProgressBar(max=0, size=(Window.width, BTN_H))

        if os.path.exists(filename):
            self.code_input.code_input.text = open(filename).read()
        else:
            self.code_input.code_input.text = ""

        self.run_button.on_press = self.run_file
        self.save_button.on_press = self.save
        self.stop_button.on_press = self.stop_program
        self.gettype_button.on_press = self.get_type
        self.inc_font_size_button.on_press = lambda: self.code_input.set_font_size(
            self.code_input.fontsize - 1
        )
        self.dec_font_size_button.on_press = lambda: self.code_input.set_font_size(
            self.code_input.fontsize + 1
        )
        self.redo_button.on_press = self.code_input.code_input.do_redo
        self.undo_button.on_press = self.code_input.code_input.do_undo

        self.add_widget(self.code_input)
        self.add_widget(self.run_button)
        self.add_widget(self.save_button)
        self.add_widget(self.stop_button)
        self.add_widget(self.inc_font_size_button)
        self.add_widget(self.dec_font_size_button)
        self.add_widget(self.gettype_button)
        self.add_widget(self.undo_button)
        self.add_widget(self.redo_button)
        self.add_widget(self.loading_bar)
