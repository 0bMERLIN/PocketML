%%%
import time

def PML_mkDict(t):
	if t == None: return {}
	xs = list(t.values())
	acc = {}
	for e in xs:
		k = e["_0"]
		v = e["_1"]
		acc[k]=v
	return acc

def mklist(xs):
	if xs == []: return ("PML_Nil",)
	return ("PML_Cons",xs[0],mklist(xs[1:]))

EDITOR = globals()["editor"] if "editor" in globals() else None
def PML_cls(_):
	global EDITOR
	EDITOR.terminalout.text=""

def error(s):
	raise Exception(s)

def mymap(f):
	def inner(l):
		if l[0] == "PML_Nil":
			return ("PML_Nil",)
		else:
			return ("PML_Cons",f(l[1]),mymap(f)(l[2]))
	return inner

def PML_imap(f, i=0):
	def inner(l):
		if l[0] == "PML_Nil":
			return ("PML_Nil",)
		else:
			return ("PML_Cons",f(i)(l[1]),PML_imap(f,i=i+1)(l[2]))
	return inner

def foldr(f,a,l):
	if l[0] == "PML_Nil": return a
	else:
		return foldr(f, f(a)(l[1]), l[2])

import time
import sys
import numpy as np
import random
import os.path
globals().update(locals())

tup = lambda l:dict(zip(
		[f"_{i}" for i in range(100)],l
	))

PML_time = lambda _: time.time()
PML_not = lambda x: not x
PML_dictGet =  lambda d: (lambda k: ("Just", d[k]) if k in d else ("Nothing",))
PML_dictInsert = lambda s:lambda d:lambda x: dict(list(d.items())+[(s,x)])
PML_dictEmpty = {}
PML_vec = lambda xs:np.array(list(xs.values()))
PML_vget = lambda i:lambda xs: xs[int(i)]
PML_setreclimit = lambda x:sys.setrecursionlimit(int(x))
PML_tup1 = tup
PML_tup2 = tup
PML_tup3 = tup
PML_tup4 = tup
PML_foldr = lambda f:lambda a:lambda l:foldr(f,a,l)
PML_randint = lambda a:lambda b:random.randint(*sorted([int(a),int(b)]))
PML_time = lambda _: time.time()
PML_fileexists = os.path.exists
PML_range = lambda a: lambda b: mklist([*range(int(a),int(b))])
PML_float = float

%%%;

let time : Unit -> Number;

data List a
	= Cons a (List a)
	| Nil;

let cls : Unit -> Unit;
let time : Unit -> Number;
let setreclimit : Number -> Unit;
let error : String -> a;
let str : a -> String;
let fileexists : String -> Bool;

let randint : Number -> Number -> Number;
let range : Number -> Number -> List Number;

let not : Bool -> Bool;
let eq = equal;
let neq = \a->\b->not (equal a b);

let float : a -> Number;
let int : a -> Number;

let neg : Number -> Number;
let neg = \x -> -x;

let id : a -> a;
let id = \x -> x;

let const : a -> b -> a;
let const x y = x;

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
let mkDict : a -> Dict b;

let dictEmpty : Dict a;

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