"""
Pytest suite for Affine Cyclotomic Classifier and Exact Spectral Circle Classification.
"""

import pytest
import math
import numpy as np
from experiments.affine_cyclotomic_classifier import AffineDynamicalSystem

@pytest.mark.parametrize("p,n,q,r", [
    (2, 2, 3, 1),
    (2, 3, 3, 1),
    (2, 4, 3, 1),
    (2, 5, 3, 1),
    (3, 1, 2, 1),
    (3, 2, 2, 1),
    (3, 2, 4, 1),
    (5, 1, 2, 1),
    (5, 1, 4, 1),
    (7, 1, 2, 1),
    (7, 1, 3, 1),
    (11, 1, 3, 1),
    (13, 1, 2, 1),
])
def test_spectral_reconstruction_exactness(p, n, q, r):
    sys_obj = AffineDynamicalSystem(p=p, n=n, q=q, r=r)
    passed, max_err = sys_obj.verify_spectral_equivalence(tol=1e-7)
    assert passed, f"Spectral reconstruction error {max_err} exceeds tolerance for ({p}, {n}, {q}, {r})"

@pytest.mark.parametrize("p,n", [
    (2, 2), (2, 3), (2, 4), (2, 5),
    (3, 1), (3, 2), (3, 3),
    (5, 1), (5, 2),
    (7, 1), (7, 2),
    (11, 1), (13, 1), (17, 1), (19, 1),
])
def test_cyclotomic_product_identity(p, n):
    q = 3 if p == 2 else 2
    if math.gcd(q, p) != 1: q = 3
    sys_obj = AffineDynamicalSystem(p=p, n=n, q=q, r=1)
    info = sys_obj.classify_spectral_geometry()
    expected = 2.0 if p == 2 else 1.0
    assert abs(abs(info['total_weight_prod']) - expected) < 1e-7

@pytest.mark.parametrize("p", [3, 7, 11, 19, 23, 31])
def test_qr_exact_unit_circle_theorem(p):
    # Find primitive root g
    for g in range(2, p):
        if len(set(pow(g, k, p) for k in range(1, p))) == p - 1:
            q_qr = pow(g, 2, p)
            sys_obj = AffineDynamicalSystem(p=p, n=1, q=q_qr, r=1)
            info = sys_obj.classify_spectral_geometry()
            assert info['is_single_circle'], f"Prime {p} QR failed to form a single circle"
            assert abs(info['unique_radii'][0] - 1.0) < 1e-7, f"Prime {p} QR radius is {info['unique_radii'][0]} != 1.0"
            break

def test_golden_ratio_spectrum_p5():
    sys_5 = AffineDynamicalSystem(p=5, n=1, q=4, r=1)
    info = sys_5.classify_spectral_geometry()
    assert len(info['unique_radii']) == 2
    r1, r2 = info['unique_radii']
    phi = (1 + math.sqrt(5)) / 2
    assert abs(r1 - 1/phi) < 1e-5
    assert abs(r2 - phi) < 1e-5
    assert abs(r1 * r2 - 1.0) < 1e-7
