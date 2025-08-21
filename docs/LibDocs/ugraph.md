# ugraph.ml

A simplistic Undirected graph.


## Definitions

### Types
```haskell
Edges a = Dict (List a)
```
```haskell
Vertices a = List a
```
```haskell
Graph a = Graph (Edges a) (Vertices a)
```
### Functions
```haskell
edgesFromGraph : Graph a -> List (List a)
```
