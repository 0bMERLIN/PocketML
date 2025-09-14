import lib.image;
import lib.tea;
import lib.math (sin,cos,noise);
import lib.numpy (get);
import lib.util (copy, readFileUnsafe);
import lib.list (listAt,filter);

data Sprite = Sprite Num Vec Vec
	# sprite defined by a 2D upright bounding box (x0,y0,x1,y1)
;

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

let atlasMap : Atlas -> List Number;
let atlasMap = \case Atlas tex szs ->
	Cons 0 (take (len szs-1) (foldr (\acc s ->
		let l = acc._1;
		let y = acc._0;
		let y1 = y + get [1] s;
		(y1, append (y1/imgHeight tex) l)
	)
	(0, []) szs)._1);

let myshader = readFileUnsafe "voxelspace.glsl";

let render3D : Vec -> Number -> List Sprite -> Atlas -> Number -> Vec -> Bool -> Widget;
let render3D pos angle sprites atl worldTexture skyColor hasFog =
	let am = atlasMap atl;
	case atl|Atlas tex szs ->
	
	SRect myshader
		([UniformInt "atlasSize" (len szs)
		, UniformInt "nSprites" (len sprites)
		, UniformTex0 "tex" tex
		, UniformFloat "angle" angle
		, UniformVec2 "pos" pos
        , UniformInt "worldTexture" worldTexture
		, UniformVec3 "sky" skyColor
		, UniformInt "fogEnabled" (if hasFog then 1 else 0)
		]
		# Atlas map
		+ imap (\i ->
			UniformFloat("atlasMap["+str i+"]"))
			am
		# Atlas image sizes
		+ imap (\i ->
			UniformVec2
				("atlasSizes["+str i+"]"))
			szs
		
		# Size of the entire atlas
		+ [UniformVec2 "atlasImgSize" (imgSize tex)]
		
		+ concat (imap spriteUniforms sprites))
		@(width,width) @(0,height*.2);

module (render3D, type Sprite, Sprite)
