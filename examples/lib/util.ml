%%%
import time

def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

EDITOR = globals()["editor"] if "editor" in globals() else None
def PML_cls(_):
	global EDITOR
	EDITOR.terminalout.text=""

@curry
def PML_mapRecord(b,a):
    return dict(list(a.items()) + list(b(a).items()))

def PML_error(msg):
	raise Exception("PocketML Runtime Error: "+str(msg))

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
PML_setreclimit = lambda x:sys.setrecursionlimit(int(x))
PML_randint = lambda a:lambda b:random.randint(*sorted([int(a),int(b)]))
PML_time = lambda _: time.time()
PML_fileexists = os.path.exists
PML_float = float
PML_int = int
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

%%%;

let time : Unit -> Number;
let setTickInterval : Number -> state -> (state->state) -> Unit;
let setUpdate : state -> (state->state) ->Unit;

let cls : Unit -> Unit;
let time : Unit -> Number;
let setreclimit : Number -> Unit;
let error : String -> a;
let str : a -> String;
let fileexists : String -> Bool;

let randint : Number -> Number -> Number;

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

module (*)