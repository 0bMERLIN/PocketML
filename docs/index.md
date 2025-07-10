# Pocket ML 📱

PocketML is a functional statically-typed language designed for
tinkering / small projects. Its main feature is the editor android app.
The language is similar to Elm and is based on a python backend.

## Guides
- [Features & Type system](Features.md)
- [Language Guide](Guide.md)
- [Hacking / Python interop](Hacking.md)

## Libraries
> Note: Neither of these are fully integrated, but can be accessed fully through python blocks. The most important functions are available directly in PocketML.

| Library |  | Features |
| --- | --- | ---|
| numpy | lib/math.ml| 1D arrays as vectors (`Vec`) |
| kivy | lib/tea.ml | TEA-inspired GUI library |
| lark | lib/parsing.ml | generate custom parsers from a grammar file/string |
