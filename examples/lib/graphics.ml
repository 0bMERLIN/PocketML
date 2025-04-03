cache;

import lib.std;

%%
import time
t1 = time.time()

EDITOR = self.env["editor"]
from kivy.graphics import Color,Rectangle,Ellipse
from kivy.core.window import Window
import numpy as np

def il(x):
	# convert numpy array to int List
	return list(map(int, list(x)))

def setaction(nm):
	return lambda x: lambda f: setattr(x, nm, lambda: f(None))

def g(f):
	global EDITOR

	with EDITOR.graphicalout.canvas:
		return f()

def show(x):
	global EDITOR
	EDITOR.terminalout.text+=str(x)+"\n"

globals().update(locals())

rect = lambda pos: lambda size: g(lambda: Rectangle(pos=il(pos),size=il(size)))
circle = lambda pos: lambda r: g(lambda: Ellipse(pos=il(pos),size=(r,r)))
button = lambda text: lambda pos: lambda size: EDITOR.graphicalout.button(text, il(pos), il(size))
color = lambda c: GraphicalOut.color(il(c))
clear = lambda _: EDITOR.graphicalout.canvas.clear()

def setPos(obj):
	def f(v):
		obj.pos = il(v)
	return f

def mapPos(f,obj):
	obj.pos= il(f(np.array(obj.pos)))

def colRect(r1, r2):
    return not (r1[0] + r1[2] <= r2[0] or r2[0] + r2[2] <= r1[0] or
                r1[1] + r1[3] <= r2[1] or r2[1] + r2[3] <= r1[1])

def collide(a,b):
	return colRect(
		(*a.pos, *a.size),
		(*b.pos, *b.size)
	)

globals().update(locals())

__EXPORTS__={
	"execute":EDITOR.graphicalout.execute,
	"setUpdate": EDITOR.graphicalout.setUpdate,
	"button": button,
	"rect": rect,
	"circle":circle,
	"clear":clear,
	"setPos":setPos,
	"getPos":lambda obj:np.array(obj.pos),
	"mapPos":lambda f:lambda obj:mapPos(f,obj),
	"onpress": setaction("on_press"),
	"onrel": setaction("on_release"),
	"width":Window.width,
	"height":Window.height-120,
	"collide":lambda a:lambda b:collide(a,b),
}
%%;

let time : Unit -> Number;

let width : Number;
let height : Number;

data Obj;
let rect : Vec -> Vec -> Obj;
let circle : Vec -> Number -> Obj;
let clear : Unit -> Unit;

let setPos : Obj -> Vec -> Unit;
let getPos : Obj -> Vec;
let mapPos : (Vec -> Vec) -> Obj -> Unit;

let setUpdate : a -> (a -> (List String) -> a) -> Unit;
let setTick = \f -> setUpdate () (\_->\_k-> f ());

data Btn;
let button : String -> Vec -> Vec -> Btn;
let onpress : Btn -> (Unit -> Unit) -> Unit;
let onrel : Btn -> (Unit -> Unit) -> Unit;

let collide : Obj -> Obj -> Bool;

module (*)