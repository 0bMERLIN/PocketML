import functools
import re

def word_at_index(s, index):
    words = list(re.finditer(r'[a-zA-Z_][a-zA-Z_0-9]*', s))  # Find words using regex
    for match in words:
        if match.start() <= index < match.end():  # Check if index falls inside the word
            return match.group()
    return None  # If index is out of range


def curry(func):
    """A decorator that curries the given function.

    @curried
    def a(b, c):
        return (b, c)

    a(c=1)(2)  # returns (2, 1)
    """

    @functools.wraps(func)
    def _curried(*args, **kwargs):
        return functools.partial(func, *args, **kwargs)

    return _curried

