# weird example to showcase graphing, buttons
# and TEA

import lib.graphing;
import lib.calculus;
import lib.math;
import lib.std;

type State = { zoom : Number, y : Number,
	v : Number, data : Vec, nticks : Number };

let mapZoom f s = {zoom=f (s.zoom),y=s.y,v=s.v,data=s.data,nticks=s.nticks };

let mapY f s = {zoom=s.zoom, y=f (s.y),v=s.v,data=s.data,nticks=s.nticks};

let mapV f s = {zoom=s.zoom,y=s.y,v=f (s.v),data=s.data,nticks=s.nticks};

let addDataPoint y s = {zoom=s.zoom,y=s.y,v=s.v,
  nticks=s.nticks, data=(
	let newData = vecAppend y (s.data);
	vecSlice
		(max 0 (vecLen newData - 200))
		(vecLen newData)
		newData
)};

let incNTicks s = {zoom=s.zoom,y=s.y,v=s.v,data=s.data,nticks=s.nticks+1};

let view : State -> Widget;
let view s = Many
	[ viewGraphs [\x -> 5*vecAtSafe (vecLen s.data - int (x*40+50)) 0 s.data]
		(s.zoom) 0 0
	, Btn "+" "+" @(100,100) @(0,height-250)
	, Btn "-" "-" @(100,100) @(100,height-250+s.y)
	];

let update : Event -> State -> State;
let update e s = case e
	| BtnHeld "+" -> mapZoom (mul 1.04) s
	| BtnHeld "-" -> mapZoom (mul (1/1.04)) s
	| Tick -> (
		# bounce and fall
		mapV (\v ->
			.2 + if s.y < -height/2
			then -abs v*0.7 else v)
		# become stationary when v small
		>> mapV (\v ->
			if abs v < 1 && abs (s.y + height/2) < 2
			then 0 else v)
		# don't intersect floor!
		>> mapY (\y -> if y <= -height/2
			then -height/2+1 else y)
		# dy/dt = v
		>> mapY (\y -> y - s.v)
		# graph
		>> (if divisible (s.nticks) 2 && (abs (s.y + height/2) > 5 || abs s.v > 2)
			then addDataPoint (s.y/height/2)
			else id)
		# tick
		>> incNTicks
		) s
	| _ -> s;

let init =
	{ zoom=1
	, y=0,v=0
	, data=@(0,0)
	, nticks=0
	};

setTick init update view
