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
import requests
import interpreter.path as path

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
PML_fileexists = lambda p: os.path.exists(path.cwd+p)
PML_float = float
PML_int = int
PML_setUpdate = lambda s: lambda f: editor.graphicalout.setUpdate(s, lambda s: lambda _: f(s))

@curry
def PML_setInterval(i,s,f):
	@curry
	def helper(ts, _):
		t, s = ts
		if time.time()-t > i:
			return time.time(), f(s)
		return t,s
	editor.graphicalout.setUpdate(
		(time.time(),s), helper)

def PML_printl(l):
	PML_print(" ".join(list(map(str, convlist(l)))))

def PML_setTermFontSize(s):
	editor.terminalout.font_size = s

def PML_setCompilerCWD(p):
	import interpreter.typecheck as tc
	import interpreter.compiler as co
	while not tc.storage_path.endswith("myapp"):
		tc.storage_path = tc.storage_path[:-1]
	tc.storage_path += "/" + p
	co.storage_path = tc.storage_path

def PML_traceTime(f):
	t = time.time()
	res = f(None)
	PML_print("[traceTime]", time.time()-t)
	return res

@curry
def PML_download(from_path, to_path):
	response = requests.get(from_path)
	response.raise_for_status()

	with open(path.storage_path+"/"+to_path, 'wb') as f:
		f.write(response.content)

from copy import deepcopy as copy
PML_copy=copy

def PML_readFile(p):
	from kivy import platform
	p = path.cwd+"/"+p
	p = p.replace("//","/")
	try:
		with open(p,'r') \
				as f:
			return ("PML_Just",f.read())
	except Exception as e:
		PML_print(e)
		return ("PML_Nothing",)
%%%;

## Util functions for the OS, kivy process, network and more.

### ### Time
let time : Unit -> Number;
let traceTime : (Unit -> b) -> b
	# log the time an action takes to execute
;
let setInterval : Number -> state -> (state->state) -> Unit
	# args: n, state, tick
	# run tick every n seconds.
;
let setUpdate : state -> (state->state) ->Unit;

### ### Terminal
let cls : Unit -> Unit;
let error : String -> a;
let setTermFontSize : Number -> Unit;
let str : a -> String
	# deprecated. Use lib.string (str)
;

data List a
	# --hide
;
let printl : List a -> Unit;

### ### Misc.

let setreclimit : Number -> Unit;
let setCompilerCWD : String -> Unit;
let randint : Number -> Number -> Number;

### ### File system

let fileexists : String -> Bool;
data Maybe a = Just a | Nothing
	# --hide
;
let readFile : String -> Maybe String;

let readFileUnsafe : String -> String;
let readFileUnsafe s = case readFile s
	| Just x -> x;

### ### Network
let download : String -> String -> Unit;

### ### Basic functions
let copy : a -> a;
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

let with : a -> b -> b;
let with x = mapRecord (\_ -> x);

let union : a -> a -> a;
let union = with;

let times : Number -> (a -> a) -> a -> a;
let times n f x = if n <= 0 then x else times (n-1) f (f x);

let ftee : (a -> Unit) -> (a -> a) -> a -> a;
let ftee t g x =
	let res = g x; const res (t res);

#let _= download "http://localhost:8080/C13.png" "test.png";

module (*)