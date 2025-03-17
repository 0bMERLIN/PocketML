from math import sqrt
from interpreter.typecheck import load_file
from interpreter.evaluator import Evaluator

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
            "print": output,
            "print2": lambda a: lambda b: output(a, b),
        }
    )
    evaluator.env.update(env.items())

    try:
        evaluator.visit(tree)
    except Exception as e:
        raise Exception(f"Runtime error ({filename}):\n"+str(e))
