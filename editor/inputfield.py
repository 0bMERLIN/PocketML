import os
import traceback

from kivy.uix.widget import Widget
from kivy.uix.button import Button
from kivy.uix.codeinput import CodeInput
from kivy.core.window import Window

from editor.graphicalout import GraphicalOut

from interpreter.interpreter import run_file
from interpreter.lexer import Lexer
from interpreter.parser import get_imports
from interpreter.typecheck import BUILTIN_KINDS, BUILTIN_TYPES, ModuleData, load_file

from utils import BTN_H, BTN_W, word_at_index


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

        # see if name is in builtins
        builtins = dict(list(BUILTIN_TYPES.items()) + list(BUILTIN_KINDS.items()))
        if current_symbol in builtins:
            t = current_symbol + " : " + str(builtins[current_symbol])

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

    def __init__(self, filename, editor, **kwargs):
        super().__init__(**kwargs)

        ############### Intellisense
        # Type: Dict[str (MODULE NAME), Dict[str, Typ]]
        self.cached_names = {}

        ############### UI
        self.editor = editor
        self.filename = filename

        code_input_h = Window.height / 3 + BTN_H
        code_input_y = Window.height - code_input_h - BTN_H*2
        
        self.stop_button = Button(
            text="Stop",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(0, code_input_y - 2*BTN_H)
        )
        self.close_button = Button(
            text="Close Tab",
            size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(BTN_W, code_input_y - 2*BTN_H)
        )
        self.save_button = Button(
            text="Save", size_hint=(1, 1),
            size=(BTN_W, BTN_H),
            pos=(2*BTN_W, code_input_y - 2*BTN_H)
        )
        self.run_button = Button(
            text="Run", size_hint=(1, 1), size=(BTN_W, BTN_H),
            pos=(3*BTN_W, code_input_y - 2*BTN_H)
        )

        self.code_input = CodeInput(
            pos=(0, code_input_y),
            size=(Window.width, code_input_h),
            background_color=(0.01, 0.01, 0.01),
            foreground_color=(0.9, 0.9, 0.9),
            auto_indent=True,
            lexer=Lexer(),
        )

        self.gettype_button = Button(
            text="type ?",
            size_hint=(1, 1),
            size=(Window.width, BTN_H),
            pos=(0, code_input_y - BTN_H),
            text_size=(Window.width, BTN_H),
            halign="center",
            valign="middle"
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
