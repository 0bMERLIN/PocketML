# Blog: Module functors in PocketML
<small>July 12th '25</small>

---
I recently posted about PocketML on reddit and got a comment about the lack of modules in a language with "ML" in the name.

TL;DR for this post:
- modules are good :)
- PocketML can do modules using records (see code below)
- No modules in the standard library though, because they take too long to compile and are not terse on the users side.

#### 1.0 Modules in StandardML

The core idea is to be able to reuse more of the (library) code we write, by replacing type-specific functions with a module that our code takes as a parameter and which can be switched out by the user/caller depending on what type they want our code to process. More on this in section 1.1.

Here's a quick rundown of how StandardML does this:

- *signatures* are the type signatures of modules. They specify the contents of the module.

- *modules* are the containers for the code/types we want to pass around.

- *functors* are (potentially compile-time) functions that take a module and return a module. An example could be a `Dictionary` functor that takes in a module describing a hashable type and returns a module with all the important dictionary functions for this type.

#### 1.1 End goal
Let's take the example of getting the second ("snd") element from a sequence:

```python
# gets the second element from a Vec
let vecSnd : Vec -> Number;
let vecSnd = ...;

let listSnd : List a -> a;
let listSnd = ...;

let strSnd : String -> String;
let ...

```

We'd have to write the same function for every type! This pattern actually comes up in PocketML's standard library: There's `strLen`, `len` (for lists) and `vecLen`. That's atrocious from an ML programmers point of view! Imagine adding another type - then we'd have to write every operation again.

The most important use case for ML modules is now to turn the first code fragment (which scales badly) into the following one:

```
let snd : (module Sequence l e) -> l -> e;
let snd m seq = m.getElementAt 0 seq;
```

We can just write one generic function that works on every type that has a corresponding `Sequence` module implemented for it. In our example `String`, `List` and `Vec` all support indexing, so implementing `Sequence` is trivial.


#### 1.2 Actually implementing it
As noted at the start, we do have a way to store named values/functions and pass them around - records. Passing around types is actually just as easy, but only if we do some reparameterisation (`List a` would become `Seq (List a) a` in module form):

```python
data Seq l e = Seq
	{ hd : l -> e
	, tl : l -> l
	}
	# a sequence with a head and tail.
;
```

This is an example of how one would create a module _signature_ in PocketML.

Let's implement this module for `Vec`s:

```sml
type VecSeq = Seq Vec Number;

let vecTail : Vec -> Vec;
let vecTail v = vecSlice 1 (vecLen v) v;

let vecSeq : VecSeq;
let vecSeq = Seq { hd = vecAt 0, tl = vecTail };
```

That was easy and we need stuff like head and tail for vectors anyways! (I'd count this as zero overhead/unnescessary code for now!)

Now another user might want to take the second element of a list. Hopefully, instead of writing a list-specific `snd` function, they do the following:

```python
data Snd l e = Snd { snd : l -> e }
	# something `l` you can take the second
	# element `e` of
;

let snd : Snd l e -> l -> e
	# getter for ease of use
;
let snd m = case m | Snd s -> s.snd;

let functorSnd : Seq l e -> Snd l e;
let functorSnd m = case m | Seq s ->
	Snd { snd = times 2 (s.tl) >> s.hd };
```

They might just pass in their implementation of `Seq` for lists, but we want to operate on vectors now. We can just reuse their code by passing in our `Vec` sequence!

```sml
let vecSnd : Snd Vec Number;
let vecSnd = functorSnd vecSeq;
```

If we leave out the type annotation, that's just one line per type.
We've gone from writing every general function for every type (Imagine writing `map`, `filter`, `foldr`, `indexAt` etc. for all types that store multiple elements) to writing _a single line_ for every type. Thats O(N^2) to O(N) lines of code, which is quite amazing actually.

With 10 sequence-like types and 20 generic functions, we'd have to write at least 200 lines if every function was a one liner. Now we only have to write 30 lines.

#### 1.3 Overhead for the user

Using our "snd" function for `Vec`s looks like this:

```
(snd vecSnd) @(1,2,3,4);
```

That's actually longer than with our naïve implementation, but the idea is that the time we waste using modules is completely offset by the time we saved earlier.

Modern ML languages often use implicit modules to reduce boilerplate for the user.

#### 1.4 Modules in the standard library
One issue is that compiling modules needs a lot of type checking. Because PocketML is mainly a mobile app, we can't waste too much time compiling libraries.

Using the naïve implementation, we just have to read in all the type declarations, because the functionality is usually implemented using python interop.

One thing I will consider using this design pattern for, is to get rid of all the horrible variants of `len`. They introduce a lot of mental overhead which is not welcome in a language meant for tinkering.

---

Thank you very much for reading 'til the end. I might write some more blog posts if I come across another interesting concept I can bring into PocketML.