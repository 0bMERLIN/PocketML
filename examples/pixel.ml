import lib.std;
import lib.graphics;
import lib.image;
import lib.state;

let _ = clear ();

let file = "flappy/pipeend.png";

let n = 10;
let w = width/n;
let img = if fileexists file then loadimg file
	else image |n,n|;
let colorSt = mkSt |255,0,0,255|;

let toggle : Btn -> Number -> Number -> Unit;
let toggle b x y =
	let c = getSt colorSt;
	let _ = btncolor b c;
	setpixel img |x,y| c;

let pixel x y =
	let b = button "" |w*x, w*y| |w,w|;
	let _ = btncolor b (getpixel img |x,n-y-1|);
	onpress b (\_ -> toggle b x (n-y-1));

let pixels = map (\y ->
		map (\x -> pixel x y) (range 0 n)
	) (range 0 n);

let colors = [
	|255,0,0,255|,
	|0,255,0,255|,
	|0,0,255,255|,
	|255,255,0,255|,
	|255,165,0,255|,
	|128,0,128,255|,
	|255,255,255,255|,
	|5,5,5,255|,
	|0,0,0,0|
];

let gui =
	let btnW = height/15;
	let b=button "save"|0,height-btnW| |btnW,btnW|;
	let _ = imap
		(\i c ->
			let cb = button ""
				|i*btnW+btnW,height-btnW|
				|btnW,btnW|;
			let _ = onpress cb
				(\_ -> setSt c colorSt);
			btncolor cb c)
		colors
	;
	onpress b (\_ -> saveimg file img);

module (*)