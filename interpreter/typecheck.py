from copy import copy, deepcopy
from typing import Tuple
from lark import ParseTree, v_args
from lark.visitors import Interpreter
from dataclasses import dataclass as dat
from interpreter.parser import parse_file
from interpreter.path import storage_path
from interpreter.typ import *

DBG = False
if DBG:
    import os

# print all definitions if True
PRINT_LETS = False


@dat
class ModuleData:
    env: Dict[str, Typ]
    type_env: Dict[str, int]
    type_aliases: Dict[str, Typ]

    def __add__(self, m: "ModuleData") -> "ModuleData":
        return ModuleData(
            dict(list(self.env.items()) + list(m.env.items())),
            dict(list(self.type_env.items()) + list(m.type_env.items())),
            dict(list(self.type_aliases.items()) + list(m.type_aliases.items())),
        )

    def get_type_or_kind(self, nm):
        if nm in self.env: return self.env[nm]
        if nm in self.type_env: return self.type_env[nm]
        if nm in self.type_aliases: return self.type_aliases[nm]
    
    def get_all_types_and_kinds(self):
        return dict(
            list(self.env.items()) +
            list(self.type_env.items()) +
            list(self.type_aliases.items()))

    def subst(self, nm: str, t):
        return ModuleData(
            {k: t0.subst(nm, t) for k, t0 in self.env.items()},
            self.type_env,
            self.type_aliases,
        )


def load_module(filename) -> ModuleData:
    """
    Load a file. Raise exception if the file
    does not return a record representing
    its exports.
    """
    _, m = load_file(filename)
    if not isinstance(m, ModuleData):
        raise Exception(f"Cannot load file {filename} as a module that returns:\n{m}")
    return m

BUILTIN_TYPES = {
    "and": t_fn(t_bool, t_fn(t_bool, t_bool)),
    "or": t_fn(t_bool, t_fn(t_bool, t_bool)),
    "add": t_fn(t_num, t_fn(t_num, t_num)),
    "sub": t_fn(t_num, t_fn(t_num, t_num)),
    "mul": t_fn(t_num, t_fn(t_num, t_num)),
    "inc": t_fn(t_num, t_num),
    "dec": t_fn(t_num, t_num),
    "sqrt": t_fn(t_num, t_num),
    "pow": t_fn(t_num, t_fn(t_num, t_num)),
    "True": t_bool,
    "False": t_bool,
    "equal": Scheme.generalize(t_fn(tvar("a"), t_fn(tvar("a"), t_bool))),
    "lt": t_fn(t_num, t_fn(t_num, t_bool)),
    "print": Scheme.generalize(t_fn(tvar("a"), t_unit)),
    "print2": Scheme.generalize(t_fn(tvar("b"), t_fn(tvar("a"), t_unit))),
}

BUILTIN_KINDS = { "Bool": 0, "Number": 0, "Unit": 0, "String": 0 }

def load_file(filename) -> Tuple[ParseTree, Typ]:
    """
    Parse a file and typecheck it.
    Returns result type of the expression in the file
    and the parse tree.
    """

    tree = parse_file(filename)

    # typecheck
    typechecker = Typechecker(
        BUILTIN_TYPES, BUILTIN_KINDS
    )
    try:
        return (tree, solve(typechecker.constraints, typechecker.visit(tree)))
    except Exception as e:
        raise Exception(f"Type error ({filename}):\n"+str(e))


@v_args(True)
class Typechecker(Interpreter):
    def __init__(self, env, tenv):
        self.env = env
        self.type_env = tenv
        self.type_aliases = {}
        self.constraints = []
        self.allow_free_tvars = False
        self.current_typedef_type = None

    def constr(self, a, b, line):
        self.constraints += [(a, b, line)]

    # ===================== module system
    def typeexport(self, tname):
        if str(tname) not in self.type_env:
            raise Exception(f"Cannot export undefined type {tname} (line {tname.line})")
        return ModuleData(
            env={},
            type_env={str(tname): self.type_env[str(tname)]},
            type_aliases=(
                {str(tname): self.type_aliases[str(tname)]}
                if str(tname) in self.type_aliases
                else {}
            ),
        )

    def valueexport(self, name):
        if str(name) not in self.env:
            raise Exception(
                f"Cannot export undefined variable {name} (line {name.line})"
            )
        return ModuleData({str(name): self.env[str(name)]}, {}, {})

    def module(self, *exports):
        if len(exports) == 0:
            m = ModuleData(copy(self.env), copy(self.type_env), copy(self.type_aliases))
            return m
        exports = [self.visit(e) for e in exports]
        return sum(exports, start=ModuleData({}, {}, {}))

    def _import(self, args):
        # get filename
        modulepath = args.children[:-1]
        e = args.children[-1]
        filename = storage_path+("/"if storage_path[-1]!="/" else "")+"/".join(map(str,modulepath))
        filename += ".ml"
        
        m = load_module(filename)
        old_env = copy(self.env)
        old_tenv = copy(self.type_env)
        old_taliases = copy(self.type_aliases)

        self.env.update(m.env)
        self.type_env.update(m.type_env)
        self.type_aliases.update(m.type_aliases)
        res = self.visit(e)

        self.env = old_env
        self.env = old_tenv
        self.env = old_taliases
        return res

    # ===================== expressions
    def nparray(self, elems):
        types = self.visit_children(elems)
        for t in types: self.constr(t, t_num, t.line)
        return Typ("Vec", [], elems.meta.line)

    def infix_op(self, a, op, b):
        at, bt = self.visit(a), self.visit(b)
        # ° can multiply anything together!
        if op != "°":
            self.constr(at, bt, b.meta.line)
        return at

    def do(self, *stmts):
        for s in stmts[:-1]:
            self.visit(s)
        return self.visit(stmts[-1])

    def _tuple(self, elems):
        types = self.visit_children(elems)[0]
        t = TRecord(
            {f"_{i}": t for i, t in enumerate(types)},
            elems.meta.line,
        )
        return t

    def none(self, t):
        return Typ("Unit", [], t.meta.line)

    def python(self, _, e):
        return self.visit(e)

    def inlinepython(self, code):
        t = pytype_to_typ(get_array_element_type(code.strip("%")), code.line)
        return Typ("List", [t], code.line)

    # if-then-else
    def ite(self, c, t, f):
        ct, tt, ft = list(map(self.visit, (c, t, f)))
        self.constr(ct, t_bool, c.meta.line)
        self.constr(tt, ft, f.meta.line)
        return tt

    def letdecl(self, x, t, b):
        self.allow_free_tvars = True
        t = self.visit(t)
        if type(t) == TRecord:
            t.baked = True
        self.env[str(x)] = Scheme.generalize(t)
        self.allow_free_tvars = False

        res = self.visit(b)
        if x in self.env:  # might have been redefined and already deleted
            del self.env[str(x)]
        return res

    def let(self, x, e, b):
        # assignment
        if str(x) == "_":
            t = self.visit(e)
            solve(self.constraints, t)
            return self.visit(b)
        t = self.visit(e)
        t = solve(self.constraints, t)
        if type(t) == TRecord:
            t.baked = True

        if x in self.env:
            self.constr(self.env[x].inst(), t, x.line)
        else:
            self.env[x] = Scheme.generalize(t)
        if PRINT_LETS:
            print(x, "=", self.env[x])

        # body
        tb = self.visit(b)
        if x in self.env:  # might have been redefined and already deleted
            del self.env[x]
        return tb

    def letrec(self, x, e, b):
        # automatically apply fix
        fix_t = Scheme.generalize(t_fn(t_fn(tvar("a"), tvar("a")), tvar("a"))).inst()
        tvres = newtv(x.line)

        # simulate a lambda
        xtv = newtv(x.line)
        self.env[x] = xtv
        te = self.visit(e)

        # simulate applying fix to \x -> e
        self.constr(
            fix_t, Typ("->", [Typ("->", [xtv, te], x.line), tvres], x.line), x.line
        )

        t = solve(self.constraints, tvres)
        self.env[x] = Scheme.generalize(t)
        if PRINT_LETS:
            print(x, "=", self.env[x])
        tb = self.visit(b)
        del self.env[x]
        return tb

    def var(self, x):
        if x not in self.env:
            raise Exception(f"Variable {x} not defined (line {x.line})")
        return self.env[x].inst()

    def app(self, f, x):
        tv0 = newtv(f.meta.line)
        tvres = newtv(f.meta.line)
        self.constr(tv0, self.visit(f), f.meta.line)
        self.constr(tv0, Typ("->", [self.visit(x), tvres], f.meta.line), f.meta.line)
        return tvres

    def lam(self, x, b):
        tv = newtv(x.line)
        self.env[x] = tv
        t = self.visit(b)
        del self.env[x]
        return Typ("->", [tv, t], x.line)

    def lamcase(self, lamcases):

        argtv = newtv(lamcases.meta.line)
        cases = lamcases.children

        mt = self.match(argtv, *cases)
        
        return Typ("->", [argtv, mt], lamcases.meta.line)

    def num(self, x):
        return Typ("Number", [], x.line)

    def neg(self, x):
        t = self.visit(x)
        self.constr(t, Typ("Number", [], x.meta.line), x.meta.line)
        return t

    def string(self, s):
        return Typ("String", [], s.line)

    def entry(self, nm, v):
        return (str(nm), self.visit(v))

    def record(self, *entries):
        ts = [self.visit(e) for e in entries]
        return TRecord(dict(ts), entries[0].meta.line)

    def access(self, e, nm):
        tv = newtv(e.meta.line)
        self.constr(
            TRecord({str(nm): tv}, e.meta.line, access_check=True),
            self.visit(e),
            nm.line,
        )
        return tv

    # ===================== patterns
    def match(self, arg, *cs):
        oldenv = dict(self.env)

        argt = arg
        if type(arg) not in [TVar, Typ, TRecord]:
            argt = self.visit(arg)

        restype = newtv(argt.line)

        for case in cs:
            p, e = case.children

            # infer pattern
            pt = self.visit(p)
            self.constr(argt, pt, p.meta.line)

            # infer result
            et = self.visit(e)
            self.constr(restype, et, e.meta.line)

        self.env = oldenv

        return restype

    def pvar(self, nm):
        tv = newtv(nm.line)
        self.env[str(nm)] = tv
        return tv

    def pwildcard(self):
        return newtv(-123)

    def pnum(self, x):
        return Typ("Number", [], x.line)
    
    def pstr(self, x):
        return Typ("String", [], x.line)


    def pconstrname(self, nm):
        if str(nm) not in self.env:
            raise Exception(f"Constructor {nm} not defined. (line {nm.line})")
        t = self.env[str(nm)].inst()
        return t

    def papp(self, f, a):
        at = self.visit(a)
        ft = self.visit(f)
        tres = newtv(f.meta.line)
        self.constr(ft, Typ("->", [at, tres], f.meta.line), f.meta.line)

        return tres

    # ===================== types
    def ttuple(self, elems):
        types = self.visit_children(elems)
        return TRecord(
            {f"_{i}": t for i, t in enumerate(types)},
            elems.meta.line,
            baked=True
        )

    def tvar(self, x):
        if not (self.allow_free_tvars or str(x) in self.type_env):
            raise Exception(f"Unknown type variable {x} (line {x.line})")
        return TVar(str(x), x.line)

    def ttyp(self, name, params=None):
        if params == None:
            params = []
        elif len(params.children) == 1:
            params = [self.visit(params)]
        else:
            params = self.visit_children(params)

        # alias
        if str(name) in self.type_aliases:
            if self.type_env[str(name)] != len(params):
                raise Exception(
                    f"Type alias {name} takes {self.type_env[name]} "
                    + f"parameters, {len(params)} given (line {name.line})"
                )
            t: Typ = self.type_aliases[str(name)]
            substs = zip(t.free_tvars(), params)
            for a,b in substs:
                t = t.subst(a,b)
            return t

        # type
        if str(name) in self.type_env:
            if self.type_env[str(name)] != len(params):
                raise Exception(
                    f"Type {name} takes {self.type_env[name]} "
                    + f"parameters, {len(params)} given (line {name.line})"
                )
            return Typ(
                str(name),
                params,
                name.line,
            )

        # not found
        raise Exception(f"Type {name} not defined (line {name.line})")

    def constructor(self, name, *params):
        params = [*map(self.visit, params)]
        t = self.current_typedef_type
        for param in reversed(params):
            t = Typ("->", [param, t], name.line)
        return (name, t)

    def tfun(self, a, b):
        return Typ("->", [self.visit(a), self.visit(b)], a.meta.line)

    def typedecl(self, *args):
        name = args[0]
        params = args[1:-1]
        body = args[-1]
        self.type_env[str(name)] = len(params)
        return self.visit(body)

    def typealias(self, *args):
        name = args[0]
        params = args[1:-2]
        t = args[-2]

        # add params to
        self.type_env[str(name)] = len(params)
        for p in params:
            self.type_env[str(p)] = 0

        t = self.visit(t)
        self.type_aliases[str(name)] = t

        # cleanup
        for p in params:
            del self.type_env[str(p)]

        res = self.visit(args[-1])
        del self.type_env[str(name)]
        del self.type_aliases[str(name)]
        return res

    def typedef(self, *args):
        name = args[0]
        params = args[1:-2]
        constructors = args[-2]
        body = args[-1]

        # get types of constructor functions
        self.type_env[str(name)] = len(params)
        for p in params:
            self.type_env[str(p)] = 0

        self.current_typedef_type = Typ(
            name, [TVar(str(p), p.line) for p in params], name.line
        )
        types = self.visit_children(constructors)
        # quirk with visit_children: returns just the child if
        # the tree has only one child
        if type(types[0]) != tuple:
            types = [types]
        self.current_typedef_type = None

        for p in params:
            del self.type_env[str(p)]

        # add them to the environment
        for nm, t in types:
            self.env[str(nm)] = Scheme.generalize(t)

        # infer body type
        tb = self.visit(body)

        # cleanup
        del self.type_env[name]
        for nm, _ in types:
            del self.env[nm]

        return tb

    def tentry(self, nm, t):
        return (str(nm), self.visit(t))

    def trecord(self, *entries):
        entries = [self.visit(e) for e in entries]
        return TRecord(dict(entries), entries[0][1].line)


def solve(constraints, t):
    cs = deepcopy(constraints)
    grave = []  # all constraints that were not able to be used
    # will be kept around as they could be terminal constraints
    # (a terminal constraint is for example: t1 = Int for the type t1)

    while len(cs) > 1 or (len(cs) == 1 and not isinstance(cs[0][0], TVar)):
        if DBG:
            os.system("clear")
            for a, b, l in cs:
                print(a, "=", b, f"(line {l})")
            input()

        a, b, line = cs.pop(0)

        # maybe wrong?
        if not isinstance(t, ModuleData):
            t = t.subst(a, b)

        # [Experimental]
        # when unifying for example t3 = {y: ...} and t3 = {x: ....}
        # return t3 = {x: ..., y: ...}
        if isinstance(a, TVar) and isinstance(b, TRecord) and b.access_check:
            newcs = []

            if not any((x.occurs(a.name) or y.occurs(a.name)) for x, y, _ in cs):
                grave.append((a, b))

            for x, y, l in cs:
                if (
                    isinstance(x, TVar)
                    and isinstance(y, TRecord)
                    and y.access_check
                    and str(x) == str(a)
                ):
                    newcs += b.unify(y, l)
                    entries = copy(b.entries)
                    entries.update(y.entries)
                    b.entries = entries
                    newcs += [(a, TRecord(entries, l, True), line)]
                else:
                    newcs += [(x.subst(a.name, b), y.subst(a.name, b), l)]
            cs = newcs

        #
        elif isinstance(a, TVar):
            # if this constraint is not used further
            if not any((x.occurs(a.name) or y.occurs(a.name)) for x, y, _ in cs):
                grave.append((a, b))
            cs = [(x.subst(a.name, b), y.subst(a.name, b), l) for x, y, l in cs]

        else:  # Typ
            cs = a.unify(b, line) + cs

    # apply remaining constraints
    if len(cs) == 1:
        t = t.subst(cs[0][0].name, cs[0][1])
    for a, b in grave:
        t = t.subst(a.name, b)

    return t

