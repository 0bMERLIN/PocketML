import os
import sys
from editor.editor import Editor
from kivy.config import Config
from interpreter.path import storage_path

Config.set("kivy", "exit_on_escape", "0")
from kivy.app import App
from kivy import platform


import zipfile
import urllib.request
import os
import ssl


def download_github_folder(repo_url, branch="main", folder_path=""):
    # repo_url example: https://github.com/username/reponame
    # folder_path example: 'path/to/folder' inside repo

    # Construct ZIP URL of entire repo branch
    zip_url = repo_url.rstrip("/") + f"/archive/refs/heads/{branch}.zip"

    print(f"Downloading from {zip_url} ...")
    try:
        # Create an unverified SSL context
        ssl_context = ssl._create_unverified_context()

        # Download the ZIP file
        zip_path = os.path.join(storage_path, "repo.zip")
        with urllib.request.urlopen(zip_url, context=ssl_context) as response, open(zip_path, "wb") as out_file:
            out_file.write(response.read())

        # Extract the ZIP file
        with zipfile.ZipFile(zip_path, "r") as z:
            prefix = f"{repo_url.split('/')[-1]}-{branch}/"  # e.g. reponame-main/

            target_folder = storage_path
            os.makedirs(target_folder, exist_ok=True)

            for file in z.namelist():
                if file.startswith(prefix + folder_path):
                    # Extract relative path inside folder_path
                    rel_path = file[len(prefix + folder_path) :].lstrip("/")
                    if rel_path:
                        dest_path = os.path.join(target_folder, rel_path)
                        if file.endswith("/"):
                            os.makedirs(dest_path, exist_ok=True)
                        else:
                            os.makedirs(os.path.dirname(dest_path), exist_ok=True)
                            with open(dest_path, "wb") as f:
                                f.write(z.read(file))

        print(f"Folder extracted to {target_folder}")
    except Exception as e:
        print(f"Failed to download or extract folder: {e}")
    finally:
        # Clean up the downloaded ZIP file
        if os.path.exists(zip_path):
            os.remove(zip_path)


class EditorApp(App):
    # TODO: update std only, if new version
    def on_start(self):
        if not os.path.exists(storage_path):
            os.makedirs(storage_path, exist_ok=True)
        
        if not os.listdir(storage_path):
            download_github_folder(
                repo_url="https://github.com/0bMERLIN/PocketML",
                folder_path="examples",
            )
    

    def build(self):
        self.editor = Editor()
        self.icon = "assets/icon.png"
        return self.editor


if __name__ == "__main__":
    try:
        if platform != "android":
            from kivy.core.window import Window

            Window.size = (500, 800)

        e = EditorApp()
        e.run()
        e.editor.save_current_files()
        e.editor.save_all()

    except KeyboardInterrupt:
        e.editor.save_current_files()
        e.editor.save_all()

        try:
            sys.exit(130)
        except SystemExit:
            os._exit(130)
