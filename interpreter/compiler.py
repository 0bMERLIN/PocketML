from copy import copy
from interpreter.parser import parse_file
from interpreter.typecheck import global_module_cache
from lark import Token, Tree, v_args
from lark.visitors import Interpreter
from interpreter.path import storage_path
from utils import SHOW_CACHE_USES, curry


HEADER = """
import functools
def curry(func):
    @functools.wraps(func)
    def curried(*args):
        if len(args) >= func.__code__.co_argcount:
            return func(*args)
        return lambda *more_args: curried(*(args + more_args))
    return curried


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

    def _import(self, args):
        #####
        modulepath = args.children[:-1]
        e = args.children[-1]
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

        #####
        return (
            "\n__EXPORTS__={}\n"
            + self.visit(tree)
            + "\nglobals().update(__EXPORTS__)\n"
            + self.visit(e)
        )

    def valueexport(self, nm):
        return ""

    def typeexport(self, _):
        return ""

    def module(self, *exports):
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
        ops = {"*": "*", "°": "*", "||": "or", "&&": "and"}
        return self.emitv(
            "("
            + self.visit(a)
            + " "
            + (ops[op] if op in ops else op)
            + " "
            + self.visit(b)
            + ")"
        )

    def do(self, *stmts):
        res = None
        for s in stmts:
            res = self.visit(s)

        # return last expression
        return res

    def _tuple(self, elems):
        return "(" + ",".join([self.visit(e) for e in elems]) + ")"

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
        self.emit("return " + res)
        self.dedent()
        return self.visit(b)

    def letdecl(self, _x, _e, b):
        return self.visit(b)

    def letrec(self, *args):
        return self.let(*args)

    def var(self, x):
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
        self.emit("return " + res)
        self.dedent()

        return fn_name

    def lamcase(self, lamcases):
        param = self.newv()
        fn_name = self.newv()

        self.emit(f"def {fn_name}({param}):")
        self.indent()
        res = self.match(param, *lamcases.children, arg_compiled=True)
        self.emit("return " + res)
        self.dedent()

        return fn_name

    def num(self, x):
        return self.emitv(str(x))

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
        return self.emitv(self.visit(e) + "." + str(nm))

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
                return ('"PML_' + str(f.children[0]) + '"',)

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
