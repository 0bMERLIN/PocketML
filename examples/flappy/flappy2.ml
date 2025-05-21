import lib.std;
import lib.graphics2;
import lib.image;

type GameState = { player: Rigidbody, pipes: List Rigidbody };

let resetPipe : Rigidbody -> Rigidbody;
let resetPipe p =
    let up = randint 0 1 == 0;
    let newY = if up then randint (height/1.5) (height/2) else -(randint (height/1.5) (height/2));
    rigidbodyMapTex flipv (rigidbodyMapPos (const |0, newY|) r)
;

let mkPipe p = mkRigidbody (loadimg "flappy/pipeend.png") p |1, 0| |150, 150|;
let mkPlayer _ = mkRigidbody (loadimg "flappy/bird.png") |width/2,height/2| |0,0| |150,150|;

let state : GameState;
let state = {
    player = listen "pos" print (mkPlayer ()),
    pipes = map (\x -> mkPipe |x*(width/3), height|) [1,2,3]
};

let tick : GameState -> GameState;
let tick s = {
    player = moveRigidbody s.player,
    pipes = map (\p ->
        let pipe = moveRigidbody p;
        if vget 1 pipe.pos > width then resetPipe pipe
        else pipe) s.pipes
};

app state tick
