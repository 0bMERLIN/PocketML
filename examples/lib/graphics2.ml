import lib.std;
import lib.image;

%%%

EDITOR = globals()["editor"]
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

rect = lambda pos: lambda size: g(lambda: mkrect(pos,size))
texrect = lambda pos: lambda size: lambda t: g(lambda: mkrect(pos,size,texture=t))
circle = lambda pos: lambda r: g(lambda: GameObj(pos, Ellipse(pos=il(pos),size=(r,r)), rotate=Rotate()))

button = lambda text: lambda pos: lambda size: EDITOR.graphicalout.button(text, il(pos), il(size))
color = lambda c: GraphicalOut.color(il(c))
clear = lambda _: EDITOR.graphicalout.canvas.clear()

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

__EXPORTS__={
	"execute":EDITOR.graphicalout.execute,
	"setUpdate": EDITOR.graphicalout.setUpdate,
	"button": button,
	"rect": rect,
	"texrect": texrect,
	"circle":circle,
	"clear":clear,
	"setPos":lambda o:lambda p: setPos(o,p),
	"getPos":lambda obj:np.array(obj.pos),
	"mapPos":lambda f:lambda obj:obj.mapPos(f),
	"onpress": setaction("on_press"),
	"onrel": setaction("on_release"),
	"width":Window.width,
	"height":Window.height-120,
	"collide":lambda a:lambda b:collide(a,b),
	"setRot": lambda o: lambda a: o.rot(a),
	"mapRot": lambda f: lambda o: o.rot(f(o.rotate.angle)),
	"getRot": lambda o: o.rotate.angle,
	"btncolor":lambda b:lambda c: btncolor(b,c),
	"link": lambda p: lambda c: (p.add_child(c), p)[1],
	"push": lambda _: g(lambda: PushMatrix()),
	"pop": lambda _: g(lambda: PopMatrix()),
	"scale": lambda v: g(lambda: Scale(list(v))),
    "listen": lambda st: lambda a: lambda f: listen(st,a,f),
    "unpack": lambda a: a[1]
}

for k,v in __EXPORTS__.items():
	globals()["PML_"+k] = v

%%%;

data Attr
    = TexAttr Img
    | VecAttr Vec;

let unpack : a -> b;

type Rigidbody = { tex: Img, pos: Vec, vel: Vec, size: Vec, listeners: Dict (Attr -> Unit) };

let mkRigidbody : Img -> Vec -> Vec -> Vec -> Rigidbody;
let mkRigidbody t p v size = { tex = t, pos = p, vel = v, size = size, listeners = dictEmpty };

let rigidbodyMapPos : (Vec -> Vec) -> Rigidbody -> Rigidbody;
let rigidbodyMapPos f r =
    let newPos = f r.pos;
	let m = dictGet r.listeners "pos";
	let l = maybe (\_ -> ()) m;
	let _ = l (VecAttr newPos);
    { tex = r.tex, pos = newPos, vel = r.vel, size = r.size, listeners = r.listeners };

let rigidbodyMapTex : (Img -> Img) -> Rigidbody -> Rigidbody;
let rigidbodyMapTex f y =
    let newTex = f y.tex;
    let _ = (maybe (\_ -> ()) (dictGet y.listeners "tex")) (TexAttr newTex);
    { tex = newTex, pos = y.pos, vel = y.vel, size = y.size, listeners = y.listeners };

let moveRigidbody : Rigidbody -> Rigidbody;
let moveRigidbody r = rigidbodyMapPos (\p -> p + r.vel) r;

let listen : String -> (a -> Unit) -> Rigidbody -> Rigidbody;
let listen nm f z = { tex = z.tex, pos = z.pos, vel = z.vel, size = z.size,
    listeners = dictInsert nm z.listeners (\x -> f (unpack x)) };


##############################

let time : Unit -> Number;

let width : Number;
let height : Number;

data Obj;
let rect : Vec -> Vec -> Obj;
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

data Btn;
let button : String -> Vec -> Vec -> Btn;
let onpress : Btn -> (Unit -> Unit) -> Unit;
let onrel : Btn -> (Unit -> Unit) -> Unit;
let btncolor : Btn -> Vec -> Unit;

let collide : Obj -> Obj -> Bool;

##############################

let setUpdate : a -> (a -> (List String) -> a) -> Unit;
let app ist f = setUpdate ist (\st _k -> f st);


module (*)