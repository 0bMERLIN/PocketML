# parsing.ml

A lark-based parser. Generated data compatible with a sum type of the form `data Expr = CapitalizedRuleName ... | ...`


## Definitions

### Types
```haskell
GrammarError = String
```
```haskell
ParseError = String
```
### Creating parsers
```haskell
parser :
	String -> Either GrammarError (
		String -> Either ParseError a
	)
	# args: grammar, string

```
