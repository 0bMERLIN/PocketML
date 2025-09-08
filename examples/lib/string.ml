%%%

def mklist(xs):
	acc = ("PML_Nil",)
	for x in reversed(xs):
		acc = ("PML_Cons",x,acc)
	return acc

PML_split = lambda cs: lambda s: mklist(s.split(cs))
PML_replace = lambda o: lambda n: lambda s: s.replace(o,n)
PML_isNumeric = lambda s: s.isnumeric()
PML_strIn = lambda a: lambda b: a in b
PML_strLen = lambda s: len(s)
PML_str = str
PML_strHead = lambda s: s[0]
PML_strTail = lambda s: s[1:]
PML_strip = lambda s: s.strip()
%%%;

## Functions for working with the builtin `String` type.

data List a
	# --hide
;

let str : a -> String;
let split : String -> String -> List String;# chars str -> list
let replace : String -> String -> String -> String; # old new str
let strip : String -> String;
let isNumeric : String -> Bool;
let strIn : String -> String -> Bool; # a b, check if a is any of the characters in b
let strLen : String -> Number;
let strHead : String -> String;
let strTail : String-> String;

module (*)
