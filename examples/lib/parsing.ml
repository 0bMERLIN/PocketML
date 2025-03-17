%%%

import lark
globals().update(locals())

from lark import Tree, Token

def tree2tup(tree,lines=False,tokens=False):
    def to_tup(node):
        if isinstance(node, Tree):
            cs = tuple(to_tup(c)
            	for c in node.children)
            if lines:
                return (node.data\
                		.capitalize(),
                	(node.meta.line,
                	node.meta.column),
                	*cs)
            return (node.data\
            		.capitalize(),*cs)
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

def parser(gr):
	p = lark.Lark(gr,
		propagate_positions=True)
	def parse(s):
		return tree2tup(p.parse(s))
	return parse

__EXPORTS__ = {
	"parser":parser,
}

%%%;

let parser : String -> String -> a;
module (parser)

