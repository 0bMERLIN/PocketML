from copy import copy
from math import sqrt
from interpreter.compiler import compile
from interpreter.typecheck import load_file
from interpreter.evaluator import Evaluator
import time

from utils import SHOW_COMPILE_TIME


def conv_list(l):
    # convert a PML list to a python list

    if l[0] == "Nil":
        return []
    return [l[1]] + conv_list(l[2])


def prettify(v):
    """
    Turn a runtime value into a string.
    """
    # tuple
    if type(v) == dict and all(
        [(str(x).startswith("_") and str(x)[1:].isnumeric()) for x in v.keys()]
    ):
        return "(" + ", ".join([*map(str, v.values())]) + ")"

    # list
    if type(v) == tuple and len(v) != 0 and v[0] in ["Cons", "Nil"]:
        l = conv_list(v)
        return "[" + ", ".join(list(map(prettify, l))) + "]"

    # custom data type
    if type(v) == tuple and len(v) != 0 and type(v[0]) == str:
        res = str(v[0].strip("PML_")) + " " + " ".join(map(str, v[1:]))
        return f"({res})" if len(v) > 1 else res

    # number
    if type(v) == float:
        return str(int(v) if v.is_integer() else v)

    return str(v)


def builtin_env(output):
    # TODO: migrate this into the compiled code!
    builtins = {
        "PML_and": lambda x: lambda y: x and y,
        "PML_or": lambda x: lambda y: x or y,
        "PML_add": lambda x: lambda y: x + y,
        "PML_sub": lambda x: lambda y: x - y,
        "PML_mul": lambda x: lambda y: x * y,
        "PML_pow": lambda x: lambda y: x**y,
        "PML_sqrt": lambda x: sqrt(x),
        "PML_inc": lambda x: x + 1,
        "PML_dec": lambda x: x - 1,
        "PML_True": True,
        "PML_False": False,
        "PML_equal": lambda x: lambda y: x == y,
        "PML_lt": lambda x: lambda y: x < y,
        "PML_print": lambda *args: output(*[*map(prettify, args)]),
        "PML_print2": lambda a: lambda b: output(a, b),
        "PML_printa": lambda xs: output(*xs.values()),
        "PML_print_raw": print
    }

    return builtins


def run_file(filename, output, env={}, logger=print):
    

    env = copy(env)
    env.update(globals())
    env.update(builtin_env(output))

    res = file_to_python(filename, logger=logger)
    exec(res, env)


def run_compiled(output, env={}):
    """Run a program compiled into output.py"""
    env = copy(env)
    env.update(globals())
    env.update(builtin_env(output))
    
    with open("output.py") as f:
        src = f.read()
        exec(src, env)



def file_to_python(filename, logger=print):
    tree, _ = load_file(filename, logger)

    t1 = time.time()
    res = compile(tree)
    t2 = time.time()
    if SHOW_COMPILE_TIME:
        logger(f"[COMPILE] ({filename})\t", round(t2 - t1, 4))

    with open("output.py", "w+") as f:
        f.write(res)

    print("")
    return res
