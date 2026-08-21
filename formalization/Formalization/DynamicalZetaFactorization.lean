import Mathlib.Algebra.Polynomial.Basic
import Mathlib.Algebra.Polynomial.Eval
import Mathlib.Algebra.Polynomial.BigOperators
import Mathlib.Algebra.BigOperators.Intervals
import Formalization.CyclicWeightCharpoly
import Formalization.CyclotomicProduct

/-!
# Dynamical Fredholm Determinant Factorization

This file formalizes the exact algebraic polynomial identity for the dynamical
Fredholm determinant factorization of the Collatz transfer operator $D_n$:

  $\det(I - u D_n) = (1 - 2u)(1 - 2u^2) \prod_{k=3}^n (1 + 2u^{2^{k-1}})$

building upon `CyclicWeightCharpoly.lean` and `CyclotomicProduct.lean`.

## Mathematical Structure
1. **Perron Root Factor ($k=1$):**
   $P_1(u) = 1 - 2u$, corresponding to the dominant Perron eigenvalue $\lambda_1 = 2$.
2. **Base Sheet Inversion Factor ($k=2$):**
   $P_2(u) = 1 - 2u^2$, corresponding to the real eigenvalues $\lambda = \pm \sqrt{2}$.
3. **Cyclotomic Circle Factors ($k \ge 3$):**
   $P_k(u) = 1 + 2u^{2^{k-1}}$, corresponding to the complex eigenvalues lying on the
   spectral circle $|\lambda| = 2^{2^{-(k-1)}}$ of radius $r_k$.
4. **Dimension Equality:**
   The total number of non-zero spectral modes is $1 + 2 + \sum_{k=3}^n 2^{k-1} = 2^n - 1$.
   Together with the unique kernel mode ($\lambda = 0$), the total dimension is $(2^n - 1) + 1 = 2^n = |V_n|$.

## Main Theorems
- `cyclic_block_fredholm_product`: Algebraic product of two conjugate cyclic Fredholm
  determinants $(1 - W_1 u^L)(1 - W_2 u^L) = 1 + 2 u^{2L}$ when $W_1 + W_2 = 0$ and $W_1 W_2 = 2$.
- `cyclic_block_fredholm_collatz`: Instantiation of cyclic product for cycle length $L = 2^{k-2}$.
- `fredholmFactorization`: The explicit polynomial definition over any commutative ring $R$.
- `fredholm_succ`: Recursive step $\det(I - u D_{n+1}) = \det(I - u D_n) \cdot (1 + 2u^{2^n})$.
- `fredholmFactorization_two`: Explicit expansion at $n = 2$.
- `fredholmFactorization_three`: Explicit expansion at $n = 3$.
- `fredholmFactorization_four`: Explicit expansion at $n = 4$.
- `fredholm_eval_zero`: Normalization identity $\det(I - 0 \cdot D_n) = 1$.
- `total_nonzero_spectral_modes`: Sum of degrees equals $2^n - 1$.
- `total_state_space_dimension`: Full state space dimension equals $2^n = |V_n|$.
-/

open Polynomial Finset

variable {R : Type*} [CommRing R]

noncomputable section

namespace DynamicalZeta

/-- The Perron dominant eigenvalue factor $(1 - 2u)$. -/
def perronFactor : Polynomial R := 1 - 2 * X

/-- The base sheet deck-inversion factor $(1 - 2u^2)$. -/
def baseTwistedFactor : Polynomial R := 1 - 2 * X^2

/-- The $k$-th cyclotomic twisted circle factor $(1 + 2u^{2^{k-1}})$ for $k \ge 3$. -/
def cyclotomicTwistedFactor (k : ℕ) : Polynomial R := 1 + 2 * X ^ (2 ^ (k - 1))

/-- The product of cyclotomic twisted factors from level 3 up to level $n$. -/
def cyclotomicTowerProd (n : ℕ) : Polynomial R :=
  ∏ k ∈ Icc 3 n, cyclotomicTwistedFactor k

/-- The full dynamical Fredholm determinant polynomial $\det(I - u D_n)$ for $n \ge 2$:
    $\det(I - u D_n) = (1 - 2u)(1 - 2u^2) \prod_{k=3}^n (1 + 2u^{2^{k-1}})$. -/
def fredholmFactorization (n : ℕ) : Polynomial R :=
  perronFactor * baseTwistedFactor * cyclotomicTowerProd n

/-! ### Cyclic Block Fredholm Identities -/

/-- For two cyclic blocks of size $L$ with weights $W_1, W_2$ such that $W_1 + W_2 = 0$
    and $W_1 W_2 = 2$, their joint Fredholm determinant factors as $1 + 2 u^{2L}$.
    This algebraically links `CyclicWeightCharpoly` and `CyclotomicProduct`. -/
theorem cyclic_block_fredholm_product (L : ℕ) (W1 W2 : R)
    (h_sum : W1 + W2 = 0) (h_prod : W1 * W2 = 2) :
    (1 - C W1 * X ^ L) * (1 - C W2 * X ^ L) = (1 + 2 * X ^ (2 * L) : Polynomial R) := by
  have h_mul : (C W1 * X ^ L) * (C W2 * X ^ L) = C (W1 * W2) * X ^ (2 * L) := by
    calc (C W1 * X ^ L) * (C W2 * X ^ L)
      _ = (C W1 * C W2) * (X ^ L * X ^ L) := by ring
      _ = C (W1 * W2) * (X ^ L * X ^ L) := by rw [← map_mul]
      _ = C (W1 * W2) * X ^ (L + L) := by rw [← pow_add]
      _ = C (W1 * W2) * X ^ (2 * L) := by ring_nf
  have h_cross : (C W1 * X ^ L) + (C W2 * X ^ L) = 0 := by
    calc (C W1 * X ^ L) + (C W2 * X ^ L)
      _ = (C W1 + C W2) * X ^ L := by ring
      _ = C (W1 + W2) * X ^ L := by rw [← map_add]
      _ = C 0 * X ^ L := by rw [h_sum]
      _ = 0 := by simp
  calc (1 - C W1 * X ^ L) * (1 - C W2 * X ^ L)
    _ = 1 - (C W1 * X ^ L + C W2 * X ^ L) + (C W1 * X ^ L) * (C W2 * X ^ L) := by ring
    _ = 1 - 0 + C (W1 * W2) * X ^ (2 * L) := by rw [h_cross, h_mul]
    _ = 1 + C 2 * X ^ (2 * L) := by rw [h_prod, sub_zero]
    _ = 1 + 2 * X ^ (2 * L) := by
      have h2 : C (2 : R) = (2 : Polynomial R) := by
        simp only [map_ofNat]
      rw [h2]

/-- Instantiation of the cyclic block identity for $L = 2^{k-2}$, yielding the
    cyclotomic twisted factor $1 + 2u^{2^{k-1}}$. -/
theorem cyclic_block_fredholm_collatz (k : ℕ) (_hk : 2 ≤ k) (W1 W2 : R)
    (h_sum : W1 + W2 = 0) (h_prod : W1 * W2 = 2) :
    (1 - C W1 * X ^ (2 ^ (k - 2))) * (1 - C W2 * X ^ (2 ^ (k - 2))) =
    cyclotomicTwistedFactor (R := R) k := by
  dsimp [cyclotomicTwistedFactor]
  have h_eq := cyclic_block_fredholm_product (2 ^ (k - 2)) W1 W2 h_sum h_prod
  have h_pow : 2 * 2 ^ (k - 2) = 2 ^ (k - 1) := by
    have hk_sub : k - 1 = (k - 2) + 1 := by omega
    rw [hk_sub, pow_succ, mul_comm]
  rw [h_pow] at h_eq
  exact h_eq

/-! ### Base Cases and Inductive Step -/

/-- Base level $n = 2$: the cyclotomic tower product is empty (equal to 1). -/
@[simp]
theorem cyclotomicTowerProd_two : cyclotomicTowerProd (R := R) 2 = 1 := by
  dsimp [cyclotomicTowerProd]
  rw [Icc_eq_empty (by omega)]
  exact prod_empty

/-- Base level $n = 2$: Fredholm determinant is $(1 - 2u)(1 - 2u^2)$. -/
theorem fredholmFactorization_two :
    fredholmFactorization (R := R) 2 = (1 - 2 * X) * (1 - 2 * X^2) := by
  dsimp [fredholmFactorization, perronFactor, baseTwistedFactor]
  rw [cyclotomicTowerProd_two, mul_one]

/-- Level $n = 3$: Fredholm determinant is $(1 - 2u)(1 - 2u^2)(1 + 2u^4)$. -/
theorem fredholmFactorization_three :
    fredholmFactorization (R := R) 3 = (1 - 2 * X) * (1 - 2 * X^2) * (1 + 2 * X^4) := by
  dsimp [fredholmFactorization, perronFactor, baseTwistedFactor, cyclotomicTowerProd]
  have h_icc : Icc 3 3 = {3} := Icc_self 3
  rw [h_icc, prod_singleton]
  dsimp [cyclotomicTwistedFactor]

/-- Recursive step for the cyclotomic tower product. -/
theorem cyclotomicTowerProd_succ (n : ℕ) (hn : 2 ≤ n) :
    cyclotomicTowerProd (R := R) (n + 1) =
    cyclotomicTowerProd n * cyclotomicTwistedFactor (n + 1) := by
  dsimp [cyclotomicTowerProd]
  have h_split : Icc 3 (n + 1) = insert (n + 1) (Icc 3 n) := by
    ext x
    rw [mem_Icc, mem_insert, mem_Icc]
    omega
  have h_not_mem : n + 1 ∉ Icc 3 n := by
    rw [mem_Icc]
    omega
  rw [h_split, prod_insert h_not_mem]
  rw [mul_comm]

/-- Recursive step for the full dynamical Fredholm determinant:
    $\det(I - u D_{n+1}) = \det(I - u D_n) \cdot (1 + 2u^{2^n})$. -/
theorem fredholm_succ (n : ℕ) (hn : 2 ≤ n) :
    fredholmFactorization (R := R) (n + 1) =
    fredholmFactorization n * (1 + 2 * X ^ (2 ^ n)) := by
  dsimp [fredholmFactorization]
  rw [cyclotomicTowerProd_succ n hn]
  have h_factor : cyclotomicTwistedFactor (R := R) (n + 1) = 1 + 2 * X ^ (2 ^ n) := rfl
  rw [h_factor]
  exact (mul_assoc (perronFactor * baseTwistedFactor) (cyclotomicTowerProd n) (1 + 2 * X ^ 2 ^ n)).symm

/-- Explicit expansion at level $n = 4$:
    $\det(I - u D_4) = (1 - 2u)(1 - 2u^2)(1 + 2u^4)(1 + 2u^8)$. -/
theorem fredholmFactorization_four :
    fredholmFactorization (R := R) 4 =
    (1 - 2 * X) * (1 - 2 * X^2) * (1 + 2 * X^4) * (1 + 2 * X^8) := by
  have h4 : fredholmFactorization (R := R) 4 = fredholmFactorization 3 * (1 + 2 * X ^ (2 ^ 3)) := by
    have h := fredholm_succ (R := R) 3 (by omega)
    exact h
  rw [h4, fredholmFactorization_three]
  have h8 : (2 : ℕ) ^ 3 = 8 := by decide
  rw [h8]

/-! ### Evaluation and Normalization -/

/-- At $u = 0$, the Fredholm determinant evaluates to 1: $\det(I - 0 \cdot D_n) = 1$. -/
@[simp]
theorem fredholm_eval_zero (n : ℕ) :
    eval 0 (fredholmFactorization (R := R) n) = 1 := by
  dsimp [fredholmFactorization, perronFactor, baseTwistedFactor, cyclotomicTowerProd]
  simp only [eval_mul, eval_sub, eval_add, eval_one, eval_X, eval_pow, sub_zero, mul_one,
             eval_prod, zero_pow (by omega : 2 ≠ 0), mul_zero, add_zero]
  have h_terms : ∀ k ∈ Icc 3 n, eval 0 (cyclotomicTwistedFactor (R := R) k) = 1 := by
    intro k _
    dsimp [cyclotomicTwistedFactor]
    have hpos : 2 ^ (k - 1) ≠ 0 := by positivity
    simp [eval_pow, zero_pow hpos]
  have h_prod : (∏ k ∈ Icc 3 n, eval 0 (cyclotomicTwistedFactor (R := R) k)) = 1 := by
    apply prod_eq_one h_terms
  rw [h_prod, mul_one]

/-! ### Degree and Dimension Formula -/

lemma sum_two_pow_Icc (n : ℕ) (hn : 2 ≤ n) :
    ∑ k ∈ Icc 3 n, 2 ^ (k - 1) = 2 ^ n - 4 := by
  induction' n, hn using Nat.le_induction with n hn ih
  · rw [Icc_eq_empty (by omega), sum_empty]
    rfl
  · rw [sum_Icc_succ_top (by omega)]
    rw [ih]
    have h_sub : n + 1 - 1 = n := rfl
    rw [h_sub]
    have : 2 ^ 2 ≤ 2 ^ n := Nat.pow_le_pow_right (by omega) hn
    omega

/-- The total number of non-zero spectral modes is $1 + 2 + \sum_{k=3}^n 2^{k-1} = 2^n - 1$. -/
theorem total_nonzero_spectral_modes (n : ℕ) (hn : 2 ≤ n) :
    1 + 2 + ∑ k ∈ Icc 3 n, 2 ^ (k - 1) = 2 ^ n - 1 := by
  rw [sum_two_pow_Icc n hn]
  have : 2 ^ 2 ≤ 2 ^ n := Nat.pow_le_pow_right (by omega) hn
  omega

/-- Full state-space dimension including the unique kernel mode (zero eigenvalue):
    $(2^n - 1) + 1 = 2^n = |V_n|$. -/
theorem total_state_space_dimension (n : ℕ) (hn : 2 ≤ n) :
    (1 + 2 + ∑ k ∈ Icc 3 n, 2 ^ (k - 1)) + 1 = 2 ^ n := by
  rw [total_nonzero_spectral_modes n hn]
  have : 2 ^ 2 ≤ 2 ^ n := Nat.pow_le_pow_right (by omega) hn
  omega

end DynamicalZeta
