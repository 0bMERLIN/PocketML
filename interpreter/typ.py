import ast
from copy import copy, deepcopy
from dataclasses import dataclass as dat
from types import NoneType
from typing import Dict, List

class PMLTypeError(Exception):
    pass

@dat
class Typ:
    name: str
    params: list
    line: int
    parens: bool = False

    def map(self, f):
        params = [p.map(f) for p in self.params]
        return f(Typ(self.name, params, self.line))

    def __str__(self):
        res = ""

        if self.name == "->":
            if hasattr(self.params[0], "parens"):
                self.params[0].parens = True
            res = str(self.params[0]) + " -> " + str(self.params[1])
        elif self.params == []:
            return self.name
        else:
            res = self.name + " " + " ".join(list(map(str, self.params)))

        return f"({res})" if self.parens else res

    def __repr__(self):
        return str(self)

    def occurs(self, nm):
        return any(map(lambda p: p.occurs(nm), self.params))

    def free_tvars(self, tvs=[]):
        return sum(list(map(lambda t: t.free_tvars(tvs), self.params)), start=[])

    def inst(self):
        return self

    def subst(self, nm, t):
        return Typ(self.name, [p.subst(nm, t) for p in self.params], self.line)

    def unify(self, t, line):
        if isinstance(t, TVar):
            return t.unify(self, line)
        if isinstance(t, TRecord):
            raise PMLTypeError(
                f"Cannot unify non-record type {self} with record {t} (line {line})"
            )

        nm1 = self.name.split(".")[-1]
        nm2 = t.name.split(".")[-1]
        if nm1 != nm2:
            fn_warn = ""
            if nm2 == "->" or nm1 == "->":
                fn_warn = "\n(Probably applied non-function as a function or passed too many arguments!)"
            raise PMLTypeError(
                f"Cannot unify ({self.name}) with ({t.name}) (line {line})" + fn_warn
            )
        return sum([a.unify(b, line) for a, b in zip(self.params, t.params)], start=[])


def t_fn(x, y):
    return Typ("->", [x, y], -1)


t_num = Typ("Number", [], -1)
t_bool = Typ("Bool", [], -1)
tvar = lambda a: TVar(a, -1)
t_unit = Typ("Unit", [], -1)


@dat
class TVar:
    name: str
    line: int

    def map(self, f):
        return f(self)

    def __str__(self):
        return self.name

    def __repr__(self):
        return str(self)

    def inst(self):
        return self

    def free_tvars(self, tvs=[]):
        if self.name not in tvs:
            return [self.name]
        return []

    def subst(self, nm: str, t):
        res = t if str(self.name) == str(nm) else self
        return res

    def unify(self, t, line):
        if not isinstance(t, TVar) and t.occurs(self.name):
            raise PMLTypeError(f"Occurs check failed: {self} = {t} (line {line})")
        return [(self, t, line)]

    def occurs(self, nm):
        return self.name == nm


@dat
class TRecord:
    entries: Dict[str, Typ | TVar]
    line: int

    access_check: bool = False
    "If true, no exception will be raised if keys don't match."
    baked: bool = False

    def map(self, f):
        entries = {k: t.map(f) for k, t in self.entries.items()}
        return f(TRecord(entries, self.line, self.access_check, self.baked))

    def is_tuple(self):
        return all(
            [
                (nm.startswith("_") and len(nm) > 1 and nm[1:].isnumeric())
                for nm in self.entries
            ]
        )

    def __str__(self):
        if self.is_tuple():
            return str(tuple(self.entries.values()))

        vals = [nm + " : " + str(t) for nm, t in self.entries.items()]
        return "{" + ", ".join(vals) + "}" + ("[ACCESS]" if self.access_check else "")

    def __repr__(self):
        return str(self)

    def inst(self):
        return self

    def free_tvars(self, tvs=[]):
        return sum(
            list(map(lambda t: t.free_tvars(tvs), self.entries.values())), start=[]
        )

    def subst(self, nm: str, t):
        return TRecord(
            {k: v.subst(nm, t) for k, v in self.entries.items()},
            self.line,
            self.access_check,
            self.baked,
        )

    def unify(self, t, line):
        if isinstance(t, Typ):
            t.unify(self, line)  # raises exception
            raise Exception("what.")  # should not happen.
        if isinstance(t, TVar):
            return t.unify(self, line)
        if isinstance(t, TRecord):
            if not self.access_check or self.baked or t.baked:
                self_issubset = set(t.entries.keys()).issubset(self.entries.keys())
                t_issubset = set(self.entries.keys()).issubset(t.entries.keys())
                if not (self_issubset or t_issubset):
                    raise PMLTypeError(
                        f"Cannot unify record {t} with "
                        + f"record {self} (line {line})\n"
                        + "Probably access to a key that is not in the record."
                    )

            common_keys = self.entries.keys() & t.entries.keys()

            return sum(
                [self.entries[k].unify(t.entries[k], line) for k in common_keys],
                start=[],
            )

    def occurs(self, nm):
        return any(map(lambda t: t.occurs(nm), self.entries.values()))


@dat
class Scheme:
    tvars: List[str]
    typ: Typ
    line: int

    def subst(self, nm: str, t: Typ):
        "This method is only to be used by ModuleData.subst!"
        return Scheme(self.tvars, self.typ.subst(nm, t), self.line)

    def inst(self):
        subst = []
        for tv in self.tvars:
            subst += [(tv, newtv(self.line))]
        t = self.typ
        for s in subst:
            t = t.subst(*s)
        return t

    def free_tvars(self):
        return self.typ.free_tvars(self.tvars)

    def generalize(t: Typ | TVar):
        def disable_access_check(t):
            if isinstance(t, TRecord):
                return TRecord(t.entries, t.line, False, t.baked)
            return t

        s = Scheme(list(set(t.free_tvars())), t.map(disable_access_check), t.line)
        return s

    def __repr__(self):
        return str(self)

    def __str__(self):
        # replace tvars with prettier ones!
        tvs = list("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ")
        t = deepcopy(self.typ)
        for tv, tv1 in zip(self.tvars, tvs):
            t = t.subst(tv, TVar(tv1, -1))

        return "forall " + " ".join(tvs[:len(self.tvars)]) + " . " + str(t)

TVARIDX = 0


def newtv(l):
    global TVARIDX
    TVARIDX += 1
    return TVar("t" + str(TVARIDX), l)


def get_array_element_type(expression: str):
    """
    gets the type of the elements of the array literal `expression`
    """
    try:
        parsed = ast.literal_eval(expression)
        if isinstance(parsed, list) and parsed:
            return type(parsed[0])
        return None  # Return None for empty lists or invalid inputs
    except (SyntaxError, ValueError):
        return None  # Invalid expression


def pytype_to_typ(t, line):
    d = {
        int: Typ("Number", [], line),
        str: Typ("String", [], line),
        bool: Typ("Bool", [], line),
        None: newtv(line),
        NoneType: Typ("Unit", [], line),
    }
    if t in d:
        return d[t]
    return newtv(line)
