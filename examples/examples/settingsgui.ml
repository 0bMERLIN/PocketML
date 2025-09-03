import lib.tea;
import lib.util;
import golpatterns;

type State = Num;

let view : State -> Widget;
let view s = grid @(0,top-100) @(700,200) 2 1
	[ Slider "TermFontSize" 0 100 5 50 @(600,50)
	, Label "TermFontSizeL"
		("Terminal font size: "+str s) @(200,50)
	]
;

let tick : Event -> State -> State;
let tick e s = case e
	| SliderMoved "TermFontSize" v ->
		let _ = setTermFontSize v;
		v
	| _ -> s;

app 30 tick view
