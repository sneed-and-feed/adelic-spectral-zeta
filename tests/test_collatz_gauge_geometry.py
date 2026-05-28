"""
Test suite: test_collatz_gauge_geometry.py
Tests mathematical properties and correctness invariants.
"""
import pytest
import numpy as np
from scipy.linalg import norm

def build_operators(depth):
    N = 1 << depth
    
    # 1. Translation operator A
    A = np.zeros((N, N))
    for x in range(N):
        A[(x + 1) % N, x] = 1.0
        
    # 2. Parity Projections
    P0 = np.zeros((N, N))
    P1 = np.zeros((N, N))
    for x in range(N):
        if x % 2 == 0:
            P0[x, x] = 1.0
        else:
            P1[x, x] = 1.0
            
    # 3. Algebraic modular transfer operator B_alg
    B_alg = np.zeros((N, N))
    inv_3 = 1
    if depth > 0:
        for i in range(1, N):
            if (3 * i) % N == 1:
                inv_3 = i
                break
    for x in range(N):
        y1 = (2 * x) % N
        B_alg[x, y1] += 0.5
        y2 = ((2 * x - 1) * inv_3) % N
        B_alg[x, y2] += 0.5
        
    # 4. Numerical integer-division transfer operator B_num
    B_num = np.zeros((N, N))
    for x in range(N):
        if x % 2 == 0:
            Tx = (x // 2) % N
        else:
            Tx = ((3 * x + 1) // 2) % N
        B_num[Tx, x] = 1.0
    # Normalize B_num columns to make it a Perron-Frobenius transition matrix
    col_sums = B_num.sum(axis=0)
    for c in range(N):
        if col_sums[c] > 0:
            B_num[:, c] /= col_sums[c]
            
    return A, P0, P1, B_alg, B_num

def test_operator_gauge_identity():
    """Checks Proposition 3: B_alg A^2 = A B_alg P0 + A^3 B_alg P1 holds with zero defect."""
    for depth in range(3, 8):
        A, P0, P1, B_alg, _ = build_operators(depth)
        lhs = B_alg @ (A @ A)
        rhs = A @ B_alg @ P0 + (A @ A @ A) @ B_alg @ P1
        defect = lhs - rhs
        assert norm(defect, 'fro') < 1e-12  # Tolerance accounts for floating-point truncation

def test_numerical_representation_defect():
    """Checks that the numerical representation B_num has Frobenius norm defect exactly 2.0."""
    for depth in range(3, 8):
        A, P0, P1, _, B_num = build_operators(depth)
        lhs = B_num @ (A @ A)
        rhs = A @ B_num @ P0 + (A @ A @ A) @ B_num @ P1
        defect = lhs - rhs
        # Defect Frobenius norm must be exactly 2.0
        assert np.isclose(norm(defect, 'fro'), 2.0)

def test_curvature_scaling_limit():
    """Checks that the normalized commutator norm is exactly C(d) = sqrt(1 - 2^(1-d))."""
    for depth in range(3, 8):
        N = 1 << depth
        A, _, _, B_alg, _ = build_operators(depth)
        comm = A @ B_alg - B_alg @ A
        norm_comm = norm(comm, 'fro') / np.sqrt(N)
        expected = np.sqrt(1.0 - 2.0**(1 - depth))
        assert np.isclose(norm_comm, expected)

def test_commutator_kernel_dimension():
    """Checks Theorem 5: rank(K_d) = 2^(d-1) - 1 and dim(ker(K_d)) = 2^(d-1) + 1."""
    for depth in range(3, 8):
        N = 1 << depth
        A, _, _, B_alg, _ = build_operators(depth)
        K_d = A @ B_alg - B_alg @ A
        
        # SVD exploration of rank
        s = np.linalg.svdvals(K_d)
        rank = np.sum(s > 1e-10)
        kernel_dim = N - rank
        
        expected_rank = (1 << (depth - 1)) - 1
        expected_kernel = (1 << (depth - 1)) + 1
        
        assert rank == expected_rank
        assert kernel_dim == expected_kernel

def test_rank_1_commutator():
    """Checks that [B_alg, omega] = 1/2 |u><v| in finite dimensions."""
    for depth in range(3, 8):
        N = 1 << depth
        _, P0, P1, B_alg, _ = build_operators(depth)
        
        # Build sector indicator vectors
        ones = np.ones(N)
        one_0 = np.zeros(N)
        one_1 = np.zeros(N)
        for x in range(N):
            if x % 2 == 0:
                one_0[x] = np.sqrt(2)
            else:
                one_1[x] = np.sqrt(2)
                
        # Build omega matrix using the L^2 inner product weight 1/N
        # omega = 1/2 * 1/N * (|one_0><one_1| + |one_1><one_0|)
        omega = 0.5 * (1.0 / N) * (np.outer(one_0, one_1) + np.outer(one_1, one_0))
        
        # Compute commutator [B_alg, omega]
        comm = B_alg @ omega - omega @ B_alg
        
        # Build target rank-1 operator 1/2 |u><v|
        # u(x) = (-1)^x
        # v(y) = 1 if y = 0,1 mod 4 else -1
        u = np.zeros(N)
        v = np.zeros(N)
        for x in range(N):
            u[x] = 1.0 if x % 2 == 0 else -1.0
            v[x] = 1.0 if (x % 4) in (0, 1) else -1.0
            
        # Target matrix represents 1/2 * 1/N * |u><v|
        target = 0.5 * (1.0 / N) * np.outer(u, v)
        
        # Check that they match to machine precision
        assert np.allclose(comm, target)


def test_exact_graph_correspondence():
    """Checks that (M_d + M_d^T) L = 1/2 L A_G_d holds on the periodic subspace."""
    for depth in range(2, 9):
        N = 1 << depth
        half_N = 1 << (depth - 1)
        
        # 1. Shift operator A_d
        A = np.zeros((N, N))
        for x in range(N):
            A[(x + 1) % N, x] = 1.0
            
        # 2. Transfer operator B_d
        B = np.zeros((N, N))
        inv_3 = 1
        for i in range(1, N):
            if (3 * i) % N == 1:
                inv_3 = i
                break
        for x in range(N):
            y1 = (2 * x) % N
            B[x, y1] += 0.5
            y2 = ((2 * x - 1) * inv_3) % N
            B[x, y2] += 0.5
            
        # Adjoints
        B_dag = B.T.copy()
        A_dag = A.T.copy()
        
        # M_d = B_d A_d B_d^dagger A_d^dagger
        M = B @ A @ B_dag @ A_dag
        
        # Adjacency matrix of G_d on Z / 2^(d-1) Z
        A_G = np.zeros((half_N, half_N))
        inv_3_half = 1
        for i in range(1, half_N):
            if (3 * i) % half_N == 1:
                inv_3_half = i
                break
                
        for x in range(half_N):
            A_G[(3 * x) % half_N, x] += 1.0
            A_G[(3 * x - 1) % half_N, x] += 1.0
            A_G[(inv_3_half * x) % half_N, x] += 1.0
            A_G[(inv_3_half * (x + 1)) % half_N, x] += 1.0

        # Periodic extension map L: V_{d-1} -> V_d
        L = np.zeros((N, half_N))
        for x in range(N):
            L[x, x % half_N] = 1.0
            
        # Check identity: (M + M^T) L = 1/2 L A_G
        lhs = (M + M.T) @ L
        rhs = 0.5 * L @ A_G
        defect = lhs - rhs
        assert norm(defect, 'fro') < 1e-12  # Tolerance accounts for floating-point truncation

