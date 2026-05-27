import mpmath
import time

mpmath.mp.dps = 30
iv = mpmath.iv
iv.dps = 30

N = 1000000
print("Allocating...")
v = [iv.mpf("1.0")] * N
print("Computing sum...")
t0 = time.time()
# simulate a simple operation
# we can do this via python loops
v_new = [x * 3.14 for x in v]
print(f"Done in {time.time()-t0} s")
