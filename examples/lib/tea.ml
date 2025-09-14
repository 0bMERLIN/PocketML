import lib.shaders;

%%%from kivy.graphics import Color,Rectangle,Ellipse,Rotate,PushMatrix,PopMatrix,Scale,Line
from kivy.uix.button import Button
from kivy.core.window import Window
from kivy.uix.label import Label
import numpy as np

from kivy.app import App
from kivy.uix.widget import Widget
from kivy.graphics import RenderContext, Rectangle
from kivy.core.window import Window
from kivy.clock import Clock

from kivy.resources import resource_find
from kivy.graphics.opengl import *
from kivy.graphics.texture import Texture
from kivy.graphics import Callback,BindTexture

from kivy.uix.boxlayout import BoxLayout;

from kivy.uix.colorpicker import ColorWheel

class SRectWidget(Widget):
	def __init__(self, src, **kwargs):
		self.canvas = RenderContext()
		super().__init__(**kwargs)
		
		with self.canvas:	
			self.rect = Rectangle(pos=self.pos, size=self.size)
		self.bind(pos=self.update_rect, size=self.update_rect)
		self.canvas.shader.fs = src
		if self.canvas.shader.success == 0:
			PML_print(checkshader(src))
		
	def update_rect(self, *args):
		self.rect.pos = self.pos
		self.rect.size = self.size


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

###### PRIMITIVES / HELPERS

class CustomColorPicker(Widget):
	def __init__(self, name, size=(200,200), pos=(0,0)):
		super().__init__()
		self.name = name
		self.size = size
		self.pos = pos
		x, y = pos
		w, h = size

		# Sliders
		labels = list(reversed(["R", "G", "B", "A"]))
		self.sliders = []
		for i, label_text in enumerate(labels):
			label = Label(
				text=label_text,
				pos=(x, y + i * h / 5),
				size=(w / 5, h / 5),
				halign="right",
				valign="middle"
			)
			self.add_widget(label)
			slider = Slider(
				min=0, max=1, value=1, step=.01,
				pos=(x + w / 5, y + i * h / 5),
				size=(w * 2 / 5, h / 5)
			)
			self.add_widget(slider)
			slider.bind(value=lambda _, v: self.color_picked())
			self.sliders.append(slider)

		# Color wheel
		self.color_wheel = ColorWheel(
			size=(w / 2, w / 2),
			size_hint=(None,None),
			pos=(x + w / 1.5, y+1000)
		)

		Clock.schedule_once(lambda *_: self.position_color_wheel(x,y,w,h), .5)

		self.add_widget(self.color_wheel)
		self.color_wheel.bind(color=lambda _, v: self.on_wheel_color(v))

		# Rectangle to display the current color
		with self.canvas:
			self.color_instruction = Color(1, 1, 1, 1)
			self.color_rect = Rectangle(
				pos=(x + w / 5, y + 4 * h / 5),
				size=(w * 4 / 5, h / 5)
			)
	
	def position_color_wheel(self,x,y,w,h):
		self.color_wheel.pos = (x + w / 1.5, y)

	def on_wheel_color(self, v):
		# Update sliders and color rectangle when color wheel changes
		for i, val in enumerate(reversed(v)):
			self.sliders[i].value = val
		self.color_picked()
		
	def color_picked(self):
		v = [s.value for s in reversed(self.sliders)]
		self.color_instruction.rgba = tuple(v)
		emit_event("ColorPicked", self.name, np.array(v) * 255)

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

from kivy.uix.slider import Slider

def color(c):
	editor.graphicalout.__class__.color(list(c))

from kivy.graphics import Color, Rectangle

######### WIDGET MANAGEMENT
def init_btn(name,txt,size,pos):
	b = button(txt,floats(pos),floats(size))
	b.bind(on_press=lambda _:btn_press(name))
	b.bind(on_release=lambda _:btn_rel(name))
	return b

def update_btn(b,name,txt,size,pos):
	b.pos=floats(pos)
	b.size=floats(size)
	b.text=txt

def init_slider(name,
		min, max, step, value, size, pos):
	s = Slider(min=min, max=max,
		value=value,pos=floats(pos),size=floats(size))
	editor.graphicalout.add_widget(s)
	s.bind(value=lambda _,v:slider_move(name,v))
	return s

def update_slider(s,name,
		min, max, step, value, size, pos):
	s.pos,s.size,s.min,s.max,s.step=floats(pos), floats(size),min, max, step

def init_label(name,txt,size,pos):
	return label(txt,floats(pos),floats(size))

def update_label(l,name,txt,size,pos):
	l.text=txt
	l.pos=floats(pos)
	l.size=floats(size)

def init_srect(src,_,size,pos):
	pos = pos - np.array([Window.width,Window.height]) / 2
	s = SRectWidget(
		src=src,
		size=floats(2*size/np.array([Window.width,Window.height])),
		pos=floats(2*pos/np.array([Window.width,Window.height]))
	)
	editor.graphicalout.add_widget(s)
	return s

def update_srect(s, src,_,size,pos):
	pos = pos - np.array([Window.width,Window.height]) / 2
	s.src = src
	s.size = floats(2*size/np.array([Window.width,Window.height]))
	s.pos = floats(2*pos/np.array([Window.width,Window.height]))

def init_colpicker(name, size,pos):
	c = CustomColorPicker(name, size=floats(size),pos=floats(pos))
	editor.graphicalout.add_widget(c)
	return c

def update_colpicker(c,_,size,pos):
	c.pos=floats(pos)
	c.size=floats(size)

UPDATERS = {
	"PML_Btn": update_btn,
	"PML_Slider": update_slider,
	"PML_Label": update_label,
	"PML_SRect": update_srect,
	"PML_ColorPicker": update_colpicker
}

# create widget objects
INITIALIZERS = {
	"PML_Btn": init_btn,
	"PML_Slider": init_slider,
	"PML_Label": init_label,
	"PML_SRect": init_srect,
	"PML_ColorPicker": init_colpicker
}

######### VDOM / EVENTS

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

def slider_move(name,v):
	emit_event("SliderMoved",name,v)

from kivy.core.image import Image as CoreImage

def draw(v):
	global n_used, ff

	if v[0] in INITIALIZERS:
		name=v[1]
		if name in WIDGETS:
			[x,_] = WIDGETS[name]
			UPDATERS[v[0]](x,*v[1:])
			WIDGETS[name][1] = True # used
		else: # new btn
			x = INITIALIZERS[v[0]](*v[1:])
			WIDGETS[name] = [x,True]
	
	if v[0] == "PML_SRect":
		uniforms = convlist(v[2])
		s = WIDGETS[v[1]][0]
		
		for typ, name, value in uniforms:
			if typ == "PML_UniformFloat":
				s.canvas[name] = value
			if typ == "PML_UniformInt":
				s.canvas[name] = int(value)
			if typ.startswith("PML_UniformVec"):
				n = int(typ[-1])
				if len(value) != n:
					raise Exception(
						f"[uniformError] Cannot set uniform vec{n} to a Vec of length {len(value)}"
					)
				s.canvas[name] = tuple(floats(value))
			if typ == "PML_UniformTex0":
				s.rect.texture = value
	
	if v[0] in ("PML_Rect", "PML_TRect"):
		_,c,size,pos=v
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

	def on_mouse_up(window, x, y, button, modifiers):
		global PRESSED
		PRESSED = {}
	
	Window.bind(on_mouse_up=on_mouse_up)

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
				w = WIDGETS[b][0]
				w.opacity = 0
				w.pos=(Window.width*100,0)
				editor.graphicalout.remove_widget(WIDGETS[b][0])
				del WIDGETS[b]

		ff = False
		return s

	editor.graphicalout.setUpdate(state, lambda s: lambda _: helper(s))

import numpy as np
import random
def PML_randPos(_):
	return np.array((random.randint(0,400), random.randint(0,400)))


PML_app = set_tick
PML_width = Window.width
PML_height = Window.height
PML_stop = lambda _: editor.graphicalout.clearUpdate()

def PML_forceUpdate(s):
	global DOUPDATE
	DOUPDATE = True
	return s

@curry
def PML_setPos(w, p):
	w.pos = p

def PML_getFPS(_):
	return Clock.get_rfps()

%%%;

import lib.std;
import lib.image;

## Graphics framework inspired by TEA. Uses kivy and VDOM-diffing internally. Supports GUIs, canvas graphics & shaders


### ### Types
type Color = Vec
	# Alias used for clarity. Vec of length 4.
;

data Uniform
	= UniformFloat String Number
	| UniformInt String Number
	| UniformVec2 String Vec
	| UniformVec3 String Vec
	| UniformVec4 String Vec
	| UniformTex0 String Img

	# Uniform types for shaders. Arguments: uniformName, value
;

data Widget
	= Rect Color Vec Vec
	| TRect Img Vec Vec
	| SRect String (List Uniform) Vec Vec
	| Btn String String Vec Vec
	| Slider String Number Number Number Number Vec Vec
	| Label String String Vec Vec
	| Line (List Vec) Number Color
	| Many (List Widget)
	| ColorPicker String Vec Vec
;
###>| Attributes for Widgets | |
###>|-|-|
###>| Rect | color, size, pos |
###>| TRect | texture, size, pos |
###>| Btn   | name, text, size, pos |
###>| Slider| name, min, max, step, value, size, pos |
###>| Label | name, text, size, pos |
###>| Line  | polygon-points, width, color |
###>| Many  | children |

# builtin event type
data Event
	= Tick
	| BtnPressed String
	| BtnReleased String
	| BtnHeld String
	| SliderMoved String Number
	| ColorPicked String Color
	# Event type for the `tick` function in the app. Make sure pattern matching on
	# events is exhaustive, so `tick` does not throw an error.
;

### ### Starting the App

let app : state -> (Event -> state -> state) -> (state -> Widget) -> Unit
	# starts an app given an initial `state`, `tick` and `view`
;

let forceUpdate : state -> state;

###>The view gets updated based on the state. The app assumes that
###>view is pure: It always returns the same Widgets for the same state.
###>When side effects do need to be used for some reason, the `tick` function
###>can request an update.
###>
###>Example:
###>```
###>let view _ = Label "time" (str $ time ()) @(200, 200) @(0, 0);
###>let tick _ _ = forceUpdate (); # Note that the state is Unit and constant.
###>setTick () tick view
###>```

let stop : Unit -> Unit
	# Effectful.
	# Stops the app. Takes effect on the next tick, the current tick is stil executed.
;

###>Example:
###>```
###>let tick event state = do
###>	if state > 1000 then stop ()
###>	inc state;
###>
###>let view state = Label "mylabel" (str state) @(200, 200) @(0, 0);
###>
###>setTick 0 
###>```
###

### ### Basic kinds of apps / patterns

let staticView : (Unit -> Widget) -> Unit
	# Renders a view and then halts the app.
	# Use for graphing, etc.
;
let staticView view =
	app () (const stop) view;

### ### Getters

let width : Number;
let height: Number;
let top = height - height*.1;
let getFPS : Unit -> Number;

### ### Positioning / layouts
let setPos : Widget -> Vec -> Unit;
let randPos : Unit -> Vec;

let grid : Vec -> Vec -> Num -> Num -> List (Vec -> Widget) -> Widget;
let grid pos spacing nx ny elems =
	Many (imap (\i e ->
		let y = int (i / nx);
		let x = i - y*nx;
		e ( pos + @(x,y) * spacing )
	) elems)
;

### ### Colors & constants
let red : Color;
let red = @(255,0,0,255);

let black : Color;
let black = @(0,0,0,255);

let white : Color;
let white = @(255,255,255,255);

let blue : Color;
let blue = @(0, 0, 255, 255);

let green : Color;
let green = @(0,255,0,255);

let yellow : Color;
let yellow = @(255, 255, 0, 255);

module (*)

