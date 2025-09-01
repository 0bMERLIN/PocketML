---
nav_order: 2
title: list
parent: Library Documentation
---

# list.ml

A simple linked list implementation.


## Definitions

### Types

```haskell
data List a
	= Cons a (List a)
	| Nil
```

> The default list type generated<br>
> by `[...]`


### Creating lists

```haskell
range : Number -> Number -> List Number
```





```haskell
srange : Number -> Number -> Number -> List Number
```

> start, end, step


### Accessors

```haskell
tail : List a -> List a
```





```haskell
tailSafe : List a -> List a
```





```haskell
head : List a -> a
```





```haskell
len : List a -> Number
```





```haskell
listAtSafe : Number -> List a -> Maybe a
```





```haskell
listAt : Number -> List a -> a
```





```haskell
take : Number -> List a -> List a
```





```haskell
chunksOf : Number -> List a -> List (List a)
```





```haskell
contains : a -> List a -> Bool
```




### Sorting, etc.

```haskell
sort : List a -> List a
```





```haskell
nub : List a -> List a
```




### Manipulating lists

```haskell
append : a -> List a -> List a
```





```haskell
foldr : (b -> a -> b) -> b -> List a -> b
```





```haskell
extend : List a -> List a -> List a
```





```haskell
concat : List (List a) -> List a
```





```haskell
filter : (a -> Bool) -> List a -> List a
```





```haskell
reverse : List a -> List a
```





```haskell
map : (a -> b) -> (List a) -> List b
```





```haskell
foreach2D : Number -> Number -> (Number->Number-> Unit) -> Unit
```





```haskell
imap : (Number -> a -> b) -> List a -> List b
```





```haskell
any : List Bool -> Bool
```





```haskell
zip : List a -> List b -> List (a,b)
```




