import lib.numpy;
import lib.util;
import lib.list;
import examples.golpatterns;

let getNbSum : Vec -> Index -> Number;
let getNbSum g pos =
	(sum $ slicePartial (map dec pos)
		(map (times 2 inc) pos)
		g) - (get pos g)
;

let alive : Number -> Number -> Number;
let alive nbs c =
	# dead
	if c == 0 then int (nbs == 3)
	# alive
	else int (nbs == 3 || nbs == 2);

let tick : Vec -> Vec;
let tick g = ivectorize
	(getNbSum g >> alive) g;

let showC c = if c == 0 then " " else "#";

let printG : Vec -> Unit;
let printG g0 =
	let g = slice [0,10] [13,45] g0;
	let _ = map printl $ (map (map showC) $ 
		chunksOf
			(listAt 1 $ size g)
			(toList $ flatten g));
	()
;

let _ = setTermFontSize 20;
let _ = setInterval .05 (gosper, 0) (\s -> do
	cls ()
	printG s._0
	print s._1
	(tick s._0, s._1 + 1)
);

module (*)
