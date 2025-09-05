import lib.image;
import lib.tea;
import lib.math (sin,cos,noise);
import lib.numpy (get);
import lib.util (copy, readFileUnsafe);
import lib.list (listAt,filter);

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

let atlasMap : Atlas -> List Number;
let atlasMap = \case Atlas tex szs ->
	Cons 0 (take (len szs-1) (foldr (\acc s ->
		let l = acc._1;
		let y = acc._0;
		let y1 = y + get [1] s;
		(y1, append (y1/imgHeight tex) l)
	)
	(0, []) szs)._1);

let myshader = readFileUnsafe
	"../assets/voxelspace.glsl";
let render3D : Vec -> Number -> List Sprite -> Atlas -> Widget;
let render3D pos angle sprites atl =
	let am = atlasMap atl;
	case atl|Atlas tex szs ->
	
	SRect myshader
		([UniformInt "atlasSize" (len szs)
		, UniformInt "nSprites" (len sprites)
		, UniformTex0 "tex" tex
		, UniformFloat "angle" angle
		, UniformVec2 "pos" pos
		]
		# Atlas map
		+ imap (\i ->
			UniformFloat("atlasMap["+str i+"]"))
			am
		# Atlas image sizes
		+ imap (\i ->
			UniformVec2
				("atlasSizes[+"+str i+"+]"))
			szs
		
		+ concat (imap spriteUniforms sprites))
		@(width,width) @(0,height*.2);

type State =
	{ angle : Number
	, pos : Vec
	};

let genMapShader = readFileUnsafe
	"../assets/mapgen.glsl";

let genMap w h =
	let i = image @(w, h);
	imgShade i genMapShader;

let mymap = genMap 300 300;

let view : Atlas -> State -> Widget;
let view atlas s = Many
	[ render3D (s.pos) (s.angle)
		[Sprite 0 @(0,.05,0) @(0,0,.04)]
		atlas
	, cross
		(Btn "/\\" "/\\") (Btn "\\/" "\\/")
		(Btn "<" "<") (Btn ">" ">")
		@(width/5,width/5) @(width/3,height/3.5)
	, Label "Pos" (str (getFPS())) @(width,50) @(0,0)
	]
;

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

app { pos = @(0,0.2), angle=0 } tick
	(view $ mkAtlas [mymap, mymap, mymap])
