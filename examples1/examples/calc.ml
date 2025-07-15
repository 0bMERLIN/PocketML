import lib.std;
import lib.parsing;

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

############################## parsing

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

####################### interpreter
let eval : Dict Number -> Exp -> Maybe Number;
let binop : (Number -> Number -> Number) -> Dict Number -> Exp -> Exp -> Maybe Number;

let binop = \f -> \env -> \x -> \y ->
	bind (eval env y) (\a->
	bind (eval env x) (\b->
	Just (f a b)));

let eval = \env -> \exp -> case exp
	| Add x y -> binop add env x y
	| Num myyy -> Just (float myyy)
	| Mul x y -> binop mul env x y
	| Var nm -> dictGet env nm
	| Let nm e b ->
		bind (eval env e) (\eres ->
		eval (dictInsert nm env eres) b)
	| Neg x -> fmap neg (eval env x)
;

######################### tests

let test = "1 + 3";

let res = eval (mkDict ()) (parse test);

let main = print res;

 module (*)

