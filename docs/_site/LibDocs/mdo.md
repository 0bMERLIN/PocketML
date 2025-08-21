# mdo.ml



## Definitions

```haskell
mkMDo :
	((a -> M b) -> M a -> M b)
	-> ((M t -> t) -> M c) -> M c
	# args: bind, do block
	# Example:
	#	mkMDo Maybe.bind $ \yield ->
	# 		x = yield $ Just 1
	# 		y = yield $ Just 2
	# 		Just (x+y)

```
