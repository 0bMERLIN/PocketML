import functools
import os
import re
from kivy.core.window import Window
from kivy import platform

# settings
VERBOSE = False
SHOW_COMPILE_TIME = True
SHOW_CACHE_USES = False
if VERBOSE:
    SHOW_CACHE_USES = True


#
BTN_H = Window.height/15
BTN_W = Window.width/4
if platform != "android":
    BTN_H = 800/15
    BTN_W = 500/4

def word_at_index(s, index):
    words = list(re.finditer(r'[a-zA-Z_][a-zA-Z_0-9]*', s))  # Find words using regex
    for match in words:
        if match.start() <= index <= match.end():  # Check if index falls inside the word
            return match.group()
    return None  # If index is out of range

def curry(func):
    @functools.wraps(func)
    def curried(*args):
        if len(args) >= func.__code__.co_argcount:
            return func(*args)
        return lambda *more_args: curried(*(args + more_args))
    return curried

def relpath(path):
    """
    Try to get the relative path, otherwise return original path
    """
    try:
        return os.path.relpath(path)
    except:
        return path
