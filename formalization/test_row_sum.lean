import Formalization.CollatzSpectral
import Formalization.CollatzConnectivity

open Classical
open Matrix
open CollatzSpectral

lemma A'_matrix_val {d : ℕ} (hd : d ≥ 3) (x y : (ZMod (2^(d-2))) × ZMod 2) :
    A'_matrix hd x y = if (G_d d).Adj ((sheetSplit hd).symm x) ((sheetSplit hd).symm y) then (1 : ℚ) else (0 : ℚ) := rfl

lemma sum_A'_matrix_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    ∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) ≤ 4 := by
  have h_sum : ∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) = ∑ v, ∑ b : ZMod 2, A'_matrix hd (u, 0) (v, b) := by
    apply Finset.sum_congr rfl
    intro v _
    have h_zmod2 : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
    have h_not_mem : (0 : ZMod 2) ∉ ({1} : Finset (ZMod 2)) := by decide
    rw [h_zmod2, Finset.sum_insert h_not_mem, Finset.sum_singleton]
  rw [h_sum, ← Finset.sum_product']
  have h_univ_prod : (Finset.univ : Finset (ZMod (2^(d-2)))) ×ˢ (Finset.univ : Finset (ZMod 2)) = Finset.univ := rfl
  rw [h_univ_prod]
  have h_eq : ∑ p : (ZMod (2^(d-2))) × ZMod 2, A'_matrix hd (u, 0) p = ∑ y : ZMod (2^(d-1)), if (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y then (1 : ℚ) else (0 : ℚ) := by
    have h_equiv := Equiv.sum_comp (sheetSplit hd).symm (fun y => if (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y then (1 : ℚ) else (0 : ℚ))
    rw [← h_equiv]
    apply Finset.sum_congr rfl
    intro p _
    rw [A'_matrix_val]
  rw [h_eq]
  have h_filter : ∑ y : ZMod (2^(d-1)), (if (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y then (1 : ℚ) else (0 : ℚ)) = ((Finset.univ.filter (fun y => (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y)).card : ℚ) := by
    rw [Finset.sum_ite]
    simp only [Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul, mul_one]
  rw [h_filter]
  have h_bound := G_d_degree_le hd ((sheetSplit hd).symm (u, 0))
  exact_mod_cast h_bound

lemma realWeightedMatrix_row_sum_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    ∑ v, ‖realWeightedMatrix hd u v‖ ≤ 4 := by
  have h_sum : ∑ v, ‖realWeightedMatrix hd u v‖ = ∑ v, (realWeightedMatrix hd u v) := by
    apply Finset.sum_congr rfl
    intro v _
    unfold realWeightedMatrix
    rw [Matrix.map_apply]
    have h_nonneg : (0 : ℝ) ≤ algebraMap ℚ ℝ (weightedMatrix hd u v) := by
      unfold weightedMatrix
      rw [map_add]
      have h1 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0)) := by
        rw [A'_matrix_val]
        split_ifs
        · norm_num
        · norm_num
      have h2 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1)) := by
        rw [A'_matrix_val]
        split_ifs
        · norm_num
        · norm_num
      exact add_nonneg h1 h2
    exact Real.norm_of_nonneg h_nonneg
  rw [h_sum]
  have h_map : ∑ v, realWeightedMatrix hd u v = algebraMap ℚ ℝ (∑ v, weightedMatrix hd u v) := by
    unfold realWeightedMatrix
    rw [map_sum]
    apply Finset.sum_congr rfl
    intro v _
    rw [Matrix.map_apply]
  rw [h_map]
  have h_sum_q : ∑ v, weightedMatrix hd u v = ∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) := by
    apply Finset.sum_congr rfl
    intro v _
    unfold weightedMatrix
    rfl
  rw [h_sum_q]
  have h_le := sum_A'_matrix_le hd u
  have h_alg : algebraMap ℚ ℝ (∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) = ∑ v : ZMod (2^(d-2)), ((A'_matrix hd (u, 0) (v, 0) : ℝ) + (A'_matrix hd (u, 0) (v, 1) : ℝ)) := by
    rw [map_sum]
    apply Finset.sum_congr rfl
    intro v _
    rw [map_add]
    rfl
  rw [h_alg]
  exact_mod_cast h_le

lemma realSheetDiffMatrix_row_sum_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    ∑ v, ‖realSheetDiffMatrix hd u v‖ ≤ 4 := by
  have h_le : ∀ v, ‖realSheetDiffMatrix hd u v‖ ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) := by
    intro v
    unfold realSheetDiffMatrix sheetDiffMatrix
    rw [Matrix.map_apply, map_sub, map_add]
    have h1 : ‖algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0)) - algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1))‖ ≤ ‖algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0))‖ + ‖algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1))‖ := norm_sub_le _ _
    have hp1 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0)) := by
      rw [A'_matrix_val]
      split_ifs
      · norm_num
      · norm_num
    have hp2 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1)) := by
      rw [A'_matrix_val]
      split_ifs
      · norm_num
      · norm_num
    rw [Real.norm_of_nonneg hp1, Real.norm_of_nonneg hp2] at h1
    exact h1
  have h_sum_le : ∑ v, ‖realSheetDiffMatrix hd u v‖ ≤ ∑ v, algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) := Finset.sum_le_sum (fun v _ => h_le v)
  have h_map : ∑ v, algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) = algebraMap ℚ ℝ (∑ v, (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) := by
    rw [map_sum]
  rw [h_map] at h_sum_le
  have h_le2 := sum_A'_matrix_le hd u
  have h_le3 : algebraMap ℚ ℝ (∑ v, (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) ≤ 4 := by
    have h_alg : algebraMap ℚ ℝ (∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) = ∑ v : ZMod (2^(d-2)), ((A'_matrix hd (u, 0) (v, 0) : ℝ) + (A'_matrix hd (u, 0) (v, 1) : ℝ)) := by
      rw [map_sum]
      apply Finset.sum_congr rfl
      intro v _
      rw [map_add]
      rfl
    rw [h_alg]
    exact_mod_cast h_le2
  exact h_sum_le.trans h_le3
