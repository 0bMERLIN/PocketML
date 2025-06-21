import lib.math;

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

let rec integral f a b =
	let dx = .1;
	if a < b then f a * dx + integral f (a+dx) b
	else 0;

let taylor f n x0 x = sigma
	(\k -> pow (x-x0) k * diff f k x0 / fac k)
	0 n;

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