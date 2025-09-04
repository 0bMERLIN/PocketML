%%%
def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

def PML_dictItems(d):
	acc = []
	for k,v in d.items():
		acc += [{"_0": k,"_1": v}]
	return mklist(acc)

def PML_mkDict(t):
	if t == None: return {}
	xs = convlist(t)
	acc = {}
	for e in xs:
		k = e["_0"]
		v = e["_1"]
		acc[k]=v
	return acc

PML_dictGet =  lambda d: (lambda k: ("PML_Just", d[k]) if k in d else ("PML_Nothing",))
PML_dictInsert = lambda s:lambda d:lambda x: dict(list(d.items())+[(s,x)])
PML_dictEmpty = {}
%%%;

## Dictionaries with `String`-keys. Internally python dicts.

data List a
	# --hide
;
data Maybe a
	# --hide
;

### ### Creation

data Dict a;


let mkDict : List (String, a) -> Dict a;

### ### Accessing

let dictItems : Dict a -> List (String, a);

let dictGet : Dict a -> String -> Maybe a;
let dictInsert : String -> Dict a -> a -> Dict a;
let dictEmpty : Dict a;
let dictEmpty = mkDict [];

module (*)