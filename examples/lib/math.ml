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
PML_round=lambda x:lambda n:round(x,int(n))
PML_mod=lambda x: lambda y: x % y

PML_vecAppend = lambda x: lambda a: np.append(a, x)
PML_vecDeleteAt = lambda i: lambda a: np.delete(a, i)
PML_vecAt = lambda i: lambda a: a[i]
PML_vecSlice = lambda start: lambda end: lambda a: a[start:end]
PML_vecLen = len

%%%;

let sin : Number -> Number;
let cos : Number -> Number;
let tan : Number -> Number;
let pi : Number;
let sign x = if x < 0 then -1 else 1;
let pow : Number -> Number -> Number;
let round : Number -> Number -> Number;
let abs x = if x < 0 then -x else x;
# sum
let rec sigma f a b = if a > b then 0
	else (if a == b then f b else (f a + sigma f (a+1) b));
let fac : Number -> Number;
let exp : Number -> Number;
let min x y = if x < y then x else y;
let max x y = if x > y then x else y;
let mod : Number -> Number -> Number;

let divisible : Number -> Number -> Bool;
let divisible a b = mod a b == 0;

# numpy array vector operations
let vecAppend : Number -> Vec -> Vec;
let vecDeleteAt : Number -> Vec -> Vec;
let vecAt : Number -> Vec -> Number;
let vecSlice : Number -> Number -> Vec -> Vec;
let vecLen : Vec -> Number;

let vecAtSafe : Number -> Number -> Vec -> Number;
let vecAtSafe n d v = if vecLen v <= n || n < 0 then d else vecAt n v;

let vecLast : Vec -> Number;
let vecLast v = vecAt (vecLen v-1) v;

module (*)
