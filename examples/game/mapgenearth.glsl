#ifdef GL_ES
precision mediump float;
#endif

vec2 fade(vec2 t) {
    return t * t * t * (t * (t * 6.0 - 15.0) + 10.0);
}

float lerp(float a, float b, float t) {
    return a + t * (b - a);
}

// Hash function to generate gradients
vec2 hash(vec2 p) {
    p = vec2(dot(p, vec2(127.1, 311.7)),
             dot(p, vec2(269.5, 183.3)));
    return -1.0 + 2.0 * fract(sin(p) * 43758.5453123);
}

// 2D Perlin noise
float perlin(vec2 p) {
    vec2 pi = floor(p);
    vec2 pf = p - pi;
    vec2 f = fade(pf);

    float n00 = dot(hash(pi + vec2(0.0, 0.0)), pf - vec2(0.0, 0.0));
    float n10 = dot(hash(pi + vec2(1.0, 0.0)), pf - vec2(1.0, 0.0));
    float n01 = dot(hash(pi + vec2(0.0, 1.0)), pf - vec2(0.0, 1.0));
    float n11 = dot(hash(pi + vec2(1.0, 1.0)), pf - vec2(1.0, 1.0));

    float nx0 = lerp(n00, n10, f.x);
    float nx1 = lerp(n01, n11, f.x);
    return lerp(nx0, nx1, f.y);
}

// Perlin noise with octaves
float noiseHelp(vec2 p, int octaves, float persistence) {
    float total = 0.0;
    float amplitude = 1.0;
    float frequency = 1.0;
    float maxValue = 0.0;

    for (int i = 0; i < octaves; i++) {
        total += perlin(p * frequency) * amplitude;
        maxValue += amplitude;
        amplitude *= persistence;
        frequency *= 2.0;
    }

    return total / maxValue;
}

float noise(vec2 p, int octaves, float persistence) {
	float seed = 5.0;
	
    float n = noiseHelp(p+vec2(seed), octaves, persistence)/2.0+0.5;

	n = clamp(n*3.0 - 1.0, 0.0, 1.0);
	return n;
}

varying vec2 tex_coord0;

void main() {
	float h = noise(tex_coord0.xy*3.0,5,0.5);
	h = max(.4,h);
	
	vec3 col;
	if (h <= .4) col = vec3(0,.3,1.0);
	else if (h < .5) col = vec3(1,1,0);
	else if (h < .7) col = vec3(.3,.9,.2) * h;
	else col = vec3(1,1,1);
	
	gl_FragColor = vec4(col,h);
}