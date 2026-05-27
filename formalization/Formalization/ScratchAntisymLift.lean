import Formalization.SchreierAntisymBound
open Mathlib

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

def antisym_lift (w : ZMod (2^(d-2)) → ℝ) : ZMod (2^(d-1)) → ℝ :=
  fun x => if x.val < 2^(d-2) then w (pi x) else - w (pi x)

lemma antisym_lift_tau (w : ZMod (2^(d-2)) → ℝ) (x : ZMod (2^(d-1))) :
    antisym_lift w (tau x) = - antisym_lift w x := by
  have h_bound : 2^(d-2) < 2^(d-1) := by
    apply Nat.pow_lt_pow_right (by decide)
    omega
  have h_pow : 2^(d-1) = 2 * 2^(d-2) := by
    have h_sub : d - 1 = d - 2 + 1 := by omega
    rw [h_sub, pow_add, pow_one, mul_comm]
  have h_tau_val_eq : (tau x).val = (x.val + 2^(d-2)) % 2^(d-1) := by
    dsimp [tau]
    rw [ZMod.val_add]
    have h_cast : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := ZMod.val_natCast_of_lt h_bound
    rw [h_cast]
  have hx_bound : x.val < 2^(d-1) := ZMod.val_lt x
  dsimp [antisym_lift]
  rw [tau_pi hd x]
  by_cases hx : x.val < 2^(d-2)
  · -- Case 1
    have h_tau_val : (tau x).val = x.val + 2^(d-2) := by
      rw [h_tau_val_eq]
      apply Nat.mod_eq_of_lt
      omega
    have h_tau_ge : ¬ ((tau x).val < 2^(d-2)) := by omega
    rw [if_pos hx, if_neg h_tau_ge]
  · -- Case 2
    have h_tau_val : (tau x).val = x.val - 2^(d-2) := by
      rw [h_tau_val_eq]
      have h1 : 2^(d-1) ≤ x.val + 2^(d-2) := by omega
      have h4 : x.val + 2^(d-2) - 2^(d-1) < 2^(d-1) := by omega
      have h3 : (x.val + 2^(d-2)) % 2^(d-1) = (x.val + 2^(d-2) - 2^(d-1)) % 2^(d-1) := Nat.mod_eq_sub_mod h1
      have h5 : (x.val + 2^(d-2) - 2^(d-1)) % 2^(d-1) = x.val + 2^(d-2) - 2^(d-1) := Nat.mod_eq_of_lt h4
      rw [h3, h5]
      omega
    have h_tau_lt : (tau x).val < 2^(d-2) := by omega
    rw [if_neg hx, if_pos h_tau_lt, neg_neg]

lemma antisym_lift_zero_iff (w : ZMod (2^(d-2)) → ℝ) :
    antisym_lift w = 0 ↔ w = 0 := by
  constructor
  · intro h
    funext y
    have h_exists_lift : ∃ x : ZMod (2^(d-1)), pi x = y ∧ x.val < 2^(d-2) := by
      use (y.val : ZMod (2^(d-1)))
      constructor
      · rw [pi_natCast, ZMod.natCast_zmod_val]
      · have h_lt : y.val < 2^(d-2) := ZMod.val_lt y
        have h_cast : ((y.val : ℕ) : ZMod (2^(d-1))).val = y.val := ZMod.val_natCast_of_lt (by 
          have h_pow : 2^(d-1) = 2 * 2^(d-2) := by
            have h_sub : d - 1 = d - 2 + 1 := by omega
            rw [h_sub, pow_add, pow_one, mul_comm]
          linarith
        )
        rw [h_cast]
        exact h_lt
    obtain ⟨x, hx_pi, hx_lt⟩ := h_exists_lift
    have h_eval : antisym_lift w x = 0 := by rw [h]; rfl
    have h_eval2 : antisym_lift w x = w (pi x) := if_pos hx_lt
    rw [h_eval2, hx_pi] at h_eval
    exact h_eval
  · rintro rfl
    funext x
    dsimp [antisym_lift]
    split
    · rfl
    · rw [neg_zero]

end SchreierSpectral
