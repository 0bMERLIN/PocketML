from copy import copy
import time
from interpreter.parser import parse_file
from interpreter.typecheck import global_module_cache
from lark import Token, Tree, v_args
from lark.visitors import Interpreter
from interpreter.path import storage_path
from utils import SHOW_CACHE_USES, curry


HEADER = """
import functools
import numpy as np
def curry(func):
    @functools.wraps(func)
    def curried(*args):
        if len(args) >= func.__code__.co_argcount:
            return func(*args)
        return lambda *more_args: curried(*(args + more_args))
    return curried

    
def compose(f,g):
    return lambda x: f(g(x))

def convlist(l):
    # convert a PML list to a python list
    if l[0] == "PML_Nil":
        return []
    return [l[1]] + convlist(l[2])

def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc
    
def prettify(v):
    '''
    Turn a runtime value into a string.
    '''
    # tuple
    if type(v) == dict and all(
        [(str(x).startswith("_") and str(x)[1:].isnumeric()) for x in v.keys()]
    ):
        return "(" + ", ".join([*map(prettify, v.values())]) + ")"

    # list
    if type(v) == tuple and len(v) != 0 and v[0] in ["PML_Cons", "PML_Nil"]:
        l = convlist(v)
        return "[" + ", ".join(list(map(prettify, l))) + "]"

    # custom data type
    if type(v) == tuple and len(v) != 0 and type(v[0]) == str:
        res = str(v[0].removeprefix("PML_")) + " " + " ".join(map(prettify, v[1:]))
        return f"({res})" if len(v) > 1 else res

    # number
    if type(v) == float:
        return str(int(v) if v.is_integer() else v)

    # str
    if type(v) == str:
        return f'"{v}"'

    return str(v)


def builtin_env(output):
    builtins = {
        "PML_and": lambda x: lambda y: x and y,
        "PML_or": lambda x: lambda y: x or y,
        "PML_add": lambda x: lambda y: mklist(convlist(x) + convlist(y)) if type(x) == tuple and x[0] in ["PML_Cons", "PML_Nil"] else x + y,
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
        "PML_print": lambda *args: output(*[*map(lambda x: prettify(x) if type(x) != str else x, args)]),
        "PML_print2": lambda a: lambda b: output(a, b),
        "PML_printa": lambda xs: output(*xs.values()),
        "PML_print_raw": output
    }

    return builtins

globals().update(builtin_env(PML_output))

"""


def compile(tree):
    c = Compiler()
    c.visit(tree)
    return HEADER + postprocess(c.res)


def postprocess(src: str):
    res = ""
    i = 0
    ls = src.split("\n")
    while ls != []:
        l = ls.pop(0)

        # indentation
        if l == ":>":
            i += 1
        elif l == "<:":
            i -= 1

        # inlining
        elif l.startswith("PML_anon"):
            var = l.split(" ")[0]
            x = l.replace(var + " = ", "")
            for j in range(len(ls)):
                if ls[j] == "<:":
                    res += "\t" * i + l + "\n"
                    break
                if ls[j].count(var) > 0:
                    ls[j] = ls[j].replace(var, x)
                    break

            else:
                res += "\t" * i + x + "\n"

        # anything else
        else:
            res += "\t" * i + l + "\n"
    return res


@v_args(inline=True)
class Compiler(Interpreter):

    def __init__(self):
        self.res = ""
        self.var_n = 0

    def emit(self, code: str, end=None):
        self.res += code + ("\n" if end == None else end)

    def newv(self):
        res = f"PML_anon{self.var_n}"
        self.var_n += 1
        return res

    def newv_noinline(self):
        """Create a new variable name that will not be inlined"""
        res = f"PML_tmp{self.var_n}"
        self.var_n += 1
        return res

    def emitv(self, code: str):
        v = self.newv()
        self.emit(v + " = " + code)
        return v

    def indent(self):
        self.emit(":>")

    def dedent(self):
        self.emit("<:")

    #############
    def cache(self, next):
        return self.visit(next)

    def import_module_path(self, *path):
        # return the path items as a list of strings
        # from the path lark.Tree object.
        return [str(p) for p in path]

    def import_as(self, alias):
        # return the alias as a string from the lark.Tree object.
        return str(alias)

    def valueimport(self, x):
        return str(x)

    def typeimport(self, x):
        return "type " + str(x)

    def import_list(self, *items):
        return [self.visit(c) for c in items]

    def parse_import(self, args):
        # get filename
        has_import_list = "import_list" in [c.data for c in args.children]
        has_alias = "import_as" in [c.data for c in args.children]

        modulepath = self.visit(args.children[0])

        # get import list if it is there
        import_list = None
        if has_import_list:
            import_list = self.visit(args.children[1])

        # get alias if it is there
        alias = None
        if has_alias:
            alias = self.visit(args.children[2 if has_import_list else 1])

        return modulepath, import_list, alias

    def _import(self, args):
        # TODO: handle names from module colliding with current environment

        modulepath, import_list, alias = self.parse_import(args)
        e = args.children[-1]

        #####
        filename = (
            storage_path
            + ("/" if storage_path[-1] != "/" else "")
            + "/".join(map(str, modulepath))
        )
        filename += ".ml"

        if global_module_cache.cached(filename):
            if SHOW_CACHE_USES:
                print("----> used cached parse for", filename)
            tree = global_module_cache.get(filename)[1]
        else:
            tree = parse_file(filename)

        # create the appropriate __EXPORTS__ dict, if import list is given
        exports = {}
        if import_list is not None:
            for item in import_list:
                if not item.startswith("type "):
                    # imported module gets compiled, inserted and
                    # sets a __EXPORTS__ variable.
                    # Generate new __EXPORTS__ dict including
                    # only items from import_list.
                    exports[item] = f'__EXPORTS__["PML_{item}"]'

        self.emit("\n__EXPORTS__={}\n")
        self.emit("\n__OLD_ENV__=copy(globals())\n")
        self.visit(tree)
        # if module alias, replace __EXPORTS__ with { "[alias]" : __EXPORTS__ }
        self.emit("\nglobals().update({ " + f'"PML_{alias}" : __EXPORTS__' + " })")

        # handle import list
        exports_compiled = (
            "{" + ", ".join([f"'PML_{k}' : {v}" for k, v in exports.items()]) + "}"
        )
        self.emit(
            f"\nglobals().update(__EXPORTS__)\n"
            if import_list is None
            else f"\nglobals().update({exports_compiled})"
        )
        self.emit("\nglobals().update(__OLD_ENV__)\n")

        # body
        return self.visit(e)

    def valueexport(self, nm):
        return str(nm)

    def typeexport(self, _):
        return "type DONOTEXPORT"

    def module(self, *exports):
        exports = [self.visit(e) for e in exports]
        # if exports is empty export everything
        if len(exports) == 0:
            self.emit(
                "__EXPORTS__ = {k:v for k,v in globals().items() if k.startswith('PML_')}\n"
            )
            return ""

        # put all value exports in a dict
        exports = [f"{e}" for e in exports if not e.startswith("type ")]
        exports = [f'"PML_{e}": PML_{e}' for e in exports]

        self.emit("__EXPORTS__ = {" + ", ".join(exports) + "}\n")
        return ""

    # ========== EXPRESSIONS
    def list(self, elems):
        es = self.visit_children(elems)

        res = "('PML_Nil',)"
        for e in reversed(es):
            res = "('PML_Cons'," + e + "," + res + ")"

        return self.emitv(res)

    def nparray(self, elems):
        es = self.visit_children(elems)
        return self.emitv(f"np.array([{', '.join(es)}])")

    def infix_op(self, a, op, b):

        if op == "$":
            return self.emitv(self.visit(a) + "(" + self.visit(b) + ")")

        if op == "<<":
            return self.emitv(f"compose({self.visit(a)}, {self.visit(b)})")

        if op == ">>":
            return self.emitv(f"compose({self.visit(b)}, {self.visit(a)})")

        if op == "+":
            return self.emitv(f"PML_add({self.visit(a)})({self.visit(b)})")

        ops = {"*": "*", "°": "*", "||": "or", "&&": "and"}

        return self.emitv(
            f"({self.visit(a)} {ops[op] if op in ops else op} {self.visit(b)})"
        )

    def do(self, *stmts):
        res = None
        for s in stmts:
            res = self.visit(s)

        # return last expression
        return res

    def _tuple(self, elems):
        xs = self.visit_children(elems)[0]
        return "{" + ",".join([(f'"_{i}": {x}') for i, x in enumerate(xs)]) + "}"

    def none(self, _):
        return "None"

    def python(self, code, e):
        self.emit(code.strip("%"))
        return self.visit(e)

    def inlinepython(self, code):
        return code.strip("%")

    def ite(self, c, *cases):
        res = self.newv()

        # if
        self.emit(f"if {self.visit(c)}:")
        self.indent()
        ires = self.visit(cases[0])
        self.emit(res + " = " + ires)
        self.dedent()

        # else
        if len(cases) > 1:
            self.emit("else:")
            self.indent()
            eres = self.visit(cases[1])
            self.emit(res + " = " + eres)
            self.dedent()

        return res

    def let(self, *args):
        x = args[0]
        params = args[1:-2]
        e, b = args[-2], args[-1]

        # normal assignment (x = ...)
        if len(params) == 0:
            self.emit(f"PML_{x} = {self.visit(e)}")
            return self.visit(b)

        # function definition (def ...)
        if len(params) > 1:
            self.emit("\n@curry")
        self.emit(f"def PML_{x}({', '.join(map(lambda x:'PML_'+x,params))}):")
        self.indent()
        res = self.visit(e)
        self.emit("return (" + res + ")")
        self.dedent()
        return self.visit(b)

    def letdecl(self, _x, _e, b):
        return self.visit(b)

    def letrec(self, *args):
        return self.let(*args)

    def var(self, x):
        if str(x) == "yield":
            return str(x)
        return "PML_" + str(x)

    def app(self, f, x):
        return self.emitv(self.visit(f) + "(" + self.visit(x) + ")")

    def lam(self, *args):
        xs = args[:-1]
        b = args[-1]

        fn_name = self.newv()

        # function definition (def ...)
        if len(xs) > 1:
            self.emit("\n@curry")
        self.emit(f"def {fn_name}({', '.join(map(lambda x:'PML_'+x, xs))}):")
        self.indent()
        res = self.visit(b)
        self.emit("return (" + res + ")")
        self.dedent()

        return fn_name

    def lamcase(self, lamcases):
        param = self.newv()
        fn_name = self.newv()

        self.emit(f"def {fn_name}({param}):")
        self.indent()
        res = self.match(param, *lamcases.children, arg_compiled=True)
        self.emit("return (" + res + ")")
        self.dedent()

        return fn_name

    def num(self, x):
        return str(x)

    def string(self, s: str):
        return self.emitv(s.replace("\n", "\\n"))

    def neg(self, x):
        return self.emitv("-" + self.visit(x))

    def entry(self, nm, v):
        return (str(nm), self.visit(v))

    def record(self, *entries):
        items = [self.visit(e) for e in entries]
        return self.emitv("{" + ",".join([f'"{a}":{b}' for a, b in items]) + "}")

    def access(self, e, nm):
        return self.emitv(
            self.visit(e)
            + "['"
            + str(nm)
            + f"' if '{str(nm)}' in "
            + self.visit(e)
            + " else 'PML_"
            + str(nm)
            + "']"
        )

    def typedecl(self, *args):
        return self.visit(args[-1])

    def typedef(self, *args):
        cs = args[-2]
        for c in cs.children:
            # build the constructor as a lambda
            cname = str(c.children[0])
            nargs = len(c.children) - 1
            names = [f"x{x}" for x in range(nargs)]
            lambdas = [f"lambda {x}: " for x in names]
            tup = f"('PML_{cname}', {', '.join(names)})"
            constr = "".join(lambdas) + tup

            self.emit(f"PML_{cname} = {constr}")
        return self.visit(args[-1])

    def typealias(self, *args):
        return self.visit(args[-1])

    # ========== patterns
    def match(self, arg, *cs, arg_compiled=False):
        res = self.newv_noinline()
        self.emit(f"{res} = None")

        a = arg if arg_compiled else self.visit(arg)
        self.emit(f"match {a}:")
        self.indent()
        for case in cs:
            c, e = case.children
            self.emit(f"case {self.visit(c)}:")
            self.indent()
            self.emit(res + " = " + self.visit(e))
            self.dedent()

        self.dedent()
        return res

    def pentry(self, nm, p):
        return (str(nm), self.visit(p))

    def precordvar(self, nm):
        return (str(nm), "PML_"+str(nm))

    def precord(self, *entries):
        xs = list(map(self.visit, entries))
        return "{" + ",".join([(f'"{k}": {v}') for k,v in xs]) + "}"

    def ptuple(self, elems):
        xs = self.visit_children(elems)
        return "{" + ",".join([(f'"_{i}": {x}') for i, x in enumerate(xs)]) + "}"

    def pvar(self, nm):
        return "PML_" + str(nm)

    def pwildcard(self):
        return "_"

    def pnum(self, x):
        return str(x)

    def pstr(self, s):
        return str(s)

    def pconstrname(self, nm):
        return str(("PML_" + str(nm),))

    # ((F, a1), a2)
    def papp(self, f, a):

        def helper(f):
            if isinstance(f, Tree) and f.data == "pconstrname":
                return ('"PML_' + str(f.children[-1]) + '"',)

            elif isinstance(f, Tree) and f.data == "papp":
                a1 = tuple(map(self.visit, f.children[1:]))

                f1 = f.children[0]
                if isinstance(f1, Tree) and f1.data == "pconstrname":
                    return ('"PML_' + str(f1.children[0]) + '"',) + a1

                f1 = helper(f1)
                if type(f1) == str:
                    return (f1,) + a1
                else:
                    return f1 + a1

            else:
                return self.visit(f)

        x = helper(f)
        res = x + (self.visit(a),)
        return "(" + ", ".join(res) + ")"
