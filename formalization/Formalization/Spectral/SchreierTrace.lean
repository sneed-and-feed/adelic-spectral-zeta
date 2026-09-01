import Mathlib.Data.Matrix.Basic
import Formalization.Spectral.SchreierSpectral
import Formalization.Spectral.SchreierConnectivity

open Matrix
open Classical

namespace SchreierSpectral

lemma A'_diag_zero {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    A'_matrix hd (u, 0) (u, 0) = 0 := by
  simp only [A'_matrix, Matrix.reindex_apply]
  dsimp [Matrix.submatrix]
  rw [sheetSplitInv_zero hd u]
  simp only [adjacencyMatrix]
  simp

lemma A'_diag_one {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    A'_matrix hd (u, 0) (u, 1) = if (G_d d).Adj (canonicalLift u) (tau (canonicalLift u)) then 1 else 0 := by
  simp only [A'_matrix, Matrix.reindex_apply]
  dsimp [Matrix.submatrix]
  rw [sheetSplitInv_zero hd u, sheetSplitInv_one hd u]
  simp only [adjacencyMatrix]

/-- The unique canonical lift that connects to its tau counterpart is 2^(d-3). -/
lemma canonicalLift_adj_tau {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    (G_d d).Adj (canonicalLift u) (tau (canonicalLift u)) ↔ u = 2^(d-3) := by
  constructor
  · intro h_adj
    let k := u.val
    have hk_lt : k < 2^(d-2) := ZMod.val_lt u
    have h_pow1 : 2^(d-1) = 2 * 2^(d-2) := by
      rw [show d - 1 = d - 2 + 1 by omega, pow_add, pow_one]; ring
    have h_pow2 : 2^(d-2) = 2 * 2^(d-3) := by
      rw [show d - 2 = d - 3 + 1 by omega, pow_add, pow_one]; ring
    have h_d1_zero : ((2^(d-1) : ℕ) : ZMod (2^(d-1))) = 0 := ZMod.natCast_self _
    have h_2d2_zero : 2 * (2^(d-2) : ZMod (2^(d-1))) = 0 := by
      rw [show 2 * (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) by push_cast; rfl,
          ← h_pow1, h_d1_zero]
    have h_pos : 0 < 2^(d-3) := by positivity
    have hu_k : u = (k : ZMod (2^(d-2))) := (ZMod.natCast_zmod_val u).symm
    have h_adj2 : (G_d d).Adj (k : ZMod (2^(d-1))) ((k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) := by
      have h := h_adj
      unfold canonicalLift tau at h
      push_cast at h
      exact h
    rcases h_adj2.2 with h1 | h2 | h3 | h4
    · -- Case 1: k + 2^(d-2) = 3k
      have h_eq : ((2 * k : ℕ) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by
        push_cast; linear_combination -h1
      have h_nat : 2 * k = 2^(d-2) := by
        have := congrArg ZMod.val h_eq
        rwa [ZMod.val_natCast_of_lt (by omega), ZMod.val_natCast_of_lt (by omega)] at this
      have hk : k = 2^(d-3) := by omega
      rw [hu_k, hk]; push_cast; rfl
    · -- Case 2: k + 2^(d-2) = 3k - 1
      have h_eq : ((2 * k : ℕ) : ZMod (2^(d-1))) = ((2^(d-2) + 1 : ℕ) : ZMod (2^(d-1))) := by
        push_cast; linear_combination -h2
      have h_nat : 2 * k = 2^(d-2) + 1 := by
        have := congrArg ZMod.val h_eq
        rwa [ZMod.val_natCast_of_lt (by omega), ZMod.val_natCast_of_lt (by omega)] at this
      omega
    · -- Case 3: k = 3(k + 2^(d-2))
      have hk_cast : ((2 * k + 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        push_cast; linear_combination -h3 - h_2d2_zero
      have h_dvd : 2^(d-1) ∣ 2 * k + 2^(d-2) :=
        (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) _).mp hk_cast
      obtain ⟨c, hc⟩ := h_dvd
      have hc1 : c = 1 := by
        have : 0 < 2 * k + 2^(d-2) := by omega
        have : 2 * k + 2^(d-2) < 2 * 2^(d-1) := by omega
        nlinarith
      have hk : k = 2^(d-3) := by
        rw [hc1, mul_one, h_pow1, h_pow2] at hc; omega
      rw [hu_k, hk]; push_cast; rfl
    · -- Case 4: k = 3(k + 2^(d-2)) - 1
      have hk_cast : ((2 * k + 2^(d-2) - 1 : ℕ) : ZMod (2^(d-1))) = 0 := by
        rw [Nat.cast_sub (by omega)]; push_cast; linear_combination -h4 - h_2d2_zero
      have h_dvd : 2^(d-1) ∣ 2 * k + 2^(d-2) - 1 :=
        (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) _).mp hk_cast
      obtain ⟨c, hc⟩ := h_dvd
      have hc1 : c = 1 := by
        have : 0 < 2 * k + 2^(d-2) - 1 := by omega
        have : 2 * k + 2^(d-2) - 1 < 2 * 2^(d-1) := by omega
        nlinarith
      rw [hc1, mul_one, h_pow1, h_pow2] at hc
      omega
  · rintro rfl
    have h_lt : 2^(d-3) < 2^(d-2) := by
      have : 0 < 2^(d-3) := by positivity
      rw [show d - 2 = d - 3 + 1 by omega, pow_add, pow_one]; omega
    have h_can : canonicalLift (2^(d-3) : ZMod (2^(d-2))) = (2^(d-3) : ZMod (2^(d-1))) := by
      unfold canonicalLift
      rw [show (2^(d-3) : ZMod (2^(d-2))) = ((2^(d-3) : ℕ) : ZMod (2^(d-2))) by push_cast; rfl,
          ZMod.val_natCast_of_lt h_lt]
      push_cast; rfl
    have h_pow : (2^(d-2) : ZMod (2^(d-1))) = 2 * (2^(d-3) : ZMod (2^(d-1))) := by
      rw [show d - 2 = d - 3 + 1 by omega, pow_add, pow_one]; ring
    have h_gen : tau (canonicalLift (2^(d-3) : ZMod (2^(d-2)))) = 3 * canonicalLift (2^(d-3) : ZMod (2^(d-2))) := by
      rw [h_can]
      have : tau (2^(d-3) : ZMod (2^(d-1))) = (2^(d-3) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) := by
        unfold tau; push_cast; rfl
      rw [this, h_pow]; ring
    exact ⟨(tau_neq hd _).symm, Or.inl h_gen⟩

lemma A'_diag_one_eq {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    A'_matrix hd (u, 0) (u, 1) = if u = 2^(d-3) then 1 else 0 := by
  rw [A'_diag_one hd u]
  congr 1
  exact propext (canonicalLift_adj_tau hd u)

theorem sheetDiffMatrix_trace {d : ℕ} (hd : d ≥ 3) :
    Matrix.trace (sheetDiffMatrix hd) = -1 := by
  simp only [Matrix.trace, sheetDiffMatrix, diag]
  simp only [A'_diag_zero hd]
  simp only [zero_sub]
  have h_sum : (∑ i : ZMod (2 ^ (d - 2)), A'_matrix hd (i, 0) (i, 1)) = 1 := by
    simp only [A'_diag_one_eq hd]
    rw [Finset.sum_eq_single (2^(d-3))]
    · simp
    · intro b _ hb
      simp [hb]
    · intro h_not_in
      exfalso
      apply h_not_in
      exact Finset.mem_univ _
  rw [Finset.sum_neg_distrib, h_sum]

end SchreierSpectral
