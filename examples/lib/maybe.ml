data Maybe a = Nothing | Just a;

let maybe : a -> Maybe a -> a;
let maybe d m = case m
	| Just x -> x
	| Nothing -> d;

let bind : Maybe a -> (a -> Maybe b) -> Maybe b;
let bind m f_bnd = case m
	| Just x -> f_bnd x
	| Nothing -> Nothing;

let fmap : (a -> b) -> Maybe a -> Maybe b;
let fmap g = \case
	Just x -> Just (g x)
	| Nothing -> Nothing;

module (*)
