from copy import copy, deepcopy
from dataclasses import dataclass
import sys
from typing import List

import numpy as np
from lark import v_args
from lark.visitors import Interpreter

from interpreter.parser import parse_file
from interpreter.path import storage_path


@dataclass
class Lambda:
    eval: "Evaluator"
    params: List[str]  # len > 1
    body: object
    closure: dict
    body_evaluated: bool = False

    def apply(self, arg):
        if len(self.params) <= 1:
            old_env = copy(self.eval.env)
            self.eval.env.update(self.closure)
            param = str(self.params[0])
            if param != "_":
                self.eval.env[param] = arg
            res = self.body if self.body_evaluated else self.eval.visit(self.body)
            self.eval.env = old_env
            return res

        env = dict(list(self.closure.items()) + [(self.params[0], arg)])
        return Lambda(self.eval, self.params[1:], self.body, env, self.body_evaluated)

    def __call__(self, *args):
        return self.apply(*args)


@v_args(inline=True)
class Evaluator(Interpreter):
    def __init__(self, env):
        self.env = env
        self.toplevel = False  # is the current node a toplevel node?

    # ========== MODULE SYSTEM
    def _import(self, args):
        modulepath = args.children[:-1]
        e = args.children[-1]
        filename = (
            storage_path
            + ("/" if storage_path[-1] != "/" else "")
            + "/".join(map(str, modulepath))
        )
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
    def list(self, elems):
        xs = self.visit_children(elems)
        l = ("Nil",)
        for x in reversed(xs):
            l = ("Cons", x, l)
        return l

    def nparray(self, elems):
        return np.array(self.visit_children(elems))

    def infix_op(self, a, op, b):
        x, y = self.visit(a), self.visit(b)
        if op == "+":
            return x + y
        if op == "-":
            return x - y
        if op in "*°":
            return x * y
        if op == "/":
            return x / y
        if op == "==":
            return x == y
        if op == "!=":
            return x != y
        if op == "<":
            return x < y
        if op == "<=":
            return x <= y
        if op == ">":
            return x > y
        if op == ">=":
            return x >= y
        if op == "||":
            return x or y
        if op == "&&":
            return x and y

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

    def inlinepython(self, code):
        res = eval(code.strip("%%%"))
        return res

    def ite(self, c, *cases):
        if self.visit(c):
            return self.visit(cases[0])
        return self.visit(cases[1]) if len(cases) != 1 else None

    def let(self, *args):
        x = args[0]
        params = args[1:-2]
        e, b = args[-2], args[-1]

        if len(params) == 0:
            self.env[str(x)] = self.visit(e)
        else:
            self.env[str(x)] = Lambda(self, params, e, copy(self.env))

        return self.visit(b)

    def letdecl(self, _x, _e, b):
        return self.visit(b)

    def letrec(self, *args):
        x = args[0]
        params = args[1:-2]
        e, b = args[-2], args[-1]

        def Y(f):
            return (lambda x: f(lambda v: x(x)(v)))(lambda x: f(lambda v: x(x)(v)))

        e0 = Lambda(self, [x] + [*params], e, copy(self.env))

        self.env[str(x)] = Y(e0)

        res = self.visit(b)

        return res

    def var(self, x):
        if str(x) not in self.env:
            print("ERROR:", x.line)
        return self.env[str(x)]

    def app(self, f, x):
        return self.visit(f)(self.visit(x))

    def lam(self, *args, body_evaluated=False):
        xs = args[:-1]
        b = args[-1]
        return Lambda(self, xs, b, copy(self.env), body_evaluated)

    def lamcase(self, lamcases):
        closure = copy(self.env)

        def inner(v):
            old_env = copy(self.env)
            self.env.update(closure)
            res = self.match(v, *lamcases.children, match_arg_evaluated=True)
            self.env = old_env
            return res

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
        old_ma = self.match_arg  # might need copy()!

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
