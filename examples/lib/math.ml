%%%
import math
import numpy as np

PML_sin=math.sin
PML_cos=math.cos
PML_pi=math.pi
PML_pow = lambda a: lambda b: a**b
PML_tan=math.tan
PML_fac=math.factorial
PML_exp=math.exp
PML_ln=math.log
PML_round=lambda x:lambda n:round(x,int(n))
PML_mod=lambda x: lambda y: x % y

PML_vecAppend = lambda x: lambda a: np.append(a, x)
PML_vecDeleteAt = lambda i: lambda a: np.delete(a, i)
PML_vecAt = lambda i: lambda a: a[i]
PML_vecSlice = lambda start: lambda end: lambda a: a[start:end]
PML_vecLen = len
PML_vecIMap = lambda f: lambda v: np.array(list(map(lambda t:f(t[0])(t[1]),enumerate(list(v)))))
PML_vecZeros = lambda l: np.zeros(l)
PML_vecFromList = lambda l: np.array(convlist(l))

import numpy as np

def fade(t):
    return 6*t**5 - 15*t**4 + 10*t**3

def lerp(a, b, t):
    return a + t * (b - a)

def gradient(h, x, y):
    vectors = np.array([[0,1],[0,-1],[1,0],[-1,0],
                        [1,1],[-1,1],[1,-1],[-1,-1]])
    g = vectors[h % 8]
    return g[0] * x + g[1] * y

def PML_noise(v, seed=0):
    x,y=list(v*10)
    # Create permutation table
    rng = np.random.default_rng(seed)
    p = np.arange(256, dtype=int)
    rng.shuffle(p)
    p = np.concatenate([p, p])
    
    # Integer coords
    xi = int(np.floor(x)) & 255
    yi = int(np.floor(y)) & 255
    xf = x - np.floor(x)
    yf = y - np.floor(y)
    
    u = fade(xf)
    v = fade(yf)
    
    # Hash coordinates of the 4 corners
    aa = p[p[xi] + yi]
    ab = p[p[xi] + yi + 1]
    ba = p[p[xi + 1] + yi]
    bb = p[p[xi + 1] + yi + 1]
    
    # Calculate gradients and interpolate
    x1 = lerp(gradient(aa, xf, yf),
              gradient(ba, xf - 1, yf), u)
    x2 = lerp(gradient(ab, xf, yf - 1),
              gradient(bb, xf - 1, yf - 1), u)
    
    return (lerp(x1, x2, v) + 1) / 2

%%%;

import lib.util (not, const);

## Advanced mathematical functions, functions on `Number`s

### ### Trig
let sin : Number -> Number;
let cos : Number -> Number;
let tan : Number -> Number;
let pi : Number;

### ### Misc.
let sign x = if x < 0 then -1 else 1;
let pow : Number -> Number -> Number;
let round : Number -> Number -> Number; # x n_digits
let abs x = if x < 0 then -x else x;
let ln : Number -> Number;

# sum
let rec sigma f a b = if a > b then 0
	else (if a == b then f b else (f a + sigma f (a+1) b));
let fac : Number -> Number;
let exp : Number -> Number;

let min : Number -> Number -> Number;
let min x y = if x < y then x else y;

let max : Number -> Number -> Number;
let max x y = if x > y then x else y;

### ### Predicates / Checking properties of numbers

let mod : Number -> Number -> Number;

let divisible : Number -> Number -> Bool; # a divisible by b?
let divisible a b = mod a b == 0;

let odd : Number -> Bool;
let odd x = not (divisible x 2);

let even : Number -> Bool;
let even x = divisible x 2;

### ### Random

let noise : Vec -> Number;

module (*)
