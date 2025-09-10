import lib.dict;
import lib.string (str);
import lib.maybe;
import lib.list;

%%%

def PML_Mut(m):
	return ["PML_Mut", m]

@curry
def PML_mut(m, f):
	m[1] = f(m[1])

@curry
def PML_read(m):
	return m[1]

%%%;

data Type
	= TApp Type Type
	| TVar String
	| TCon String
;

data Exp
	= Lam String Exp
	| App Exp Exp
	| Var String
	| Num Number
	| Let String Exp Exp
;

data TypeCon = TypeCon Type Type;

# Mutable box, implemented using python FFI
data Mut m;

let Mut : m -> Mut m;
let mut : Mut m -> (m -> m) -> ();
let read : Mut m -> m;

let write : Mut m -> m -> ();
let write m v = mut m (\_ -> v);

#
let newTV : Mut Num -> Type;
let newTV st = do
	mut st inc
	TVar ("t" + str (read st))
;

# operations on types
let frees : Type -> List String;
let frees = \case
	TVar x -> [x]
	| TCon _ -> []
	| TApp a b -> frees a + frees b
;

let subst : String -> Type -> Type -> Type;
let subst x r = \case
	TVar y -> if x == y then r else TVar y
	| TCon y -> TCon y
	| TApp a b -> TApp (subst x r a) (subst x r b)
;

let substConstr : String -> Type -> TypeCon -> TypeCon;
let substConstr x r (TypeCon a b) = TypeCon (subst x r a) (subst x r b);

let inst : Mut Num -> Type -> Type;
let inst tv t =
	let go : Type -> List String -> Type;
	let go t1 = \case
		Nil -> t1
		| Cons f fs -> go (subst f (newTV tv) t1) fs;
	go t (frees t)
;

# generation of type constraints
let constrain : Mut (List TypeCon) -> Type -> Type -> ();
let constrain cs t1 t2 = mut cs (\xs -> Cons (TypeCon t1 t2) xs);

# pre-declare solve for mutual recursion
let solve : List TypeCon -> Type -> Type;

type Ctx = Dict (Bool, Type)
	# Bool indicates if the variable is a type scheme (let-bound)
;

let con : Mut (List TypeCon) -> Mut Num -> Ctx -> Exp -> Maybe Type;
let con cs tv ctx = \case
	Num _ -> Just $ TCon "Num"
	| Let x e b ->
		bind (con cs tv ctx e) $ \eT ->
		# solve constraints so far and wrap in a type scheme
		con cs tv (dictInsert x ctx (True, solve (read cs) eT)) b
	| Var x ->
		fmap
			(\case (isScheme, t) ->
				if isScheme then inst tv t else t)
			(dictGet ctx x)
	| Lam x b ->
		let xT = newTV tv;
		bind (con cs tv (dictInsert x ctx (False, xT)) b) $ \bT ->
		Just $ TApp (TApp (TCon "->") xT) bT
	| App f a ->
		bind (con cs tv ctx f) $ \fT ->
		bind (con cs tv ctx a) $ \aT ->
		let resT = newTV tv;
		let _ = constrain cs fT $ TApp (TApp (TCon "->") aT) resT;
		Just resT
;

# solve type constraints
let unify : Type -> Type -> List TypeCon;
let unify a b = case (a, b)
	| (TApp a1 a2, TApp b1 b2) -> [TypeCon a1 b1, TypeCon a2 b2]
	| (TVar x, TVar y) -> if x == y then [] else [TypeCon a b]
	| (TVar x, _) -> [TypeCon a b]
	| (_, TVar y) -> [TypeCon b a]
	| (TCon x, TCon y) -> if x == y then [] else error ("Cannot unify " + x + " and " + y)
;

let solve cs t = case cs
	| Nil -> t
	| Cons (TypeCon a b) cs1 ->
		(case (a, b)
		| (TVar x, _) -> solve (map (substConstr x b) (tail cs)) (subst x b t)
		| (_, _) -> solve (extend (unify a b) (tail cs)) t)
;

# test
let expr =
	Let "id" (Lam "x" (Var "x"))
	(App (Var "id") (Num 42));

let cs = Mut [];
let t = con cs (Mut 0) dictEmpty expr;
let res = fmap (solve (read cs)) t;
print res
