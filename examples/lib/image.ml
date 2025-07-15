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

@curry
def PML_imgMap(texture, f):
	try:
		arr = np.frombuffer(texture.pixels, dtype=np.uint8).copy()
		w, h = texture.width, texture.height
		for y in range(h):
			for x in range(w):
				pos = (x + y * w) * 4
				color = arr[pos:pos+4]
				new_color = f(x)(y)(np.array(color))
				arr[pos:pos+4] = list(new_color)
		texture.blit_buffer(arr.tobytes(), colorfmt='rgba', bufferfmt='ubyte')
	except Exception as e:
		print(e)

def imgGet(buf, x, y):
	arr,w,_ = buf
	pos = (x + y * w) * 4
	return arr[pos:pos+4]

def PML_imgBuf(tex):
	return (np.frombuffer(tex.pixels, dtype=np.uint8),tex.width,tex.height)

def imgSave(fname, texture):
	data = io.BytesIO()
	CoreImage(texture).save(data, fmt='png')
	with open(SP + fname, "wb+") as f:
		f.write(data.getvalue())
	print("Image saved " + fname)

def PML_imgLoad(p):
	try:
		t = CoreImage(SP + p).texture
		t.mag_filter = "nearest"
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

%%%;

import lib.std;

data Img;
data Buffer; # more efficient for getting pixels
type Color = Vec;

let setpixel : Img -> Vec -> Color -> Unit; # slow. Use imgMap instead

let image : Vec -> Img;
let imgMap : Img -> (Number->Number->Color->Color) -> Unit;
let imgBuf : Img -> Buffer;
let imgGet : Buffer -> Vec -> Vec;
let imgSave : String -> Img -> Unit;
let imgLoad : String -> Img;
let imgCopy : Img -> Img;
let imgClear : Img -> Color -> Unit;

let imgFlipH : Img -> Img;
let imgFlipV : Img -> Img;

module (*)