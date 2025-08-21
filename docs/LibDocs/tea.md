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




```haskell
data Uniform
	= UniformFloat String Number
	| UniformInt String Number
	| UniformVec2 String Vec
	| UniformVec3 String Vec
	| UniformVec4 String Vec
	| UniformTex0 String Img
```




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
```




```haskell
WIDGET_DOCS : doc
```

> Attributes for Widgets:<br>
> Rect  : color, size, pos<br>
> TRect : texture, size, pos<br>
> Btn   : name, text, size, pos<br>
> Slider: name, min, max, step, value, size, pos<br>
> Label : name, text, size, pos<br>
> Line  : polygon-points, width, color<br>
> Many  : children


```haskell
data Event
	= Tick
	| BtnPressed String
	| BtnReleased String
	| BtnHeld String
	| SliderMoved String Number
```




### Starting the App
```haskell
setTick : a -> (Event -> a -> a) -> (a -> Widget) -> Unit
```




```haskell
forceUpdate : state -> state
```




```haskell
stop : Unit -> Unit
```




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
