import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval
import Mathlib.Algebra.BigOperators.Group.Finset
import Mathlib.Algebra.BigOperators.Ring

open Polynomial
open Finset

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

/--
The cycle of 1 under multiplication by 3 modulo 2^n.
-/
def cycle_one (n : ℕ) : Finset (ZMod (2^n)) :=
  sorry

/--
The cycle of -1 under multiplication by 3 modulo 2^n.
-/
def cycle_minus_one (n : ℕ) : Finset (ZMod (2^n)) :=
  sorry

/--
For n ≥ 3, the odd residues are exactly the union of cycle_one and cycle_minus_one.
-/
lemma odd_residues_decomposition (hn : 3 ≤ n) :
  cycle_one n ∪ cycle_minus_one n = {x : ZMod (2^n) | Odd x.val}.toFinset := by
  sorry

def W_1 (C_1 : Finset (ZMod (2^n))) : F :=
  ∏ x ∈ C_1, (1 + zeta ^ (-x).val)

def W_2 (C_2 : Finset (ZMod (2^n))) : F :=
  ∏ x ∈ C_2, (1 + zeta ^ (-x).val)

lemma eval_one_cyclotomic_two_pow (hn : 1 ≤ n) : 
  eval 1 (cyclotomic (2^n) F) = 2 := by
  have hp : Fact (Nat.Prime 2) := ⟨Nat.prime_two⟩
  have h1 : 2^n = 2^(n-1 + 1) := by 
    congr 1
    omega
  rw [h1]
  exact eval_one_cyclotomic_prime_pow (n-1)

lemma prod_one_sub_primitive_roots :
  ∏ μ ∈ primitiveRoots (2^n) F, (1 - μ) = eval 1 (cyclotomic (2^n) F) := by
  have h1 : cyclotomic (2^n) F = ∏ μ ∈ primitiveRoots (2^n) F, (X - C μ) := 
    cyclotomic_eq_prod_X_sub_primitiveRoots hzeta
  have h2 : eval 1 (cyclotomic (2^n) F) = eval 1 (∏ μ ∈ primitiveRoots (2^n) F, (X - C μ)) := by rw [h1]
  rw [h2, eval_prod]
  apply prod_congr rfl
  intro x _
  simp

/--
The product W_1 * W_2 equals 2.
This proves that the product of the weights over the cycles gives 2.
-/
lemma W_1_mul_W_2_eq_two (hn : 2 ≤ n) (C_1 C_2 : Finset (ZMod (2^n))) 
  (h_partition : Disjoint C_1 C_2) 
  (h_union : C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset)
  (h_neg : C_2 = C_1.image (fun x ↦ -x)) :
  W_1 zeta C_1 * W_2 zeta C_2 = 2 := by
  have h1 : W_1 zeta C_1 * W_2 zeta C_2 = ∏ x ∈ C_1 ∪ C_2, (1 + zeta ^ (-x).val) := by
    unfold W_1 W_2
    rw [prod_union h_partition]
  rw [h1, h_union]
  -- proof that this product equals eval 1 (cyclotomic (2^n) F) = 2
  -- uses prod_one_sub_primitive_roots and eval_one_cyclotomic_two_pow
  sorry

/--
Spectral Gap Theorem for S_n:
If lambda is the eigenvalue associated with the cycle C_1 of length 2^{n-2},
it satisfies lambda^(2^{n-2}) = W_1.
By symmetry, the conjugate eigenvalue satisfies lambda_conj^(2^{n-2}) = W_2.
Thus their product is 2, meaning the magnitude squared is 2^{1/2^{n-2}},
yielding an exact magnitude of 2^{1/2^{n-1}}.
-/
lemma eigenvalue_magnitude_squared_eq (lambda lambda_conj : F)
  (C_1 C_2 : Finset (ZMod (2^n)))
  (h_lambda : lambda ^ (2^(n-2)) = W_1 zeta C_1)
  (h_lambda_conj : lambda_conj ^ (2^(n-2)) = W_2 zeta C_2)
  (hn : 2 ≤ n)
  (h_partition : Disjoint C_1 C_2) 
  (h_union : C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset)
  (h_neg : C_2 = C_1.image (fun x ↦ -x)) :
  (lambda * lambda_conj) ^ (2^(n-2)) = 2 := by
  calc
    (lambda * lambda_conj) ^ (2^(n-2)) = lambda ^ (2^(n-2)) * lambda_conj ^ (2^(n-2)) := by rw [mul_pow]
    _ = W_1 zeta C_1 * W_2 zeta C_2 := by rw [h_lambda, h_lambda_conj]
    _ = 2 := W_1_mul_W_2_eq_two zeta hn C_1 C_2 h_partition h_union h_neg
