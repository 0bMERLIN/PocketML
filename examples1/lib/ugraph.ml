import lib.std;

type Edges a = Dict (List a);
type Vertices a = List a;
data Graph a = Graph (Edges a) (Vertices a);

let edgesFromGraph : Graph a -> List (List a);
let edgesFromGraph g = case g | Graph es _ ->
	nub $ concat (map (\t -> 
		let from = t._0;
		let to = t._1;
		map (\a -> sort [from, a]) to
	) (dictItems es))
;

module (*)