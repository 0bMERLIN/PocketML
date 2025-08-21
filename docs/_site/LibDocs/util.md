# util.ml

Util functions for the OS, kivy process, network and more.


## Definitions

### Time
```haskell
time : Unit -> Number
```
```haskell
traceTime : (Unit -> b) -> b
	# log the time an action takes to execute

```
```haskell
setInterval : Number -> state -> (state->state) -> Unit
	# args: n, state, tick
	# run tick every n seconds.

```
```haskell
setUpdate : state -> (state->state) ->Unit
```
### Terminal
```haskell
cls : Unit -> Unit
```
```haskell
error : String -> a
```
```haskell
setTermFontSize : Number -> Unit
```
```haskell
str : a -> String
	# deprecated. Use lib.string (str)

```
```haskell
printl : List a -> Unit
```
### Misc.
```haskell
setreclimit : Number -> Unit
```
```haskell
setCompilerCWD : String -> Unit
```
```haskell
randint : Number -> Number -> Number
```
### File system
```haskell
fileexists : String -> Bool
```
```haskell
readFile : String -> Maybe String
```
```haskell
readFileUnsafe : String -> String
```
### Network
```haskell
download : String -> String -> Unit
```
### Basic functions
```haskell
copy : a -> a
```
```haskell
uncurry2 : (a -> b -> c) -> (a,b) -> c
```
```haskell
not : Bool -> Bool
```
```haskell
float : a -> Number
```
```haskell
int : a -> Number
```
```haskell
neg : Number -> Number
```
```haskell
between : Number-> Number -> Number -> Bool
```
```haskell
id : a -> a
```
```haskell
const : a -> b -> a
```
```haskell
when : Bool -> (Unit -> Unit) -> Unit
```
```haskell
mapRecord : (a -> a) -> a -> a
```
```haskell
with : a -> b -> b
```
```haskell
union : a -> a -> a
```
```haskell
times : Number -> (a -> a) -> a -> a
```
```haskell
ftee : (a -> Unit) -> (a -> a) -> a -> a
```
