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


def run_file(filename, output, env={}, logger=print):
    env = copy(env)
    env.update(globals())
    env.update({"PML_output": output})
    #env.update(builtin_env(output))

    res = file_to_python(filename, logger=logger)
    exec(res, env)


def run_compiled(output, env={}):
    """Run a program compiled into output.py"""
    env = copy(env)
    env.update(globals())
    env.update({"PML_output": output})

    #env.update(builtin_env(output))
    
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
