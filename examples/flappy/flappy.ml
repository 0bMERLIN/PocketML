import lib.std;
import lib.graphics;
import lib.state;
import lib.image;

let velSt = mkSt |0, 0|;

let mkPipe : Vec -> Obj;
let mkPipe pos =
	let _ = push ();
	let _ = scale |1,-1,1|;
	let top = rect (pos + |width/40,0|) |width/20, height|;
	let _ = pop ();

	link top (texrect pos
		|width/10, width/10|
		(copyimg (loadimg "flappy/pipeend.png")))
;

let onUp : Unit -> Unit;
let onUp _ = setSt |0,10| velSt;

let movePipe p =
	if vget 0 p < 0
	then |width,
		if randint 0 1 == 0
		then randint (height/1.5) (height/2)
		else -(randint (height/1.5) (height/2))|
	else p+|-5,0|;

let deathCond player pipes =
	# when player hits floor
	vget 1 (getPos player) < 0
	# player hits pipe
	|| any (map (collide player) pipes)
;

let handleDeath player pipes =
	if (deathCond player pipes) then do
		setTick (\_ -> ())
		imap (\x p -> setPos p |x*(width/3), height|) pipes
		setPos player |width/2,height/2|
;

let tick : Obj -> List Obj -> Unit -> Unit;
let tick player pipes _ = do
	
	# make pipes move to the left
	map (mapPos movePipe) pipes
	
	# make player fall
	mapPos (\p -> p + (getSt velSt)) player
	mapSt (\v -> v+|0,-0.5|) velSt

	mapRot (\r -> if r < vget 1 (getSt velSt) then r + 1 else r - 1) player
	
	# player death
	handleDeath player pipes
	
	()
;

let main = do
	clear ()
	let player = texrect |width/2,height/2| |height/15,height/15| (loadimg "flappy/bird.png");
	let up = button "Up" |width-width/5, height-height/5| |width/5, height/5|;
	let start = button "Start" |width-2*width/5, height-height/5| |width/5, height/5|;
	let pipes = map (\x -> mkPipe |x*(width/3), height|) [1,2,3];
	
	onpress up onUp
	onpress start (\_->setTick (tick player pipes))
	
	()
;

module (*)


