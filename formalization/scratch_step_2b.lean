import Mathlib.Data.Matrix.Basic
import Formalization.CollatzConnectivity
import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral
open Classical

lemma sheetSplit_left_inv {d : ℕ} (hd : d ≥ 3) :
  Function.LeftInverse (fun ⟨v, b⟩ => if b = 0 then (v.val : ZMod (2^(d-1))) else tau (v.val : ZMod (2^(d-1))))
                       (fun x => (pi x, (if x.val < 2^(d-2) then 0 else 1 : ZMod 2))) := by
  intro x
  simp only [pi, tau, canonicalLift, ZMod.val]
  by_cases h : x.val < 2^(d-2)
  · -- x is in sheet 0
    simp [h]
    -- Need: (x.val % 2^(d-2) : ZMod (2^(d-1))) = x
    have h_mod : x.val % 2^(d-2) = x.val := Nat.mod_eq_of_lt h
    rw [h_mod]
    exact ZMod.natCast_zmod_val x
  · -- x is in sheet 1
    simp [h]
    have h_ge : x.val ≥ 2^(d-2) := by omega
    have h_lt : x.val < 2^(d-1) := ZMod.val_lt x
    -- x.val = 2^(d-2) + r where r = x.val - 2^(d-2) < 2^(d-2)
    have h_mod : x.val % 2^(d-2) = x.val - 2^(d-2) := by
      rw [Nat.mod_eq_of_lt (by omega)]
      omega
    rw [h_mod]
    -- Need: (x.val - 2^(d-2) + 2^(d-2) : ZMod (2^(d-1))) = x
    have : ((x.val - 2^(d-2) + 2^(d-2) : ℕ) : ZMod (2^(d-1))) = x := by
      have h_eq : x.val - 2^(d-2) + 2^(d-2) = x.val := by omega
      rw [h_eq]
      exact ZMod.natCast_zmod_val x
    exact this

lemma sheetSplit_right_inv {d : ℕ} (hd : d ≥ 3) :
  Function.RightInverse (fun ⟨v, b⟩ => if b = 0 then (v.val : ZMod (2^(d-1))) else tau (v.val : ZMod (2^(d-1))))
                        (fun x => (pi x, (if x.val < 2^(d-2) then 0 else 1 : ZMod 2))) := by
  rintro ⟨v, b⟩
  simp only [pi_natCast, tau_pi, canonicalLift]
  have hb : b = 0 ∨ b = 1 := by
    have h : b.val < 2 := ZMod.val_lt b
    have : b.val = 0 ∨ b.val = 1 := by omega
    rcases this with h0 | h1
    · left; exact ZMod.val_injective 2 h0
    · right; exact ZMod.val_injective 2 h1
  rcases hb with hb | hb
  · -- b = 0
    simp [hb]
    -- Need: pi (v.val : ZMod (2^(d-1))) = v and sign is 0
    constructor
    · -- pi part
      rw [pi_natCast]
      exact ZMod.natCast_zmod_val v
    · -- sign part
      have h_lt : v.val < 2^(d-2) := ZMod.val_lt v
      have h_sign : ((v.val : ℕ) : ZMod (2^(d-1))).val < 2^(d-2) := by
        rw [ZMod.val_natCast_of_lt (by omega)]
        exact h_lt
      simp [h_sign]
  · -- b = 1
    simp [hb]
    constructor
    · -- pi part
      rw [tau_pi hd, pi_natCast]
      exact ZMod.natCast_zmod_val v
    · -- sign part
      have h_lt : v.val < 2^(d-2) := ZMod.val_lt v
      have h_sign : (tau ((v.val : ℕ) : ZMod (2^(d-1)))).val ≥ 2^(d-2) := by
        simp [tau]
        rw [ZMod.val_add, ZMod.val_natCast_of_lt (by omega)]
        omega
      simp [h_sign]
