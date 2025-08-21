import lib.list;

## Maybe type with monad implementation

### ### Type & Creating / unwrapping
data Maybe a = Nothing | Just a;

let maybe : a -> Maybe a -> a;
let maybe d m = case m
	| Just x -> x
	| Nothing -> d;


### ### Monad implementation
let flatMap : (a -> Maybe b) -> Maybe a -> Maybe b;
let flatMap f m = case m
	| Just x -> f x
	| Nothing -> Nothing;

let bind : Maybe a -> (a -> Maybe b) -> Maybe b;
let bind x y = flatMap y x;

let pure : a -> Maybe a;
let pure = Just;

let fmap : (a -> b) -> Maybe a -> Maybe b;
let fmap g = flatMap (g >> pure);

let mapM : (a -> Maybe b) -> List a -> Maybe (List b);
let mapM f l = case l
	| Cons x xs ->
		bind (f x) $ \y ->
		bind (mapM f xs) $ \ys ->
		Just (Cons y ys)
	| Nil -> pure Nil
;

module (*)
