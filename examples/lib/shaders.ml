%%%

from kivy.graphics.opengl import *
from ctypes import create_string_buffer, byref, c_int
from ctypes import c_char_p

DEFAULT_FRAG_HEADER = ''''''

DEFAULT_VERTEX_SHADER = '''
#ifdef GL_ES
precision mediump float;
#endif

attribute vec2 position;
attribute vec2 tex_coord0;
varying vec2 tex_coord;

void main(void) {
    gl_Position = vec4(position, 0.0, 1.0);
    tex_coord = tex_coord0;
}
'''

def compile_shader(source, shader_type):
    shader = glCreateShader(shader_type)
    glShaderSource(shader, source.encode('utf-8'))
    glCompileShader(shader)

    status = glGetShaderiv(shader, GL_COMPILE_STATUS)
    if status == 0:
        log = glGetShaderInfoLog(shader, 1024)  # Provide buffer size
        glDeleteShader(shader)
        return None, log.decode('utf-8')
    return shader, None

def checkshader(fragment_source: str, vertex_source: str = DEFAULT_VERTEX_SHADER) -> str | None:
    # Compose fragment shader with default header
    full_fs_source = DEFAULT_FRAG_HEADER + '\n' + fragment_source

    vertex_shader, error = compile_shader(vertex_source, GL_VERTEX_SHADER)
    if error:
        return f"Vertex shader compile error:\n{error}"

    fragment_shader, error = compile_shader(full_fs_source, GL_FRAGMENT_SHADER)
    if error:
        glDeleteShader(vertex_shader)
        return f"Fragment shader compile error:\n{error}"

    program = glCreateProgram()
    glAttachShader(program, vertex_shader)
    glAttachShader(program, fragment_shader)
    glLinkProgram(program)

    link_status = glGetProgramiv(program, GL_LINK_STATUS)
    if link_status == 0:
        log = glGetProgramInfoLog(program, 1024)
        glDeleteProgram(program)
        return f"Shader link error:\n{log.decode('utf-8')}"

    glDeleteShader(vertex_shader)
    glDeleteShader(fragment_shader)
    return None  # success

%%%;

## Internally used for working with kivy glsl shaders

module (*)