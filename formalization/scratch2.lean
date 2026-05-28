import Mathlib
import Formalization.CyclotomicProduct
import Formalization.SpectralCircle

open Finset

lemma odd_is_unit {n : ℕ} {x : ZMod (2^n)} (hx : x.val % 2 = 1) : IsUnit x := by
  have hc : Nat.Coprime x.val 2 := by
    rw [Nat.coprime_two_right, Nat.odd_iff]
    exact hx
  have hc_pow : Nat.Coprime x.val (2^n) := Nat.Coprime.pow_right n hc
  have h_is_unit_cast : IsUnit (x.val : ZMod (2^n)) := (ZMod.isUnit_iff_coprime x.val (2^n)).mpr hc_pow
  have : (x.val : ZMod (2^n)) = x := ZMod.natCast_zmod_val x
  rwa [← this]

lemma three_pow_mod_eight (m : ℕ) : (3 : ZMod 8)^m = 1 ∨ (3 : ZMod 8)^m = 3 := by
  induction m with
  | zero => left; ring
  | succ m ih =>
    rcases ih with h1 | h3
    · right; rw [pow_succ, h1]; ring
    · left; rw [pow_succ, h3]; decide

lemma orbit_disjoint (n : ℕ) (hn : n ≥ 3)
    (C : Finset (ZMod (2^n)))
    (hC_orbit : ∀ k ∈ C, (3 : ZMod (2^n)) * k ∈ C)
    (hC_size : C.card = 2^(n-2))
    (hC_odd : ∀ k ∈ C, (k.val % 2 = 1)) :
    Disjoint C (C.image (fun x ↦ -x)) := by
  by_contra h_not_disjoint
  rw [Finset.not_disjoint_iff] at h_not_disjoint
  rcases h_not_disjoint with ⟨x, hx_C, hx_neg_C⟩
  rw [Finset.mem_image] at hx_neg_C
  rcases hx_neg_C with ⟨y, hy_C, hy_eq⟩
  have hy_eq_neg : y = -x := by
    calc y = -(-y) := by rw [neg_neg]
      _ = -x := by rw [hy_eq]
  
  have h_x_unit : IsUnit x := odd_is_unit (hC_odd x hx_C)
  let u_3 : (ZMod (2^n))ˣ := ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide))
  have h_u_3 : (3 : ZMod (2^n)) = u_3 := rfl

  let S := (Finset.range (2^(n-2))).image (fun m ↦ (3 : ZMod (2^n))^m * x)
  have hS_sub : S ⊆ C := by
    intro z hz
    rw [Finset.mem_image] at hz
    rcases hz with ⟨m, _, hm_eq⟩
    rw [← hm_eq]
    clear hz z hm_eq
    induction m with
    | zero => 
      simp only [pow_zero, one_mul]
      exact hx_C
    | succ m ih =>
      rw [pow_succ]
      have h4 : (3 : ZMod (2^n)) * 3^m * x = (3 : ZMod (2^n)) * (3^m * x) := by ring
      rw [h4]
      exact hC_orbit (3^m * x) ih

  have hS_card : S.card = 2^(n-2) := by
    have h_card_range : (Finset.range (2^(n-2))).card = 2^(n-2) := Finset.card_range _
    rw [← h_card_range]
    apply Finset.card_image_of_injOn
    intro a ha b hb hab
    have ha_lt : a < 2^(n-2) := Finset.mem_range.mp (Finset.mem_coe.mp ha)
    have hb_lt : b < 2^(n-2) := Finset.mem_range.mp (Finset.mem_coe.mp hb)
    have h_cancel : (3 : ZMod (2^n))^a = (3 : ZMod (2^n))^b := by
      exact IsUnit.mul_right_cancel h_x_unit hab
    have h_unit_pow : (u_3 : ZMod (2^n))^a = (u_3 : ZMod (2^n))^b := by
      push_cast
      exact h_cancel
    have h_unit_eq : u_3^a = u_3^b := by
      ext
      exact h_unit_pow
    have h_mod : a ≡ b [MOD orderOf u_3] := pow_eq_pow_iff_modEq.mp h_unit_eq
    have h_ord : orderOf u_3 = 2^(n-2) := order_three_mod_pow_two n hn
    rw [h_ord] at h_mod
    exact Nat.ModEq.eq_of_lt_of_lt h_mod ha_lt hb_lt
  
  have hS_eq_C : S = C := by
    apply Finset.eq_of_subset_of_card_le hS_sub
    rw [hS_card, hC_size]
  
  have hy_S : y ∈ S := by
    rw [hS_eq_C]
    exact hy_C
  
  rw [hy_eq_neg] at hy_S
  rw [Finset.mem_image] at hy_S
  rcases hy_S with ⟨m, _, hm_eq⟩
  have h_m_cancel : -x = (3 : ZMod (2^n))^m * x := hm_eq.symm
  have h_neg_one : (-1 : ZMod (2^n)) * x = (3 : ZMod (2^n))^m * x := by
    calc (-1 : ZMod (2^n)) * x = - (1 * x) := by ring
      _ = -x := by rw [one_mul]
      _ = (3 : ZMod (2^n))^m * x := h_m_cancel
  
  have h_neg_eq : (-1 : ZMod (2^n)) = (3 : ZMod (2^n))^m := by
    exact IsUnit.mul_right_cancel h_x_unit h_neg_one
  
  let f : ZMod (2^n) →+* ZMod 8 := ZMod.castHom (pow_dvd_pow 2 (show 3 ≤ n by omega)) (ZMod 8)
  have h_f : f (-1) = f ((3 : ZMod (2^n))^m) := by
    rw [h_neg_eq]
  
  have h_f_neg : f (-1) = -1 := by
    rw [RingHom.map_neg, RingHom.map_one]
  
  have h_f_3 : f 3 = 3 := by
    have h : (3 : ZMod (2^n)) = 1 + 1 + 1 := by ring
    have h8 : (3 : ZMod 8) = 1 + 1 + 1 := by ring
    rw [h, RingHom.map_add, RingHom.map_add, RingHom.map_one, ← h8]

  have h_f_pow : f ((3 : ZMod (2^n))^m) = (3 : ZMod 8)^m := by
    rw [RingHom.map_pow, h_f_3]
  
  rw [h_f_neg, h_f_pow] at h_f
  
  have h_3_pow_8 := three_pow_mod_eight m
  rcases h_3_pow_8 with h1 | h3
  · rw [h1] at h_f
    revert h_f
    decide
  · rw [h3] at h_f
    revert h_f
    decide
