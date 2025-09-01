---
nav_order: 2
title: image
parent: Library Documentation
---

# image.ml

A library for kivy textures. An `Img` is a kivy texture. Images can be loaded from disk or created programmatically.


## Definitions

### Definitions & Creating images/buffers

```haskell
data Img
```





```haskell
data Buffer
```





```haskell
type Color = Vec
```





```haskell
setpixel : Img -> Vec -> Color -> Unit
```





```haskell
image : Vec -> Img
```





```haskell
imgLoad : String -> Img
```





```haskell
imgBuf : Img -> Buffer
```




### Functions

```haskell
imgSize : Img -> Vec
```





```haskell
imgCopy : Img -> Img
```





```haskell
imgMap : Img -> (Number->Number->Color->Color) -> Unit
```





```haskell
imgGet : Buffer -> Vec -> Vec
```





```haskell
imgSave : String -> Img -> Unit
```





```haskell
imgClear : Img -> Color -> Unit
```





```haskell
imgMapRect: Vec -> Vec -> Img -> (Number->Number->Color->Color) -> Unit
```

> args: size, pos, img, func



```haskell
imgSmooth : Img -> Img
```





```haskell
imgFlipH : Img -> Img
```





```haskell
imgFlipV : Img -> Img
```





```haskell
imgShade : Img -> String -> Img
```





```haskell
mkAtlas : List Img -> Img
```




