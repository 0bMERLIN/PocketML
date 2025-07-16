import lib.std;
import lib.ugraph;

type Path = List String;

let complete : Graph String -> Path -> Bool;
let complete g p = case g
	| Graph _ vs -> len p == len (edgesFromGraph g)+1;

# f.ex.: [1,2,3,2,1] -> [(1,2),(2,3),(3,2), ...]
let edgesFromPath : Path -> List (List String);
let edgesFromPath p =
	case p
	| Cons _ Nil -> []
	| Cons x xs ->
		(Cons (sort [x,head xs])
			$ edgesFromPath xs)
	| _ -> []
;

let valid : Path -> Bool;
let valid p =
	let es = edgesFromPath p;
	listeq (nub es) es;

let gen : Graph String -> Path -> List Path;
let gen g p = case g | Graph es _ ->
	if len p == 0 then []
	else
		let cs = maybe [] (dictGet es (head p));
    	map (\c -> Cons c p) cs
;

let euler : Graph String -> Path -> List Path;
let euler g sol =
	if complete g sol then
		[sol]
	else
		let nextSols =
			filter valid (gen g sol);
		let results = concat $ map (euler g) nextSols;
		filter (complete g) results
;

let haus_des_nikolaus = Graph
    # edges:
    (mkDict (
        ("A", ["B", "D", "E"]),
        ("B", ["A", "E", "D"]),
        ("C", ["D", "E"]),
        ("D", ["A", "B", "C", "E"]),
        ("E", ["A", "B", "C", "D"])
    ))

    # vertices:
    ["A", "B", "C", "D", "E"]
;

let _ =
	let sols = euler haus_des_nikolaus ["A"];
	printl $ reverse (head sols)
;


module (*)
