# bingus mc spiongus zarp III. junior

import os
import shutil
from kivy.uix.floatlayout import FloatLayout
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.textinput import TextInput
from kivy.uix.filechooser import FileChooserListView
from kivy.uix.popup import Popup

from interpreter import path
from utils import BTN_H, BTN_W, relpath


class FileManager(FloatLayout):
    def new_item(self, create, text="New"):
        path = self.file_chooser.path

        content = BoxLayout(orientation="vertical")
        filename_input = TextInput()
        close_btn = Button(text="done")
        content.add_widget(filename_input)
        content.add_widget(close_btn)

        popup = Popup(
            title=text, content=content, size_hint=(None, None), size=(400, 400)
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
        self.new_item(lambda p: self.editor.create_new_file_tab(p).save())

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

    def move(self):
        path = self.file_chooser.selection[0].split("\n")[-1]
        file = path.split("/")[-1]

        # build layout
        layout = BoxLayout(orientation="vertical")

        donebtn = Button(text="Move here", size_hint=(1, 0.15))
        cancelbtn = Button(text="Cancel", size_hint=(1, 0.15))
        filechooser = FileChooserListView(size_hint=(1, 1), dirselect=True)
        filechooser.path = path[: -len(file)]

        layout.add_widget(filechooser)
        layout.add_widget(donebtn)
        layout.add_widget(cancelbtn)

        # build popup
        popup = Popup(
            title=f"Move {file}?", content=layout, size_hint=(1, 1), size=(800, 800)
        )
        popup.open()

        # logic
        def helper():
            target = ""
            selected = filechooser.selection[0].split("\n")[-1]
            if os.path.isdir(selected):
                target = selected
            else:
                target = filechooser.path

            shutil.move(path, target)
            popup.dismiss()
            self.file_chooser._update_files()
            if relpath(path) in self.editor.file_tabs:
                self.editor.file_tabs[relpath(path)].content.close()
            new_path = target + "/" + path.split("/")[-1]
            if relpath(path) in self.editor.file_tabs:
                self.editor.create_new_file_tab(new_path)

        donebtn.on_press = helper
        cancelbtn.on_press = popup.dismiss

    def rename(self):
        selected = self.file_chooser.selection[0].split("\n")[-1]

        def helper(p):
            if relpath(selected) in self.editor.file_tabs:
                self.editor.file_tabs[relpath(selected)].content.close()
            new_path = "/".join(selected.split("/")[:-1]) + "/" + p.split("/")[-1]
            os.rename(selected, new_path)
            if relpath(selected) in self.editor.file_tabs:
                self.editor.create_new_file_tab(new_path)

        self.new_item(helper, text="Rename")

    def __init__(self, editor, **kwargs):
        super().__init__(**kwargs)
        self.editor = editor

        self.mode = "Normal"  # Normal | Move

        self.file_chooser = FileChooserListView(size_hint=(1, 1), dirselect=True)
        self.file_chooser.path = path.storage_path
        layout = BoxLayout(orientation="horizontal")
        self.new_file_button = Button(
            text="New File", pos_hint={"y": 0}, size_hint=(0.166, 0.1)
        )
        self.new_folder_button = Button(
            text="New Dir", pos_hint={"y": 0}, size_hint=(0.166, 0.1)
        )
        self.open_file_button = Button(
            text="Open", pos_hint={"y": 0}, size_hint=(0.166, 0.1)
        )

        self.delete_file_button = Button(
            text="Delete", pos_hint={"y": 0}, size_hint=(0.166, 0.1)
        )
        self.move_button = Button(
            text="Move", pos_hint={"y": 0}, size_hint=(0.166, 0.1)
        )
        self.rename_button = Button(
            text="Rename", pos_hint={"y": 0}, size_hint=(0.166, 0.1)
        )

        self.new_file_button.on_press = self.new_file
        self.new_folder_button.on_press = self.new_folder
        self.open_file_button.on_press = self.open_file
        self.delete_file_button.on_press = self.delete_file
        self.move_button.on_press = self.move
        self.rename_button.on_press = self.rename

        self.add_widget(self.file_chooser)
        layout.add_widget(self.open_file_button)
        layout.add_widget(self.delete_file_button)
        layout.add_widget(self.new_folder_button)
        layout.add_widget(self.new_file_button)
        layout.add_widget(self.move_button)
        layout.add_widget(self.rename_button)
        self.add_widget(layout)
