import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval

open Polynomial
open Finset

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

def W_1 (C_1 : Finset (ZMod (2^n))) : F := ∏ x ∈ C_1, (1 + zeta ^ (-x).val)
def W_2 (C_2 : Finset (ZMod (2^n))) : F := ∏ x ∈ C_2, (1 + zeta ^ (-x).val)

lemma eval_one_cyclotomic_two_pow (hn : 1 ≤ n) : eval 1 (cyclotomic (2^n) F) = 2 := by
  rw [←Nat.sub_add_cancel hn]; exact eval_one_cyclotomic_prime_pow (n-1)

lemma prod_one_sub_primitive_roots :
  ∏ μ ∈ primitiveRoots (2^n) F, (1 - μ) = eval 1 (cyclotomic (2^n) F) := by
  rw [cyclotomic_eq_prod_X_sub_primitiveRoots hzeta, eval_prod]; simp

lemma odd_coprime_pow_two {a n : ℕ} (ha : Odd a) : a.Coprime (2^n) :=
  (Nat.coprime_two_right.mpr ha).pow_right n

lemma neg_val_odd {n : ℕ} {a : ZMod (2^n)} (hn : 1 ≤ n) (ha : Odd a.val) : Odd (-a).val := by
  haveI : NeZero (2^n) := ⟨by positivity⟩
  have h_ne : a ≠ 0 := by rintro rfl; rw [ZMod.val_zero] at ha; exact Nat.even_iff_not_odd.mp even_zero ha
  have h_val_neg : (-a).val = 2^n - a.val := @ZMod.val_neg_of_ne_zero (2^n) ⟨by positivity⟩ a ⟨h_ne⟩
  rw [h_val_neg]
  have h_pos : n ≠ 0 := by omega
  exact Nat.Even.sub_odd (ZMod.val_lt a).le (Even.pow_of_ne_zero even_two h_pos) ha

lemma neg_mem_primitiveRoots (μ : F) (hn : 2 ≤ n) (hμ : μ ∈ primitiveRoots (2^n) F) :
  -μ ∈ primitiveRoots (2^n) F := by
  rw [mem_primitiveRoots (by positivity)] at hμ ⊢
  have h_pos : n ≠ 0 := by omega
  have heven : Even (2^n) := Even.pow_of_ne_zero even_two h_pos
  refine ⟨by rw [neg_pow, heven.neg_one_pow, one_mul, hμ.pow_eq_one], fun l hl ↦ ?_⟩
  have heven_l : Even l := by
    have hl2 : (-μ)^(2*l) = 1 := by rw [mul_comm, pow_mul, hl, one_pow]
    rw [pow_mul, neg_sq, ←pow_mul] at hl2
    have hdvd : 2^n ∣ 2 * l := hμ.dvd_of_pow_eq_one _ hl2
    have h2 : 2^2 ∣ 2^n := Nat.pow_dvd_pow 2 hn
    exact even_iff_two_dvd.mpr (Nat.dvd_of_mul_dvd_mul_left zero_lt_two (h2.trans hdvd))
  rw [neg_pow, heven_l.neg_one_pow, one_mul] at hl
  exact hμ.dvd_of_pow_eq_one _ hl

lemma W_1_mul_W_2_eq_two (hn : 2 ≤ n) (C_1 C_2 : Finset (ZMod (2^n))) 
  (h_partition : Disjoint C_1 C_2) 
  (h_union : C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset)
  (h_neg : C_2 = C_1.image (fun x ↦ -x)) :
  W_1 zeta C_1 * W_2 zeta C_2 = 2 := by
  haveI : NeZero (2^n) := ⟨by positivity⟩
  have hn1 : 1 ≤ n := by omega
  rw [W_1, W_2, ←prod_union h_partition, h_union]
  have h_bij : ∏ x ∈ {x : ZMod (2^n) | Odd x.val}.toFinset, (1 + zeta ^ (-x).val) = 
               ∏ μ ∈ primitiveRoots (2^n) F, (1 - μ) := by
    apply prod_bij (fun (x : ZMod (2^n)) _ ↦ - (zeta ^ (-x).val))
    · simp only [Set.mem_toFinset, Set.mem_setOf_eq]
      intro a ha
      exact neg_mem_primitiveRoots (zeta ^ (-a).val) hn ((mem_primitiveRoots (by positivity)).mpr (hzeta.pow_of_coprime _ (odd_coprime_pow_two (neg_val_odd hn1 ha))))
    · simp only [Set.mem_toFinset, Set.mem_setOf_eq, neg_inj]
      intro a _ b _ heq
      exact neg_inj.mp <| ZMod.val_injective _ <| hzeta.pow_inj (ZMod.val_lt _) (ZMod.val_lt _) heq
    · intro μ hμ
      have h_prim_neg_mu := (mem_primitiveRoots (by positivity)).mp (neg_mem_primitiveRoots μ hn hμ)
      obtain ⟨i, hi_lt, hi_eq⟩ := hzeta.eq_pow_of_pow_eq_one h_prim_neg_mu.pow_eq_one (by positivity)
      have hi_coprime := (hzeta.pow_iff_coprime (by positivity) i).mp (by rwa [hi_eq])
      refine ⟨- (i : ZMod (2^n)), ?_, by rw [neg_neg, ZMod.val_natCast_of_lt hi_lt, hi_eq, neg_neg]⟩
      have hd : Odd (i : ZMod (2^n)).val := by
        rw [ZMod.val_natCast_of_lt hi_lt, Nat.odd_iff_not_even]
        intro heven
        have h2 : 2 ∣ Nat.gcd i (2^n) := Nat.dvd_gcd heven.two_dvd (dvd_pow_self 2 (by omega))
        rw [hi_coprime] at h2; revert h2; decide
      rw [Set.mem_toFinset, Set.mem_setOf_eq]
      exact neg_val_odd hn1 hd
    · intro a _ha
      ring
  rw [h_bij, prod_one_sub_primitive_roots zeta hzeta, eval_one_cyclotomic_two_pow hn1]

lemma eigenvalue_magnitude_squared_eq (lambda lambda_conj : F)
  (C_1 C_2 : Finset (ZMod (2^n)))
  (h_lambda : lambda ^ (2^(n-2)) = W_1 zeta C_1)
  (h_lambda_conj : lambda_conj ^ (2^(n-2)) = W_2 zeta C_2)
  (hn : 2 ≤ n)
  (h_partition : Disjoint C_1 C_2) 
  (h_union : C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset)
  (h_neg : C_2 = C_1.image (fun x ↦ -x)) :
  (lambda * lambda_conj) ^ (2^(n-2)) = 2 := by
  rw [mul_pow, h_lambda, h_lambda_conj, W_1_mul_W_2_eq_two zeta hzeta hn C_1 C_2 h_partition h_union h_neg]
