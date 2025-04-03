from math import sqrt
from interpreter.typecheck import load_file
from interpreter.evaluator import Evaluator


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
        res = str(v[0]) + " " + " ".join(map(str, v[1:]))
        return f"({res})" if len(v) > 1 else res

    # number
    if type(v) == float:
        return str(int(v) if v.is_integer() else v)

    return str(v)

def run_file(filename, output, env={}):

    tree, _ = load_file(filename)

    # run
    evaluator = Evaluator(
        {
            "and": lambda x: lambda y: x and y,
            "or": lambda x: lambda y: x or y,
            "add": lambda x: lambda y: x + y,
            "sub": lambda x: lambda y: x - y,
            "mul": lambda x: lambda y: x * y,
            "pow": lambda x: lambda y: x**y,
            "sqrt": lambda x: sqrt(x),
            "inc": lambda x: x + 1,
            "dec": lambda x: x - 1,
            "True": True,
            "False": False,
            "equal": lambda x: lambda y: x == y,
            "lt": lambda x: lambda y: x < y,
            "print": lambda *args: output(*[*map(prettify, args)]),
            "print2": lambda a: lambda b: output(a, b),
            "printa": lambda xs: output(*xs.values())
        },
        filename
    )
    evaluator.env.update(env.items())

    try:
        evaluator.visit(tree)

        print("[RAN]", filename)
    except Exception as e:
        raise Exception(f"Runtime error ({filename}):\n" + str(e))
