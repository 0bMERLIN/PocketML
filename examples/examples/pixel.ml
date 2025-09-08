import lib.tea;
import lib.image;
import lib.numpy;
import lib.util (fileexists);

%%%
PML_getMouse = lambda _: np.array(Window.mouse_pos)
%%%;
let getMouse : Unit -> Vec;

data Brush = Brush Number Vec;

let fp="../assets/hm.png";
let i = if fileexists fp
	then
		let _=print "a";
		imgLoad fp
	else image @(128,128);

let brushAt pos brush t =
	case brush | Brush w c ->
	imgMapRect @(w,w) pos t
		(\x y _ -> c);

let view _ = Many [
	TRect i @(width,width) @(0,0),
	Btn "pen" "pen" @(200,200) @(0,width),
	Btn "eraser" "eraser" @(200,200) @(200,width),
	Btn "save" "save" @(200,200) @(0,width+200),
	ColorPicker "colpicker" @(600,600) @(400,width)
];

let tick e brush = case brush | Brush s c -> (
	case e
	| BtnPressed "pen" ->
		Brush s (set [3] 255 c)
	| BtnPressed "eraser" ->
		Brush s (set [3] 0 c)
	| BtnPressed "save" ->
		let _ = imgSave fp i;
		brush
	| ColorPicked _ v -> Brush s v
	| _ ->
		let _ = brushAt
			(getMouse() ° ((get[0] $ imgSize i)/width))
			brush i;
		forceUpdate brush
);

setTick (Brush 10 @(255,255,255,255)) tick view
