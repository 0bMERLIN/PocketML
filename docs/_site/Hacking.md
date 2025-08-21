## Hacking / Extending

#### 1.1 Writing your own libraries
PocketML is not opinionated when it comes to project structure. All default libraries are in `lib/`.

You can also write bigger chunks of code on your pc for testing and then transfer them. Connect your phone via USB and open the folder `Internal Storage/Android/data/org.test.myapp/files/`.


#### 1.2 Python interop
PocketML is compiled to python. It
has access to all features of python and the
libraries `numpy`, `pygments`, `lark`, and `kivy`.
Python code can be included in PocketML code using
`%%% ... %%%`. PocketML uses the `PML_[varname]` naming scheme internally. Python functions exported to PocketML should be named accordingly.

```sml
%%%
def half(x):
    return x / 2

PML_half = half
%%%;

let half : Number -> Number;

print (half 2)
```

Python code can also be used to compute values
in PocketML code using the inline `%% ... %%` syntax.
Python types are largely compatible with PocketML types.
```sml
print %%f"PocketML does not have f-strings but python does {'!'*10}"%%
```
Another example:
```python
import lib.std;

# get name and greet!
input "Name:" (\nm -> print %%f"Hi, {PML_nm}!"%%)
```

As discussed in the [Language Guide](Guide.md) on _records_, one can also build a function with default arguments using python interop:

```sml
let mkVec : { x : Number, y : Number, z : Number } -> Vec;

%%%
def PML_mkVec(r):
    defaults = {"x":0,"y":0,"z":0}
    defaults.update(r)
    return np.array(list(defaults.values()))
%%%;
```
```python
print $ mkVec {y=20} # => [ 0 20  0]
```

#### 1.3 The editor

##### Extending and hacking!
The PocketML editor is accessible to the language by using python interop.
The editor object can be accessed directly by the name `editor`. It contains the "terminalout"
and "graphicalout" objects.
```python
%%%
def cls(_):
    # example usage:
    # clear the terminal
    editor.terminalout.text = ""
%%%;
()
```
`editor.graphicalout` is the kivy object for the "Graphics" tab in the editor and can be added to / manipulated like any other kivy object.

For a better insight into accessing the graphicalout object from code,
refer to the `tea.ml` library.

