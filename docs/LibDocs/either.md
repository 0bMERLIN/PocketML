# either.ml

Either type for errors etc.


## Definitions

### Definitions / Working with `Either`
```haskell
Either a b = Left a | Right b
```
```haskell
unRight : Either a b -> b
```
```haskell
fromMaybe : b -> Maybe a -> Either b a
```
### Monad definition
```haskell
bind : Either e a -> (a -> Either e b) -> Either e b
```
```haskell
flatMap : (a -> Either e b) -> Either e a -> Either e b
```
```haskell
fmap : (a -> b) -> Either e a -> Either e b
```
```haskell
pure : a -> Either e a
```
