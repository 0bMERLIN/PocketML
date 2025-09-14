#ifdef GL_ES
precision mediump float;
#endif

#define N 10
/* max. number of elements in atlas/etc. */

varying vec2 tex_coord0;

uniform vec2 pos;
uniform float angle;

uniform sampler2D tex;
uniform float atlasMap[N];
uniform vec2 atlasSizes[N]; // sizes of the images on the atlas in pixels
uniform vec2 atlasImgSize; // size of the atlas texture in pixels
uniform int atlasSize;

uniform vec4 spriteLines[N];
uniform vec2 spriteHeights[N];
uniform int spriteTextures[N];
uniform int nSprites;
uniform int worldTexture; // which index in the atlas is the world map
uniform vec3 sky;
uniform bool fogEnabled;

float vscale = .15;
float pi = 3.141;
float horizon = 0.5;
float fov = 60.0;

float texHeight(int t) {
	return (t < atlasSize-1)
		? (atlasMap[t+1]-atlasMap[t])
		: (1.0-atlasMap[t]);
}

vec4 sample(vec2 v, int t) {
	if (v.x>1.0 || v.x<0.0
		|| v.y>1.0 || v.y<0.0) {
		return vec4(0.0);
	}
	
	vec2 sz = atlasSizes[t];
	float h = texHeight(t);
	vec2 p = v;
	return texture2D(tex, vec2(p.x * (atlasSizes[t].x / atlasImgSize.x),atlasMap[t] + p.y*h));
}

vec4 sample0(vec2 v) {
	return sample(v,0);
}

vec4 sample1(vec2 v) {
	return sample(v,1);
}

// returns vec2(z,uvx)
vec2 raySegmentInt(vec2 ro, vec2 rd, vec2 a, vec2 b) {
    vec2 v = b - a;
    vec2 w = ro - a;
    float det = rd.x * v.y - rd.y * v.x;
    if (abs(det) < 1e-8) return vec2(-1.0); // parallel or collinear

    float t = ( v.x * w.y - v.y * w.x) / det;
    float u = (rd.x * w.y - rd.y * w.x) / det;

    if (t >= 0.0 && u >= 0.0 && u <= 1.0) {
    	return vec2(t,u);
    }
    return vec2(-1.0);
}

float random(float xx, float yy) {
	int x = int(xx);
	int y = int(yy);
	float f = sin(xx * 12.9898 + yy * 78.233) * 43758.5453;
	return fract(f);
}

void main(void) {
	vec2 uv = tex_coord0.xy;
	
	vec3 P = vec3(pos, sample(pos, worldTexture).a+0.05);
	
	float theta = angle + (uv.x-0.5)*pi*fov/180.0;
	float dist = 0.3;
	float dz = dist / 120.0;
	vec2 heading = vec2(cos(theta), sin(theta));
	
	vec4 col = vec4(sky, 1.0);

	// Add stars
	float starDensity = (uv.y > 0.5) ? 0.00000002 : 0.0;
	float star = random(uv.x + angle, uv.y);
	if (star < starDensity)
		col = vec4(1.0);

	float depth = 1000.0;
	
	// raycast
	for (float z = dist; z > 0.0; z -= dz) {
		vec2 ray = heading * z + P.xy;
	
		float s = sample(ray, worldTexture).a-P.z;
		float h = (s/z) * vscale + horizon;
		
		if (uv.y < h) {
			col = sample(ray, worldTexture);
			if (fogEnabled) {
				col.rgb =
					mix(col.rgb, sky,
						max(0.0, 2.0*(z/dist-.5)));
			}
			col.a=1.0;
			depth = z;
		}
	}
	
	// sprites
	for (int i = 0; i < nSprites; i++) {
		vec3 A = vec3(spriteLines[i].xy,
			spriteHeights[i].x);
		vec3 B = vec3(spriteLines[i].ba,
			spriteHeights[i].y);
	
		vec2 it = raySegmentInt(P.xy, heading,
			A.xy,B.xy);
		
		if (it.x > 0.0 && it.x < depth) {
			float uvy = (it.x*(uv.y-horizon)
				/vscale+P.z-A.z/vscale
				)/(B.z-A.z)*vscale;
			float uvx = it.y;
			
			vec4 c = sample(vec2(uvx,uvy),
					spriteTextures[i]);
			col = c.a*c + (1.0-c.a)*col;
			col.rgb =
				mix(col.rgb, sky,
					min(1.0, max(0.0, 2.0*(it.x/dist-.5))));
		}
	}
    
    gl_FragColor = col;
}