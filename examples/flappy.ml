import lib.std;
import lib.graphics;
import lib.state;

let velSt = mkSt |0, 0|;

let mkPipe : Vec -> Obj;
let mkPipe = \pos ->
	rect pos |width/10, height|
;

let onUp : Unit -> Unit;
let onUp = \_ ->
	let _a = setSt |0,10| velSt;
	();

let movePipe = \p ->
	if lt (vget 0 p) 0
	then |width,
		if eq (randint 0 1) 0
		then randint (height/1.5) (height/2)
		else -(randint (height/1.5) (height/2))|
	else p+|-5,0|;

let deathCond = \player -> \pipes -> or
	# when player hits floor
	(lt (vget 1 (getPos player)) 0)
	
	# player hits pipe
	(any (map (collide player) pipes))
;

let handleDeath = \player->\pipes->when
	(deathCond player pipes)(\_->
		let _ = setTick (\_p -> ());
		let _ = imap (\x -> \p -> setPos p |x*(width/3), height|) pipes;
		let _ = setPos player |width/2,height/2|;
		()
	)
;

let tick : Obj -> List Obj -> Unit -> Unit;
let tick = \player -> \pipes -> \_ -> do
	
	# make pipes move to the left
	map (mapPos movePipe) pipes
	
	# make player fall
	mapPos (\p -> p + (getSt velSt)) player
	mapSt (\v -> v+|0,-0.5|) velSt
	
	# player death
	handleDeath player pipes
	
	()
;

let main = do
	clear ()
	let player = circle |width/2,height/2| (height/20);
	let up = button "Up" |width-width/5, height-height/5| |width/5, height/5|;
	let start = button "Start" |width-2*width/5, height-height/5| |width/5, height/5|;
	let pipes = map (\x -> mkPipe |x*(width/3), height|) [1,2,3];
	
	onpress up onUp
	onpress start (\_->setTick (tick player pipes))
	
	()
;

module (*)


