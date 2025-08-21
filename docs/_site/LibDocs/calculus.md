# calculus.ml

Basic numeric calculus functions like differentiation, integration, series.


## Definitions

### Differentiation & Integration
```haskell
diff : (Number -> Number) -> Number -> (Number -> Number)
	# args: func, n
	# returns: n-th derivative of func.

```
```haskell
integral : (Number -> Number) -> Number -> Number -> Number
	# args: func, x_start, x_end

```
### Series expansions (Taylor, Fourier etc.)
```haskell
taylor : (Number -> Number) -> Number -> Number -> (Number -> Number)
	# args: f, n, x0, x

```
```haskell
fourier : (Number -> Number) -> Number -> (Number -> Number)
	# args: f, m, x

```
