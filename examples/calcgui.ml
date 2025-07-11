import lib.tea;
import lib.std;
import lib.math;

%%%
def PML_eval(s):
	try:
		return str(round(eval(s),4))
	except ZeroDivisionError:
		return "error: division by zero"
%%%;
let eval : String -> String;

type State = String; # my state

let init = "";

let tick : Event -> State -> State;
let tick e s = case e
	| BtnPressed "=" ->
		eval (replace "^" "**" s)
	| BtnPressed "C" -> ""
	| BtnPressed x ->
		if isNumeric x || strIn x "()+-*/^."
		then s+x
		else s
	| _ -> s;

let mkBtn w n t =
	let pos = @(n-4*int (n/4), 4-int (n/4)) ° w;
	Btn t t pos @(w*.9,w*.9);

let btnLayout = [
	"C", "(", ")", "/",
	"7", "8", "9", "*",
	"4", "5", "6", "-",
	"1", "2", "3", "+",
	".", "0", "=", "^"
];

let view : State -> Widget;
let view s =
	let w = width/5;
	let btns = Many (imap (mkBtn w) btnLayout);
	let inp = Label s "inp" @(0,w*5) @(w*4,w);
	Many [inp, btns];

setTick init tick view
