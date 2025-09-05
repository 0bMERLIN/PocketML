import cProfile
import pstats
from interpreter.typecheck import load_file
import interpreter.path as path

def main():
    path.cwd = "examples/examples"
    load_file("examples/examples/lp.ml")

if __name__ == "__main__":
    cProfile.run('main()', 'typecheck.prof')
    stats = pstats.Stats('typecheck.prof')
    stats.sort_stats('cumtime').print_stats(30)  # Top 30 slowest functions

