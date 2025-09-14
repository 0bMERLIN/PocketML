import lib.tea;
import lib.image;
import lib.numpy;
import lib.util (fileexists);

%%%
PML_getMouse = lambda _: np.array(Window.mouse_pos)

mouse_is_down = False
def toggle_mouse_down(*_):
	global mouse_is_down
	mouse_is_down = not mouse_is_down
Window.bind(on_mouse_down=toggle_mouse_down)
Window.bind(on_mouse_up=toggle_mouse_down)

PML_getMousePressed = lambda _: mouse_is_down
%%%;

let getMouse : Unit -> Vec;
let getMousePressed : Unit -> Bool;

data Brush = Brush Number Vec;

let fp="../game/rock.png";
let i = if fileexists fp
	then
		let _ = print "a";
		imgLoad fp
	else image @(128,128);

let brushAt pos brush t =
	case brush | Brush w c ->
	imgMapRect @(w,w) pos t
		(\x y _ -> c);

let view _ = Many
	[ TRect i @(width,width) @(0,0)
	, Btn "pen" "pen" @(width/5,width/5) @(0,width)
	, Btn "eraser" "eraser" @(width/5,width/5) @(width/5,width)
	, Btn "save" "save" @(width/5,width/5) @(0,width+width/5)
	, ColorPicker "colpicker" @(width/2,width/3) @(width/2.5,width+width/10)
	, Label "brushsizelabel" "Brush Size" @(width/5,20) @(width/2.5,width+width/20)
	, Slider "brushsize" 1 15 0 .1 @(width/4,20) @(width/2.5+width/5,width+width/20)
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
	| SliderMoved "brushsize" s -> Brush s c
	| _ ->
		let _ = if getMousePressed () then brushAt
			(getMouse() ° ((get[0] $ imgSize i)/width))
			brush i;
		forceUpdate brush
);

app (Brush 2 @(255,255,255,255)) tick view
