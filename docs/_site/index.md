PocketML is a functional statically-typed language designed for
tinkering / small projects. Its main feature is the editor android app.
The language is similar to Elm and is based on a python backend.

Visit the [PocketML](https://github.com/0bMERLIN/PocketML) repository.

## Guides
- [Language/Installation Guide](Guide.md)
- [Programming in PocketML: The Game of Life](GameOfLife.md)
- [Programming in PocketML: Making a calculator GUI](CalcGUI.md)
- [Hacking / Python interop](Hacking.md)
- [Features, Libraries & Type system](Features.md)

## Blog
- [Powerful ML Modules in PocketML](BlogModules.md)

## Docs
[Library documentation](LibDocs.md)

## Motivation
This project is an exercise in input schemes. A terse functional language paired with cursor navigation (AnysoftKeyboard) using hardware buttons might actually make coding on mobile/a small screen feasable.

I learned to code in python on my phone using the app PyDroid3. Nowadays I regularly use the app to run some quick calculations for my phyics & maths classes or just to kill boredom on a long trip. This project was created because PyDroid3 has ads and because of my preference for functional languages.

## Python Libraries
> Note: Neither of these are fully integrated, but can be accessed fully through python blocks. The most important functions are available directly in PocketML.

| Library |  | Features |
| --- | --- | ---|
| numpy | lib/math.ml| 1D arrays as vectors (`Vec`) |
| kivy | lib/tea.ml | TEA-inspired GUI library |
| lark | lib/parsing.ml | generate custom parsers from a grammar file/string |


