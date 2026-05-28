import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval

open Polynomial
open Finset

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

lemma neg_mem_primitiveRoots (μ : F) (hn : 2 ≤ n) (hμ : μ ∈ primitiveRoots (2^n) F) :
  -μ ∈ primitiveRoots (2^n) F := by
  have hnpos : 0 < 2^n := by positivity
  have h_prim : IsPrimitiveRoot μ (2^n) := (mem_primitiveRoots hnpos).mp hμ
  apply (mem_primitiveRoots hnpos).mpr
  have heven : Even (2^n) := by
    obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
    use 2 * 2^m
    ring
  constructor
  · rw [neg_pow, heven.neg_one_pow, one_mul, h_prim.pow_eq_one]
  · intro l hl
    have heven_l : Even l := by
      have hl2 : (-μ)^(2*l) = 1 := by rw [mul_comm, pow_mul, hl, one_pow]
      have hl2_pos : (-μ)^(2*l) = μ^(2*l) := by
        rw [pow_mul, neg_sq, ←pow_mul]
      rw [hl2_pos] at hl2
      have hdvd := h_prim.dvd_of_pow_eq_one _ hl2
      obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
      have h1 : 2^(2+m) = 2 * 2^(1+m) := by
        rw [show 2+m = 1+(1+m) by omega, pow_add, pow_one]
      rw [h1] at hdvd
      have h2 : 2^(1+m) ∣ l := Nat.dvd_of_mul_dvd_mul_left zero_lt_two hdvd
      rcases h2 with ⟨k, rfl⟩
      use 2^m * k
      rw [show 1+m = m+1 by omega, pow_add, pow_one]
      ring
    have hl_pos : (-μ)^l = μ^l := by
      rw [neg_pow, heven_l.neg_one_pow, one_mul]
    rw [hl_pos] at hl
    exact h_prim.dvd_of_pow_eq_one _ hl

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

lemma odd_coprime_pow_two {a n : ℕ} (ha : Odd a) : a.Coprime (2^n) := by
  have h1 : a.Coprime 2 := Nat.coprime_two_right.mpr ha
  exact h1.pow_right n

lemma neg_val_odd {n : ℕ} {a : ZMod (2^n)} (hn : 1 ≤ n) (ha : Odd a.val) : Odd (-a).val := by
  have hpos : 0 < 2^n := by positivity
  have _inst : NeZero (2^n) := ⟨ne_of_gt hpos⟩
  have h_ne_zero : a ≠ 0 := by
    intro h
    rw [h] at ha
    have h_zero : (0 : ZMod (2^n)).val = 0 := ZMod.val_zero
    rw [h_zero] at ha
    simp at ha
  have _inst2 : NeZero a := ⟨h_ne_zero⟩
  have h_val_neg : (-a).val = 2^n - a.val := ZMod.val_neg_of_ne_zero (a := a)
  rw [h_val_neg]
  have heven : Even (2^n) := by
    obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
    use 2^m
    ring
  have h_lt : a.val ≤ 2^n := le_of_lt (ZMod.val_lt a)
  exact Nat.Even.sub_odd h_lt heven ha

/--
The product W_1 * W_2 equals 2.
This proves that the product of the weights over the cycles gives 2.
Surjectivity of the Galois permutation is left as a sorry for now.
-/
lemma W_1_mul_W_2_eq_two (hn : 2 ≤ n) (C_1 C_2 : Finset (ZMod (2^n))) 
  (h_partition : Disjoint C_1 C_2) 
  (h_union : C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset)
  (h_neg : C_2 = C_1.image (fun x ↦ -x)) :
  W_1 zeta C_1 * W_2 zeta C_2 = 2 := by
  have hn_ge_1 : 1 ≤ n := by omega
  have hpos : 0 < 2^n := by positivity
  have _inst : NeZero (2^n) := ⟨ne_of_gt hpos⟩
  
  have h_prod : W_1 zeta C_1 * W_2 zeta C_2 = ∏ x ∈ C_1 ∪ C_2, (1 + zeta ^ (-x).val) := by
    rw [W_1, W_2, ←prod_union h_partition]
  rw [h_union] at h_prod
  rw [h_prod]
  
  have h_bij : ∏ x ∈ {x : ZMod (2^n) | Odd x.val}.toFinset, (1 + zeta ^ (-x).val) = 
               ∏ μ ∈ primitiveRoots (2^n) F, (1 - μ) := by
    apply prod_bij (fun (x : ZMod (2^n)) _ ↦ - (zeta ^ (-x).val))
    · intro a ha
      simp only [Set.toFinset_setOf, mem_filter, mem_univ, true_and] at ha
      have h1 : Odd (-a).val := neg_val_odd hn_ge_1 ha
      have h2 : (-a).val.Coprime (2^n) := odd_coprime_pow_two h1
      have h3 : IsPrimitiveRoot (zeta ^ (-a).val) (2^n) := hzeta.pow_of_coprime _ h2
      have h4 : zeta ^ (-a).val ∈ primitiveRoots (2^n) F := (mem_primitiveRoots hpos).mpr h3
      exact neg_mem_primitiveRoots zeta hzeta (zeta ^ (-a).val) hn h4
    · intro a ha b hb heq
      simp only [Set.toFinset_setOf, mem_filter, mem_univ, true_and] at ha hb
      simp only [neg_inj] at heq
      have h_lt_a : (-a).val < 2^n := ZMod.val_lt (-a)
      have h_lt_b : (-b).val < 2^n := ZMod.val_lt (-b)
      have heq2 : (-a).val = (-b).val := hzeta.pow_inj h_lt_a h_lt_b heq
      have heq3 : (-a) = (-b) := ZMod.val_injective (2^n) heq2
      exact neg_inj.mp heq3
    · intro μ hμ
      sorry
    · intro a ha
      ring
  rw [h_bij]
  have h_prod2 := prod_one_sub_primitive_roots zeta hzeta
  rw [h_prod2]
  exact eval_one_cyclotomic_two_pow hn_ge_1

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
    _ = 2 := W_1_mul_W_2_eq_two zeta hzeta hn C_1 C_2 h_partition h_union h_neg
