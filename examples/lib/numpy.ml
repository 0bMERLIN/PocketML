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
	if len(convlist(idx)) != len(arr.shape):
		raise Exception(f"lib.numpy: Cannot index into an array with shape {arr.shape} using indices {convlist(idx)}!")
	return arr.item(*convlist(idx))

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

@curry
def PML_ivectorize(func, array):
    result = np.empty_like(array)
    for idx, val in np.ndenumerate(array):
        result[idx] = func(mklist(list(idx)))(val)
    return result

def PML_sum(arr):
	return np.sum(arr)

def PML_flatten(arr):
	return arr.flatten()

@curry
def PML_dot(a,b):
	return np.dot(a,b)

@curry
def PML_reshape(size, arr):
	size=convlist(size)
	return np.reshape(arr,tuple(size))

PML_transpose = np.transpose

def PML_delete(i, arr):
	return np.delete(arr,i)

@curry
def PML_concatenate(ax, a, b):
	try:
		return np.concatenate((a,b),ax)
	except:
		raise Exception("Cannot concatenate on axis " + str(ax))


%%%;
import lib.list (type List, map, zip);
import lib.math (min, max, type Vec);
import lib.util (uncurry2);

## A library for using numpy in PocketML.

### ### Type Aliases
type Size = List Number;
type Index = List Number;

### ### Creating arrays
let array : List Number -> Vec;

let zeros : Size -> Vec;
let full : Size -> Number -> Vec;
let linspace : Number -> Number -> Number -> Vec
	# start, end, nsteps
;


### ### Getters
let toList : Vec -> List Number
	# only 1-dim.!
;

let size : Vec -> Size
	# <=> arr.shape in numpy!
;

let get : Index -> Vec -> Number;
let slice : Index -> Index -> Vec -> Vec
	# - start, end, input_array
	# - fails if out of bounds
;

let sliceInc : Index -> Index -> Vec -> Vec
	# like slice but end index is included.
;
let sliceInc s e a = slice s (map inc e) a;

let slicePartial : Index -> Index -> Vec -> Vec
	# same as slice, but return all
	# elements in index range instead
	# of failing
;
let slicePartial s e a =
	let start = map (max 0) s;
	let end = map (uncurry2 min)$zip (size a) e;
	slice start end a
;

### ### Manipulating `Vec`s
let set : Index -> Number -> Vec -> Vec;

let vectorize : (Number -> Number) -> Vec -> Vec;
let ivectorize : (Index -> Number -> Number) -> Vec -> Vec;

let sum : Vec -> Number;
let dot : Vec -> Vec -> Number;
let flatten : Vec -> Vec;
let delete : Number -> Vec -> Vec
	# args: i, arr
	# remove the element at i
	# only for flat Vecs
;

let concatenate : Number -> Vec -> Vec -> Vec
	# args: axis, arr1, arr2
;

let reshape : Size -> Vec -> Vec;
let transpose : Vec -> Vec;

module (*)
