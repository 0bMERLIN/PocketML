import lib.maybe;
import lib.util;

# implementation
type PosNum = String;

let posNum : Number -> Maybe PosNum;
let posNum x =
	if x > 0 then Just (str x)
	else Nothing;

let toNum : PosNum -> Number;
let toNum x = float x;

# signature
data PosNum;
let posNum : Number -> Maybe PosNum;
let toNum : PosNum -> Number;

module (type PosNum, posNum, toNum)
