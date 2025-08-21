import lib.tea;

let myshader = """

#ifdef GL_ES
precision mediump float;
#endif

uniform sampler2D tex;
varying vec2 tex_coord0;
uniform vec2 size;
uniform float time;

void main(void) {
	vec2 uv = tex_coord0.xy;
    
    vec4 acc = vec4(0.0);
    float w = min(100.0, time*10.0);
    int i = 0;
    float step = w/10.0;
    for (float y = -w; y <= w; y += step) {
    	for (float x = -w; x <= w; x += step) {
    		acc += texture2D(tex,
    			vec2(uv.x+x/size.x,
    				uv.y+y/size.y));
    		i++;
    	}
    }
    acc = acc / float(i);
    
    gl_FragColor = vec4(acc.rgb, 1.0);
}
""";

let startTime = time ();

let img = imgLoad "assets/test.png";

let tick e _ = time ();
let view _ = Many
	[ SRect myshader
		[ UniformTex0 "tex" img
		, UniformVec2 "size" @(width/2,width/2)
		, UniformFloat "time" (time()-startTime)
		]
		@(width/2,width/2) @(0,0)
	]
;


setTick 0 tick view
