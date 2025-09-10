import lib.std;
import lib.image;
import lib.math;
import lib.tea;
import lib.numpy;
import examples.golpatterns;
import lib.util;

let nAlive buf v =
	let offsets = [
		@(-1,-1),@(0,-1),@(1,-1),
		@(-1,0),@(1,0),
		@(-1,1),@(0,1),@(1,1)
	];
	
	len (filter (\x -> x > 0) $
		map (\o ->
			let p = imgGet buf (v+o);
			if mag p == 0 then 0 else
			get [0] p)
		offsets);

let determineAlive : Bool -> Number -> Bool;
let determineAlive c n =
	if c then not (n < 2 || n > 3)
	else (n == 3)
;

let tick img =
	# save the image in a buffer, to
	# stop neighbours from being
	# overwritten.
	let buf = imgBuf img;
	imgMap img (\x y cell ->
		let n = nAlive buf @(x,y);
		let c = get [0] cell > 0;
		if determineAlive c n
			then @(255,255,255,255)
			else @(0,0,0,255)
);

let addPattern : Img -> Vec -> Vec -> Unit;
let addPattern img v p = foreach2D
	13 55
	(\x y ->
		let c = get [x,y] p;
		setpixel img (v+@(x,y))
			(@(c,c,c,255) ° 255)
	);

let w = 60;

let mygrid : Img;
let mygrid = image @(w,w);

let _ =
	addPattern mygrid @(0, 0) gosper
;

let _ = app 0 (\e t -> case e | Tick ->
	let _ = when (divisible t 5)
		(\_ -> traceTime (\_ -> tick mygrid));
	inc t) (\_ -> TRect mygrid @(700,700) @(150,800));

module (*)
