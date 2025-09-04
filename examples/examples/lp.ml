import lib.dict;
import lib.maybe;
import lib.util (error, when);
import lib.string (str);

data Term
    = Var String
    | Lam String Term Term
    | Pi String Term Term
    | App Term Term
    | Star
    | Nat
    | NatLit Number
;

type Ctx = Dict Term;

let subst : String -> Term -> Term -> Term;
let subst s r = \case
    Var x -> if x == s then r else Var x
    | App f a -> App (subst s r f) (subst s r a)
    | Lam x t b -> Lam x (subst s r t) (subst s r b)
    | Pi x t b -> Pi x (subst s r t) (subst s r b)
    | o -> o
;

let betaReduce : Term -> Term;
let betaReduce = \case
	App (Lam x t b) a -> subst x a b
	| App f a -> App (betaReduce f) (betaReduce a)
	| Lam x t a -> Lam x (betaReduce t) (betaReduce a)
	| Pi x t a -> Pi x (betaReduce t) (betaReduce a)
    | t -> t
;

let normalForm : Term -> Term;
let normalForm t =
	let b = betaReduce t;
	if b == t then t else normalForm b
;

let alphaEquiv : Dict Num -> Dict Num -> Term -> Term -> Bool;
let alphaEquiv c1 c2 t1 t2 = case (t1, t2)
	| (Var x, Var y) ->
		(case (dictGet c1 x, dictGet c2 y)
			| (Just v1, Just v2) ->
				let _ = print ("v1,v2: " + str v1 + ", " + str v2);
				v1 == v2
			| (Nothing, Nothing) ->
				let _ = print ("x,y: " + str x + ", " + str y);
				x == y
			| _ -> False
		)
	| (App m n, App p q) ->
		alphaEquiv c1 c2 m p && alphaEquiv c1 c2 n q
	| (Lam x1 t1 b1, Lam x2 t2 b2) ->
		let l = len (dictItems c1);
		let tres = alphaEquiv c1 c2 t1 t2;
		let bres =  alphaEquiv
			(dictInsert x1 c1 l)
			(dictInsert x2 c2 l)
			b1 b2;
		let _ = print ("tres,bres: " + str tres + ", " + str bres);
		tres && bres
	| (Pi x1 t1 b1, Pi x2 t2 b2) ->
		let l = len (dictItems c1);
		alphaEquiv c1 c2 t1 t2 && alphaEquiv
			(dictInsert x1 c1 l)
			(dictInsert x2 c2 l)
			t1 t2
	| (x, y) -> x == y
;

let betaEquiv : Term -> Term -> Bool;
let betaEquiv = alphaEquiv dictEmpty dictEmpty;

let typ : Ctx -> Term -> Term;
let typ c = \case
    Var x -> (case dictGet c x
        | Just res -> res
        | Nothing -> error "variable not found.")
    | Lam x t b ->
        Pi x t (typ (dictInsert x c t) b)
    | Pi x t b -> Star
    | App f a -> (case typ c f
        | Pi x t b ->
			let aT = typ c a;
			let _ = when (not $ betaEquiv t aT) (\_ ->
				error ("Type mismatch: " + str t + ", " + str aT));
            subst x a b
		| o -> error ("expected a Pi-type, got " + str o))
    | Nat -> Star
    | NatLit _ -> Nat
    | o -> error (str o + " is not a valid term.")
;

print $ typ dictEmpty
	(App
		(App
			(Lam "a" Star (Lam "x" (Var "a") (Var "x")))
			Nat)
		(Lam "_" Nat (NatLit 10)))


