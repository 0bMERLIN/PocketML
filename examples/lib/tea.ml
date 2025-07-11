%%%

from kivy.graphics import Color,Rectangle,Ellipse,Rotate,PushMatrix,PopMatrix,Scale,Line
from kivy.uix.button import Button
from kivy.core.window import Window
from kivy.uix.label import Label
import numpy as np

from editor.graphicalout import GraphicalOut

u = lambda: globals().update(locals())

def ints(l):
	# convert numpy array to int List
	return [int(x) for x in l]

def floats(l):
	return [float(x) for x in l]

def g(f):
	global editor
	with editor.graphicalout.canvas.before:
		return f()

def to_list(l):
	acc = []
	while l[0] != "PML_Nil":
		acc += [l[1]]
		l = l[2]
	return acc

class GameObj:
	def __init__(self, pos, c,rotate=None):
		self.cs = [c]
		self.p = pos
		
		self.rotate = rotate

		self.o = pos
		self.origin = pos

	def add_child(self, c):
		self.cs += [c]
	
	@property
	def rot(self):
		return self.rotate.angle
	
	@rot.setter
	def rot(self, a):
		self.rotate.angle=a
	
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
		return ints(np.array([xmax,ymax])-np.array([xmin,ymin]))
	
	def mapPos(self, f):
		p = ints(f(np.array(self.pos)))
		dp = np.array(p)-np.array(self.pos)
		self.p = p
		self.origin = p
		for c in self.cs:
			c.pos = ints(np.array(c.pos) + dp)

###### PRIMITIVES

def rect(pos,size,texture=None):
	PushMatrix()
	r=Rotate()
	o=Rectangle(pos=ints(pos),size=ints(size),texture=texture)
	PopMatrix()
	return GameObj(pos, o, r)

def button(text,pos,size):
	return editor.graphicalout.button(
		text,floats(pos),floats(size))

def label(text,pos,size):
	l = Label(text=text,pos=pos,size=size)
	editor.graphicalout.add_widget(l)
	return l

def color(c):
	editor.graphicalout.__class__.color(list(c))

from kivy.graphics import Color, Rectangle


######### VDOM

WIDGETS = {}
n_used=0
ff=True # first frame?
EVENTS = []

def emit_event(name, *args):
	global EVENTS
	EVENTS.append(("PML_"+name, *args))

PRESSED = {}
def btn_press(name):
	global PRESSED
	PRESSED[name]=True
	emit_event("BtnPressed",name)

def btn_rel(name):
	global PRESSED
	PRESSED[name]=False
	emit_event("BtnReleased",name)

def draw(v):
	global n_used, ff

	if v[0] in ["PML_Btn","PML_Label"]:
		_,txt,name,pos,size = v
		if name in WIDGETS:
			[b,_] = WIDGETS[name]
			b.pos=floats(pos)
			b.size=floats(size)
			b.text=txt
			WIDGETS[name][1] = True # used
		elif v[0] == "PML_Btn": # new btn
			b = button(
				txt,floats(pos),floats(size))
			b.bind(
			 on_press=lambda _:btn_press(name))
			b.bind(
		 	on_release=lambda _:btn_rel(name))
			WIDGETS[name] = [b,True]
		elif v[0] == "PML_Label":
			l = label(txt,floats(pos),floats(size))
			WIDGETS[name]=[l,True]
	
	if v[0] in ("PML_Rect", "PML_TRect"):
		_,pos,size,c=v
		tex = None
		if v[0]=="PML_Rect":
			g(lambda:color(c))
		else:
			tex = c
		g(lambda:rect(pos,size,tex))
	if v[0] == "PML_Line":
		_,ps,d,c = v
		ps = list(map(ints, to_list(ps)))
		g(lambda: color(c))
		g(lambda: Line(points=ps,width=d))
	if v[0] == "PML_Many":
	 	_,l=v
	 	for w in to_list(l):
	 		draw(w)

DOUPDATE = False

@curry
def set_tick(state, update, view):

	def helper(s):

		# prep
		global n_used,ff,EVENTS,DOUPDATE
		n_used = 0
		
		# prep events
		EVENTS.append(("PML_Tick",))
		for name in PRESSED:
			if PRESSED[name]:
				emit_event("BtnHeld",name)
		
		# new state
		s_old = s
		while len(EVENTS)>0:
			s = update(EVENTS.pop())(s)
		
		# draw
		if id(s_old) != id(s) or ff or DOUPDATE:
			editor.graphicalout.canvas.before.clear()
			v = view(s)
			for b in WIDGETS:
				WIDGETS[b][1] = False
			draw(v)
			DOUPDATE = False

		# remove old btns
		for b in list(WIDGETS.keys()):
			if not WIDGETS[b][1]:
				WIDGETS[b][0].opacity = 0
				editor.graphicalout.remove_widget(WIDGETS[b][0])
				del WIDGETS[b]

		ff = False
		return s

	editor.graphicalout.setUpdate(state, lambda s: lambda _: helper(s))

import numpy as np
import random
def PML_randPos(_):
	return np.array((random.randint(0,400), random.randint(0,400)))


PML_setTick = set_tick
PML_width = Window.width
PML_height = Window.height
PML_stop = lambda _: editor.graphicalout.clearUpdate()

def PML_forceUpdate(s):
	global DOUPDATE
	DOUPDATE = True
	return s

%%%;

import lib.std;
import lib.image;

type Color = Vec;

data Widget
	= Rect Vec Vec Color
	| TRect Vec Vec Img
	| Btn String String Vec Vec
	| Label String String Vec Vec
	| Line (List Vec) Number Color
	| Many (List Widget)
;

# builtin event type
data Event
	= Tick
	| BtnPressed String
	| BtnReleased String
	| BtnHeld String
;

let setTick : a -> (Event -> a -> a) -> (a -> Widget) -> Unit;

let forceUpdate : state -> state;

let stop : Unit -> Unit;

let staticView : (Unit -> Widget) -> Unit;
let staticView view =
	setTick () (const stop) view;

let width : Number;
let height: Number;

let randPos : Unit -> Vec;

let RED = @(255,0,0,255);
let BLACK = @(0,0,0,255);
let WHITE = @(255,255,255,255);
let BLUE = @(0, 0, 255, 255);
let GREEN = @(0,255,0,255);

module (*)

