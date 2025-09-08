from copy import copy, deepcopy
import time
from typing import Tuple
from interpreter.cache import Cache
from lark import ParseError, ParseTree, Token, Tree, v_args
from lark.visitors import Interpreter
from dataclasses import dataclass as dat
from interpreter.parser import parse_file
from interpreter.path import storage_path
import interpreter.path as path
from interpreter.typ import *
import os

from utils import SHOW_CACHE_USES, SHOW_COMPILE_TIME

DBG = False

CACHING = True

# print all definitions if True
PRINT_LETS = False


# enum: which namespace is a name from (is it a typealias, type, value etc.)
class NamespaceType:
    TYPE = 0
    TYPE_ALIAS = 1
    VALUE = 2
    MODULE = 3


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
        if nm in self.env:
            return self.env[nm]
        if nm in self.type_env:
            return self.type_env[nm]
        if nm in self.type_aliases:
            return self.type_aliases[nm]

    def get_type_or_kind_in_namespace(self, nm, ns):
        """
        Get type or kind of a name in a specific namespace.
        If the name is not found in the namespace, return None.
        namespace `MODULE` not supported, returns None.
        """
        e = None
        match ns:
            case NamespaceType.TYPE:
                e = self.type_env
            case NamespaceType.TYPE_ALIAS:
                e = self.type_aliases
            case NamespaceType.VALUE:
                e = self.env
            case NamespaceType.MODULE:
                return None
        if e is not None and nm in e:
            return e[nm]
        return None

    def get_type_or_kind_with_namespace(self, nm, line) -> Tuple[object, NamespaceType]:
        """
        Try to find a name.
        WARNING: If not found return None.
        """
        if nm in self.env:
            return self.env[nm], NamespaceType.VALUE
        if nm in self.type_aliases:
            return (self.type_aliases[nm], self.type_env[nm]), NamespaceType.TYPE_ALIAS
        if nm in self.type_env:
            return self.type_env[nm], NamespaceType.TYPE
        return None

    def get_all_types_and_kinds(self):
        return dict(
            list(self.env.items())
            + list(self.type_env.items())
            + list(self.type_aliases.items())
        )

    def subst(self, nm: str, t):
        return ModuleData(
            {k: t0.subst(nm, t) for k, t0 in self.env.items()},
            self.type_env,
            self.type_aliases,
        )


# store filename, types & file hash
global_module_cache: Cache[Tuple[ModuleData, ParseTree]] = Cache()


BUILTIN_TYPES = {
    "and": t_fn(t_bool, t_fn(t_bool, t_bool)),
    "or": t_fn(t_bool, t_fn(t_bool, t_bool)),
    "not": t_fn(t_bool, t_bool),
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
    "printa": Scheme.generalize(
        t_fn(
            TRecord({f"_{n}": tvar(f"a{n}") for n in range(10)}, -1, baked=True), t_unit
        )
    ),
    "print_raw": Scheme.generalize(t_fn(tvar("a"), t_unit))
}

BUILTIN_KINDS = {"Bool": 0, "Number": 0, "Unit": 0, "String": 0, "Vec": 0, "Num": 0}

BUILTIN_TALIASES = {"Num": t_num}


def load_file(filename, logger=print) -> Tuple[ParseTree, ModuleData]:
    """
    Parse a file and typecheck it.
    Returns result type of the expression in the file
    and the parse tree.
    """

    filename = path.abspath(filename).replace("//", "/")
    
    if not os.path.isfile(filename):
        raise ParseError(f"Module ({filename}) not found!")

    with open(filename) as f:
        txt = f.read()

    # check if cached
    if global_module_cache.cached(filename):
        if SHOW_CACHE_USES:
            print("----> used type cache", filename)
        if SHOW_COMPILE_TIME:
            logger(f"[CACHED] ({filename})\t", 0)
        return (
            global_module_cache.get(filename)[1],
            global_module_cache.get(filename)[0],
        )

    t1 = time.time()
    tree = parse_file(filename, txt)
    t2 = time.time()
    if SHOW_COMPILE_TIME:
        logger(f"[PARSING] ({filename})\t", round(t2 - t1, 4))

    # typecheck
    typechecker = Typechecker(
        copy(BUILTIN_TYPES), copy(BUILTIN_KINDS), copy(BUILTIN_TALIASES), logger
    )

    try:
        t1 = time.time()
        m = solve(typechecker.constraints, typechecker.visit(tree))
        t2 = time.time()

        if not isinstance(m, ModuleData):
            m = ModuleData(
                copy(typechecker.env),
                copy(typechecker.type_env),
                copy(typechecker.type_aliases),
            )

        global_module_cache.cache(filename, (m, tree))
        if SHOW_COMPILE_TIME:
            logger(f"[TYPED] ({filename})\t", round(t2 - t1, 4))

        return (tree, m)
    except ParseError as e:
        raise ParseError(f"Parse error ({filename}):\n" + str(e))
    except PMLTypeError as e:
        raise PMLTypeError(f"Type error ({filename}):\n" + str(e))


@v_args(True)
class Typechecker(Interpreter):
    def __init__(self, env, tenv, taliases={}, logger=print):
        self.env = env
        self.type_env = tenv
        self.type_aliases = taliases
        self.imported_modules = {}
        self.constraints = []
        self.allow_free_tvars = False
        self.current_typedef_type = None
        self.logger = logger

    def constr(self, a, b, line):
        self.constraints += [(a, b, line)]

    # ===================== module system
    def typeexport(self, tname):
        if str(tname) not in self.type_env:
            raise PMLTypeError(
                f"Cannot export undefined type {tname} (line {tname.line})"
            )
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
            raise PMLTypeError(
                f"Cannot export undefined variable {name} (line {name.line})"
            )
        return ModuleData({str(name): self.env[str(name)]}, {}, {})

    def module(self, *exports):
        if len(exports) == 0:
            m = ModuleData(copy(self.env), copy(self.type_env), copy(self.type_aliases))
            return m
        exports = [self.visit(e) for e in exports]
        return sum(exports, start=ModuleData({}, {}, {}))

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
        """
        Returns the different parts of an import tree.
        Returns a tuple of (modulepath, import_list, alias).
        - modulepath: a list of strings representing the path to the module.
        - import_list: a list of strings representing the items to import.
        - alias: a string representing the alias of the module, or None if not given.
        """

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
        modulepath, import_list, alias = self.parse_import(args)

        e = args.children[-1]
        line = e.meta.line if hasattr(e, "meta") else e.line

        filename = (
            storage_path
            + ("/" if storage_path[-1] != "/" else "")
            + "/".join(map(str, modulepath))
        )
        filename += ".ml"

        m = load_file(filename, logger=self.logger)[1]
        old_env = copy(self.env)
        old_tenv = copy(self.type_env)
        old_taliases = copy(self.type_aliases)

        # add imported module to the environment
        if import_list is None and alias is None:
            self.env.update(m.env)
            self.type_env.update(m.type_env)
            self.type_aliases.update(m.type_aliases)
        elif import_list is not None:
            for item in import_list:
                if isinstance(item, str):
                    # type import
                    if item.startswith("type "):
                        item = item.removeprefix("type ")
                        if item not in m.type_env:
                            raise PMLTypeError(
                                f"Type {item} not found in module {filename} (line {line})"
                            )
                        self.type_env[item] = m.type_env[item]
                        if item in m.type_aliases:
                            self.type_aliases[item] = m.type_aliases[item]
                    else:
                        # value import
                        if item not in m.env:
                            raise PMLTypeError(
                                f"Variable {item} not found in module {filename} (line {line})"
                            )
                        self.env[item] = m.env[item]

        if alias is not None:
            # if alias is given, add the module as a single item
            self.imported_modules[alias] = ModuleData(m.env, m.type_env, m.type_aliases)

        res = self.visit(e)

        # restore old envs
        self.env = old_env
        self.type_env = old_tenv
        self.type_aliases = old_taliases
        if alias is not None:
            if alias in self.imported_modules:
                del self.imported_modules[alias]

        return res

    def to_module(self):
        """
        Return self as a ModuleData object.
        """
        return ModuleData(self.env, self.type_env, self.type_aliases)

    def resolve_name(
        self, name: str, line: int, namespace=None
    ) -> Tuple[object, NamespaceType] | object:
        """
        Find a name in the current environment or imported modules.
        name can be regular name or a dotted name (e.g. "math.sin").
        If namespace is given, look for it in a specific namespace and
        return the type or kind of the name (object).
        """
        # name from a module? (e.g "math.sin")
        if "." in name:
            # use get_type_or_kind_with_namespace to get the type or kind
            module_name, item_name = name.split(".", 1)
            if module_name in self.imported_modules:
                module: ModuleData = self.imported_modules[module_name]
                if namespace is not None:
                    res = module.get_type_or_kind_in_namespace(item_name, namespace)
                else:
                    res = module.get_type_or_kind_with_namespace(item_name, line)
                if res is None:
                    raise PMLTypeError(
                        f"Name {item_name} not found in module {module_name} (line {line})"
                    )
                return res
            else:
                raise PMLTypeError(f"Module {module_name} not found (line {line})")

        # name from the current module
        # if namespace is given, look for it in a specific namespace
        if namespace is not None:
            res = self.to_module().get_type_or_kind_in_namespace(name, namespace)
            if res is None:
                raise PMLTypeError(f"Name {name} not found in namespace (line {line})")
            return res

        # if namespace is not given, look for it in the current environment
        if name in self.env:
            return self.env[name].inst(), NamespaceType.VALUE
        if name in self.type_aliases:
            return (
                self.type_aliases[name],
                self.type_env[name],
            ), NamespaceType.TYPE_ALIAS
        if name in self.type_env:
            return self.type_env[name], NamespaceType.TYPE

        # not found
        raise PMLTypeError(f"Name {name} not found (line {line})")

    # ===================== expressions
    def list(self, elems):
        line = elems.meta.line if hasattr(elems, "line") else -1
        prev = newtv(line)
        for e in elems.children:
            t = self.visit(e)
            self.constr(prev, t, e.meta.line)
            prev = t
        return Typ("List", [prev], line)

    def nparray(self, elems):
        types = self.visit_children(elems)
        for t in types:
            self.constr(t, t_num, t.line)
        return Typ("Vec", [], elems.meta.line)

    def infix_op(self, a, op, b):
        at, bt = self.visit(a), self.visit(b)
        if op in ["||", "&&"]:
            self.constr(at, t_bool, a.meta.line)
            self.constr(bt, t_bool, b.meta.line)
            return Typ("Bool", [], a.meta.line)
        elif op in ["<", ">", ">=", "<="]:
            self.constr(at, t_num, a.meta.line)
            self.constr(bt, t_num, b.meta.line)
            return Typ("Bool", [], a.meta.line)
        elif op in ["==", "!="]:
            self.constr(at, bt, b.meta.line)
            return Typ("Bool", [], a.meta.line)
        elif op == "$":
            ret_t = newtv(a.meta.line)
            self.constr(at, Typ("->", [bt, ret_t], a.meta.line), a.meta.line)
            return ret_t
        elif op in ["<<", ">>"]:  # compose
            # (<<) : (y -> z) -> (x -> y) -> (x -> z)
            # (>>) : (x -> y) -> (y -> z) -> (x -> z)
            x = newtv(a.meta.line)
            y = newtv(a.meta.line)
            z = newtv(b.meta.line)
            self.constr(
                bt if op == "<<" else at, Typ("->", [x, y], a.meta.line), a.meta.line
            )
            self.constr(
                at if op == "<<" else bt, Typ("->", [y, z], b.meta.line), b.meta.line
            )
            return Typ("->", [x, z], a.meta.line)

        # ° can multiply anything together!
        elif op != "°":
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
    def ite(self, c, *cases):
        # else omitted -> must be Unit
        if len(cases) == 1:
            ct, tt = list(map(self.visit, (c, cases[0])))
            self.constr(ct, t_bool, c.meta.line)
            self.constr(tt, t_unit, cases[0].meta.line)
            return Typ("Unit", [], c.meta.line)

        t, f = cases
        ct, tt, ft = list(map(self.visit, (c, t, f)))
        self.constr(ct, t_bool, c.meta.line)
        self.constr(tt, ft, f.meta.line)
        return tt

    def letdecl(self, x, t, b):
        old_env = self.env
        self.allow_free_tvars = True
        t = self.visit(t)
        if type(t) == TRecord:
            t.baked = True
        self.env[str(x)] = Scheme.generalize(t)
        self.allow_free_tvars = False

        res = self.visit(b)
        self.env = old_env
        return res

    # regular let
    def let(self, *args):

        x = args[0]
        params = args[1:-2] # pattern params
        e, b = args[-2], args[-1]
        old_env = copy(self.env)

        # visit args
        tvs = [*map(self.visit, params)]

        # build type of `e`
        t = self.visit(e)
        for tv, a in reversed(list(zip(tvs, params))):
            t = Typ("->", [tv, t], a.meta.line)
        t = solve(self.constraints, t)
        
        # self.constraints = [] # TODO: find out if this is allowed or if it breaks something

        # assignment
        if str(x) == "_":
            return self.visit(b)

        if type(t) == TRecord:
            t.baked = True

        self.env = copy(old_env)
        
        if x in self.env:
            self.constr(self.env[x].inst(), t, x.line)
        else:
            self.env[x] = Scheme.generalize(t)
        if PRINT_LETS:
            print(x, "=", self.env[x])

        # body
        tb = self.visit(b)

        self.env = old_env

        return tb

    def letrec(self, *args):
        x = args[0]
        params = args[1:-2]
        e, b = args[-2], args[-1]
        old_env = copy(self.env)

        # automatically apply fix
        fix_t = Scheme.generalize(t_fn(t_fn(tvar("a"), tvar("a")), tvar("a"))).inst()
        tvres = newtv(x.line)

        # simulate a lambda
        xtv = newtv(x.line)
        self.env[x] = xtv
        te = self.lam(*params, e)

        # simulate applying fix to \x -> e
        self.constr(
            fix_t, Typ("->", [Typ("->", [xtv, te], x.line), tvres], x.line), x.line
        )

        t = solve(self.constraints, tvres)

        self.env = copy(old_env)

        self.env[x] = Scheme.generalize(t)
        if PRINT_LETS:
            print(x, "=", self.env[x])

        # body
        tb = self.visit(b)

        self.env = old_env

        return tb

    def var(self, x):
        """
        x is always toplevel name.
        `access` prevents `var` from executing on a module name.
        """

        # get name using find_name_with_namespace
        name = str(x)
        res, ns = self.resolve_name(name, x.line)

        if ns != NamespaceType.VALUE:
            # if it is not a value, raise an error
            raise PMLTypeError(f"Name {name} is not a value (line {x.line})")

        return res.inst()

    def app(self, f, x):
        tv0 = newtv(f.meta.line)
        tvres = newtv(f.meta.line)
        self.constr(tv0, self.visit(f), f.meta.line)
        self.constr(tv0, Typ("->", [self.visit(x), tvres], f.meta.line), f.meta.line)
        return tvres

    def lam(self, *args):

        xs = args[:-1] # pattern params
        b = args[-1]

        # visit args
        tvs = []
        old_env = copy(self.env)
        tvs = [*map(self.visit, xs)]

        # visit body
        t = self.visit(b)

        # revert to old env
        self.env = old_env

        # built lambda type
        res = t

        for tv, x in reversed(list(zip(tvs, xs))):
            res = Typ("->", [tv, res], x.meta.line)

        return res

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
        ename = str(e.children[0])
        # if e is a modules name (e.g. str(e) in self.imported_modules):
        if ename in self.imported_modules:
            # find using find_name_with_namespace
            res, ns = self.resolve_name(ename + "." + str(nm), e.meta.line)
            if ns != NamespaceType.VALUE:
                raise PMLTypeError(
                    f"Name {nm} is not a value, but a type. (line {nm.line})"
                )
            return res.inst()

        #
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

    def pentry(self, nm, p):
        return (str(nm), self.visit(p))

    def precordvar(self, nm):
        tv = newtv(nm.line)
        self.env[str(nm)] = tv
        return (str(nm), tv)

    def precord(self, *entries):
        ts = [self.visit(e) for e in entries]
        return TRecord(dict(ts), entries[0].meta.line, baked=True)

    def ptuple(self, elems):
        types = self.visit_children(elems)
        t = TRecord(
            {f"_{i}": t for i, t in enumerate(types)},
            elems.meta.line,
        )
        return t

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

    def pconstrname(self, *args):
        # pconstrname: (NAME ".")? UPPERNAME
        name = None
        if len(args) == 1:
            name = args[0]
        else:
            # concatenate the name parts
            name = ".".join(str(a) for a in args)

        # find name using find_name_with_namespace
        line = args[0].line if len(args) > 0 else -1
        res, ns = self.resolve_name(name, line)
        if ns != NamespaceType.VALUE:
            # if it is not a value, raise an error
            raise PMLTypeError(f"Name {name} is not a value, but a type. (line {line})")

        # if it is a value, return its type
        return res.inst()

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
            {f"_{i}": t for i, t in enumerate(types)}, elems.meta.line, baked=True
        )

    def tvar(self, x):
        if not (self.allow_free_tvars or str(x) in self.type_env):
            raise PMLTypeError(f"Unknown type variable {x} (line {x.line})")
        return TVar(str(x), x.line)

    def tunit(self):
        return Typ("Unit", [], -1)

    def typename(self, *args):
        if len(args) == 1:
            name = args[0]
        else:
            # concatenate the name parts
            name = ".".join(str(a) for a in args)
        return name

    def ttyp(self, nm, *params):
        params = [self.visit(p) for p in params]
        name = self.visit(nm)
        line = nm.line if hasattr(nm, "line") else nm.meta.line

        # try to find name using find_name_with_namespace
        try:
            res = self.resolve_name(str(name), line, NamespaceType.TYPE_ALIAS)
            ns = NamespaceType.TYPE_ALIAS
        except PMLTypeError:
            try:
                res = self.resolve_name(str(name), line, NamespaceType.TYPE)
                ns = NamespaceType.TYPE
            except PMLTypeError:
                # if not found, raise an error
                raise PMLTypeError(f"Type {name} not found (line {line})")

        # alias
        if ns == NamespaceType.TYPE_ALIAS:
            n_params = self.to_module().get_type_or_kind_in_namespace(
                name, NamespaceType.TYPE
            )
            if n_params != len(params):
                raise PMLTypeError(
                    f"Type alias {name} takes {n_params} "
                    + f"parameters, {len(params)} given (line {line})"
                )
            substs = zip(res.free_tvars(), params)
            for a, b in substs:
                res = res.subst(a, b)
            return res

        # type
        if ns == NamespaceType.TYPE:
            n_params = res[1] if type(res) == tuple else res
            if n_params != len(params):
                raise PMLTypeError(
                    f"Type {name} takes {n_params} "
                    + f"parameters, {len(params)} given (line {line})"
                )
            return Typ(
                str(name),
                params,
                line,
            )

        # not possible
        raise Exception("This should not happen: type or type alias not found. (ttyp)")

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

        if str(name) in self.type_aliases:
            del self.type_aliases[str(name)]
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

        if not isinstance(t, ModuleData):
            t = t.subst(a, b)

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
