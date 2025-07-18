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
	xs = list(t.values())
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

data List a;
data Maybe a;

data Dict a;

let mkDict : a -> Dict b
# WARNING: `a` should always be a record.
;

let dictEmpty : Dict a;

let dictItems : Dict a -> List (String, a);

let dictGet : Dict a -> String -> Maybe a;
let dictInsert : String -> Dict a -> a -> Dict a;

module (*)