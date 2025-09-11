<img src="assets/logo.jpeg" style="float: left; margin-right: 50px" width="250"/>

PocketML&nbsp;is&nbsp;a&nbsp;__language__ and&nbsp;__IDE__&nbsp;for&nbsp;coding&nbsp;your&nbsp;phone.
Whip up a quick _GUI_, _plot_ or even prototype _your new programming language_ _anywhere_ and _on the go_!

Visit the [PocketML](https://github.com/0bMERLIN/PocketML) repository.

---

A little sample:
```haskell
app () (\event state -> state + 1)
    (\state -> Label "mylabel" (str state) @(100, 100) @(0, 0))
```

## Guides
- [Language/Installation Guide](Guide.md)
- [Programming in PocketML: The Game of Life](GameOfLife.md)
- [Programming in PocketML: Making a calculator GUI](CalcGUI.md)
- [Hacking / Python interop](Hacking.md)
- [Features, Libraries & Type system](Features.md)

## Blog
- [Powerful ML Modules in PocketML](BlogModules.md)
- [Dependent types with PocketML](BlogDependentTypes.md)

## Docs
- [Library documentation](LibDocs.md)

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


