data Kind = KStar | KArr Kind Kind;

data Type
	= TApp Type Type
	| TVar String # both tvars and constructors
	| TArr Type Type
;

data Exp
	= Lam String Exp
	| App Exp Exp
	| Var String
	| Num Number
;

data Con = Eq Type Type;
data Ctx = Ctx (Dict Type) (Dict Kind);

import lib.state;
let myst =
	bind get $ \s ->
	bind (set (s + 4)) $ \_ ->
	pure ()
;

print $ runState 0 myst
