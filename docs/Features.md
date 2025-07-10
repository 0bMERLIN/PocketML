## Features & The type system

#### 1.1 Syntax
PocketML`s syntax is largely based on Standard-ML
and Haskell. Some quirks include:
- Separation of top-level statements using `;`
```sml
let a = 10;
let b = 20;
print (a + b)
```
- Comments using `#`
```python
# i am a comment
```

##### GUI
A large part of PocketML is its editor.
Use the `Editor` tab in the top toolbar
to edit files. Close files by long pressing the
file tab. Results show up in either
the `Graphics` tab for graphics or the `Text Out`
tab for text output. The info box above the keyboard shows the type
of the symbol the cursor is on when clicked (no live type checking yet,
because the typechecker is too slow). Manage project files and directories
in the `Files` tab. For advanced file management
use a File manager app that can access the
`InternalStorage/Android/data/org.myapp.test/files/`
directory. The `Docs` tab provides a Hoogle-like interface for searching types, names or libraries.

#### 1.2 Type system

PocketML has a set of builtin types:
Vec (numpy arrays), Number, String, Bool, Tuples,
Lists, Dict and Maybe. Num is an alias for Number and will replace it eventually.

The operators *, /, +, - support
addition of strings, numbers, and Vecs,
as long as both sides of the operator
have the same type. The ° operator acts the
same as *, but allows two different types to
be multiplied (i.e. vector-scalar multiplication,
string multiplication, etc.).

<table border=3>
<tr><td>Operator</td><td>Type</td></tr>
<tr><td>+,-,*,/</td><td>a -> a -> a</td></tr>
<tr><td>°</td><td>a -> b -> a</td></tr>

<tr><td>composition operators:</td></tr>
<tr><td><<</td><td>(y -> z) -> (x -> y) -> (x -> z)</td></tr>
<tr><td>>></td><td>(x -> y) -> (y -> z) -> (x -> z)</td></tr>
<tr><td>$</td><td>(x -> y) -> x -> y</td></tr>

<tr><td>logical operators / equality:</td></tr>
<tr><td>&&, ||</td><td>Bool -> Bool -> Bool</td></tr>
<tr><td><=, >=, <, ></td><td>Number -> Number -> Bool</td></tr>
</table>

#### 1.3 Builtins
Most of the essentials are contained in the standard library `lib.std`, but some basic functions are passed through from python directly:

<table border=3>
<tr><td>Function</td><td>Type</td></tr>
<tr><td>and,or</td><td>Bool -> Bool -> Bool</td></tr>
<tr><td>add,sub,mul,pow</td><td>Number -> Number -> Number</td></tr>
<tr><td>sqrt, inc, dec</td><td>Number -> Number</td></tr>
<tr><td>True, False</td><td>Bool</td></tr>
<tr><td>equal</td><td>a -> a -> Bool</td></tr>
<tr><td>lt</td><td>Number -> Number -> Bool</td></tr>
<tr><td>print</td><td>a -> ()</td></tr>
<tr><td>print2</td><td>a -> b -> ()</td></tr>
</table>