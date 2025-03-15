%%
EDITOR = self.env["editor"]
from kivy.graphics import Color,Rectangle,Ellipse
from kivy.core.window import Window


def setaction(nm):
	return lambda x: lambda f: setattr(x, nm, lambda: f(None))

def g(f):
	global EDITOR

	with EDITOR.graphicalout.canvas:
		return f()

globals().update(locals())

rect = lambda pos: lambda size: g(lambda: Rectangle(pos=pos.values(),size=size.values()))

circle = lambda pos: lambda r: g(lambda: Ellipse(pos=pos.values(),size=(r,r)))

clear = lambda _: EDITOR.graphicalout.canvas.clear()

def setPos(obj):
	def f(v):
		obj.pos = list(v.values())
	return f


__EXPORTS__={
	"rect": rect,
	"circle":circle,
	"clear":clear,
	"setPos":setPos,
	"contains":lambda l: lambda x: x in l,
	"onpress": setaction("on_press"),
	"onrel": setaction("on_release"),
	"width":Window.width,
	"height":Window.height-120
}
%%;

import std;

let width : Number;
let height : Number;

type Vec2 = (Number,Number);

data Rect;
let rect : Vec2 -> Vec2 -> Rect;
let circle : Vec2 -> Number -> Rect;
let clear : Unit -> Unit;
let setPos : Rect -> Vec2 -> Vec2;
let setUpdate : a -> (a -> (List String) -> a) -> Unit;
let setTick = \f -> setUpdate () (\_->\_k-> f ());

data Btn;
let button : String -> Vec2 ->Vec2-> Btn;
let onpress : Btn ->(Unit->Unit) -> Unit;
let onrel : Btn -> (Unit->Unit) -> Unit;


module (*)