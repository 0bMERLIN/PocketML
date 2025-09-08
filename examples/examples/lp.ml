import lib.dict;
import lib.either;
import lib.maybe as M;
import lib.util (error, when, cls);
import lib.string (str, strip);
import lib.parsing;
import lib.list (len);
import lib.input;

let gr= '

?start: expr

?expr: term "+" expr -> add
	| term

?term: term atom -> app
	| atom

?atom: NAME -> var
	| "(" NAME ":" expr ")" "->" expr -> lam
	| "Pi" "(" NAME ":" expr ")" "->" expr -> pi
	| "Let" NAME "=" expr ";" expr -> let
	| "*" -> star
	| "Nat" -> nat
	| NUMBER -> nat_lit

NAME: /[a-z_][a-zA-Z0-9_]*/
NUMBER: /-?\d+(\.\d+)?/

%import common.WS
%import common.CNAME
%ignore WS
';

data Term
    = Var String
    | Lam String Term Term
    | Pi String Term Term
    | App Term Term
    | Star
    | Nat
    | NatLit Number
    | Let String Term Term
    | Add Term Term
;

type Ctx = Dict Term;

let subst : String -> Term -> Term -> Term;
let subst s r = \case
    Var x -> if x == s then r else Var x
    | App f a -> App (subst s r f) (subst s r a)
    | Lam x t b -> Lam x (subst s r t) (subst s r b)
    | Pi x t b -> Pi x (subst s r t) (subst s r b)
    | Let x e b -> Let x (subst s r e) (subst s r b)
    | Add a b -> Add (subst s r a) (subst s r b)
    | o -> o
;

let betaReduce : Term -> Term;
let betaReduce = \case
	App (Lam x t b) a -> subst x a b
	| App f a -> App (betaReduce f) (betaReduce a)
	| Lam x t a -> Lam x (betaReduce t) (betaReduce a)
	| Pi x t a -> Pi x (betaReduce t) (betaReduce a)
	| Add a b -> (case (betaReduce a,betaReduce b)
		| (NatLit n, NatLit m) -> NatLit (n+m)
		| (x,y) -> Add x y)
    | t -> t
;

let normalForm : Term -> Term;
let normalForm t =
	let b = betaReduce t;
	if b == t then t else normalForm b
;

let alphaEquiv : Dict Num->Dict Num->Term->Term->Bool;
let alphaEquiv c1 c2 t1 t2 = case (t1, t2)
	| (Var x, Var y) ->
		(case (dictGet c1 x, dictGet c2 y)
			| (Just v1, Just v2) -> v1 == v2
			| (Nothing, Nothing) -> x == y
			| _ -> False)
	| (App m n, App p q) ->
		alphaEquiv c1 c2 m p && alphaEquiv c1 c2 n q
	| (Lam x1 t1 b1, Lam x2 t2 b2) ->
		let l = len (dictItems c1);
		alphaEquiv c1 c2 t1 t2 && alphaEquiv
			(dictInsert x1 c1 l)
			(dictInsert x2 c2 l)
			b1 b2
	| (Pi x1 t1 b1, Pi x2 t2 b2) ->
		let l = len (dictItems c1);
		alphaEquiv c1 c2 t1 t2 && alphaEquiv
			(dictInsert x1 c1 l)
			(dictInsert x2 c2 l)
			t1 t2
	| (Add m n, Add p q) ->
		alphaEquiv c1 c2 m p && alphaEquiv c1 c2 n q
	| (x, y) -> x == y
;

let betaEquiv : Term -> Term -> Bool;
let betaEquiv t1 t2 = alphaEquiv dictEmpty dictEmpty
	(normalForm t1) (normalForm t2);

let typ : Ctx -> Term -> Either String Term;
let typ c = \case
    Var x -> fromMaybe
    	("variable "+x+" not found.")
    	(dictGet c x)
    | Lam x t b ->
    	bind (typ (dictInsert x c t) b) (\bT ->
        Right (Pi x t bT))
    | Pi x t b -> Right Star
    | App f a ->
    	bind (typ c f) $ \fT ->
    	(case fT
        | Pi x t b ->
			bind (typ c a) $ \aT ->
			if not $ betaEquiv t aT
			then Left ("Type mismatch: " + str t
					+ ", " + str aT)
            else Right (subst x a b)
		| o -> Left
			("expected a Pi-type, got " + str o))
    | Nat -> Right Star
    | NatLit _ -> Right Nat
    | Let x e b ->
    	bind (typ c e) $ \t ->
    	typ (dictInsert x c t) b
    | Add x y ->
    	bind (typ c x) $ \xT ->
    	bind (typ c y) $ \yT ->
    	if not (betaEquiv xT yT &&
    		betaEquiv xT Nat)
    	then Left
    		("Type mismatch: Expected Nat and Nat"
    		+ ", got " + str xT +" and " +str yT)
    	else Right Nat
	| o -> Left (str o + " is not a valid term.")
;

let parse = unRight (parser gr);

# REPL
let rec inputLoop = \_ ->
	input "dep>" (\src ->
		let _ = print src;
		let _ = if strip src == "cls"
			then cls()
			else
				let res = bind (parse src)
					(typ dictEmpty);
				print res;
		inputLoop ())
;

inputLoop ()