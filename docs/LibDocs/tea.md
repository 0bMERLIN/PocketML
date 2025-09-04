---
nav_order: 2
title: tea
parent: Library Documentation
---

# tea.ml

Graphics framework inspired by TEA. Uses kivy and VDOM-diffing internally. Supports GUIs, canvas graphics & shaders


## Definitions

### Types

```haskell
type Color = Vec
```

> Alias used for clarity. Vec of length 4.



```haskell
data Uniform
	= UniformFloat String Number
	| UniformInt String Number
	| UniformVec2 String Vec
	| UniformVec3 String Vec
	| UniformVec4 String Vec
	| UniformTex0 String Img
```

> Uniform types for shaders. Arguments: uniformName, value



```haskell
data Widget
	= Rect Color Vec Vec
	| TRect Img Vec Vec
	| SRect String (List Uniform) Vec Vec
	| Btn String String Vec Vec
	| Slider String Number Number Number Number Vec Vec
	| Label String String Vec Vec
	| Line (List Vec) Number Color
	| Many (List Widget)
	| ColorPicker String Vec Vec
```




>| Attributes for Widgets | |
>|-|-|
>| Rect | color, size, pos |
>| TRect | texture, size, pos |
>| Btn   | name, text, size, pos |
>| Slider| name, min, max, step, value, size, pos |
>| Label | name, text, size, pos |
>| Line  | polygon-points, width, color |
>| Many  | children |

```haskell
data Event
	= Tick
	| BtnPressed String
	| BtnReleased String
	| BtnHeld String
	| SliderMoved String Number
	| ColorPicked String Color
```

> Event type for the `tick` function in the app. Make sure pattern matching on<br>
> events is exhaustive, so `tick` does not throw an error.


### Starting the App

```haskell
app : state -> (Event -> state -> state) -> (state -> Widget) -> Unit
```

> starts an app given an initial `state`, `tick` and `view`



```haskell
forceUpdate : state -> state
```




>The view gets updated based on the state. The app assumes that
>view is pure: It always returns the same Widgets for the same state.
>When side effects do need to be used for some reason, the `tick` function
>can request an update.
>
>Example:
>```
>let view _ = Label "time" (str $ time ()) @(200, 200) @(0, 0);
>let tick _ _ = forceUpdate (); # Note that the state is Unit and constant.
>setTick () tick view
>```

```haskell
stop : Unit -> Unit
```

> Effectful.<br>
> Stops the app. Takes effect on the next tick, the current tick is stil executed.


>Example:
>```
>let tick event state = do
>    if state > 1000 then stop ()
>    inc state;
>
>let view state = Label "mylabel" (str state) @(200, 200) @(0, 0);
>
>setTick 0
>```

### Basic kinds of apps / patterns

```haskell
staticView : (Unit -> Widget) -> Unit
```

> Renders a view and then halts the app.<br>
> Use for graphing, etc.


### Getters

```haskell
width : Number
```





```haskell
height: Number
```





```haskell
getFPS : Unit -> Number
```




### Positioning / layouts

```haskell
setPos : Widget -> Vec -> Unit
```





```haskell
randPos : Unit -> Vec
```





```haskell
grid : Vec -> Vec -> Num -> Num -> List (Vec -> Widget) -> Widget
```




### Colors & constants

```haskell
red : Color
```





```haskell
black : Color
```





```haskell
white : Color
```





```haskell
blue : Color
```





```haskell
green : Color
```





```haskell
yellow : Color
```




