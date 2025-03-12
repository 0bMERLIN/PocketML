from copy import copy, deepcopy
import sys

import numpy as np
from lark import v_args
from lark.visitors import Interpreter

from parser import parse_file
from path import storage_path


@v_args(inline=True)
class Evaluator(Interpreter):
    def __init__(self, env):
        self.env = env
        self.toplevel = False # is the current node a toplevel node?

    # ========== MODULE SYSTEM
    def _import(self, args):
        modulepath = args.children[:-1]
        e = args.children[-1]
        filename = storage_path+("/"if storage_path[-1]!="/" else "")+"/".join(map(str,modulepath))
        filename += ".ml"

        tree = parse_file(filename)
        m = self.visit(tree)
        self.env.update(m)
        return self.visit(e)

    def valueexport(self, nm):
        return {str(nm): self.env[str(nm)]}

    def typeexport(self, _):
        return {}

    def module(self, *exports):
        acc = {}
        if len(exports) == 0:
            return copy(self.env)
        for e in exports:
            acc.update(self.visit(e))
        return acc

    # ========== EXPRESSIONS
    def nparray(self, elems):
        return np.array(self.visit_children(elems))

    def infix_op(self, a, op, b):
        x, y = self.visit(a), self.visit(b)
        if op == "+": return x + y
        if op == "-": return x - y
        if op in "*°": return x * y
        if op == "/": return x / y

    def do(self, *stmts):
        for s in stmts[:-1]:
            self.visit(s)
        return self.visit(stmts[-1])

    def _tuple(self, elems):
        elems = self.visit_children(elems)[0]
        return {f"_{i}": x for i, x in enumerate(elems)}

    def none(self, _):
        return None

    def python(self, code, e):
        exec(code.strip("%%%"))
        if "__EXPORTS__" in locals():
            self.env.update(locals()["__EXPORTS__"])
        return self.visit(e)

    def inlinepython(self,code):
        res = eval(code.strip("%%%"))
        return res

    def ite(self, c, t, f):
        if self.visit(c):
            return self.visit(t)
        return self.visit(f)

    def let(self, x, e, b):
        self.env[str(x)] = self.visit(e)
        return self.visit(b)

    def letdecl(self, _x, _e, b):
        return self.visit(b)

    def letrec(self, x, e, b):
        def Y(f):
            return (lambda x: f(lambda v: x(x)(v)))(lambda x: f(lambda v: x(x)(v)))

        e0 = self.lam(x, e)

        # old = self.env[str(x)] if str(x) in self.env else ">>NONE<<MAGIC"
        self.env[str(x)] = Y(e0)
        res = self.visit(b)
        # if old != ">>NONE<<MAGIC":
        #     self.env[str(x)] = old
        return res

    def var(self, x):
        if str(x) not in self.env:
            print("ERROR:", x.line)
        return self.env[str(x)]

    def app(self, f, x):
        return self.visit(f)(self.visit(x))

    def lam(self, x, b):
        closure = copy(self.env)
        def inner(v):
            old_env = copy(self.env)
            self.env.update(closure)
            self.env[str(x)] = v
            res = self.visit(b)
            self.env = old_env
            return res

        return inner

    def lamcase(self, lamcases):
        def inner(v):
            return self.match(v, *lamcases.children, match_arg_evaluated=True)

        return inner

    def num(self, x):
        return float(str(x))

    def string(self, s):
        return str(s).strip('"').replace('\\"', '"').replace("\\n", "\n")

    def neg(self, x):
        return -self.visit(x)

    def entry(self, nm, v):
        return (str(nm), self.visit(v))

    def record(self, *entries):
        items = [self.visit(e) for e in entries]
        return dict(items)

    def access(self, e, nm):
        return self.visit(e)[str(nm)]

    def typedecl(self, *args):
        return self.visit(args[-1])

    def typedef(self, *args):
        cs = args[-2]

        env_overwritten = {}
        for c in cs.children:
            cname = str(c.children[0])
            nargs = len(c.children) - 1

            names = [f"x{x}" for x in range(nargs)]
            lambdas = [f"lambda {x}: " for x in names]
            tup = f"('{cname}', {', '.join(names)})"
            constr = "".join(lambdas) + tup

            if cname in self.env:
                env_overwritten[cname] = self.env[cname]
            self.env[cname] = eval(constr)
        res = self.visit(args[-1])
        for k, v in env_overwritten.items():
            self.env[k] = v
        return res

    def typealias(self, *args):
        return self.visit(args[-1])

    # ========== patterns
    match_arg = None

    def match(self, arg, *cs, match_arg_evaluated=False):
        """If match_arg_evaluated, arg will not be evaluated"""
        old_env = dict(list(self.env.items()))
        a = arg if match_arg_evaluated else self.visit(arg)
        self.match_arg = a
        for case in cs:
            c, e = case.children
            res = self.visit(c)
            if res:
                eres = self.visit(e)
                self.env = old_env
                return eres

        self.match_arg = None
        self.env = old_env

    def pvar(self, nm):
        self.env[str(nm)] = self.match_arg
        return True

    def pwildcard(self):
        return True

    def pnum(self, x):
        return True if int(str(x)) == self.match_arg else False

    def pstr(self, s):
        return True if s[1:-1] == self.match_arg else False

    def pconstrname(self, nm):
        return str(nm) == str(self.match_arg[0])

    def papp(self, f, a):
        old_ma = deepcopy(self.match_arg)

        if len(self.match_arg) == 1:
            self.match_arg = self.match_arg[0]
            res = self.visit(f)
            self.match_arg = old_ma
            return res

        # match f
        self.match_arg = self.match_arg[:-1]
        res = self.visit(f)

        # match arg
        if res:
            self.match_arg = old_ma[-1]
            res = self.visit(a)

        self.match_arg = old_ma
        return res
