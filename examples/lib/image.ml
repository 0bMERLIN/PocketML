cache;

%%%

EDITOR = globals()["editor"] if "editor" in globals() else None

def print(*xs):
	EDITOR.terminalout.text += (" ".join(map(str,xs)))+"\n"

from kivy.core.image import Image as CoreImage
from kivy.graphics.texture import Texture
import io
from kivy import platform

SP = "/storage/emulated/0/Android/data/org.test.myapp/files/" \
	if platform == "android" else "examples/"

def mkimage(width,height):
	# Create pixel data (RGB format, flattened)
	pixels = bytearray([0 for y in range(height) for x in range(width * 4)])

	# Create a texture and load pixel data
	texture = Texture.create(size=(width, height),colorfmt="rgba")
	texture.blit_buffer(pixels, colorfmt='rgba', bufferfmt='ubyte')
	return texture

def PML_copyimg(i):
	tex = Texture.create(size=(i.width, i.height),colorfmt="rgba")
	tex.blit_buffer(i.pixels, colorfmt="rgba", bufferfmt="ubyte")
	tex.flip_vertical()
	return tex

def setpixel(texture,x,y,c):
	try:
		pixels = list(texture.pixels)
		if x > texture.width or x < 0 or y < 0 or y > texture.height:
			return
		pos = (x+y*texture.width) * 4
		pixels[pos:pos+4] = c
		texture.blit_buffer(bytearray(pixels), colorfmt='rgba', bufferfmt='ubyte')
	except Exception as e:
		print(e)

import numpy as np

def getpixel(tex, x,y):
	pos = (x+y*tex.width) * 4
	return np.array(list(tex.pixels[pos:pos+4]))

def saveimg(fname,texture):
	# Save the texture as a PNG file
	data = io.BytesIO()
	CoreImage(texture).save(data, fmt='png')

	# Write to disk
	import os
	with open(SP+fname, "wb+") as f:
		f.write(data.getvalue())
	print("Image saved assbsbs "+fname)


def PML_loadimg(p):
	try:
		t = CoreImage(SP+p).texture
		t.mag_filter = "nearest"
		return t
	except:
		print("Oops")

globals().update(locals())

PML_image = lambda a: mkimage(*map(int,list(a)))
PML_setpixel = lambda i: lambda pos: lambda c: (
		setpixel(i, *map(int,list(pos)),
			[*map(int, list(c))])
	)

PML_saveimg = lambda p: lambda i: saveimg(p,i)
PML_getpixel = lambda i: lambda pos: getpixel(i, *map(int,list(pos)))
PML_fliph = lambda t: (t1 := PML_copyimg(t), t1.flip_horizontal(), t1)[-1]
PML_flipv = lambda t: (t1 := PML_copyimg(t), t1.flip_vertical(), t1)[-1]

%%%;

import lib.std;

data Img;
type Color = Vec;
let image : Vec -> Img;
let setpixel : Img -> Vec -> Color -> Unit;
let getpixel : Img -> Vec -> Vec;
let saveimg : String -> Img -> Unit;
let loadimg : String -> Img;
let copyimg : Img -> Img;

let fliph : Img -> Img;
let flipv : Img -> Img;

module (*)