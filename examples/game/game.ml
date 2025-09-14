import render as Render;
import lib.tea;
import lib.math (sin,cos,random,pi,angleOf);
import lib.image;
import lib.numpy;
import lib.list;

# utils
let cross u d l r size pos = Many
	[ u size (pos + size * @(1,0))
	, d size (pos + size * @(1,-2))
	, l size (pos + size * @(0,-1))
	, r size (pos + size * @(2,-1))
	]
;

let randomPoints : Number -> List Vec;
let randomPoints n =
	if n <= 0 then []
	else Cons @(random 0 1, random 0 1, 0) (randomPoints (n-1));

let vec2To3 : Vec -> Vec;
let vec2To3 v = @(get [0] v, get [1] v, 0);

# generate a map
let earthmap = imgShade (image @(300, 300)) (readFileUnsafe "mapgenearth.glsl");
let moonmap = imgShade (image @(300, 300)) (readFileUnsafe "mapgenmoon.glsl");
let textures =
	[ earthmap
	, moonmap
	, imgLoad "rock.png"
	, imgLoad "tree.png"
	];

let atlas = mkAtlas textures;

# planets
data Planet = Earth | Moon;

let planetToTexture : Planet -> Number;
let planetToTexture = \case
	  Earth -> 0
	| Moon -> 1
;

let planetSkyColor : Planet -> Vec;
let planetSkyColor = \case
	  Earth -> @(0.5,0.8,0.9)
	| Moon -> @(0,0,0)
;

let planetHasFog : Planet -> Bool;
let planetHasFog p = p != Moon;

let getMapHeight : Planet -> Vec -> Number;
let getMapHeight p v =
	let m = listAt (planetToTexture p) textures;
	0.15 * (get [3] $ imgGet (imgBuf m) (slice [0] [2] v ° 300)) / 255
;

# game model
data Resource = Tree | Rock;

let resourceToTexture : Resource -> Number;
let resourceToTexture r = 2 + case r
	| Tree -> 0
	| Rock -> 1
;

type Scene =
	{ planet : Planet
	, resources : List (Resource, Vec)
	};

type State =
	{ angle : Number
	, pos : Vec
	, scene : Scene
	};


# app
let resourceToBillboard : Vec -> (Resource, Vec) -> Render.Sprite;
let resourceToBillboard playerPos (res, pos) =
	let heading = angleOf (vec2To3 playerPos - pos) + pi/2;
	let right = @(cos heading, sin heading, 0);
	let up = @(0,0,1);
	Render.Sprite (resourceToTexture res) pos (pos + up ° 0.03 - right ° 0.03)
;

let view state =
	Many
	[ Render.render3D
		state.pos state.angle
		(map (resourceToBillboard state.pos) state.scene.resources)
		atlas
		(planetToTexture state.scene.planet)
		(planetSkyColor state.scene.planet)
		(planetHasFog state.scene.planet)
	
	# controls
	, cross
		(Btn "/\\" "/\\") (Btn "\\/" "\\/")
		(Btn "<" "<") (Btn ">" ">")
		@(width/5,width/5) @(width/3,height/3.5)
	
	, Label "pos" (str state.pos) @(50,50) @(width/2,0)
	, Btn "pick_up" "Pick Up" @(width/5, width/5) @(0,0)
	];

let tick : Event -> State -> State;
let tick e s =
	let v = @(cos(s.angle), sin(s.angle))°.001;
	case e
	| BtnHeld ">" -> with {angle=s.angle+.05} s
	| BtnHeld "<" -> with {angle=s.angle-.05} s
	| BtnHeld "\\/" -> with {pos=s.pos-v} s
	| BtnHeld "/\\" -> with {pos=s.pos+v} s
	| BtnPressed "pick_up" ->
		let picked = map (\(r, _) -> r) $ filter
			(\(_, p) -> mag (vec2To3 p - vec2To3 s.pos) < 0.06)
			s.scene.resources;
		let _ = print picked;
		s
	| _ -> forceUpdate s
;

let init : State;
let init =
	let pl = Earth;

	{ angle=0, pos=@(0, 0)
	, scene =
		{ planet = pl
		, resources =
			map (\p ->
				let _ = print (str p);
				( if random 0 1 > 0.5 then Tree else Rock
				, p + @(0,0,getMapHeight pl p))
			) (Cons @(0,0,0) (randomPoints 4))
		}
	};

app init tick view
