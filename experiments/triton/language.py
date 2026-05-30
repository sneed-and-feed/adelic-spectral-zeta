class ConstExprType:
    pass

constexpr = ConstExprType()

class FakeObj:
    pass

float32 = FakeObj()

def program_id(*args): return 0
def arange(*args): return FakeObj()
def load(*args, **kwargs): return FakeObj()
def store(*args, **kwargs): pass
def sum(*args, **kwargs): return FakeObj()
def maximum(*args, **kwargs): return FakeObj()
def exp(*args, **kwargs): return FakeObj()
def zeros(*args, **kwargs): return FakeObj()
