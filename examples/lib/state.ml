data State s a = State (s -> (s, a));

let runState : s -> State s a -> (s, a);
let runState s (State f) = f s;

let flatMap : (a -> State s b) -> State s a -> State s b;
let flatMap f (State g) = State (\s ->
	case g s | (newS, a) ->
	runState newS (f a));

let get : State s s;
let get = State (\s -> (s,s));

let set : s -> State s Unit;
let set s = State (\_ -> (s, ()));

let pure : a -> State s a;
let pure x = State (\s -> (s, x));

let bind : State s a -> (a -> State s b) -> State s b;
let bind x y = flatMap y x;

let fmap : (a -> b) -> State s a -> State s b;
let fmap f = flatMap (f >> pure);

module (*)