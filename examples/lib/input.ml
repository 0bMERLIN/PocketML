%%%
from kivy.clock import Clock

t = editor.terminalout if "editor" in globals() else None
l = len(t.text) if t else 0
res = ""
input_ev = None

def listen(cb):
	def tick(_):
		global t, l, res
		if l != len(t.text):
			res += t.text[l:]
			l = len(t.text)
			if res[-1] == "\n":
				cb(res)
				Clock.unschedule(input_ev)
	input_ev = Clock.schedule_interval(tick,1/10)

def inp(msg, cb):
	global l, res, input_ev
	editor.terminalout.text += msg
	l = len(t.text)
	res = ""
	input_ev = None
	listen(cb)

if "editor" in globals():
	PML_input = lambda m: lambda cb: inp(m,cb)
else:
	PML_input = lambda m: lambda cb: cb(input(m))

%%%;

let input : String -> (String -> Unit) -> Unit;

module (*)

