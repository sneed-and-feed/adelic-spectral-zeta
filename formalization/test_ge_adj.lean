import Mathlib.Data.Matrix.Basic
import Formalization.CollatzConnectivity
import Formalization.CollatzSpectral

open Matrix
open Classical
open CollatzSpectral

lemma tau_eq_of_sub_eq_pow {d : ℕ} (hd : d ≥ 3) (x y : ZMod (2^(d-1))) 
    (h : x - y = (2^(d-2) : ZMod (2^(d-1)))) : tau x = y := by
  have h_pow : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h2 : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
    have h4 : 2 * 2^(d-2) = 2^(d-1) := by
      calc 2 * 2^(d-2) = 2^1 * 2^(d-2) := by ring
        _ = 2^(1 + (d - 2)) := by rw [← pow_add]
        _ = 2^(d-1) := by
          have : 1 + (d - 2) = d - 1 := by omega
          rw [this]
    rw [h4] at h2
    rw [h2]
    exact CharP.cast_eq_zero (ZMod (2^(d-1))) (2^(d-1))
  have h_tau : tau x = x + (2^(d-2) : ZMod (2^(d-1))) := rfl
  calc tau x = x + (2^(d-2) : ZMod (2^(d-1))) := h_tau
    _ = (y + (2^(d-2) : ZMod (2^(d-1)))) + (2^(d-2) : ZMod (2^(d-1))) := by
      have hxy : x = y + (2^(d-2) : ZMod (2^(d-1))) := by
        calc x = x - y + y := by ring
             _ = (2^(d-2) : ZMod (2^(d-1))) + y := by rw [h]
             _ = y + (2^(d-2) : ZMod (2^(d-1))) := by ring
      rw [hxy]
    _ = y + ((2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) := by ring
    _ = y + 0 := by rw [h_pow]
    _ = y := by ring

lemma three_mul_tau {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) :
    3 * tau x = 3 * x + (2^(d-2) : ZMod (2^(d-1))) := by
  have h_tau : tau x = x + (2^(d-2) : ZMod (2^(d-1))) := rfl
  have h_pow : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h2 : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
    have h4 : 2 * 2^(d-2) = 2^(d-1) := by
      calc 2 * 2^(d-2) = 2^1 * 2^(d-2) := by ring
        _ = 2^(1 + (d - 2)) := by rw [← pow_add]
        _ = 2^(d-1) := by
          have : 1 + (d - 2) = d - 1 := by omega
          rw [this]
    rw [h4] at h2
    rw [h2]
    exact CharP.cast_eq_zero (ZMod (2^(d-1))) (2^(d-1))
  calc 3 * tau x = 3 * (x + (2^(d-2) : ZMod (2^(d-1)))) := by rw [h_tau]
    _ = 3 * x + 3 * (2^(d-2) : ZMod (2^(d-1))) := by ring
    _ = 3 * x + (2^(d-2) : ZMod (2^(d-1))) + ((2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) := by ring
    _ = 3 * x + (2^(d-2) : ZMod (2^(d-1))) + 0 := by rw [h_pow]
    _ = 3 * x + (2^(d-2) : ZMod (2^(d-1))) := by ring

lemma lift_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    (G_d (d-1)).Adj u v →
    (G_d d).Adj (canonicalLift u) (canonicalLift v) ∨ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) := by
  intro h_adj
  rcases h_adj with ⟨h_ne, h_cases⟩
  have hx : canonicalLift u ≠ canonicalLift v := by
    intro h
    have h2 : pi (canonicalLift u) = pi (canonicalLift v) := by rw [h]
    rw [pi_canonicalLift, pi_canonicalLift] at h2
    exact h_ne h2
  have hy : canonicalLift u ≠ tau (canonicalLift v) := by
    intro h
    have h2 : pi (canonicalLift u) = pi (tau (canonicalLift v)) := by rw [h]
    rw [pi_canonicalLift, tau_pi hd, pi_canonicalLift] at h2
    exact h_ne h2
  rcases h_cases with h | h | h | h
  · -- v = 3u
    have h_pi : pi (canonicalLift v - 3 * canonicalLift u) = 0 := by
      rw [pi_sub, pi_mul_three, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inl ?_⟩
      calc canonicalLift v = canonicalLift v - 3 * canonicalLift u + 3 * canonicalLift u := by ring
        _ = 0 + 3 * canonicalLift u := by rw [h0]
        _ = 3 * canonicalLift u := by ring
    · right
      refine ⟨hy, Or.inl ?_⟩
      exact tau_eq_of_sub_eq_pow hd (canonicalLift v) (3 * canonicalLift u) h2
  · -- v = 3u - 1
    have h_pi : pi (canonicalLift v - (3 * canonicalLift u - 1)) = 0 := by
      rw [pi_sub, pi_mul_three_sub_one, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inr (Or.inl ?_)⟩
      calc canonicalLift v = canonicalLift v - (3 * canonicalLift u - 1) + (3 * canonicalLift u - 1) := by ring
        _ = 0 + (3 * canonicalLift u - 1) := by rw [h0]
        _ = 3 * canonicalLift u - 1 := by ring
    · right
      refine ⟨hy, Or.inr (Or.inl ?_)⟩
      exact tau_eq_of_sub_eq_pow hd (canonicalLift v) (3 * canonicalLift u - 1) h2
  · -- u = 3v
    have h_pi : pi (canonicalLift u - 3 * canonicalLift v) = 0 := by
      rw [pi_sub, pi_mul_three, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inr (Or.inr (Or.inl ?_))⟩
      calc canonicalLift u = canonicalLift u - 3 * canonicalLift v + 3 * canonicalLift v := by ring
        _ = 0 + 3 * canonicalLift v := by rw [h0]
        _ = 3 * canonicalLift v := by ring
    · right
      refine ⟨hy, Or.inr (Or.inr (Or.inl ?_))⟩
      calc canonicalLift u = canonicalLift u - 3 * canonicalLift v + 3 * canonicalLift v := by ring
        _ = (2^(d-2) : ZMod (2^(d-1))) + 3 * canonicalLift v := by rw [h2]
        _ = 3 * canonicalLift v + (2^(d-2) : ZMod (2^(d-1))) := by ring
        _ = 3 * tau (canonicalLift v) := (three_mul_tau hd (canonicalLift v)).symm
  · -- u = 3v - 1
    have h_pi : pi (canonicalLift u - (3 * canonicalLift v - 1)) = 0 := by
      rw [pi_sub, pi_mul_three_sub_one, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inr (Or.inr (Or.inr ?_))⟩
      calc canonicalLift u = canonicalLift u - (3 * canonicalLift v - 1) + (3 * canonicalLift v - 1) := by ring
        _ = 0 + (3 * canonicalLift v - 1) := by rw [h0]
        _ = 3 * canonicalLift v - 1 := by ring
    · right
      refine ⟨hy, Or.inr (Or.inr (Or.inr ?_))⟩
      calc canonicalLift u = canonicalLift u - (3 * canonicalLift v - 1) + (3 * canonicalLift v - 1) := by ring
        _ = (2^(d-2) : ZMod (2^(d-1))) + (3 * canonicalLift v - 1) := by rw [h2]
        _ = 3 * canonicalLift v + (2^(d-2) : ZMod (2^(d-1))) - 1 := by ring
        _ = 3 * tau (canonicalLift v) - 1 := by rw [three_mul_tau hd (canonicalLift v)]

lemma weighted_adj_ge_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≥ if (G_d (d-1)).Adj u v then 1 else 0 := by
  by_cases h_adj : (G_d (d-1)).Adj u v
  · rw [if_pos h_adj]
    rw [weighted_adj_eq_sum hd]
    have h_lift := lift_adj hd u v h_adj
    rcases h_lift with h1 | h2
    · have h_eq1 : (if (G_d d).Adj (canonicalLift u) (canonicalLift v) then (1:ℚ) else 0) = 1 := if_pos h1
      have h_eq2 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) then 1 else 0 := by split_ifs <;> norm_num
      linarith
    · have h_eq1 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (canonicalLift v) then 1 else 0 := by split_ifs <;> norm_num
      have h_eq2 : (if (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) then (1:ℚ) else 0) = 1 := if_pos h2
      linarith
  · rw [if_neg h_adj]
    have hp1 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (canonicalLift v) then 1 else 0 := by split_ifs <;> norm_num
    have hp2 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) then 1 else 0 := by split_ifs <;> norm_num
    rw [weighted_adj_eq_sum hd]
    exact add_nonneg hp1 hp2
