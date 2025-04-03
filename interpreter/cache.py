
import hashlib
from typing import Dict, Generic, Tuple, TypeVar


def get_file_hash(filename):
    hasher = hashlib.sha256()
    with open(filename, "rb") as f:
        hasher.update(f.read())
    return hasher.hexdigest()


T = TypeVar('T')
class Cache(Generic[T]):
    def __init__(self):
        self.data: Dict[str, Tuple[str, T]] = {}
    
    def cached(self, k):
        return k in self.data and get_file_hash(k) == self.data[k][0]
    
    def get(self, k):
        return self.data[k][1]
    
    def cache(self, k, v):
        self.data[k] = (get_file_hash(k), v)

