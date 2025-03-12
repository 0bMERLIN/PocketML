import std;
import parsing;

#########################################
let grammar = """
?start: sum
	| "let" NAME "=" sum ";" sum -> let

?sum: product
	| sum "+" product   -> add
    | sum "-" product   -> sub

?product: atom
    | product "*" atom  -> mul
    | product "/" atom  -> div

?atom: NUMBER           -> num
     | "-" atom         -> neg
     | NAME 		    -> var
     | "(" sum ")"

%import common.CNAME -> NAME
%import common.NUMBER
%import common.WS_INLINE
%ignore WS_INLINE
""";

#########################################

let _ = setreclimit 3000;

data Exp
	= Add Exp Exp
	| Mul Exp Exp
	| Neg Exp
	| Num String
	| Let String Exp Exp
	| Var String;

let parse : String -> Exp;
let parse = parser grammar;

let eval : (Dict Number)-> Exp -> Maybe Number;
let binop : (Number -> Number -> Number)->(Dict Number) -> Exp -> Exp -> Maybe Number;

let binop = \f -> \env -> \x -> \y ->
	bind (eval env y) (\a->
	bind (eval env x) (\b->
	Just (f a b)));

let eval = \env -> \exp -> case exp
	| Num m -> Just (float m)
	| Add x y -> binop add env x y
	| Mul x y -> binop mul env x y
	| Var nm -> dictGet env nm
	| Let nm e b ->
		bind (eval env e) (\eres ->
		eval (dictInsert nm env eres) b)
	| Neg x -> fmap neg (eval env x)
;

#########################################

let test = parse 
	"let x = 2 + 4; x * 2";

let res = eval (dict ()) test;
let _ = print res;

module (*)

