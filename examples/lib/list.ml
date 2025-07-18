%%%
import time

def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

@curry
def mymap(f,l):
	acc = []
	while l[0] != "PML_Nil":
		acc += [f(l[1])]
		l = l[2]
	return mklist(acc)

@curry
def PML_foldr(f,acc,l):
	while l[0] != "PML_Nil":
		acc = f(acc)(l[1])
		l = l[2]
	return acc

def PML_imap(f, i=0):
	def inner(l):
		if l[0] == "PML_Nil":
			return ("PML_Nil",)
		else:
			return ("PML_Cons",f(i)(l[1]),PML_imap(f,i=i+1)(l[2]))
	return inner

def PML_reverse(l):
	return mklist(list(reversed(convlist(l))))

@curry
def PML_contains(x,l):
	py_l = PML_foldr(lambda acc: lambda y: acc+[y],[],l)
	return x in py_l

def PML_nub(l):
	acc = []
	pyl = convlist(l)
	for x in pyl:
		if x not in acc:
			acc += [x]
	return mklist(acc)

PML_range = lambda a: lambda b: mklist([*range(int(a),int(b))])
PML_srange = lambda a: lambda b: lambda s: mklist([*range(int(a),int(b),int(s))])
PML_map = mymap
PML_sort = lambda l: mklist(sorted(convlist(l)))

def PML_error(msg):
	raise Exception("PocketML Runtime Error: "+str(msg))

@curry
def PML_chunksOf(n,l):
	cur = []
	acc = []
	for x in convlist(l):
		cur += [x]
		if len(cur) >= n:
			acc += [mklist(cur)]
			cur=[]
	return mklist(acc)

@curry
def PML_take(n,l):
	acc= []
	while n > 0 and l[0] != "PML_Nil":
		if l[0] == "PML_Cons":
			acc += [l[1]]
			l = l[2]
		n-=1
	return mklist(acc)

%%%;

import lib.maybe;
import lib.util (times);

data List a
	= Cons a (List a)
	| Nil
	# The default list type generated
	# by `[...]`
;

let error : String -> a;

let range : Number -> Number -> List Number;
let srange : Number -> Number -> Number -> List Number
	# start, end, step
;
let sort : List a -> List a;

let append : a -> List a -> List a;
let rec append a l = case l
	| Cons x xs -> Cons x (append a xs)
	| Nil -> Cons a Nil;

let foldr : (b -> a -> b) -> b -> List a -> b;

let extend : List a -> List a -> List a;
let extend l xs = foldr (\acc x -> append x acc) l xs;

let concat : List (List a) -> List a;
let concat = foldr (\acc l -> extend acc l) [];

let reverse : List a -> List a;

let map : (a -> b) -> (List a) -> List b;

let foreach2D : Number -> Number -> (Number->Number-> Unit) -> Unit; # w h f
let foreach2D w h f = 
	let _ = map (\x ->
		map (\y -> f x y) (range 0 w))
		(range 0 w);
	();

let nub : List a -> List a;

let imap : (Number -> a -> b) -> List a -> List b;

let any : List Bool -> Bool;
let any = foldr or False;

let head : List a -> a;
let head l = case l
	| Cons x xs -> x
	| Nil -> error "head on empty list";

let tail : List a -> List a;
let tail l = case l
	| Cons x xs -> xs
	| Nil -> error "tail on empty list";

let tailSafe : List a -> List a;
let tailSafe l = case l
	| Cons x xs -> xs
	| Nil -> Nil;

let len : List a -> Number;
let rec len = \case
	  Cons _ l -> 1 + (len l)
	| Nil -> 0;

let listAtSafe : Number -> List a -> Maybe a;
let listAtSafe n l = if n > 0
	then listAtSafe (n-1) (tailSafe l)
	else (if len l == 0 then Nothing else Just (head l));

let listAt : Number -> List a -> a;
let listAt i l = case listAtSafe i l
	| Just x -> x
	| Nothing -> error "Index out of bounds.";

let zip : List a -> List b -> List (a,b);
let rec zip xs ys =
	if len xs == 0 || len ys == 0
	then []
	else Cons
		((head xs), (head ys))
		(zip (tail xs) (tail ys));

let take : Number -> List a -> List a;

let chunksOf : Number -> List a -> List (List a);

let contains : a -> List a -> Bool;

let filter : (a -> Bool) -> List a -> List a;
let filter f l = foldr (\acc x -> if f x then append x acc else acc) [] l;

module (*)