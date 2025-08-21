---
nav_order: 2
title: numpy
parent: Library Documentation
---

# numpy.ml

A library for using numpy in PocketML.


## Definitions

### Type Aliases
```haskell
type Size = List Number
```




```haskell
type Index = List Number
```




### Creating arrays
```haskell
array : List Number -> Vec
```




```haskell
zeros : Size -> Vec
```




```haskell
full : Size -> Number -> Vec
```




```haskell
linspace : Number -> Number -> Number -> Vec
```

> start, end, nsteps


### Getters
```haskell
toList : Vec -> List Number
```

> only 1-dim.!


```haskell
size : Vec -> Size
```

> <=> arr.shape in numpy!


```haskell
get : Index -> Vec -> Number
```




```haskell
slice : Index -> Index -> Vec -> Vec
```

> - start, end, input_array<br>
> - fails if out of bounds


```haskell
sliceInc : Index -> Index -> Vec -> Vec
```

> like slice but end index is included.


```haskell
slicePartial : Index -> Index -> Vec -> Vec
```

> same as slice, but return all<br>
> elements in index range instead<br>
> of failing


### Manipulating `Vec`s
```haskell
set : Index -> Number -> Vec -> Vec
```




```haskell
vectorize : (Number -> Number) -> Vec -> Vec
```




```haskell
ivectorize : (Index -> Number -> Number) -> Vec -> Vec
```




```haskell
sum : Vec -> Number
```




```haskell
dot : Vec -> Vec -> Number
```




```haskell
flatten : Vec -> Vec
```




```haskell
delete : Number -> Vec -> Vec
```

> args: i, arr<br>
> remove the element at i<br>
> only for flat Vecs


```haskell
concatenate : Number -> Vec -> Vec -> Vec
```

> args: axis, arr1, arr2


```haskell
reshape : Size -> Vec -> Vec
```




```haskell
transpose : Vec -> Vec
```




