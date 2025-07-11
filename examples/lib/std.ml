import lib.input;

%%%
import time

def PML_dictItems(d):
	acc = []
	for k,v in d.items():
		acc += [{"_0": k,"_1": v}]
	return mklist(acc)

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
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

EDITOR = globals()["editor"] if "editor" in globals() else None
def PML_cls(_):
	global EDITOR
	EDITOR.terminalout.text=""

def error(s):
	raise Exception(s)

@curry
def mymap(f,l):
	acc = []
	while l[0] != "PML_Nil":
		acc += [f(l[1])]
		l = l[2]
	return mklist(acc)

@curry
def PML_foldr(f,acc,l):
	while l[0] != "PML_Nil":
		acc = f(acc)(l[1])
		l = l[2]
	return acc

def PML_imap(f, i=0):
	def inner(l):
		if l[0] == "PML_Nil":
			return ("PML_Nil",)
		else:
			return ("PML_Cons",f(i)(l[1]),PML_imap(f,i=i+1)(l[2]))
	return inner

def PML_reverse(l):
	return mklist(list(reversed(conv_list(l))))

@curry
def PML_mapRecord(b,a):
    return dict(list(a.items()) + list(b(a).items()))

def PML_error(msg):
	raise Exception("PocketML Runtime Error: "+str(msg))

@curry
def PML_contains(x,l):
	py_l = PML_foldr(lambda acc: lambda y: acc+[y],[],l)
	return x in py_l

def PML_nub(l):
	acc = []
	pyl = conv_list(l)
	for x in pyl:
		if x not in acc:
			acc += [x]
	return mklist(acc)

import time
import sys
import numpy as np
import random
import os.path
globals().update(locals())

tup = lambda *l:dict(zip(
		[f"_{i}" for i in range(100)],l
	))

PML_str = str
PML_time = lambda _: time.time()
PML_not = lambda x: not x
PML_dictGet =  lambda d: (lambda k: ("PML_Just", d[k]) if k in d else ("PML_Nothing",))
PML_dictInsert = lambda s:lambda d:lambda x: dict(list(d.items())+[(s,x)])
PML_dictEmpty = {}
PML_vec = lambda xs:np.array(list(xs.values()))
PML_vget = lambda i:lambda xs: xs[int(i)]
PML_setreclimit = lambda x:sys.setrecursionlimit(int(x))
PML_tup1 = tup
PML_tup2 = lambda x:lambda y: tup(x,y)
PML_randint = lambda a:lambda b:random.randint(*sorted([int(a),int(b)]))
PML_time = lambda _: time.time()
PML_fileexists = os.path.exists
PML_range = lambda a: lambda b: mklist([*range(int(a),int(b))])
PML_srange = lambda a: lambda b: lambda s: mklist([*range(int(a),int(b),int(s))])
PML_float = float
PML_map = mymap
PML_int = int
PML_sort = lambda l: mklist(sorted(conv_list(l)))
PML_listeq = lambda a: lambda b: conv_list(a)==conv_list(b)
PML_printl=lambda l: PML_print(str(conv_list(l)))
PML_setUpdate = lambda s: lambda f: editor.graphicalout.setUpdate(s, lambda s: lambda _: f(s))

@curry
def PML_setTickInterval(i,s,f):
	@curry
	def helper(ts, _):
		t, s = ts
		if time.time()-t > i:
			return time.time(), f(s)
		return t,s
	editor.graphicalout.setUpdate(
		(time.time(),s), helper)

PML_split = lambda s: lambda cs: mklist(s.split(cs))
PML_replace = lambda o: lambda n: lambda s: s.replace(o,n)
PML_isNumeric = lambda s: s.isnumeric()
PML_strIn = lambda a: lambda b: a in b
PML_strLen = lambda s: len(s)

%%%;

let time : Unit -> Number;
let setTickInterval : Number -> state -> (state->state) -> Unit;
let setUpdate : state -> (state->state) ->Unit;

data List a
	= Cons a (List a)
	| Nil
	# The default list type generated
	# by `[...]`
;

let cls : Unit -> Unit;
let time : Unit -> Number;
let setreclimit : Number -> Unit;
let error : String -> a;
let str : a -> String;
let fileexists : String -> Bool;

let randint : Number -> Number -> Number;
let range : Number -> Number -> List Number;
let srange : Number -> Number -> Number -> List Number;
let sort : List a -> List a;
let listeq : List a -> List a->Bool;
let printl : List a -> Unit;

let uncurry2 : (a -> b -> c) -> (a,b) -> c;
let uncurry2 f t = f (t._0) (t._1);

let not : Bool -> Bool;
let eq = equal;
let neq = \a->\b->not (equal a b);

let float : a -> Number;
let int : a -> Number;

let neg : Number -> Number;
let neg = \x -> -x;

let between : Number-> Number -> Number -> Bool;# a b c -> a < c < b
let between a b x = a <= x && x <= b;

let id : a -> a;
let id = \x -> x;

let const : a -> b -> a;
let const x y = x;

let when : Bool -> (Unit -> Unit) -> Unit;
let when cond func = if cond then func () else ();

let mapRecord : (a -> a) -> a -> a;

let with : a -> a -> a;
let with x = mapRecord (\_ -> x);

let times : Number -> (a -> a) -> a -> a;
let times n f x = if n <= 0 then x else times (n-1) f (f x);

data Maybe a = Nothing | Just a;

let maybe : a -> Maybe a -> a;
let maybe d m = case m
	| Just x -> x
	| Nothing -> d;

let bind : Maybe a -> (a -> Maybe a) -> Maybe a;
let bind m f_bnd = case m
	| Just x -> f_bnd x
	| Nothing -> Nothing;

let fmap : (a -> a) -> Maybe a -> Maybe a;
let fmap g = \case
	Just x -> Just (g x)
	| Nothing -> Nothing;

data Dict a;

let mkDict : a -> Dict b
# WARNING: `a` should always be a record.
;

let dictEmpty : Dict a;

let dictItems : Dict a -> List (String, a);

let dictGet : Dict a -> String -> Maybe a;
let dictInsert : String -> Dict a -> a -> Dict a;

let append : a -> List a -> List a;
let rec append a l = case l
	| Cons x xs -> Cons x (append a xs)
	| Nil -> Cons a Nil;

let foldr : (b -> a -> b) -> b -> List a -> b;

let extend : List a -> List a -> List a;
let extend l xs = foldr (\acc x -> append x acc) l xs;

let concat : List (List a) -> List a;
let concat = foldr (\acc l -> extend acc l) [];

let reverse : List a -> List a;

let map : (a -> b) -> (List a) -> List b;
let foreach2D : Number -> Number -> (Number->Number-> Unit) -> Unit; # w h f
let foreach2D w h f = 
	let _ = map (\x ->
		map (\y -> f x y) (range 0 w))
		(range 0 w);
	();

let nub : List a -> List a;

let imap : (Number -> a -> b) -> List a -> List b;

let any : List Bool -> Bool;
let any = foldr or False;

let head : List a -> a;
let head l = case l
	| Cons x xs -> x
	| Nil -> error "head on empty list";

let tail : List a -> List a;
let tail l = case l
	| Cons x xs -> xs
	| Nil -> error "tail on empty list";

let tailSafe : List a -> List a;
let tailSafe l = case l
	| Cons x xs -> xs
	| Nil -> Nil;

let len : List a -> Number;
let rec len = \case
	  Cons _ l -> 1 + (len l)
	| Nil -> 0;

let listAtSafe : Number -> a -> List a -> a;
let listAtSafe n d l = if n > 0
	then listAtSafe (n-1) d (tailSafe l)
	else (if len l == 0 then d else head l);

let zip : List a -> List b -> List (a,b);
let rec zip xs ys =
	if len xs == 0 || len ys == 0
	then []
	else Cons
		((head xs), (head ys))
		(zip (tail xs) (tail ys));

let contains : a -> List a -> Bool;

let foldr : (b -> a -> b) -> b -> List a -> b;

let filter : (a -> Bool) -> List a -> List a;
let filter f l = foldr (\acc x -> if f x then append x acc else acc) [] l;

# strings
let split : String -> String -> List String;# str chars -> list
let replace : String -> String -> String -> String; # old new str
let isNumeric : String -> Bool;
let strIn : String -> String -> Bool; # a b, check if a is any of the characters in b
let strLen : String -> Number;

# numpy arrays
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