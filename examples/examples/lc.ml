import lib.parsing;

let parse = parser '

?start: expr

?expr: atom
	| expr atom -> app

?atom: name -> var
	| name "->" expr -> lam
	| num
	| "(" expr ")"

?name: /[a-zA-Z_+\-*\/=<>!?][a-zA-Z0-9_+\-*\/=<>!?]*/

num: /-?\d+(\.\d+)?/

%import common.WS
%ignore WS

';

import lib.util;
import lib.list;
import lib.either;
import lib.dict;

data Exp
	= Num String
	| Var String
	| App Exp Exp
	| Lam String Exp;

data Value
	= Clos (Dict Value) String Exp
	| Fun (Value -> Either String Value)
	| Atom Number;

let apply eval fv av = case fv
	| Fun f -> f av
	| Clos c p e -> eval (dictInsert p c av) e
	| _ -> Left "Cannot apply non function"
;

let eval : Dict Value -> Exp -> Either String Value;
let eval ctx e = case e
	| Num s -> pure $ Atom (float s)
	| Var x ->
		fromMaybe ("Variable "+x+" not found!")
		(dictGet ctx x)
	| Lam p x -> pure $ Clos ctx p x
	| App f arg ->
		bind (eval ctx f) $ \fv ->
		bind (eval ctx arg) $ \av ->
		apply eval fv av
	| _ -> pure (Atom (-1))
;

# ======≠===== test
let binop f = Fun (\case Atom x -> pure $
		Fun (\case Atom y ->
			pure $ Atom (f x y)));

let env = mkDict [
	("pi", Atom 3),
	("inc", Fun
		(\case Atom x -> pure $ Atom (x + 1))),
	("add", binop add)
];

let s = "inc 1";

let tree = unRight $ unRight parse s;
let _ = do
	print tree
	print $ eval env tree
;

module (*)
