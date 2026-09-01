import Mathlib.LinearAlgebra.Matrix.ToLin
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic

/-!
# Monomial Operators and Permutation Matrix Powers

This module formalizes monomial endomorphisms and permutation matrices with weights over
a commutative ring `R`.

## Main Definitions
- `monomialEnd π w`: The linear endomorphism on `X → R` defined by `(monomialEnd π w f) x = w x * f (π x)`.
- `monomialMatrix π w`: The matrix representation of `monomialEnd π w` for finite `X`.

## Main Results
- `monomialEnd_pow_apply`: The `k`-th power of `monomialEnd π w` acts by multiplying along
  the `k`-step orbit: `(∏ j ∈ Finset.range k, w ((π ^ j) x)) * f ((π ^ k) x)`.
- `monomialEnd_two_cycle_pow`: If `π ^ (2 * L) = 1` and the product of weights along every orbit
  of length `2 * L` is `-c`, then `(monomialEnd π w) ^ (2 * L) = -c • LinearMap.id`.
- `monomialMatrix_pow_apply`: Entrywise formula for powers of `monomialMatrix π w`.
- `monomialMatrix_two_cycle_pow`: Matrix power identity `(monomialMatrix π w) ^ (2 * L) = -c • 1`.
-/

variable {R : Type*} [CommRing R] {X : Type*}

/-- The monomial endomorphism on `X → R` associated with a permutation `π` and weight function `w`.
    `(monomialEnd π w f) x = w x * f (π x)`. -/
def monomialEnd (π : Equiv.Perm X) (w : X → R) : (X → R) →ₗ[R] (X → R) where
  toFun f x := w x * f (π x)
  map_add' _ _ := by ext; dsimp; ring
  map_smul' _ _ := by ext; dsimp; ring

@[simp]
lemma monomialEnd_apply (π : Equiv.Perm X) (w : X → R) (f : X → R) (x : X) :
    (monomialEnd π w f) x = w x * f (π x) :=
  rfl

/-- Key orbit lemma: the action of `π ^ (j + 1)` on `x` is `(π ^ j) (π x)`. -/
lemma perm_pow_succ_apply (π : Equiv.Perm X) (j : ℕ) (x : X) :
    (π ^ (j + 1)) x = (π ^ j) (π x) := by
  rw [pow_succ, Equiv.Perm.coe_mul, Function.comp_apply]

/-- Key orbit lemma: the action of `π ^ (j + 1)` on `x` is also `π ((π ^ j) x)`. -/
lemma perm_pow_succ_apply' (π : Equiv.Perm X) (j : ℕ) (x : X) :
    (π ^ (j + 1)) x = π ((π ^ j) x) := by
  rw [pow_succ', Equiv.Perm.coe_mul, Function.comp_apply]

/-- The `k`-th power of `monomialEnd π w` evaluates along the permutation orbit of `x`. -/
theorem monomialEnd_pow_apply (π : Equiv.Perm X) (w : X → R) (k : ℕ) (f : X → R) (x : X) :
    ((monomialEnd π w) ^ k) f x = (∏ j ∈ Finset.range k, w ((π ^ j) x)) * f ((π ^ k) x) := by
  induction k generalizing x with
  | zero => simp
  | succ k ih =>
    have : ((monomialEnd π w) ^ (k + 1)) f = monomialEnd π w (((monomialEnd π w) ^ k) f) := by
      rw [pow_succ' (monomialEnd π w) k]; rfl
    rw [this, monomialEnd_apply, ih (π x), Finset.prod_range_succ', mul_comm]
    have h0 : (π ^ 0 : Equiv.Perm X) x = x := rfl
    rw [h0]
    simp_rw [perm_pow_succ_apply]
    ring

/-- For a permutation system where applying `π ^ (2 * L)` returns to `x` and the cumulative
    weight product over the `2 * L` steps is `-c`, `(monomialEnd π w) ^ (2 * L) = -c • LinearMap.id`. -/
theorem monomialEnd_two_cycle_pow (π : Equiv.Perm X) (w : X → R) (L : ℕ) (c : R)
    (h_cycle : ∀ x : X, (π ^ (2 * L)) x = x)
    (h_weight : ∀ x : X, (∏ j ∈ Finset.range (2 * L), w ((π ^ j) x)) = -c) :
    (monomialEnd π w) ^ (2 * L) = -c • LinearMap.id := by
  ext f x
  simp [monomialEnd_pow_apply, h_cycle x, h_weight x]

section MatrixRep

variable [DecidableEq X]

/-- Matrix representation of a weighted permutation (monomial) operator. -/
def monomialMatrix (π : Equiv.Perm X) (w : X → R) : Matrix X X R :=
  fun i j => if j = π i then w i else 0

@[simp]
lemma monomialMatrix_apply (π : Equiv.Perm X) (w : X → R) (i j : X) :
    monomialMatrix π w i j = if j = π i then w i else 0 :=
  rfl

variable [Fintype X]

/-- Entrywise formula for powers of a monomial permutation matrix. -/
theorem monomialMatrix_pow_apply (π : Equiv.Perm X) (w : X → R) (k : ℕ) (i j : X) :
    ((monomialMatrix π w) ^ k) i j =
      if j = (π ^ k) i then ∏ l ∈ Finset.range k, w ((π ^ l) i) else 0 := by
  induction k generalizing i with
  | zero =>
    simp only [pow_zero, Matrix.one_apply, Finset.range_zero, Finset.prod_empty, Equiv.Perm.coe_one, id_eq]
    split_ifs <;> aesop
  | succ k ih =>
    have h_sum : (∑ m : X, monomialMatrix π w i m * ((monomialMatrix π w) ^ k) m j) =
        monomialMatrix π w i (π i) * ((monomialMatrix π w) ^ k) (π i) j := by
      refine Finset.sum_eq_single (π i) ?_ (fun h => (h (Finset.mem_univ _)).elim)
      intro b _ hb
      dsimp [monomialMatrix]
      split_ifs with h
      · exact (hb h).elim
      · rw [zero_mul]
    rw [pow_succ' (monomialMatrix π w) k, Matrix.mul_apply, h_sum]
    simp only [monomialMatrix_apply, ite_true]
    rw [ih (π i), perm_pow_succ_apply π k i]
    split_ifs with hj
    · rw [Finset.prod_range_succ', mul_comm]
      have h0 : (π ^ 0 : Equiv.Perm X) i = i := rfl
      rw [h0]
      simp_rw [perm_pow_succ_apply]
    · rw [mul_zero]

/-- The matrix power corollary: if applying `π ^ (2 * L)` returns to each `x` and the cumulative
    weight along the cycle is `-c`, then the `(2 * L)`-th power of `monomialMatrix π w` is `-c • 1`. -/
theorem monomialMatrix_two_cycle_pow (π : Equiv.Perm X) (w : X → R) (L : ℕ) (c : R)
    (h_cycle : ∀ x : X, (π ^ (2 * L)) x = x)
    (h_weight : ∀ x : X, (∏ j ∈ Finset.range (2 * L), w ((π ^ j) x)) = -c) :
    (monomialMatrix π w) ^ (2 * L) = -c • (1 : Matrix X X R) := by
  ext i j
  rw [monomialMatrix_pow_apply, h_cycle i, h_weight i]
  simp only [Matrix.smul_apply, Matrix.one_apply, smul_eq_mul]
  split_ifs <;> aesop

/-- Connection with `Matrix.mulVec`: `mulVec (monomialMatrix π w) = monomialEnd π w`. -/
lemma monomialMatrix_mulVec (π : Equiv.Perm X) (w : X → R) (v : X → R) :
    Matrix.mulVec (monomialMatrix π w) v = monomialEnd π w v := by
  ext i
  simp only [Matrix.mulVec, monomialMatrix, dotProduct, monomialEnd_apply]
  rw [Finset.sum_eq_single (π i)
        (fun j _ hj => by split_ifs with h <;> [exact (hj h).elim; rw [zero_mul]])
        (fun h => (h (Finset.mem_univ _)).elim)]
  simp

/-- Linear map isomorphism: `Matrix.toLin'` maps `monomialMatrix π w` to `monomialEnd π w`. -/
lemma toLin'_monomialMatrix (π : Equiv.Perm X) (w : X → R) :
    Matrix.toLin' (monomialMatrix π w) = monomialEnd π w :=
  LinearMap.ext (monomialMatrix_mulVec π w)

end MatrixRep
