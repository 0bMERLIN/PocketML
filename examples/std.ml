%%
def foldr(f):
	def inner(acc):
		def inner2(l):
			res = acc
			for x in reversed(l):
				res = f(res)(x)
			return res
		return inner2
	return inner

def mkdict(t):
	if t == None: return {}
	xs = list(t.values())
	acc = {}
	for e in xs:
		k = e["_0"]
		v = e["_1"]
		acc[k]=v
	return acc

def mklist(xs):
	if xs == []: return ("Nil",)
	return ("Cons",xs[0],mklist(xs[1:]))

EDITOR = self.env["editor"]
def cls(_):
	global EDITOR
	EDITOR.terminalout.text=""

import time
import sys
import numpy as np
globals().update(locals())

tup = lambda l:dict(zip(
		[f"_{i}" for i in range(100)],l
	))

__EXPORTS__={
	"float":float,
	"int":int,
	"str":str,
	"time":lambda _: time.time(),
	"cls":cls,
	"not":lambda x: not x,
	"dict":mkdict,
	"foldr": foldr,
	"head": lambda xs: xs[0],
	"tail": lambda xs: xs[1:],
	"map": lambda f: lambda l: list(map(f,l)),
	"dictGet": lambda d: (lambda k: ("Just", d[k])
		if k in d else ("Nothing",)),
	"dictInsert":lambda s:lambda d:lambda x: dict(list(d.items())+[(s,x)]),
	"len":len,
	"list": lambda xs: mklist(list(xs.values())),
	"vec":lambda xs:np.array(list(xs.values())),
	"vget":lambda i:lambda xs: xs[int(i)],
	"setreclimit":lambda x:sys.setrecursionlimit(int(x)),
	"tup1":tup,"tup2":tup,"tup3":tup,
	"tup4":tup
}%%;

data List a
	= Cons a (List a)
	| Nil;

let cls : Unit->Unit;
let time : Unit -> Number;
let setreclimit : Number->Unit;
let str : a -> String;

let not : Bool -> Bool;
let eq = equal;
let neq = \a->\b->not (equal a b);

let float : a -> Number;
let int : a -> Number;
let neg = \x -> -x;
let rec mull = \case
	  Nil -> 0
	| Cons x xs -> add x (mull xs);

let id = \x -> x;
let when = \cond -> \func -> if cond
	then func () else ();

data Maybe a = Nothing | Just a;
let maybe = \d -> \m -> case m
	| Just x -> x
	| Nothing -> d;
let bind = \m->\f->case m
	| Just x -> f x
	| Nothing -> Nothing;
let fmap = \g -> \case
	Just x -> Just (g x)
	| Nothing -> Nothing;

data Dict a;
# tuple of (String,b)
let dict : a -> Dict b;
let dictGet : (Dict a) -> String -> Maybe a;
let dictInsert : String -> (Dict a) -> a -> Dict a;

let foldr : (b -> a -> b) -> b -> (List a) -> b;
let map : (a -> b) -> (List a) -> List b;
let head : (List a) -> a;
let len : (List a) -> Number;

# Max. 20 elements.
let list : (a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a,a) -> List a;

let sumWith : (a -> a -> a) -> (List a) -> Maybe a;
let sumWith = \f -> \l ->
	if equal 0 (len l)
	then Nothing
	else Just (foldr f (head l) l);

# numpy arrays
data Vec;
let vec : (Number,Number,Number,Number,Number,Number,Number,Number,Number) -> Vec;
let vget : Number -> Vec -> Number;

let vmul : Vec -> Vec -> Vec;
let vadd : Vec -> Vec -> Vec;
let vmul = \a -> \b -> a * b;
let vadd = \a -> \b -> a + b;

let tup1 : Vec -> (Number,);
let tup2 : Vec -> (Number,Number);
let tup3 : Vec -> (Number,Number,Number);
let tup4 : Vec -> (Number,Number,Number,Number);

module (*)