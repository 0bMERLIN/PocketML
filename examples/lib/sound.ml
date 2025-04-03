cache;

%%%
import math
import wave
import struct
from kivy.core.audio import SoundLoader

MAXAMP = 32767

def gen_wave(f, duration,
        filename="tone.wav",
        sample_rate=44100):
    
    num_samples=int(sample_rate*duration)
    wav_file = wave.open(filename, "w")
    wav_file.setnchannels(1)  # Mono
    wav_file.setsampwidth(2)  # 16-bit
    wav_file.setframerate(sample_rate)

    for i in range(num_samples):
        sample = f(i/sample_rate)
        wav_file.writeframes(
          struct.pack("<h", int(sample)))

    wav_file.close()

def sound(f, duration):
    filename = "tone.wav"
    gen_wave(f, duration, filename)
    sound = SoundLoader.load(filename)
    if sound:
        return sound

def play(s):
    s.play()

globals().update(locals())

# Example usage
play(sound(lambda t: MAXAMP * math.sin(2 * math.pi * 440 * t), 2))

%%%;

import lib.std;

data Sound;

# sound(generator, duration)
let sound : (Number -> Number) -> Number -> Sound;

let beep : Number -> Number -> Sound;
let beep freq dur = sound
    (\t -> mull %[MAXAMP, sin]%) 2

let play : Sound -> Unit;

module (*)




