import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval

open Polynomial

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

/--
The Fourier characters over ZMod (2^n).
-/
def chi (k x : ZMod (2^n)) : F :=
  zeta ^ (k * x).val

/--
The directed relation matrix $D_n$ applied to a function $f$ over $\mathbb{Z}/2^n\mathbb{Z}$.
-/
def D_n (f : ZMod (2^n) → F) : ZMod (2^n) → F :=
  fun x ↦ f (3 * x) + f (3 * x - 1)

/--
The subspace of T-odd functions where $f(x + 2^{n-1}) = -f(x)$.
-/
def is_T_odd (f : ZMod (2^n) → F) : Prop :=
  ∀ x : ZMod (2^n), f (x + (2^(n-1) : ℕ)) = - f x

lemma T_odd_shift (n : ℕ) (hn : 1 ≤ n) (x : ZMod (2^n)) :
  3 * (x + (2^(n-1) : ℕ)) = 3 * x + (2^(n-1) : ℕ) := by
  have h1 : 3 * 2^(n-1) = 2^(n-1) + 2^n := by
    calc
      3 * 2^(n-1) = (1 + 2) * 2^(n-1) := by rfl
      _ = 2^(n-1) + 2 * 2^(n-1) := by ring
      _ = 2^(n-1) + 2^1 * 2^(n-1) := by ring
      _ = 2^(n-1) + 2^(1 + (n - 1)) := by rw [← pow_add]
      _ = 2^(n-1) + 2^n := by
        congr 2
        omega
  have h2 : ((3 * 2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) + 2^n : ℕ) : ZMod (2^n)) := by
    rw [h1]
  have h3 : ((2^n : ℕ) : ZMod (2^n)) = 0 := by
    exact ZMod.natCast_self (2^n)
  calc
    3 * (x + (2^(n-1) : ℕ)) = 3 * x + 3 * ((2^(n-1) : ℕ) : ZMod (2^n)) := by ring
    _ = 3 * x + ((3 * 2^(n-1) : ℕ) : ZMod (2^n)) := by push_cast; ring
    _ = 3 * x + ((2^(n-1) + 2^n : ℕ) : ZMod (2^n)) := by rw [h2]
    _ = 3 * x + ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^n : ℕ) : ZMod (2^n)) := by push_cast; ring
    _ = 3 * x + ((2^(n-1) : ℕ) : ZMod (2^n)) + 0 := by rw [h3]
    _ = 3 * x + (2^(n-1) : ℕ) := by ring

lemma T_odd_shift_minus_one (n : ℕ) (hn : 1 ≤ n) (x : ZMod (2^n)) :
  3 * (x + (2^(n-1) : ℕ)) - 1 = (3 * x - 1) + (2^(n-1) : ℕ) := by
  rw [T_odd_shift n hn x]
  ring

/--
The twisted block $S_n$ acts exactly on the T-odd subspace.
This lemma proves that $D_n$ preserves the T-odd subspace,
hence the restriction of $D_n$ to this subspace is well-defined.
-/
lemma D_n_preserves_T_odd (hn : 1 ≤ n) (f : ZMod (2^n) → F) (hf : is_T_odd f) :
  is_T_odd (D_n f) := by
  intro x
  unfold D_n
  have h1 : f (3 * (x + (2^(n-1) : ℕ))) = - f (3 * x) := by
    rw [T_odd_shift n hn x]
    exact hf (3 * x)
  have h2 : f (3 * (x + (2^(n-1) : ℕ)) - 1) = - f (3 * x - 1) := by
    rw [T_odd_shift_minus_one n hn x]
    exact hf (3 * x - 1)
  rw [h1, h2]
  ring

lemma pow_mod_eq_pow (x : ℕ) : zeta ^ (x % 2^n) = zeta ^ x := by
  have h1 : x = x % 2^n + 2^n * (x / 2^n) := by exact (Nat.mod_add_div x (2^n)).symm
  conv => rhs; rw [h1]
  rw [pow_add, pow_mul]
  have h2 : zeta ^ (2^n) = 1 := hzeta.pow_eq_one
  rw [h2, one_pow, mul_one]

lemma pow_val_add (a b : ZMod (2^n)) : zeta ^ (a + b).val = zeta ^ a.val * zeta ^ b.val := by
  have h1 : (a + b).val = (a.val + b.val) % 2^n := ZMod.val_add a b
  rw [h1, pow_mod_eq_pow zeta hzeta, pow_add]

lemma pow_val_eq_of_eq {a b : ZMod (2^n)} (h : a = b) : zeta ^ a.val = zeta ^ b.val := by
  rw [h]

/--
Theorem: The directed relation matrix $D_n$ applied to an odd character `chi k`
yields `(1 + omega^{-k}) * chi (3k)`.
-/
lemma D_n_chi (k : ZMod (2^n)) :
  D_n (chi zeta k) = fun x ↦ (1 + zeta ^ (-k).val) * chi zeta (3 * k) x := by
  ext x
  unfold D_n chi
  have h1 : k * (3 * x) = 3 * k * x := by ring
  have h2 : k * (3 * x - 1) = -k + 3 * k * x := by ring
  have eq1 : zeta ^ (k * (3 * x)).val = zeta ^ (3 * k * x).val := pow_val_eq_of_eq zeta h1
  have eq2 : zeta ^ (k * (3 * x - 1)).val = zeta ^ (-k + 3 * k * x).val := pow_val_eq_of_eq zeta h2
  rw [eq1, eq2]
  have eq3 : zeta ^ (-k + 3 * k * x).val = zeta ^ (-k).val * zeta ^ (3 * k * x).val := pow_val_add zeta hzeta (-k) (3 * k * x)
  rw [eq3]
  ring
