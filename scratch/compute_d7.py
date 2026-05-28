import numpy as np

def compute_d7():
    coeffs = [1.0, -32.0, 400.0, -2496.0, 8200.0, -13568.0, 9536.0, -1664.0, 4.0]
    # Evaluate at 16
    val = np.polyval(coeffs, 16.0)
    print(f"P_7(16) = {val}")
    print(f"Product = {val / 65536.0}")

if __name__ == "__main__":
    compute_d7()
