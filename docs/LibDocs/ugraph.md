---
nav_order: 2
title: ugraph
parent: Library Documentation
---

# ugraph.ml

A simplistic Undirected graph.


## Definitions

### Types
```haskell
type Edges a = Dict (List a)
```




```haskell
type Vertices a = List a
```




```haskell
data Graph a = Graph (Edges a) (Vertices a)
```




### Functions
```haskell
edgesFromGraph : Graph a -> List (List a)
```




