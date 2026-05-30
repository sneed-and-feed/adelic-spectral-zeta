def jit(fn):
    fn.is_mocked = True
    def wrapper(*args, **kwargs):
        grid = kwargs.pop('grid', None)
        print(f"[MOCK] Triton kernel {fn.__name__} called with grid {grid}")
        return
    class Indexer:
        def __getitem__(self, grid):
            return lambda *args, **kwargs: wrapper(*args, grid=grid, **kwargs)
    return Indexer()

def next_power_of_2(x):
    n = 1
    while n < x:
        n *= 2
    return n
