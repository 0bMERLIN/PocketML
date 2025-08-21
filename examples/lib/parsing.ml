%%%

def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

import lark
globals().update(locals())

from lark import Tree, Token

import re

def find_repeated_rules(grammar: str):
	"""
	Finds all named rules (via 'rulename:' or '-> rulename') that contain a repetition operator (+ or *).
	Ignores terminals and inline regexes.
	"""
	repeated_rules = set()
	current_rule = None
	collecting_alternatives = False

	rule_def_re = re.compile(r'^\s*[\?]?(\w+)\s*:\s*(.+)')
	alt_line_re = re.compile(r'^\s*\|(.+)')
	named_alt_re = re.compile(r'->\s*(\w+)')
	repeat_re = re.compile(r'\b\w+\s*[\*\+]')  # e.g., atom+ or expr *

	lines = grammar.splitlines()
	for i, line in enumerate(lines):
		stripped = line.strip()
		if not stripped or stripped.startswith('%'):
			continue

		rule_match = rule_def_re.match(line)
		if rule_match:
			current_rule, expr = rule_match.groups()
			collecting_alternatives = True

			if '/' in expr:
				continue  # Ignore terminals (regex)

			if repeat_re.search(expr):
				repeated_rules.add(current_rule)

			alt_match = named_alt_re.search(expr)
			if alt_match and repeat_re.search(expr):
				repeated_rules.add(alt_match.group(1))
			continue

		elif collecting_alternatives:
			alt_match = alt_line_re.match(line)
			if alt_match:
				alt_expr = alt_match.group(1)
				if repeat_re.search(alt_expr):
					name_match = named_alt_re.search(alt_expr)
					if name_match:
						repeated_rules.add(name_match.group(1))

	return sorted(repeated_rules)

def camelize(s):
    parts = s.replace('-', ' ').replace('_', ' ').split()
    return parts[0].capitalize() + ''.join(word.capitalize() for word in parts[1:])

def tree2tup(tree,reps,lines=False,tokens=False):

    def to_tup(node):
        if isinstance(node, Tree):
            cs = tuple(to_tup(c)
            	for c in node.children)
            if str(node.data) in reps:
            	cs = [mklist(cs)]
            
            name = camelize(str(node.data))
            if lines:
                return ("PML_"+name,
                	(node.meta.line,
                	node.meta.column),
                	*cs)
            return ("PML_"+name,*cs)
        elif isinstance(node, Token) \
        		and tokens:
            if lines:
                return (node.type,
                	(node.line,
                	node.column),
                	node.value)
            return (node.type,node.value)
        elif isinstance(node, Token):
        	return node.value
        else:
            raise TypeError(
            	"Unexpected node type"
            	+ f": {type(node)}")

    return to_tup(tree)
globals().update(locals())

def PML_parser(gr):
	try:
		p = lark.Lark(gr,
			propagate_positions=True)
	except Exception as e:
		return ("PML_Left", str(e))
	
	reps = find_repeated_rules(gr)
	def parse(s):
		try:
			return ("PML_Right",tree2tup(p.parse(s), reps))
		except Exception as e:
			return ("PML_Left", str(e))
	return ("PML_Right",parse)

%%%;

import lib.either;

## A lark-based parser. Generated data compatible with a sum type of the form `data Expr = CapitalizedRuleName ... | ...`

### ### Types

type GrammarError = String;
type ParseError = String;

### ### Creating parsers

let parser :
	String -> Either GrammarError (
		String -> Either ParseError a
	)
	# args: grammar, string
;
module (parser)

