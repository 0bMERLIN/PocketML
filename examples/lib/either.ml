import lib.util (error);
import lib.string (str);

## Either type for errors etc.

### ### Definitions / Working with `Either`
data Either a b = Left a | Right b;

let unRight : Either a b -> b;
let unRight e = case e
	| Right x -> x
	| Left x ->
		error ("unRight: Cannot unRight Left: "+str x);

data Maybe a = Just a | Nothing
	# --hide
;

let fromMaybe : b -> Maybe a -> Either b a;
let fromMaybe b m = case m
	| Just x -> Right x
	| _ -> Left b;

### ### Monad definition

let bind : Either e a -> (a -> Either e b) -> Either e b;
let bind m f =
	case m
	| Right x -> f x
	| Left x -> Left x;

let flatMap : (a -> Either e b) -> Either e a -> Either e b;
let flatMap x y = bind y x;

let fmap : (a -> b) -> Either e a -> Either e b;
let fmap g = flatMap (g >> Right);

let pure : a -> Either e a;
let pure = Right;

module (*)
