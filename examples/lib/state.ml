%%%
def mkSt(x):
	class State:
		def __init__(self, x): self.x = x
	return State(x)

def setSt(x):
	def inner(s):
		s.x = x
	return inner

def mapSt(f):
	def inner(s):
		s.x = f(s.x)
	return inner
	
def getSt(s):
	return s.x

PML_getSt = getSt
PML_mkSt = mkSt
PML_setSt = setSt
PML_mapSt = mapSt

%%%;

data State a;
let mkSt : a -> State a;
let mapSt : (a -> a) -> (State a) -> Unit;
let setSt : a -> (State a) -> Unit;
let getSt : (State a) -> a;
module (*)