import Mathlib.Data.Matrix.Basic
import Formalization.CollatzConnectivity
import Formalization.CollatzSpectral

open Matrix
open CollatzSpectral

def toBlockIndices {d : ℕ} (hd : d ≥ 3) : 
    ZMod (2^(d-1)) ≃ (ZMod (2^(d-2)) × ZMod 2) where
  toFun x := (pi x, fiberSign hd x)
  invFun := fun ⟨v, s⟩ => canonicalLift v + s.val * (2^(d-2) : ℕ)
  left_inv := by
    intro x
    sorry
open Classical in
noncomputable def tauMatrix {d : ℕ} : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ :=
  fun x y => if y = tau x then 1 else 0

lemma tauMatrix_involutive {d : ℕ} (hd : d ≥ 3) :
    (tauMatrix : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ) ^ 2 = 1 := by
  ext i j
  simp [pow_two, Matrix.mul_apply, tauMatrix, one_apply]
  have h_sum : (∑ k : ZMod (2^(d-1)), (if k = tau i then (1 : ℚ) else 0) * (if j = tau k then 1 else 0)) = 
               (if j = tau (tau i) then 1 else 0) := by
    rw [Finset.sum_eq_single (tau i)]
    · simp
    · intro k _ hk
      simp [hk]
    · intro h
      simp at h
  rw [h_sum, tau_tau hd i]
  congr 1
  exact eq_comm
    have h_tau_val : (tau x).val = (x.val + 2^(d-2)) % 2^(d-1) := by
      have h1 : tau x = x + (2^(d-2) : ℕ) := rfl
      rw [h1]
      have h2 : ((x.val + 2^(d-2) : ℕ) : ZMod (2^(d-1))) = x + (2^(d-2) : ℕ) := by push_cast; rfl
      rw [← h2]
      exact ZMod.val_natCast _
    have hd_pos : 0 < d := by omega
    have h_split : 2^(d-1) = 2^(d-2) * 2 := by
      have : d - 1 = d - 2 + 1 := by omega
      rw [this, pow_add, pow_one]
    have hx : x.val < 2^(d-1) := ZMod.val_lt x
    dsimp [toBlockIndices, fiberSign]
    have h_sign_x : ((x.val / 2^(d-2) : ZMod 2)).val = x.val / 2^(d-2) := by
      rw [ZMod.val_natCast]
      have : x.val / 2^(d-2) < 2 := by rw [h_split] at hx; exact Nat.div_lt_of_lt_mul hx
      exact Nat.mod_eq_of_lt this
    have h_sign_tau : (((tau x).val / 2^(d-2) : ZMod 2)).val = (tau x).val / 2^(d-2) := by
      rw [ZMod.val_natCast]
      have htau : (tau x).val < 2^(d-1) := ZMod.val_lt _
      have : (tau x).val / 2^(d-2) < 2 := by rw [h_split] at htau; exact Nat.div_lt_of_lt_mul htau
      exact Nat.mod_eq_of_lt this
    rw [h_sign_tau, h_sign_x]
    have h_add : (((x.val / 2^(d-2) : ZMod 2) + 1).val) = (x.val / 2^(d-2) + 1) % 2 := by
      have h_cast : ((x.val / 2^(d-2) + 1 : ℕ) : ZMod 2) = (x.val / 2^(d-2) : ZMod 2) + 1 := by push_cast; rfl
      rw [← h_cast]
      exact ZMod.val_natCast _
    rw [h_add, h_tau_val]
    omega
