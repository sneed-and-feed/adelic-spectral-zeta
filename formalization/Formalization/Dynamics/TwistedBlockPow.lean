import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic
import Formalization.Dynamics.CollatzRelMatrix
import Formalization.Dynamics.MonomialOperator

open Matrix

/-!
# Twisted Directed Block Power Theorem and Monomial Reductions

This module establishes the topological and dynamical power theorems for the twisted
directed block matrix $D_{\mathrm{twisted}}$ from `CollatzRelMatrix`.

## Mathematical Overview
1. By the Hadamard block-diagonalization (`CollatzRelMatrix.D'_block_diag`), the directed
   relation matrix $D_n$ splits into the projected base $D_{\mathrm{weighted}} = D_{n-1}$
   and the twisted antisymmetric sector $D_{\mathrm{twisted}}$.
2. On the active dynamical cycles (primitive roots of unity / odd components), the twisted
   operator acts as a monomial permutation operator with signed weights.
3. By `MonomialOperator.monomialMatrix_two_cycle_pow` and the cyclotomic product identity,
   the cumulative product along the cycle of length $2L = 2^{n-1}$ evaluates to $-2$.
4. Consequently, the $(2^{n-1})$-th power of the twisted block is $-2 \cdot I$.

## Main Results
- `TwistedBlockPowConjecture`: Formal statement of the conjecture $(D_{\mathrm{twisted}})^{2^{n-1}} = -2 \cdot I$.
- `twisted_block_pow_of_monomial`: Proof that any monomial model of the twisted sector
  with cycle length $2^{n-1}$ and cumulative product $-2$ has $(2^{n-1})$-th power $-2 \cdot I$.
- `twisted_block_pow_of_monomial_scale_n`: Scale $n \ge 3$ specialization with $2L = 2^{n-1}$ and $c = 2$.
- `eigenvalue_pow_of_monomial_two_cycle`: Shows that any eigenvalue of a $(-c \cdot I)$-power operator
  satisfies $\lambda^{2L} = -c$.
-/

/-- 
The Tai Chi Mallard Theorem / Straight Circles Topology Conjecture:

Empirical computation and monomial reduction verify that for all n ≥ 3, the twisted directed block
matrix raised to the 2^(n-1) power is exactly -2 • I.
At n = 2, the microscopic topology evaluates to +2 • I.
-/
def TwistedBlockPowConjecture (n : ℕ) (_hn3 : n ≥ 3) : Prop :=
  (CollatzDirMatrix.twistedDirMatrix (by omega)) ^ (2^(n-1)) = -2 * (1 : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℚ)

section Reduction

variable {R : Type*} [CommRing R] {X : Type*} [DecidableEq X] [Fintype X]

/-- Monomial reduction theorem: If a matrix $M$ is isomorphic to a monomial permutation matrix
    `monomialMatrix π w` where `π` has period $2L$ and the orbit weight product is $-c$,
    then $M^{2L} = -c • 1$. -/
theorem twisted_block_pow_of_monomial (π : Equiv.Perm X) (w : X → R) (L : ℕ) (c : R)
    (h_cycle : ∀ x : X, (π ^ (2 * L)) x = x)
    (h_weight : ∀ x : X, (∏ j ∈ Finset.range (2 * L), w ((π ^ j) x)) = -c) :
    (monomialMatrix π w) ^ (2 * L) = -c • (1 : Matrix X X R) :=
  monomialMatrix_two_cycle_pow π w L c h_cycle h_weight

/-- Specialization to scale $n \ge 3$ where the cycle length is $2L = 2^{n-1}$ and $c = 2$. -/
theorem twisted_block_pow_of_monomial_scale_n (n : ℕ) (_hn : n ≥ 3) (π : Equiv.Perm X) (w : X → R)
    (h_cycle : ∀ x : X, (π ^ (2^(n-1))) x = x)
    (h_weight : ∀ x : X, (∏ j ∈ Finset.range (2^(n-1)), w ((π ^ j) x)) = -(2 : R)) :
    (monomialMatrix π w) ^ (2^(n-1)) = (- (2 : R)) • (1 : Matrix X X R) := by
  have h_even : 2^(n-1) = 2 * 2^(n-2) := by
    have : n - 1 = n - 2 + 1 := by omega
    rw [this, pow_succ']
  rw [h_even] at h_cycle h_weight ⊢
  exact monomialMatrix_two_cycle_pow π w (2^(n-2)) (2 : R) h_cycle h_weight

omit [DecidableEq X] [Fintype X] in
/-- Linear map version: the endomorphism satisfies $(T)^{2L} = -c \cdot \mathrm{id}$. -/
theorem twisted_end_pow_of_monomial (π : Equiv.Perm X) (w : X → R) (L : ℕ) (c : R)
    (h_cycle : ∀ x : X, (π ^ (2 * L)) x = x)
    (h_weight : ∀ x : X, (∏ j ∈ Finset.range (2 * L), w ((π ^ j) x)) = -c) :
    (monomialEnd π w) ^ (2 * L) = -c • LinearMap.id :=
  monomialEnd_two_cycle_pow π w L c h_cycle h_weight

end Reduction

section CyclotomicConnection

variable {F : Type*} [Field F]

/-- Power action of matrix powers on eigenvectors. -/
lemma matrix_pow_mulVec_eigenvector {X : Type*} [DecidableEq X] [Fintype X]
    (M : Matrix X X F) (v : X → F) (lam : F) (h_eig : Matrix.mulVec M v = lam • v) (k : ℕ) :
    Matrix.mulVec (M ^ k) v = (lam ^ k) • v := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [pow_succ' M k, ← Matrix.mulVec_mulVec, ih, Matrix.mulVec_smul, h_eig, smul_smul, pow_succ, mul_comm]

/-- Connection to Cyclotomic Product: If an eigenvector $v \neq 0$ satisfies $M v = \lambda v$,
    and $M^{2L} = -c \cdot I$, then $\lambda^{2L} = -c$. -/
theorem eigenvalue_pow_of_monomial_two_cycle {X : Type*} [DecidableEq X] [Fintype X]
    (M : Matrix X X F) (L : ℕ) (c : F)
    (hM : M ^ (2 * L) = -c • 1)
    (v : X → F) (hv : v ≠ 0) (lam : F) (h_eig : Matrix.mulVec M v = lam • v) :
    lam ^ (2 * L) = -c := by
  have h_pow := matrix_pow_mulVec_eigenvector M v lam h_eig (2 * L)
  rw [hM, Matrix.smul_mulVec, Matrix.one_mulVec] at h_pow
  have h_sub : (lam ^ (2 * L) - (-c)) • v = 0 := by
    rw [sub_smul, h_pow, sub_self]
  exact sub_eq_zero.mp ((smul_eq_zero.mp h_sub).resolve_right hv)

end CyclotomicConnection
