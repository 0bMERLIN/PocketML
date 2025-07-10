
## Language Guide

#### 1.0 Installing
I recommend downloading the APK file
from the `bin/` directory in the [github repo](github.com/0bMERLIN/PocketML).

> Note: You might have to copy the library code/example code manually if you want/need it. I do not know why buildozer sometimes leaves it out.

You can also build the project yourself using the [buildozer](https://buildozer.readthedocs.io/en/latest/) tool.

#### 1.1 Data Types
PocketML uses Sum types like most other statically 
typed functional languages:
```haskell
data Maybe a
    | Just a
    | Nothing
```

Type aliases can be used to abbreviate
the names of other data types:
```sml
type Mb a = Maybe a;
```

#### 1.2 Branching
Pattern matching is based on the `case` keyword
and can match basic data types:
```sml
case 1
    | 1 -> "One"
    | _ -> "Something else"
```
And many other structure (except for numpy arrays):
```sml
case Just 1
    | Just x -> print x
    | Nothing -> ()
```

Use if-then-else for branching:
```sml
let f x = if x then "True!" else "false :(";
f True
```
When programming with side effects, an else branch may
not be needed. The if-then expression must always return
Unit.
```sml
let f : Bool -> Unit;
let f b = if b then print "True!";
...
```

#### 1.3 Do-Syntax
When many functions need to be
executed one after another, for example
to cause side effects, the do-syntax
can be used.
```haskell
let f _ = do
    print "1"
    print "2"
    print "3"
    launch_missiles ()
;
```
>Note: Do not confuse this do syntax
with monadic do-notation in Haskell! This is more of a C-like block (e.g. `{ ...; ...; }`).
The do-syntax is not perfect and might
fail to parse in some situations. When in
doubt use `let _ = a (); let _ = b (); ...`

#### 1.4 Lists
Lists can be created like in the following example:
```python
import std;

print [1, 2, 3]
# => (Cons 1 (Cons 2 (Cons 3 Nil)))
```

Numpy arrays can be created using the `@(x1, x2, x3, ...)` syntax:
```python
print (@(1, 2) + @(3, 4)) # => [4. 6.]
```
They have type `Vec`.

#### 1.5 Tuples and Records
PocketML supports both tuples and records. It is
best to use records and tuples sparingly,
as custom data types carry more information
and are more strongly typed.
```sml
type Point = (Number, Number);

type Person =
    { name: String
    , age: Number
    , location: Point };
```

> Note that PocketML does not support tuple and record pattern
matching yet!

Records also support a sort of weak row-polymorphism.

```sml
let getX : { x : a } -> a;
let getX r = r.x;

print $ getX {x=10, y=20}
```

Generally a record `{x : a, y : b}` and a record `{y : b}` unify. That also means that the following example only fails at runtime.
```sml
let getX : { x : a, y : b } -> a;
let getX r = r.x;

print $ getX {y=20}
```

> Note: The section _Python Interop_ has an example of how this can be used to implement named default arguments.

The standard library `lib.std` has functions for updating records:
```sml
import lib.std;

let myrec = {x=1,y=2,z=3};

do
    print (with { x = 22 } myrec)
    print (recordMap (\r -> with {x=r.x+1} r) myrec)
```

#### 1.6 Functions, recursion and let
Variables are generally introduced using the `let`
keyword. Let declarations can be used to introduce
a variables type before defining it:
```sml
let pi : Number;
let pi = 3;
```

Functions can be introduced using `\` and are
anonymous. To create recursive functions, 
the `rec` keyword or an explicit type
annotation is required:

```sml
let rec sum = \x -> case x
    | Nil -> 0
    | Cons x xs -> add x (sum xs);

print (sum [1,2,3,4])
```
Or alternatively:
```sml
let sum : (List Number) -> Number
let sum = \case
    | Nil -> 0
    | Cons x xs -> add x (sum xs);

print (sum [1,2,3,4])
```
>Note: The above example uses the `\case` notation
which is equivalent to `\x -> case x ...`.

Functions can also be introduced using let:
```
let greet x = print2 "Hello," x;
greet "there!"
```


#### 1.7 Modules
PocketML projects are organized into modules.
A module exports variables, types and type aliases.
The explicit module declaration can limit what is exported:

```sml
let greet x = print2 "Hi," x;
let pi = 4;
module (greet, pi)
```
Modules can also use `(*)` to export _all_
types and variables.

```sml
let greet x = print2 "Hi," x;
let pi = 4;
module (*)
```
Modules inside a directory can be addressed using `.`:
```python
import directory.mymodule;
```