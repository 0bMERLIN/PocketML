import std;
import state;
import graphics2;

let pos = mkSt [300,800];
let vel = mkSt [0,0];

let bounce = \_u ->
	when (lt (vget 1 (getSt pos)) 0) 
	(\_->do
		mapSt (vmul [1, 0]) pos
		mapSt (vmul [1,-.8]) vel
	);

let onUp = \_->
	mapSt (\v -> [vget 0 v, 30]) vel;

do
	clear ()
	let c = circle (300,300) 300;
	let b = button "Up" (width - 300,height - 300) (300,300);
	onpress b onUp
	
	setTick (\_ -> do
		setPos c (tup2 (getSt pos))
		mapSt (vadd (getSt vel)) pos
		mapSt (vadd [0,-1]) vel
		bounce ()
		())
	module (*)