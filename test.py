from interpreter.interpreter import file_to_python, run_file
from interpreter.parser import parse_file
import interpreter.path as path
import sys

path.cwd = "/".join(sys.argv[-1].split("/")[:-1])

run_file(sys.argv[-1], print)
