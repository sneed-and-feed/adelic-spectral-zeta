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
  have h_loopless : ¬ (G_d d).Adj (canonicalLift u) (canonicalLift u) := fun h => (G_d d).irrefl h
  simp [h_loopless]

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
    have hk_eq : k = u.val := rfl
    have hk_lt : k < 2^(d-2) := by rw [hk_eq]; exact ZMod.val_lt u
    have h_can : canonicalLift u = (k : ZMod (2^(d-1))) := by
      unfold canonicalLift
      rw [←hk_eq]
    have h1 : canonicalLift u = (k : ZMod (2^(d-1))) := h_can
    have h2 : tau (k : ZMod (2^(d-1))) = (k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) := by unfold tau; push_cast; rfl
    have h_adj2 : (G_d d).Adj (k : ZMod (2^(d-1))) ((k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) := by
      have h := h_adj
      rw [h1] at h
      rw [←h2]
      exact h
    rcases h_adj2 with ⟨_hne, h_gen⟩
    rcases h_gen with h1 | h2 | h3 | h4
    · -- Case 1: k + 2^(d-2) = 3k  =>  2^(d-2) = 2k
      have h_eq : (2 * (k : ZMod (2^(d-1)))) = (2^(d-2) : ZMod (2^(d-1))) := by
        calc (2 * (k : ZMod (2^(d-1)))) = 3 * (k : ZMod (2^(d-1))) - (k : ZMod (2^(d-1))) := by ring
          _ = ((k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) - (k : ZMod (2^(d-1))) := by rw [←h1]
          _ = (2^(d-2) : ZMod (2^(d-1))) := by ring
      have h_2k_lt : 2 * k < 2^(d-1) := by
        have hd_sub : d - 1 = d - 2 + 1 := by omega
        rw [hd_sub, pow_add, pow_one]
        omega
      have h_d2_lt : 2^(d-2) < 2^(d-1) := by
        have hd_sub : d - 1 = d - 2 + 1 := by omega
        rw [hd_sub, pow_add, pow_one]
        have : 0 < 2^(d-2) := by positivity
        omega
      have hk_val2 : 2 * k = 2^(d-2) := by
        have hk_cast : ((2 * k : ℕ) : ZMod (2^(d-1))) = (2 * (k : ZMod (2^(d-1)))) := by push_cast; rfl
        have hd2_cast : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = (2^(d-2) : ZMod (2^(d-1))) := by push_cast; rfl
        rw [←hk_cast, ←hd2_cast] at h_eq
        have hk_val : ((2 * k : ℕ) : ZMod (2^(d-1))).val = 2 * k := ZMod.val_natCast_of_lt h_2k_lt
        have hd2_val : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := ZMod.val_natCast_of_lt h_d2_lt
        have h_val_eq := congrArg ZMod.val h_eq
        rw [hk_val, hd2_val] at h_val_eq
        exact h_val_eq
      have hk_eq_pow : k = 2^(d-3) := by
        have hd_sub : d - 2 = d - 3 + 1 := by omega
        have h_pow : 2^(d-2) = 2 * 2^(d-3) := by rw [hd_sub, pow_add, pow_one]; ring
        rw [h_pow] at hk_val2
        omega
      have hu_eq : u = (k : ZMod (2^(d-2))) := (ZMod.natCast_zmod_val u).symm
      rw [hu_eq, hk_eq_pow]
      push_cast
      rfl
    · -- Case 2: k + 2^(d-2) = 3k - 1  =>  2k = 2^(d-2) + 1 (parity contradiction!)
      have h_eq : (2 * (k : ZMod (2^(d-1)))) = (2^(d-2) : ZMod (2^(d-1))) + 1 := by
        calc (2 * (k : ZMod (2^(d-1)))) = 3 * (k : ZMod (2^(d-1))) - 1 - (k : ZMod (2^(d-1))) + 1 := by ring
          _ = ((k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) - (k : ZMod (2^(d-1))) + 1 := by rw [←h2]
          _ = (2^(d-2) : ZMod (2^(d-1))) + 1 := by ring
      have h_2k_lt : 2 * k < 2^(d-1) := by
        have hd_sub : d - 1 = d - 2 + 1 := by omega
        rw [hd_sub, pow_add, pow_one]
        omega
      have h_2d2_1_lt : 2^(d-2) + 1 < 2^(d-1) := by
        have hd_sub : d - 1 = d - 2 + 1 := by omega
        have _h_pow : 2^(d-1) = 2 * 2^(d-2) := by rw [hd_sub, pow_add, pow_one]; ring
        have _h_ge : 2^(d-2) ≥ 2 := by have h : 2^1 ≤ 2^(d-2) := Nat.pow_le_pow_right (by decide) (by omega); exact h
        omega
      have hk_val2 : 2 * k = 2^(d-2) + 1 := by
        have hk_cast : ((2 * k : ℕ) : ZMod (2^(d-1))) = (2 * k : ZMod (2^(d-1))) := by push_cast; rfl
        have hd2_cast : ((2^(d-2) + 1 : ℕ) : ZMod (2^(d-1))) = (2^(d-2) + 1 : ZMod (2^(d-1))) := by push_cast; rfl
        rw [←hk_cast, ←hd2_cast] at h_eq
        have hk_val : ((2 * k : ℕ) : ZMod (2^(d-1))).val = 2 * k := ZMod.val_natCast_of_lt h_2k_lt
        have hd2_val : ((2^(d-2) + 1 : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) + 1 := ZMod.val_natCast_of_lt h_2d2_1_lt
        have h_val_eq := congrArg ZMod.val h_eq
        rw [hk_val, hd2_val] at h_val_eq
        exact h_val_eq
      exfalso
      have h_sub : d - 2 = d - 3 + 1 := by omega
      have h_pow : 2^(d-2) = 2 * 2^(d-3) := by rw [h_sub, pow_add, pow_one]; ring
      rw [h_pow] at hk_val2
      omega
    · -- Case 3: k = 3(k + 2^(d-2))  =>  2k + 3·2^(d-2) = 0 mod 2^(d-1)  =>  2k + 2^(d-2) = 0 mod 2^(d-1)
      have h_eq : (2 * (k : ZMod (2^(d-1)))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
        calc (2 * (k : ZMod (2^(d-1)))) + (2^(d-2) : ZMod (2^(d-1)))
          _ = 3 * ((k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) - (k : ZMod (2^(d-1))) - (2 * (2^(d-2) : ZMod (2^(d-1)))) := by ring
          _ = (k : ZMod (2^(d-1))) - (k : ZMod (2^(d-1))) - (2 * (2^(d-2) : ZMod (2^(d-1)))) := by rw [←h3]
          _ = 0 - (2 * (2^(d-2) : ZMod (2^(d-1)))) := by ring
          _ = 0 := by
            have hd_sub : d - 1 = d - 2 + 1 := by omega
            have h_pow : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
              rw [show 2 * 2^(d-2) = 2^(d-1) by rw [hd_sub, pow_add, pow_one]; ring]
              exact ZMod.natCast_self _
            have h_cast : 2 * (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
            rw [h_cast, h_pow]
            ring
      have h_eq_nat : 2 * k + 2^(d-2) = 2^(d-1) := by
        have hk_cast : ((2 * k + 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
          push_cast
          exact h_eq
        have h_dvd : 2^(d-1) ∣ 2 * k + 2^(d-2) := by
          exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2 * k + 2^(d-2))).mp hk_cast
        obtain ⟨c, hc⟩ := h_dvd
        have hc1 : c = 1 := by
          have h_c_pos : c > 0 := by
            by_contra h_c
            have hc0 : c = 0 := by omega
            have hc_copy := hc
            rw [hc0, mul_zero] at hc_copy
            have _h_pos : 0 < 2 * k + 2^(d-2) := by
              have _h_d2 : 0 < 2^(d-2) := by positivity
              omega
            omega
          have h_c_lt : c < 2 := by
            by_contra h_c
            have hc2 : c ≥ 2 := by omega
            have h_ge : 2 * 2^(d-1) ≤ c * 2^(d-1) := Nat.mul_le_mul_right _ hc2
            have h_sum_lt : 2 * k + 2^(d-2) < 2 * 2^(d-1) := by
              have hd_sub : d - 1 = d - 2 + 1 := by omega
              have h_pow : 2^(d-1) = 2 * 2^(d-2) := by rw [hd_sub, pow_add, pow_one]; ring
              omega
            have hc_copy := hc
            have h_comm : 2^(d-1) * c = c * 2^(d-1) := mul_comm _ _
            rw [h_comm] at hc_copy
            omega
          omega
        rw [hc1, mul_one] at hc
        exact hc
      have hk_eq_pow : k = 2^(d-3) := by
        have hd_sub1 : d - 1 = d - 2 + 1 := by omega
        have h_pow1 : 2^(d-1) = 2 * 2^(d-2) := by rw [hd_sub1, pow_add, pow_one]; ring
        have hd_sub2 : d - 2 = d - 3 + 1 := by omega
        have h_pow2 : 2^(d-2) = 2 * 2^(d-3) := by rw [hd_sub2, pow_add, pow_one]; ring
        rw [h_pow1, h_pow2] at h_eq_nat
        omega
      have hu_eq : u = (k : ZMod (2^(d-2))) := (ZMod.natCast_zmod_val u).symm
      rw [hu_eq, hk_eq_pow]
      push_cast
      rfl
    · -- Case 4: k = 3(k + 2^(d-2)) - 1  =>  2k + 2^(d-2) = 1 mod 2^(d-1) (parity contradiction!)
      have h_eq : (2 * (k : ZMod (2^(d-1)))) + (2^(d-2) : ZMod (2^(d-1))) = 1 := by
        calc (2 * (k : ZMod (2^(d-1)))) + (2^(d-2) : ZMod (2^(d-1)))
          _ = 3 * ((k : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) - 1 - (k : ZMod (2^(d-1))) - (2 * (2^(d-2) : ZMod (2^(d-1)))) + 1 := by ring
          _ = (k : ZMod (2^(d-1))) - (k : ZMod (2^(d-1))) - (2 * (2^(d-2) : ZMod (2^(d-1)))) + 1 := by rw [←h4]
          _ = 0 - (2 * (2^(d-2) : ZMod (2^(d-1)))) + 1 := by ring
          _ = 1 := by
            have hd_sub : d - 1 = d - 2 + 1 := by omega
            have h_pow : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
              rw [show 2 * 2^(d-2) = 2^(d-1) by rw [hd_sub, pow_add, pow_one]; ring]
              exact ZMod.natCast_self _
            have h_cast : 2 * (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
            rw [h_cast, h_pow]
            ring
      have h_eq_nat : 2 * k + 2^(d-2) - 1 = 2^(d-1) := by
        have hk_cast : ((2 * k + 2^(d-2) - 1 : ℕ) : ZMod (2^(d-1))) = 0 := by
          have hd_ge : 2^(d-2) ≥ 2 := by have h : 2^1 ≤ 2^(d-2) := Nat.pow_le_pow_right (by decide) (by omega); exact h
          have h_sub_nat : 2 * k + 2^(d-2) - 1 + 1 = 2 * k + 2^(d-2) := by omega
          have h_cast_sub : (((2 * k + 2^(d-2) - 1 : ℕ) : ZMod (2^(d-1))) + 1) = ((2 * k + 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by
            calc (((2 * k + 2^(d-2) - 1 : ℕ) : ZMod (2^(d-1))) + 1)
              _ = (((2 * k + 2^(d-2) - 1 + 1 : ℕ) : ZMod (2^(d-1)))) := by push_cast; rfl
              _ = ((2 * k + 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by rw [h_sub_nat]
          have h_eq2 : (((2 * k + 2^(d-2) : ℕ) : ZMod (2^(d-1)))) = 1 := by
            push_cast; exact h_eq
          rw [h_eq2] at h_cast_sub
          calc ((2 * k + 2^(d-2) - 1 : ℕ) : ZMod (2^(d-1)))
            _ = ((2 * k + 2^(d-2) - 1 : ℕ) : ZMod (2^(d-1))) + 1 - 1 := by ring
            _ = 1 - 1 := by rw [h_cast_sub]
            _ = 0 := by ring
        have h_dvd : 2^(d-1) ∣ 2 * k + 2^(d-2) - 1 := by
          exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) _).mp hk_cast
        obtain ⟨c, hc⟩ := h_dvd
        have hc1 : c = 1 := by
          have h_c_pos : c > 0 := by
            by_contra h_c
            have hc0 : c = 0 := by omega
            have hc_copy := hc
            rw [hc0, mul_zero] at hc_copy
            have _h_pos2 : 0 < 2 * k + 2^(d-2) - 1 := by
              have hd_ge : 2^1 ≤ 2^(d-2) := Nat.pow_le_pow_right (by decide) (by omega)
              omega
            omega
          have h_c_lt : c < 2 := by
            by_contra h_c
            have hc2 : c ≥ 2 := by omega
            have h_ge : 2 * 2^(d-1) ≤ c * 2^(d-1) := Nat.mul_le_mul_right _ hc2
            have h_sum_lt : 2 * k + 2^(d-2) < 2 * 2^(d-1) := by
              have hd_sub : d - 1 = d - 2 + 1 := by omega
              have h_pow : 2^(d-1) = 2 * 2^(d-2) := by rw [hd_sub, pow_add, pow_one]; ring
              omega
            have hc_copy := hc
            have h_comm : 2^(d-1) * c = c * 2^(d-1) := mul_comm _ _
            rw [h_comm] at hc_copy
            omega
          omega
        rw [hc1, mul_one] at hc
        exact hc
      exfalso
      have hd_sub1 : d - 1 = d - 2 + 1 := by omega
      have h_pow1 : 2^(d-1) = 2 * 2^(d-2) := by rw [hd_sub1, pow_add, pow_one]; ring
      have hd_sub2 : d - 2 = d - 3 + 1 := by omega
      have h_pow2 : 2^(d-2) = 2 * 2^(d-3) := by rw [hd_sub2, pow_add, pow_one]; ring
      rw [h_pow1, h_pow2] at h_eq_nat
      omega
  · intro h_eq
    subst h_eq
    have h_lt : 2^(d-3) < 2^(d-2) := by
      have hd_sub : d - 2 = d - 3 + 1 := by omega
      have _h_pow : 2^(d-2) = 2 * 2^(d-3) := by rw [hd_sub, pow_add, pow_one]; ring
      have _h_pos : 0 < 2^(d-3) := by positivity
      omega
    have h_can : canonicalLift (2^(d-3) : ZMod (2^(d-2))) = (2^(d-3) : ZMod (2^(d-1))) := by
      unfold canonicalLift
      have h_val_eq : ((2^(d-3) : ℕ) : ZMod (2^(d-2))).val = 2^(d-3) := ZMod.val_natCast_of_lt h_lt
      have h_cast : (2^(d-3) : ZMod (2^(d-2))) = ((2^(d-3) : ℕ) : ZMod (2^(d-2))) := by push_cast; rfl
      rw [h_cast, h_val_eq]
      push_cast
      rfl
    have h_tau : tau (2^(d-3) : ZMod (2^(d-1))) = (2^(d-3) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) := by
      unfold tau
      push_cast
      rfl
    rw [h_can, h_tau]
    have h_ne : (2^(d-3) : ZMod (2^(d-1))) ≠ (2^(d-3) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) := by
      intro h
      have h_sub : (2^(d-3) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) - (2^(d-3) : ZMod (2^(d-1))) = (2^(d-2) : ZMod (2^(d-1))) := by ring
      have h_zero : (2^(d-3) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) - (2^(d-3) : ZMod (2^(d-1))) = 0 := by rw [←h, sub_self]
      rw [h_zero] at h_sub
      have h3 : 2^(d-1) ∣ 2^(d-2) := by
        have h_cast : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by push_cast; exact h_sub.symm
        exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2^(d-2))).mp h_cast
      have h4 : 2^(d-1) ≤ 2^(d-2) := Nat.le_of_dvd (by positivity) h3
      have h5 : d - 2 < d - 1 := by omega
      have h6 : 2^(d-2) < 2^(d-1) := by
        have hd_sub : d - 1 = d - 2 + 1 := by omega
        have _h_pow : 2^(d-1) = 2 * 2^(d-2) := by rw [hd_sub, pow_add, pow_one]; ring
        have _h_pos : 0 < 2^(d-2) := by positivity
        omega
      linarith
    have h_eq_three : (2^(d-3) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 3 * (2^(d-3) : ZMod (2^(d-1))) := by
      have h_pow : (2^(d-2) : ZMod (2^(d-1))) = 2 * (2^(d-3) : ZMod (2^(d-1))) := by
        push_cast
        have h_sub : d - 2 = d - 3 + 1 := by omega
        rw [h_sub, pow_add, pow_one]
        ring
      rw [h_pow]
      ring
    refine ⟨h_ne, Or.inl h_eq_three⟩

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
