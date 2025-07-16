%%%

import numpy as np;
# def convlist(l: list) -> tuple available.
# tuple <=> PML linked list sum type.

def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

def PML_array(l: tuple): # -> np array
	return np.array(convlist(l))

@curry
def PML_zeros(size: tuple):
	size = convlist(size)
	return np.zeros(tuple(size))

@curry
def PML_full(size: tuple, n: float):
	size = convlist(size)
	return np.full(tuple(size), n)

@curry
def PML_linspace(start,end,nsteps):
	return np.linspace(start,end,nsteps)

def PML_size(arr):
	s = list(np.shape(arr))
	return mklist(s)

@curry
def PML_get(idx, arr):
	return arr.__getitem__(*convlist(idx))

@curry
def PML_slice(start,end,arr):
	start=convlist(start)
	end=convlist(end)
	# slice a "line" / "rectangle" / "cube"/...
	# out of the array
	slices = tuple(slice(s, e) for s, e in zip(start, end))
	return arr[slices]

def PML_toList(arr):
	return mklist(list(arr))

@curry
def PML_set(idx, x, arr):
	a = arr.copy()
	a.__setitem__(*convlist(idx), x)
	return a

PML_vectorize = np.vectorize

def PML_sum(arr):
	return np.sum(arr)

@curry
def PML_dot(a,b):
	return np.dot(a,b)

@curry
def PML_reshape(size, arr):
	size=convlist(size)
	return np.reshape(arr,tuple(size))

PML_transpose = np.transpose

%%%;
import lib.list (type List, map, zip);
import lib.math (min, max);
import lib.util (uncurry2);

data Array;
type Size = List Number;
type Index = List Number;

# construction
let array : List Number -> Array;

let zeros : Size -> Array;
let full : Size -> Number -> Array;
let linspace : Number -> Number -> Number -> Array
	# start, end, nsteps
;

# getters / info
let toList : Array -> List Number
	# only 1-dim.!
;

let size : Array -> Size # <=> arr.shape in numpy!
;

let get : Index -> Array -> Number;
let slice : Index -> Index -> Array -> Array
	# - start, end, input_array
	# - fails if out of bounds
;

let sliceInc : Index -> Index -> Array -> Array
	# like slice but end index is included.
;
let sliceInc s e a = slice s (map inc e) a;

let slicePartial : Index -> Index -> Array -> Array
	# same as slice, but return all
	# elements in index range instead
	# of failing
;
let slicePartial s e a =
	let start = map (max 0) s;
	let end = map (uncurry2 min)
		$ zip (size a) e;
	slice start end a
;

# operations
let set : Index -> Number -> Array -> Array;
let vectorize : (Number -> Number) -> Array -> Array;
let sum : Array -> Number;
let dot : Array -> Array -> Number;

let reshape : Size -> Array -> Array;
let transpose : Array -> Array;

module (*)
