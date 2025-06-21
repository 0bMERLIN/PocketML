import lib.std;
import lib.image;

%%%

EDITOR = globals()["editor"] if "editor" in globals() else None

from kivy.graphics import Color,Rectangle,Ellipse,Rotate,PushMatrix,PopMatrix,Scale
from kivy.core.window import Window
import numpy as np
import time


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

def get_widget_bounds(widgets):
    """ Calculate the bounding box around a list of widgets """
    if not widgets:
        return None
    
    x_min = min(widget.pos[0] for widget in widgets)
    y_min = min(widget.pos[1] for widget in widgets)
    x_max = max(widget.pos[0] + widget.size[0] for widget in widgets)
    y_max = max(widget.pos[1] + widget.size[1] for widget in widgets)
    
    return x_min, y_min, x_max, y_max


class GameObj:
	def __init__(self, pos, c,rotate=None):
		self.cs = [c]
		self.p = pos
		
		self.rotate = rotate

		self.o = pos
		self.origin = pos

	def add_child(self, c):
		self.cs += [c]
	
	def rot(self, angle):
		self.rotate.angle = angle
	
	@property
	def origin(self):
		return self.o
	
	@origin.setter
	def origin(self, o):
		if self.rotate != None:
			self.rotate.origin = o
		
		for c in self.cs:
			if isinstance(c, GameObj):
				c.origin = o
		self.o = o
	
	@property
	def pos(self):
		return np.array(self.p)

	@pos.setter
	def pos(self, p):
		self.mapPos(lambda _: p)
	
	@property
	def size(self):
		xmin,ymin,xmax,ymax = get_widget_bounds(self.cs)
		return il(np.array([xmax,ymax])-np.array([xmin,ymin]))
	
	def mapPos(self, f):
		p = il(f(np.array(self.pos)))
		dp = np.array(p)-np.array(self.pos)
		self.p = p
		self.origin = p
		for c in self.cs:
			c.pos = il(np.array(c.pos) + dp)


def mkrect(pos,size,texture=None):
	PushMatrix()
	r=Rotate()
	o=Rectangle(pos=il(pos),size=il(size),texture=texture)
	PopMatrix()
	return GameObj(pos, o, r)

PML_rect = lambda pos: lambda size: g(lambda: mkrect(pos,size))
PML_texrect = lambda pos: lambda size: lambda t: g(lambda: mkrect(pos,size,texture=t))
PML_circle = lambda pos: lambda r: g(lambda: GameObj(pos, Ellipse(pos=il(pos),size=(r,r)), rotate=Rotate()))

PML_button = lambda text: lambda pos: lambda size: EDITOR.graphicalout.button(text, il(pos), il(size))
PML_color = lambda c: GraphicalOut.color(il(c))
PML_clear = lambda _: EDITOR.graphicalout.canvas.clear()

def colRect(r1, r2):
    return not (r1[0] + r1[2] <= r2[0] or r2[0] + r2[2] <= r1[0] or
                r1[1] + r1[3] <= r2[1] or r2[1] + r2[3] <= r1[1])

def collide(a,b):
	return colRect(
		(*a.pos, *a.size),
		(*b.pos, *b.size)
	)

def setPos(o,p):
	o.pos = p

def btncolor(b,c):
	b.background_color = [
		*list(c / 88)[0:3],
		(255/10 + c[3]/2)/88
	]

globals().update(locals())

PML_execute = EDITOR.graphicalout.execute
PML_setUpdate = EDITOR.graphicalout.setUpdate
PML_setPos = lambda o:lambda p: setPos(o,p)
PML_getPos = lambda obj:np.array(obj.pos)
PML_mapPos = lambda f:lambda obj:obj.mapPos(f)
PML_onpress = setaction("on_press")
PML_onrel = setaction("on_release")
PML_width = Window.width
PML_height = Window.height-120
PML_collide = lambda a:lambda b:collide(a,b)
PML_setRot = lambda o: lambda a: o.rot(a)
PML_mapRot = lambda f: lambda o: o.rot(f(o.rotate.angle))
PML_getRot = lambda o: o.rotate.angle
PML_btncolor = lambda b:lambda c: btncolor(b,c)
PML_link = lambda p: lambda c: (p.add_child(c), p)[1]
PML_push = lambda _: g(lambda: PushMatrix())
PML_pop = lambda _: g(lambda: PopMatrix())
PML_scale = lambda v: g(lambda: Scale(list(v)))

%%%;

let time : Unit -> Number;

let width : Number;
let height : Number;

data Obj;
let rect : Vec -> Vec -> Obj;

# pos,size,img
let texrect : Vec -> Vec -> Img -> Obj;
let circle : Vec -> Number -> Obj;
let clear : Unit -> Unit;
let link : Obj -> Obj -> Obj;

let setPos : Obj -> Vec -> Unit;
let getPos : Obj -> Vec;
let mapPos : (Vec -> Vec) -> Obj -> Unit;

let setRot : Obj -> Number -> Unit;
let getRot : Obj -> Number;
let mapRot : (Number -> Number) -> Obj -> Unit;

let scale : Vec -> Unit;
let push : Unit -> Unit;
let pop : Unit -> Unit;

let setUpdate : a -> (a -> (List String) -> a) -> Unit;
let setTick = \f -> setUpdate () (\_->\_k-> f ());

data Btn;
let button : String -> Vec -> Vec -> Btn;
let onpress : Btn -> (Unit -> Unit) -> Unit;
let onrel : Btn -> (Unit -> Unit) -> Unit;
let btncolor : Btn -> Vec -> Unit;

let collide : Obj -> Obj -> Bool;

module (*)