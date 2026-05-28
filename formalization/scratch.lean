import Mathlib
import Formalization.CyclotomicProduct
import Formalization.SpectralCircle

open Finset

lemma odd_is_unit {n : ℕ} {x : ZMod (2^n)} (hx : x.val % 2 = 1) : IsUnit x := by
  have h1 : Nat.Coprime x.val 2 := by
    rw [Nat.coprime_two_right]
    exact Nat.odd_iff.mpr hx
  have h2 : Nat.Coprime x.val (2^n) := Nat.Coprime.pow_right n h1
  have h3 : IsUnit (x.val : ZMod (2^n)) := ZMod.isUnit_natCast_of_coprime h2
  have h4 : (x.val : ZMod (2^n)) = x := ZMod.natCast_zmod_val x
  rwa [h4] at h3

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
    rw [← hy_eq]
    exact neg_neg x
  
  -- We know C has size 2^(n-2), and order of 3 is 2^(n-2).
  -- So C is exactly the orbit of x.
  let u_3 : (ZMod (2^n))ˣ := ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide))
  have h_ord : orderOf u_3 = 2^(n-2) := order_three_mod_pow_two n hn
  
  let O_x := (Finset.range (2^(n-2))).image (fun m ↦ (3 : ZMod (2^n))^m * x)
  have h_O_sub : O_x ⊆ C := by
    intro z hz
    rw [Finset.mem_image] at hz
    rcases hz with ⟨m, _, hm_eq⟩
    rw [← hm_eq]
    induction m with
    | zero => 
      simp only [pow_zero, one_mul]
      exact hx_C
    | succ m ih =>
      rw [pow_succ, mul_assoc]
      have h3 : (3 : ZMod (2^n)) * (3^m * x) = 3 * (3^m * x) := rfl
      rw [← h3]
      exact hC_orbit (3^m * x) ih
      
  have h_x_unit : IsUnit x := odd_is_unit (hC_odd x hx_C)
  
  have h_O_card : O_x.card = 2^(n-2) := by
    apply Finset.card_image_of_injective
    intro a ha b hb hab
    rw [Finset.mem_range] at ha hb
    -- 3^a * x = 3^b * x => 3^a = 3^b
    have h_cancel : (3 : ZMod (2^n))^a = (3 : ZMod (2^n))^b := by
      exact IsUnit.mul_right_cancel h_x_unit hab
    
    have h_unit_pow : (u_3 : ZMod (2^n))^a = (u_3 : ZMod (2^n))^b := by
      push_cast
      exact h_cancel
    
    have h_unit_eq : u_3^a = u_3^b := by
      ext
      exact h_unit_pow
    
    -- since a, b < orderOf u_3
    sorry
  
  sorry
