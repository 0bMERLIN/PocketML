import lib.math;

## Basic numeric calculus functions like differentiation, integration, series.

### ### Differentiation & Integration
let diff : (Number -> Number) -> Number -> (Number -> Number)
	# args: func, n
	# returns: n-th derivative of func.
;
let rec diff f n =
	let h = .1;
	if n <= 0 then f
	else
		let g = diff f (n-1);
		\x ->
			let dy = g (x+h) - g (x-h);
			let dx = 2*h;
			(if abs(dy/dx) < .01 then 0 else dy/dx)
;

let integral : (Number -> Number) -> Number -> Number -> Number
	# args: func, x_start, x_end
;
let rec integral f a b =
	let dx = .1;
	if a < b then f a * dx + integral f (a+dx) b
	else 0;

### ### Series expansions (Taylor, Fourier etc.)

let taylor : (Number -> Number) -> Number -> Number -> (Number -> Number)
	# args: f, n, x0, x
;
let taylor f n x0 x = sigma
	(\k -> pow (x-x0) k * diff f k x0 / fac k)
	0 n;

let fourier : (Number -> Number) -> Number -> (Number -> Number)
	# args: f, m, x
;
let fourier f m =
	let a0 = integral f (-pi) pi * 1/(2*pi);
	let a n =
		integral
			(\x -> f x * cos (n*x))
		(-pi) pi *  1/pi;
	let b n = integral
			(\x -> f x * sin (n*x))
		(-pi) pi *  1/pi;
	
	\x -> a0 + sigma
		(\k -> a k * cos(k*x) + b k * sin(k*x))
		1 m
;

module (*)