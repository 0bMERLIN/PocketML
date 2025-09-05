# Blog: Dependent types with PocketML
<small>Sep 4th '25</small>

---
As my language PocketML is becoming more and more usable, I wanted to combine my interest in dependent types with a suitable example I can implement in PocketML. This post highlights the core ideas of implementing a type checker for dependent types using λP, as I didn't find any simple guides online.

My goal for this post is for it to be understandable and usable for programming language devs and FP programmers that have worked with languages like Haskell, OCaml or Elm.

At the end of this post you can also find a breakdown of how much time the PocketML compiler spends compiling the code, which is quite interesting, because I don't think I've ever seen a compiler this slow!

#### 1.0 λP
Different type systems in the family of the lambda calculus are labeled by their functionality. The _Simply Typed Lambda Calculus_ (STLC) is the first step on our way to dependent typing and adds function types. Therefore, it's also sometimes called "λ→".

> Here's an example:
> ```
> λ x : a . x
> ```
> The above term has the type `a -> a`.
>
> Or the equivalent in Haskell/OCaml/...:
> ```
> \x -> x
> ```
> You'll probably have correctly identified this to be the identity function, that just returns its argument.

Formally, the STLC includes _type variables_ like `a` and function types like `a -> a`.

To get basic dependent types, we only have to add one more thing: The dependent function type Π (Pi).  I like to see Pi as an extension on top of the regular `->`-type. The result is the language/type theory called λP.  Let's have a look at some use cases for Pi in a basic hypothetical dependently typed language.

>```
>head = λ (n : Nat) -> λ (a : *) -> λ (v : Vec (n+1) a) -> case v
>   | Cons x _ -> x
>```
> "\*" in this syntax just means "Type"; `a` is of type "*", meaning it is a _type variable_.
> 
> Notice the missing case for the empty Vec.
> We don't need that because the type encodes that, for any natural number (here n = 0, 1, ... ∞), the Vec has a length one larger. That makes the length of the Vec >= 1 or non-empty.
>
> In the type of `head`, the `->` that would be used in the simply typed lambda calculus is now replaced with Pi-types:
> ```
> head : Π (n : Nat) -> Π (a : *) -> Π (v : Vec (n+a) a) -> a
> ```
> The return type `a` does not have any dependence on `v`, so we could also use the arrow type as a sort of syntax sugar for the  non-dependent Pi:
> ```
> head : Π (n : Nat) -> Π (a : *) -> (Vec (n+a) a -> a)
> ```

>Here's the identity function for all input types to further illustrate Pi:
>```
>id : Π (t : *) -> t -> t
>id = λ (t : *) -> λ (x : t) -> t
>-- lets use id!
>id Nat 10 -- returns 10, obviously.
>```

Before we move on to the next section, I want to highlight the similarity between lambda functions and the Pi type. In the implementation, the only real difference is that we also assert type equality when applying a Pi. In the last example, we could have also used `id` like this:
```haskell
id 10 Nat
```
with the arguments in the wrong order. That's where the type equality check should then yield a "Type mismatch" error, because the first Pi `Π (t : *) ->  ...` expects a type (again, represented syntactically as "\*"), not a number like `10`.

#### 1.1 Grammar & the AST
As stated above, implementing dependent types is actually not that different from the simply typed lambda calculus, with the exception of adding Pi types.

If you've written an interpreter for the STLC before, you probably know the drill; we start with our "expression" type, that holds our AST.
From now on I'll use PocketML, which is very similar to Haskell or OCaml.

```haskell
data Term
    = Var String
    | Lam String Term Term
    | Pi String Term Term
    | App Term Term
    | Star
    | Nat
    | NatLit Number
;
```

You should recognise `Var`, `Lam` (lambda function) and `App` (applying a function) from the simply typed lambda calculus.
Types are also included in our Term type because dependent typing allows us to mix and match types and values! That explains `Nat`, which is the type of numbers (natural numbers). `NatLit` is such a number. `Star` is "\*" from earlier (the type of types).

#### 1.2 Type checking
Lets get straight to the type checker function, which is our end goal.

Variables and numbers are pretty intuitive:
```sml
let typ : Ctx -> Term -> Term;
let typ c = \case
      Var x -> (case dictGet c x
        | Just res -> res
        | Nothing -> error "variable not found.")
    | Nat -> Star
    | NatLit _ -> Nat
    | ...
```
Number literals (`NatLit`s) have the type `Nat` and `Nat` itself is a type, so it has type "\*" (`Star`).

Lambdas are surprisingly easy, their type is just a Pi type (our replacement for the boring old `->` type from the STLC) with the argument and the arguments type. The return type is just the type of the body.

```sml
    ...
    | Lam x t b ->
        let bodyType = typ (dictInsert x c t) b;
        Pi x t bodyType
    ...
```
As their name suggests, Pi types are also just types, so their type is simply "\*".

```sml
    ...
    | Pi x t b -> Star
    ...
```

Lastly we need to handle application:

```sml
...
| App f a -> (case typ c f
    | Pi x t b ->
        let aT = typ c a;
        let _ = if not (betaEquiv t aT)
            then error
                ("Type mismatch: " + str t
                + ", " + str aT)
            else ();
        subst x a b
    | o -> error ("expected a Pi-type, got " + str o))
```
First we get the type of the argument to match it againts what the Pi type expects.

Let's say we input a function to increment a `Nat` of the type `Π (n : Nat) -> Nat` and the argument might have the type `*` because the programmer made a mistake.

Next `betaEquiv` would determine that `Nat` != `Star` and we can throw a "Type mismatch" error!

If we instead did get past the type match, we would substitute the parameter for the argument inside the return of the Pi-type.

Let's look at a more complicated case to see what the substitution `subst` does:
```
head : Π (n : Nat) -> Π (a : *) -> Vec (n+1) a -> a
head = ...

myVec : Vec 1 Nat
myVec = Cons 42 Nil

head 0 Nat myVec
```

in the last line, we would initially apply `Π (n : Nat) -> ...` to `0`. In the type checker case for `App`, one would the substitute (`subst`) `n` for `NatLit 0`.

#### 1.3 Are we done?
Sort of. We're still missing an implementation for `betaEquiv` and `subst`. The following sections just cover the implementation of those, which might not be as interesting for people familiar with type checking (substitution) and beta equivalence.

Beta equivalence is also incredibly cumbersome to implement in the AST representation we chose. DeBrujin indices, a different way of naming variables would make this a lot easier.

Let's get to it for the sake of completeness!

#### 1.4 Substitution
The substitution function just replaces any occurance of a given variable name with a given term.

> `subst` is also the sort of substitution we intuitively do when plugging in a number into a mathematical function:
>
>If we let `f(x) = x + 10`
>then applying `f` means substituting `x` for our input:
>
> `f(10) = 10 + 10 = 20`

```sml
let subst : String -> Term -> Term -> Term;
let subst s r = \case
    Var x -> if x == s then r else Var x
    | App f a -> App (subst s r f) (subst s r a)
    | Lam x t b -> Lam x (subst s r t) (subst s r b)
    | Pi x t b -> Pi x (subst s r t) (subst s r b)
    | other -> other
;
```

#### 1.5 Beta equivalence
If you've used a language like haskell before, you know the usual type matching.

Giving haskell the term `head [1,2]` will result in the type checker matching the list type in `head :: List a -> a` with our input `List Int` for example. First we match `List` with `List` and then `a` with `Int`.

Because dependent typing also allows for types like `Vec (10+1) Nat` (a vec of length 11), we need to "evaluate" the type before matching it. That's the job of `betaEquiv`:

```sml
let betaEquiv : Term -> Term -> Bool;
let betaEquiv t1 t2 = alphaEquiv
    dictEmpty dictEmpty
    (normalForm t1) (normalForm t2);
```
Beta equivalence involves converting the types we're comparing to a "normal form" (evaluating expressions like `10+1` etc.).

##### Alpha equivalence

Then the resulting types are compared using alpha equivalence, which takes into account that types with different type variable names can have the same meaning: Take for example
- `Π (t : *) -> t -> t`
- vs. `Π (a : *) -> a -> a`

They're both the type of the polymorphic identity function, just with different variable names.
Alpha equivalence would still count them as equal, which is what we need.

#### 1.6 Alpha equivalence
Here I will only cover the part of `alphaEquiv` that actually deals with the variable names. The rest just does a tree walk of the terms being compared and applies `alphaEquiv` to the sub-terms (just like `subst`). For more details, take a look at [examples/examples/lp.ml](https://github.com/0bMERLIN/PocketML/blob/main/examples/examples/lp.ml) in the git repo.


To check if two terms like `λ x : a . x` and `λ y : a . y` are alpha-equivalent, we will associate every variable with a number representing how far away from the last binder (lambda) it is. Our examples will now _both_ become: `λ : a . 0`. "x" is now represented using "0", because it is the variable bound at the 0th level of the term. In `alphaEquiv`, we keep track of the fact that "x" and "y" were bound in the 0th level of the term (the `Lam` node), using dictionaries. In this case, we would have `[("x", 0), ("y", 0)]`. If the variable is free, meaning it was not bound in the term we're checking (like `a`), it will just be compared by its name.

Also note, that we're keeping track of the variables' levels with _two_ contexts/dictionaries, one for each of the terms.

```sml
let alphaEquiv : Dict Num -> Dict Num -> Term -> Term -> Bool;
let alphaEquiv c1 c2 t1 t2 = case (t1, t2)
	| (Var x, Var y) ->
		(case (dictGet c1 x, dictGet c2 y)
			| (Just v1, Just v2) ->
				let _ = print ("v1,v2: " + str v1 + ", " + str v2);
				v1 == v2
			| (Nothing, Nothing) ->
				let _ = print ("x,y: " + str x + ", " + str y);
				x == y
			| _ -> False
		)
```

When comparing two lambdas, we just save the names into the contexts and compare the sub-terms:
```sml
...
| (Lam x1 t1 b1, Lam x2 t2 b2) ->
    let l = len (dictItems c1);
    alphaEquiv c1 c2 t1 t2 && alphaEquiv
        (dictInsert x1 c1 l)
        (dictInsert x2 c2 l)
        b1 b2
...
```

#### 1.7 Conclusion

As well as starting my journey into dependent typing, I also learned a lot about PocketML's user experience:
- PocketML is a scripting language, meant for exactly these small-scale projects.
- Long compile times are the biggest issue I faced. `lp.ml` has 100 LoC and takes up to 30 seconds on the first compile! When library modules are cached, the time goes down to 10s, which is still horrible!

Here's a breakdown of the time usage when compiling `lp.ml`.
```
[PARSING] (examples/examples/lp.ml)	 2.4139

[PARSING] (examples/lib/dict.ml)	 0.3532
[TYPED] (examples/lib/dict.ml)	 0.0045

[PARSING] (examples/lib/maybe.ml)	 0.8008
[PARSING] (examples/lib/list.ml)	 3.8617
[PARSING] (examples/lib/util.ml)	 4.26
[TYPED] (examples/lib/util.ml)	 0.1461
[TYPED] (examples/lib/list.ml)	 5.4157

[CACHED] (examples/lib/util.ml)	 0

[PARSING] (examples/lib/string.ml)	 0.3469
[TYPED] (examples/lib/string.ml)	 0.002

[COMPILE] (examples/examples/lp.ml)	 13.5368
```

For now I switched the parser to LALR, which yielded a 3x total compile time improvement (30s to 10s) from the Earley parser. As I'm working on an incredibly slow laptop, I'll have to see how compile times hold up on my phone and if the user experience is acceptable now.
You'll hear from me again, if I do a rewrite!

---

Thank you very much for reading until the end. This blog post was a lot of fun to write and I hope to find other topics I can cover in PocketML.
