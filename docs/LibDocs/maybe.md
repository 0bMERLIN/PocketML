---
nav_order: 2
title: maybe
parent: Library Documentation
---

# maybe.ml

Maybe type with monad implementation


## Definitions

### Type & Creating / unwrapping
```haskell
data Maybe a = Nothing | Just a
```




```haskell
maybe : a -> Maybe a -> a
```




### Monad implementation
```haskell
flatMap : (a -> Maybe b) -> Maybe a -> Maybe b
```




```haskell
bind : Maybe a -> (a -> Maybe b) -> Maybe b
```




```haskell
pure : a -> Maybe a
```




```haskell
fmap : (a -> b) -> Maybe a -> Maybe b
```




```haskell
mapM : (a -> Maybe b) -> List a -> Maybe (List b)
```




