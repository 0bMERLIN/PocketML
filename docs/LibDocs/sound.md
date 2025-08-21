---
nav_order: 2
title: sound
parent: Library Documentation
---

# sound.ml

Library for kivys sound system.


## Definitions

### Types
```haskell
data Sound
```




### Generating Sounds
```haskell
max_amp : Number
```




```haskell
sound : (Number -> Number) -> Number -> Sound
```




```haskell
beep : Number -> Number -> Sound
```




### Playback
```haskell
play : Sound -> Unit
```

> example:<br>
> play $ beep 440 1


