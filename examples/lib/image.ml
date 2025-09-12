import lib.shaders;

%%%
EDITOR = globals()["editor"] if "editor" in globals() else None

def print(*xs):
	EDITOR.terminalout.text += (" ".join(map(str,xs))) + "\n"

from kivy.core.image import Image as CoreImage
from kivy.graphics.texture import Texture
import io
from kivy import platform
import numpy as np

SP = "/storage/emulated/0/Android/data/org.test.myapp/files/" \
	if platform == "android" else "examples/"

def mkimage(width, height):
	pixels = bytearray(width * height * 4)
	texture = Texture.create(size=(width, height), colorfmt="rgba")
	texture.blit_buffer(pixels, colorfmt='rgba', bufferfmt='ubyte')
	texture.mag_filter = "nearest"
	texture.min_filter = "nearest"
	return texture

def PML_imgCopy(i):
	tex = Texture.create(size=(i.width, i.height), colorfmt="rgba")
	tex.blit_buffer(i.pixels, colorfmt="rgba", bufferfmt="ubyte")
	tex.flip_vertical()
	tex.mag_filter = "nearest"
	tex.min_filter = "nearest"
	return tex

def setpixel(texture, x, y, c):
	if not (0 <= x < texture.width and 0 <= y < texture.height):
		return
	try:
		arr = np.frombuffer(texture.pixels, dtype=np.uint8).copy()
		pos = (x + y * texture.width) * 4
		arr[pos:pos+4] = c
		texture.blit_buffer(arr.tobytes(), colorfmt="rgba", bufferfmt="ubyte")
	except Exception as e:
		print(e)

def setfilter(t):
	t.mag_filter = 'nearest'
	t.min_filter = 'nearest'


@curry
def PML_imgMap(texture, f):
	PML_imgMapRect(texture.size,(0,0),texture,f)

@curry
def PML_imgMapRect(size, pos, texture, f):
	try:
		w, h = texture.width, texture.height
		arr = np.frombuffer(texture.pixels, 
			dtype=np.uint8) \
			.copy().reshape((h, w, 4))
		pos=[*map(int,list(pos))]
		size=[*map(int,list(size))]
		for y in range(
				pos[1], min(h, pos[1]+size[1])):
			for x in range(
					pos[0],
					min(w, pos[0]+size[0])):
				color = arr[y,x]
				new_color = f(x)(y)(color)
				arr[y,x] = [*map(int,list(new_color))]
		texture.blit_buffer(arr.tobytes(), 
			colorfmt='rgba',
			bufferfmt='ubyte')
	except Exception as e:
		print(e)
	setfilter(texture)

def imgGet(buf, x, y):
	arr,w,_ = buf
	pos = (x + y * w) * 4
	return arr[pos:pos+4]

def PML_imgBuf(tex):
	return (np.frombuffer(tex.pixels, dtype=np.uint8),tex.width,tex.height)

def imgSave(fname, texture):
	data = io.BytesIO()
	CoreImage(texture).save(data, fmt='png')
	with open(path.cwd + fname, "wb+") as f:
		f.write(data.getvalue())
	print("Image saved " + fname)

def PML_imgLoad(p):

	try:
		t = CoreImage((path.cwd + "/" + p).replace("//", "/")).texture
		t.mag_filter = "nearest"
		# if t.uvsize[1]<0:
		# 	t.flip_vertical()
		return t
	except Exception as e:
		print("Oops", e)

def PML_imgClear(texture, color):
	arr = np.full((texture.height, texture.width, 4), color, dtype=np.uint8)
	texture.blit_buffer(arr.tobytes(), colorfmt="rgba", bufferfmt="ubyte")


# Interface bindings (unchanged)
globals().update(locals())

PML_image = lambda a: mkimage(*map(int, list(a)))
PML_setpixel = lambda i: lambda pos: lambda c: (
	setpixel(i, *map(int, list(pos)), [*map(int, list(c))])
)
PML_imgSave = lambda p: lambda i: imgSave(p, i)
PML_imgGet = lambda b: lambda pos: imgGet(b, *map(int, list(pos)))
PML_imgFlipH = lambda t: (t1 := PML_imgCopy(t), t1.flip_horizontal(), t1)[-1]
PML_imgFlipV = lambda t: (t1 := PML_imgCopy(t), t1.flip_vertical(), t1)[-1]

from kivy.graphics import Fbo, Rectangle, ClearBuffers, ClearColor
from kivy.graphics.texture import Texture

def PML_mkAtlasImg(textures):
    textures = convlist(textures)
    if not textures:
        raise ValueError("No textures provided")

    width = textures[0].width
    colorfmt = textures[0].colorfmt

    for tex in textures:
        if tex.colorfmt != colorfmt:
            raise ValueError("All textures must have the same width and color format")

    total_height = sum(tex.height for tex in textures)

    # Create an FBO with the final size
    fbo = Fbo(size=(width, total_height), with_stencilbuffer=False)

    with fbo:
        # Clear the FBO with transparent background
        ClearColor(0, 0, 0, 0)
        ClearBuffers()

        y_offset = 0
        for tex in textures:
            Rectangle(texture=tex, pos=(0, y_offset), size=(tex.width, tex.height))
            y_offset += tex.height

    # Force the FBO to render
    fbo.draw()
    setfilter(fbo.texture)
    return fbo.texture

PML_imgSize = lambda i: \
	np.array([i.width,i.height])

PML_imgWidth = lambda i: i.width
PML_imgHeight = lambda i : i.height

@curry
def PML_imgShade(img, fs):
	fbo = Fbo(size=img.size)
	fbo.shader.fs=fs
	if fbo.shader.success == 0:
		PML_print(checkshader(fs))
		return img
	with fbo:
		Rectangle(pos=(0,0),size=img.size,
			texture=img)
	fbo.draw()
	return fbo.texture

@curry
def PML_imgSmooth(i):
	i.mag_filter="linear"
	i.min_filter="linear"
	return i

%%%;

import lib.std;

## A library for kivy textures. An `Img` is a kivy texture. Images can be loaded from disk or created programmatically.

### ### Definitions & Creating images/buffers

data Img;
data Buffer; # more efficient for getting pixels
type Color = Vec;

let setpixel : Img -> Vec -> Color -> Unit; # slow. Use imgMap instead

let image : Vec -> Img;
let imgLoad : String -> Img;
let imgBuf : Img -> Buffer;

### ### Functions

let imgSize : Img -> Vec;
let imgHeight : Img -> Number;
let imgWidth : Img -> Number;
let imgCopy : Img -> Img;
let imgMap : Img -> (Number->Number->Color->Color) -> Unit;
let imgGet : Buffer -> Vec -> Vec;
let imgSave : String -> Img -> Unit;
let imgClear : Img -> Color -> Unit;
let imgMapRect: Vec -> Vec -> Img -> (Number->Number->Color->Color) -> Unit
	# args: size, pos, img, func
;
let imgSmooth : Img -> Img;
let imgFlipH : Img -> Img;
let imgFlipV : Img -> Img;

data Uniform
	= UniformFloat String Number
	| UniformInt String Number
	| UniformVec2 String Vec
	| UniformVec3 String Vec
	| UniformVec4 String Vec
	| UniformTex0 String Img
	# --hide
	# TODO
;

let imgShade : Img -> String -> Img;

data Atlas = Atlas Img (List Vec)
	# arguments: atlasTex, imgSizes
;

let mkAtlasImg : List Img -> Img
	# make an atlas of vertically stacked
	# images from the input images.
;

let mkAtlas : List Img -> Atlas
	# create an Atlas from the input images
;
let mkAtlas is = Atlas
	(imgSmooth $ mkAtlasImg is)
	(map imgSize is);


module (*)