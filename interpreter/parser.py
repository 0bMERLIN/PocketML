import os
import re
from lark import Lark, ParseError, ParseTree
import interpreter.path as path

PATH = ""


def remove_comments_and_strings(s):
    comment = False
    string = False
    python = False
    res = ""
    for i in range(len(s)):
        if comment:
            if s[i] == "\n" and not string and not python:
                comment = False

        elif s[i : i + 3] == r"%%%" and not string:
            python = not python

        elif s[i] == '"' and s[i - 1] != "\\":
            string = not string

        elif s[i] == "#" and not string and not python:
            comment = True

        res += " " if any([comment, string, python]) and s[i] != "\n" else s[i]
    return res


def preprocess_do_blocks(source_code: str):
    """
    Turn do blocks like
    ```
    do
        let x = 10
        let y = 20
        print (x + y)
    ```
    into
    ```
    do {
        let x = 10;
        let y = 20;
        print (x + y);
    }
    ```
    """

    # prep input
    comment_free_src = remove_comments_and_strings(source_code)
    original_lines = source_code.splitlines()
    lines = comment_free_src.replace("\t", "    ").splitlines()

    result = ""

    # keep track of open lets, parens
    indent_stack = [[0, 0, 0, 0]]
    next_line_do = False
    n_open_parens = 0
    prev_n_open_parens = 0
    n_open_lets = 0
    last_let_dist = 1  # number of lines since the last let

    for original_line, line in zip(original_lines, lines):
        stripped = line.lstrip()
        if not stripped:
            result += original_line + "\n"
            continue

        last_let_dist += 1
        indent = len(line) - len(stripped)

        # update let & paren count
        n_open_parens += line.count("(") - line.count(")")

        if "let " in line:
            last_let_dist = 0

        # when a new do block is opened
        if next_line_do:
            indent_stack.append([indent, prev_n_open_parens, 0, 0])
            next_line_do = False
            result += "{"

        # a do block is terminated by dedent
        if indent < indent_stack[-1][0]:
            close_lets = "}" * indent_stack[-1][2]
            indent_stack.pop()
            result += close_lets + "}" + (";" if len(indent_stack) > 1 else "")

        # do block is terminated by ";"
        if (
            line.rstrip().endswith(";")
            and last_let_dist > 0
            and len(indent_stack) > 1
            and indent_stack[-1][2] - indent_stack[-1][3] == 0
        ):
            j = line.find(";")
            original_line = (
                original_line[:j] + "}" + "}" * indent_stack[-1][2] + original_line[j:]
            )
            indent_stack.pop()

        # do block is terminated by closing paren
        # find index of parentheses that closed the do block
        # to place a ";}"
        if n_open_parens < indent_stack[-1][1]:
            j = len(line)
            for _ in range(indent_stack[-1][1]):
                j = str(reversed(line)).find(")")
            close_lets = "}" * indent_stack[-1][2]
            original_line = original_line[:j] + close_lets + ";}" + original_line[j:]
            indent_stack.pop()

        n_open_lets += line.count("let ") - (
            (line.count(";")) if n_open_lets > 0 else 0
        )
        indent_stack[-1][2] += line.count("let ")
        indent_stack[-1][3] += (line.count(";")) if n_open_lets > 0 else 0

        result += original_line

        if ";" in line and len(indent_stack) > 1:
            result += "do{"

        if (
            len(indent_stack) > 1
            and not line.rstrip().endswith(("do", ";"))
            and (n_open_parens <= indent_stack[-1][1])
            and not original_line.rstrip().endswith("*)")
        ):
            result += ";"

        result += "\n"

        if line.rstrip().endswith("do"):
            next_line_do = True

        prev_n_open_parens = n_open_parens

    for _, ps, n_open_lets, _ in indent_stack[1:]:
        if ps != 0:
            continue
        result += "}" + n_open_lets * "}"
    return result


def nocheckpreprocess(txt: str):
    """
    Remove all code except for declarations, when nocheck is activated.
    """
    if txt.startswith("nocheck;"):
        acc = ""
        for l in txt.splitlines():
            if re.match("let [a-zA-Z_0-9]+ :", l) != None or l.strip(" ").startswith(
                ("module", "data", "type")
            ):
                acc += (
                    l
                    + (
                        ""
                        if l.strip(" ").endswith(";")
                        or l.strip(" ").startswith("module")
                        else ";"
                    )
                    + "\n"
                )
            else:
                acc += "\n"
        return acc
    return txt


DBG = False

OPS = {
    -2: {"ops": ["$"], "assoc": "right"},
    -1: { "ops": ["<<", ">>"], "assoc": "left"},
    0: {"ops": ["||", "&&"], "assoc": "left"},
    1: {"ops": ["==", "!=", "<", ">", ">=", "<="], "assoc": "left"},
    2: {"ops":["+", "-"], "assoc": "left"},
    3: {"ops":["*", "/", "°"], "assoc": "left"},
}


def add_infix_operators(g):
    """
    Add the infix operators from the OPS table
    to the grammar `g`.
    """

    # generate operator table
    res = "\n"

    OPS_sorted = [OPS[i] for i in sorted(OPS)]
    for i, _ in enumerate(OPS_sorted):
        op = OPS_sorted[i]
        ops = " | ".join(map(lambda o: f'"{o}"', op["ops"]))
        res += f"OP{i}: {ops}\n"
        next = "atom" if i == len(OPS_sorted) - 1 else f"op{i+1}"
        if op["assoc"] == "left":
            res += f"?op{i}: {next} | op{i} OP{i} {next} -> infix_op"
        elif op["assoc"] == "right":
            res += f"?op{i}: {next} | {next} OP{i} op{i} -> infix_op"
        else:
            raise ValueError(f"Unknown operator association: {res['assoc']}")
        
        # the last infix layer contains prefix operators like negation
        if i == len(OPS_sorted) - 1:
            res += '| "-" atom -> neg'
        res += "\n"

    res += "\n"

    # add it to the grammar
    g = g.replace("%%%OPERATOR_TABLE%%%", res)
    return g


def parse_file(filename, txt="") -> ParseTree:
    # fail if invalid filename
    if not os.path.isfile(filename):
        raise ParseError(f"Module ({filename}) not found!")

    # read/create grammar
    with open("interpreter/grammar.lark") as f:
        grammar = f.read()

    grammar = add_infix_operators(grammar)

    # parse
    parser = Lark(grammar, parser="earley", propagate_positions=True)

    if txt == "":
        with open(filename) as f:
            txt = f.read()

    txt = preprocess_do_blocks(txt)
    if DBG:
        for line in txt.split("\n"):
            print("-", line)

    try:
        return parser.parse(txt)
    except Exception as e:
        e.args = (str(e) + "=========",)
        raise e


def get_imports(filename):
    """
    get the filenames of the modules the given file imports
    """
    # get contents
    txt = ""
    with open(filename) as f:
        txt = f.read()

    import_lines = [l for l in txt.split("\n") if l.strip().startswith("import")]

    acc = []
    for l in import_lines:
        modulepath = l.strip().strip(";").split(" ")[1].split(".")
        fname = (
            path.storage_path
            + ("/" if path.storage_path[-1] != "/" else "")
            + "/".join(modulepath)
            + ".ml"
        )
        if os.path.exists(fname):
            acc += [fname]

    return acc
