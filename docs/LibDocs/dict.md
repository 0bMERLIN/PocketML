---
nav_order: 2
title: dict
parent: Library Documentation
---

# dict.ml

Dictionaries with `String`-keys. Internally python dicts.


## Definitions

### Creation

```haskell
data Dict a
```





```haskell
mkDict : List (String, a) -> Dict a
```




### Accessing

```haskell
dictItems : Dict a -> List (String, a)
```





```haskell
dictGet : Dict a -> String -> Maybe a
```





```haskell
dictInsert : String -> Dict a -> a -> Dict a
```





```haskell
dictEmpty : Dict a
```




