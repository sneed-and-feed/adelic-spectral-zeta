
import Mathlib.Data.ZMod.Basic
import Mathlib.RingTheory.RootsOfUnity.Basic
import Mathlib.RingTheory.Polynomial.Cyclotomic.Eval
import Formalization.CyclotomicProduct

open Polynomial
open Finset

lemma odd_coprime_pow_two {a n : ℕ} (ha : Odd a) : a.Coprime (2^n) := by
  have h1 : a.Coprime 2 := Nat.coprime_two_right.mpr ha
  exact h1.pow_right n

lemma neg_val_odd {n : ℕ} {a : ZMod (2^n)} (hn : 1 ≤ n) (ha : Odd a.val) : Odd (-a).val := by
  have hpos : 0 < 2^n := by positivity
  have h_ne_zero : a ≠ 0 := by
    intro h
    rw [h] at ha
    have h_zero : (0 : ZMod (2^n)).val = 0 := ZMod.val_zero
    rw [h_zero] at ha
    simp at ha
  have h_val_neg : (-a).val = 2^n - a.val := by
    exact @ZMod.val_neg_of_ne_zero (2^n) ⟨ne_of_gt hpos⟩ a ⟨h_ne_zero⟩
  rw [h_val_neg]
  have heven : Even (2^n) := by
    obtain ⟨m, rfl⟩ := Nat.exists_eq_add_of_le hn
    use 2^m
    ring
  have h_lt : a.val ≤ 2^n := le_of_lt (ZMod.val_lt a)
  exact Nat.Even.sub_odd h_lt heven ha

variable {F : Type _} [Field F] {n : ℕ} (zeta : F) (hzeta : IsPrimitiveRoot zeta (2^n))

lemma test (hn : 2 ≤ n) (C_1 C_2 : Finset (ZMod (2^n))) 
  (h_partition : Disjoint C_1 C_2) 
  (h_union : C_1 ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset)
  (h_neg : C_2 = C_1.image (fun x ↦ -x)) :
  W_1 zeta C_1 * W_2 zeta C_2 = 2 := by
  have hn_ge_1 : 1 ≤ n := by omega
  have hpos : 0 < 2^n := by positivity
  
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
      have heq3 : (-a) = (-b) := @ZMod.val_injective (2^n) ⟨ne_of_gt hpos⟩ (-a) (-b) heq2
      exact neg_inj.mp heq3
    · intro μ hμ
      have h_prim_mu : IsPrimitiveRoot μ (2^n) := (mem_primitiveRoots hpos).mp hμ
      have h_neg_mem : -μ ∈ primitiveRoots (2^n) F := neg_mem_primitiveRoots zeta hzeta μ hn hμ
      have h_prim_neg_mu : IsPrimitiveRoot (-μ) (2^n) := (mem_primitiveRoots hpos).mp h_neg_mem
      have h_exists := hzeta.eq_pow_of_pow_eq_one h_prim_neg_mu.pow_eq_one
      rcases h_exists with ⟨i, hi_lt, hi_eq⟩
      -- zeta ^ i = -μ
      -- we need i to be coprime to 2^n
      have h_prim_zi : IsPrimitiveRoot (zeta ^ i) (2^n) := by
        rw [hi_eq]
        exact h_prim_neg_mu
      have h_coprime : i.Coprime (2^n) := (hzeta.pow_iff_coprime hpos i).mp h_prim_zi
      -- therefore i is odd
      have h_odd_i : Odd i := Nat.coprime_two_right.mp (h_coprime.coprime_pow_right hn_ge_1)
      -- now let a = -i in ZMod (2^n)
      let a : ZMod (2^n) := - (i : ZMod (2^n))
      use a
      have h_a_mem : a ∈ {x : ZMod (2^n) | Odd x.val}.toFinset := by
        simp only [Set.toFinset_setOf, mem_filter, mem_univ, true_and]
        -- need to show a.val is odd
        -- a = -i. so a.val = 2^n - (i % 2^n) = 2^n - i.
        have h_i_lt : (i : ZMod (2^n)).val = i := ZMod.val_natCast_of_lt hi_lt
        -- show it's odd
        sorry
      use h_a_mem
      -- show - (zeta ^ (-a).val) = μ
      sorry
    · intro a ha
      ring
  rw [h_bij]
  have h_prod2 := prod_one_sub_primitive_roots zeta hzeta
  rw [h_prod2]
  exact eval_one_cyclotomic_two_pow hn_ge_1
