cache;

%%
import time

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

EDITOR = self.env["editor"] if "editor" in self.env else None
def cls(_):
	global EDITOR
	EDITOR.terminalout.text=""

def error(s):
	raise Exception(s)

def mymap(f):
	def inner(l):
		if l[0] == "Nil":
			return ("Nil",)
		else:
			return ("Cons",f(l[1]),mymap(f)(l[2]))
	return inner

def imap(f, i=0):
	def inner(l):
		if l[0] == "Nil":
			return ("Nil",)
		else:
			return ("Cons",f(i)(l[1]),imap(f,i=i+1)(l[2]))
	return inner

def foldr(f,a,l):
	if l[0] == "Nil": return a
	else:
		return foldr(f, f(a)(l[1]), l[2])

import time
import sys
import numpy as np
import random
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
	"dictGet": lambda d: (lambda k: ("Just", d[k])
		if k in d else ("Nothing",)),
	"dictInsert":lambda s:lambda d:lambda x: dict(list(d.items())+[(s,x)]),
	"list": lambda xs: mklist(list(xs.values())),
	"vec":lambda xs:np.array(list(xs.values())),
	"vget":lambda i:lambda xs: xs[int(i)],
	"setreclimit":lambda x:sys.setrecursionlimit(int(x)),
	"tup1":tup,"tup2":tup,"tup3":tup,
	"tup4":tup,
	"error": error,
	#"map":mymap,
	"imap":imap,
	"foldr":lambda f:lambda a:lambda l:foldr(f,a,l),
	"randint": lambda a:lambda b:random.randint(*sorted([int(a),int(b)])),
	"time": lambda _: time.time()
}%%;

let time : Unit -> Number;

data List a
	= Cons a (List a)
	| Nil;

let cls : Unit -> Unit;
let time : Unit -> Number;
let setreclimit : Number -> Unit;
let error : String -> a;
let str : a -> String;
let randint : Number -> Number -> Number;

let not : Bool -> Bool;
let eq = equal;
let neq = \a->\b->not (equal a b);

let float : a -> Number;
let int : a -> Number;

let neg : Number -> Number;
let neg = \x -> -x;

let id : a -> a;
let id = \x -> x;

let when : Bool -> (Unit -> Unit) -> Unit;
let when cond func = if cond then func () else ();

data Maybe a = Nothing | Just a;

let maybe : a -> Maybe a -> a;
let maybe d m = case m
	| Just x -> x
	| Nothing -> d;

let bind : Maybe a -> (a -> Maybe a) -> Maybe a;
let bind m f = case m
	| Just x -> f x
	| Nothing -> Nothing;

let fmap : (a -> a) -> Maybe a -> Maybe a;
let fmap g = \case
	Just x -> Just (g x)
	| Nothing -> Nothing;

data Dict a;

# tuple of (String,b)
let dict : a -> Dict b;
let dictGet : Dict a -> String -> Maybe a;
let dictInsert : String -> Dict a -> a -> Dict a;

let append : a -> List a -> List a;
let rec append = \a -> \l -> case l
	| Cons x xs -> Cons x (append a xs)
	| Nil -> Nil;

let foldr : (b -> a -> b) -> b -> List a -> b;

let map : (a -> b) -> (List a) -> List b;
let map = \f -> \case
	  Cons x xs -> Cons (f x) (map f xs)
	| Nil -> Nil;

let imap : (Number -> a -> b) -> List a -> List b;

let any : List Bool -> Bool;
let any = foldr or False;

let head : List a -> a;
let head = \l -> case l
	| Cons x xs -> x
	| Nil -> error "head on empty list";

let tail : List a -> List a;
let tail = \l -> case l
	| Cons x xs -> xs
	| Nil -> error "tail on empty list";

let len : List a -> Number;
let rec len = \case
	  Cons _ l -> 1 + (len l)
	| Nil -> 0;

# numpy arrays
data Vec;
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