%%%
from kivy.clock import Clock

t = editor.terminalout if "editor" in globals() else None
l = len(t.text) if t else 0
res = ""
input_ev = None

def listen(cb,msg):
	def tick(_):
		global t, l, res
		if l != len(t.text):
			res += t.text[l:]
			l = len(t.text)
			if res[-1] == "\n":
				try:
					cb(t.text.split(msg)[-1])
				except Exception as e:
					print("Runtime error in input callback:", e)
				Clock.unschedule(input_ev)
	input_ev = Clock.schedule_interval(tick,1/10)

def inp(msg, cb):
	try:
		global l, res, input_ev
		editor.terminalout.text += msg
		l = len(t.text)
		res = ""
		input_ev = None
		listen(cb, msg)
	except Exception as e:
		print("Runtime error:", e)

if "editor" in globals():
	PML_input = lambda m: lambda cb: inp(m,cb)
else:
	PML_input = lambda m: lambda cb: cb(input(m))

%%%;

## Simple binding for getting input from terminalout.

let input : String -> (String -> Unit) -> Unit;

module (*)

