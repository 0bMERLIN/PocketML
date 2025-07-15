import lib.std;
import lib.tea;
import lib.math;

# draw graph
let graph f =
	let w = width/1.5;
	let offsetx=w/2;
	let offsety=height/2;
	let maxy=height/2;
	
	map (\x ->
			@(x+width/2-w/2, offsety+100*(f ((x-offsetx)/50))))
		(srange 0 w 2)
;

let cols = [
	@(255,0,0,255),
	@(0,255,0,255),
	@(0,0,255,255),
	@(255,255,0,255),
	@(0,255,255,255)
];

let viewGraphs : List (Number->Number) -> Number -> Number -> Number -> Widget; # Args: fns, zoom, x, y

let viewGraphs fs zoom xoff yoff =
	let axes = [
		((\x->40*x) ,WHITE),
		(const 0, WHITE)
	];
	Many $ map
		(\x -> Line
				(graph (\t ->(x._0)(t/zoom - xoff)))
				2 x._1)
		(extend axes (zip fs cols))
;

module (*)