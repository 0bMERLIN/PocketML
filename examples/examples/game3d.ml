import lib.image;
import lib.tea;
import lib.math (sin,cos,noise);
import lib.numpy (get);
import lib.util (copy, readFileUnsafe);
import lib.list (listAt,filter);

let myshader = readFileUnsafe "../assets/voxelspace.glsl";
let genMapShader = readFileUnsafe "../assets/mapgen.glsl";

let startTime = time ();

let genMap w h =
	let i = image @(w, h);
	imgShade i genMapShader
;

let mymap = genMap 300 300;

let atlas : Img;
let atlas = imgSmooth $ mkAtlas [mymap, mymap];

type State = { angle : Number, pos : Vec };

let tick : Event -> State -> State;
let tick e s =
	let v = @(cos(s.angle), sin(s.angle))°.001;
	case e
	| BtnHeld ">" -> with {angle=s.angle+.05} s
	| BtnHeld "<" -> with {angle=s.angle-.05} s
	| BtnHeld "\\/" -> with {pos=s.pos-v} s
	| BtnHeld "/\\" -> with {pos=s.pos+v} s
	| _ -> forceUpdate s
;

data Sprite = Sprite Num Vec Vec;

let spriteUniforms : Num -> Sprite -> List Uniform;
let spriteUniforms i = \case Sprite t a b ->
	[ UniformInt ("spriteTextures["+str i+"]") t
	, UniformVec4 ("spriteLines["+str i+"]")
		@(get [0] a, get [1] a,
		get [0] b, get [1] b)
	, UniformVec2 ("spriteHeights["+str i+"]")
		@(get [2] a, get [2] b)
	]
;

let cross u d l r size pos = Many
	[ u size (pos + size * @(1,0))
	, d size (pos + size * @(1,-2))
	, l size (pos + size * @(0,-1))
	, r size (pos + size * @(2,-1))
	]
;

let view : State -> Widget;
let view s = Many
	[ SRect myshader
		([ UniformTex0 "tex" atlas
		, UniformFloat "atlasMap[0]" 0
		, UniformFloat "atlasMap[1]" 0.5
		, UniformInt "atlasSize" 2
		, UniformVec2 "atlasSizes[0]" (imgSize mymap)
		, UniformVec2 "atlasSizes[1]" (imgSize mymap)
		
		, UniformInt "nSprites" 1
		
		, UniformFloat "angle" s.angle
		, UniformVec2 "pos" s.pos
		]
		+ spriteUniforms 0
			(Sprite 0 @(0,.05,0) @(0,0,.04))
		)
		@(width,width) @(0,height*.2)
	, cross
		(Btn "/\\" "/\\") (Btn "\\/" "\\/")
		(Btn "<" "<") (Btn ">" ">")
		@(width/5,width/5) @(width/3,height/3.5)
	, Label "Pos" (str (getFPS())) @(width,50) @(0,0)
	]
;


setTick { pos = @(0,0), angle=0 } tick view
