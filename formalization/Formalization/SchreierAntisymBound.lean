import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Data.Real.Basic
import Formalization.SchreierSpectral
import Formalization.SchreierPerronFrobenius

open Matrix
open Classical

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

def tau_op (v : ZMod (2^(d-1)) → ℝ) : ZMod (2^(d-1)) → ℝ :=
  fun x => v (tau x)

lemma tau_op_tau_op (v : ZMod (2^(d-1)) → ℝ) : tau_op (tau_op v) = v := by
  ext x
  dsimp [tau_op]
  rw [tau_tau hd]

lemma tau_op_commutes (v : ZMod (2^(d-1)) → ℝ) :
    (@realAdjacencyMatrix d).mulVec (tau_op v) = tau_op ((@realAdjacencyMatrix d).mulVec v) := by
  ext i
  dsimp [tau_op, mulVec, dotProduct]
  let e : ZMod (2^(d-1)) ≃ ZMod (2^(d-1)) := {
    toFun := tau
    invFun := tau
    left_inv := tau_tau hd
    right_inv := tau_tau hd
  }
  have h_sum : ∑ j : ZMod (2^(d-1)), (@realAdjacencyMatrix d) i j * v (tau j) =
               ∑ j : ZMod (2^(d-1)), (@realAdjacencyMatrix d) i (e j) * v (tau (e j)) := by
    exact (Equiv.sum_comp e (fun x => (@realAdjacencyMatrix d) i x * v (tau x))).symm
  rw [h_sum]
  apply Finset.sum_congr rfl
  intro j _
  have h2 : v (tau (tau j)) = v j := by rw [tau_tau hd]
  -- e j is just tau j, and tau (e j) is tau (tau j)
  -- so v (tau (e j)) simplifies to v j
  -- wait, e is just tau, so `(@realAdjacencyMatrix d) i (e j)` is `(@realAdjacencyMatrix d) i (tau j)`
  -- BUT `Equiv.sum_comp` already rewrote the sum index!
  -- Let's just simplify the `e j` stuff.
  change (@realAdjacencyMatrix d) i (tau j) * v (tau (tau j)) = (@realAdjacencyMatrix d) (tau i) j * v j
  rw [h2]
  have h3 : (@realAdjacencyMatrix d) i (tau j) = (@realAdjacencyMatrix d) (tau i) j := by
    dsimp [realAdjacencyMatrix, adjacencyMatrix, Matrix.map_apply]
    apply congrArg
    have h_adj : (G_d d).Adj i (tau j) ↔ (G_d d).Adj (tau i) j := (tau_adj_bicond hd i j).symm
    simp only [propext h_adj]
  rw [h3]

lemma pf_eigenvector_symmetric :
    let hA := @realAdjacencyMatrix_isHermitian d
    let i_max := Classical.choose (isPerronFrobeniusMax_realAdjacencyMatrix hd)
    tau_op (hA.eigenvectorBasis i_max) = hA.eigenvectorBasis i_max := by
  intro hA i_max
  have h_pf := isPerronFrobeniusMax_realAdjacencyMatrix hd
  have h_imax_def : i_max = Classical.choose h_pf := rfl
  have h_pf_spec := Classical.choose_spec h_pf
  let A := @realAdjacencyMatrix d
  let eig := hA.eigenvalues
  let evec := hA.eigenvectorBasis
  let s := Finset.image eig Finset.univ
  have hs_nonempty : s.Nonempty := ⟨eig 0, Finset.mem_image_of_mem eig (Finset.mem_univ 0)⟩
  let max_eig := Finset.max' s hs_nonempty
  let v_0 := evec i_max
  
  have hi_max_val : eig i_max = max_eig := by
    have h_bound : ∀ j, eig j ≤ eig i_max := fun j => (h_pf_spec j).1
    apply le_antisymm
    · exact Finset.le_max' s (eig i_max) (Finset.mem_image_of_mem eig (Finset.mem_univ i_max))
    · have h_mem := Finset.max'_mem s hs_nonempty
      have ⟨j, _, hj⟩ := Finset.mem_image.mp h_mem
      have hj_symm : max_eig = eig j := hj.symm
      rw [hj_symm]
      exact h_bound j

  have h_w_eig : A.mulVec (tau_op v_0) = max_eig • (tau_op v_0) := by
    have h1 := tau_op_commutes hd v_0
    rw [h1]
    have h2 : A.mulVec v_0 = hA.eigenvalues i_max • v_0 := hA.mulVec_eigenvectorBasis i_max
    have heig_eq : hA.eigenvalues i_max = max_eig := hi_max_val
    rw [heig_eq] at h2
    rw [h2]
    rfl
    
  let b := evec.toBasis
  have h_w_prop : tau_op v_0 = (b.repr (tau_op v_0) i_max) • v_0 := by
    let w := tau_op v_0
    have hw_sum : w = ∑ j, b.repr w j • evec j := (b.sum_repr w).symm
    have h_repr_eq : ∀ j, max_eig * b.repr w j = eig j * b.repr w j := by
      intro j
      have h1 : b.repr (max_eig • w) j = max_eig * b.repr w j := by
        rw [LinearEquiv.map_smul, Finsupp.smul_apply, smul_eq_mul]
      have h_Aw_eq : A.mulVec w = ∑ k, (b.repr w k) • (eig k • evec k) := by
        calc A.mulVec w = Matrix.toLin' A w := rfl
             _ = Matrix.toLin' A (∑ k, b.repr w k • evec k) := by nth_rw 1 [hw_sum]
             _ = ∑ k, Matrix.toLin' A (b.repr w k • evec k) := by exact map_sum (Matrix.toLin' A) _ _
             _ = ∑ k, (b.repr w k) • A.mulVec (evec k) := by
               apply Finset.sum_congr rfl
               intro k _
               exact LinearMap.map_smul (Matrix.toLin' A) (b.repr w k) (evec k)
             _ = ∑ k, (b.repr w k) • (eig k • evec k) := by
               apply Finset.sum_congr rfl
               intro k _
               have hk : A.mulVec (evec k) = eig k • evec k := hA.mulVec_eigenvectorBasis k
               rw [hk]
      have h2 : b.repr (A.mulVec w) j = eig j * b.repr w j := by
        rw [h_Aw_eq]
        rw [map_sum b.repr]
        simp only [Finsupp.coe_finset_sum, Finset.sum_apply]
        have h_sum_eq : (∑ k, (b.repr ((b.repr w k) • (eig k • evec k))) j) = eig j * b.repr w j := by
          have h_term : ∀ k, (b.repr ((b.repr w k) • (eig k • evec k))) j = b.repr w k * eig k * b.repr (evec k) j := by
            intro k
            rw [LinearEquiv.map_smul, LinearEquiv.map_smul]
            simp only [Finsupp.smul_apply, smul_eq_mul, b]
            ring
          have h_term2 : ∀ k, b.repr (evec k) j = if k = j then 1 else 0 := by
            intro k
            have h_repr_k : b.repr (evec k) = Finsupp.single k 1 := b.repr_self k
            rw [h_repr_k, Finsupp.single_apply]
          have h_sum_single : (∑ k, (b.repr ((b.repr w k) • (eig k • evec k))) j) = (b.repr ((b.repr w j) • (eig j • evec j))) j := by
            apply Finset.sum_eq_single_of_mem j (Finset.mem_univ j)
            intro k _ hk_neq
            rw [h_term k, h_term2 k, if_neg hk_neq]; ring
          rw [h_sum_single, h_term j, h_term2 j, if_pos rfl]; ring
        exact h_sum_eq
      have h1_Aw : b.repr (A.mulVec w) j = max_eig * b.repr w j := by
        have heq_w : A.mulVec w = max_eig • w := h_w_eig
        rw [heq_w]
        rw [LinearEquiv.map_smul, Finsupp.smul_apply, smul_eq_mul]
      rw [h1_Aw] at h2
      exact h2
    
    have hw_zero : ∀ j, j ≠ i_max → b.repr w j = 0 := by
      intro j hj
      have h_eq := h_repr_eq j
      have heig_neq : eig j ≠ max_eig := by
        intro heq
        have heq' : eig j = eig i_max := by
          rw [hi_max_val]
          exact heq
        have h_im := (h_pf_spec j).2.1 heq'
        exact hj h_im
      have heq2 : (max_eig - eig j) * b.repr w j = 0 := by
        linarith
      have heq3 : max_eig - eig j ≠ 0 := sub_ne_zero_of_ne (Ne.symm heig_neq)
      exact mul_eq_zero.mp heq2 |>.resolve_left heq3
      
    have h_w_simpl : w = (b.repr w i_max) • evec i_max := by
      calc w = ∑ j, b.repr w j • evec j := hw_sum
           _ = b.repr w i_max • evec i_max := by
             apply Finset.sum_eq_single_of_mem i_max (Finset.mem_univ i_max)
             intro j _ hj
             rw [hw_zero j hj, zero_smul]
    exact h_w_simpl
    
  let c := b.repr (tau_op v_0) i_max
  have h_w : tau_op v_0 = c • v_0 := h_w_prop
  have h_v0_pos : (∀ x, 0 < v_0 x) ∨ (∀ x, v_0 x < 0) := (h_pf_spec i_max).2.2
  have h_v0_0_ne : v_0 0 ≠ 0 := by
    cases h_v0_pos with
    | inl h_pos => exact ne_of_gt (h_pos 0)
    | inr h_neg => exact ne_of_lt (h_neg 0)
    
  have h_c_sq : c * c = 1 := by
    have h1 : tau_op (tau_op v_0) = v_0 := tau_op_tau_op hd v_0
    have h2 : tau_op (tau_op v_0) = tau_op (c • v_0) := by rw [h_w]
    have h3 : tau_op (c • v_0) = c • (tau_op v_0) := rfl
    have h4 : c • tau_op v_0 = c • (c • v_0) := by rw [h_w]
    have h5 : c • (c • v_0) = (c * c) • v_0 := smul_smul c c v_0
    rw [h1] at h2
    rw [h3, h4, h5] at h2
    have h_eval : v_0 0 = (c * c) * v_0 0 := by
      calc v_0 0 = ((c * c) • v_0) 0 := by rw [←h2]
           _ = (c * c) * v_0 0 := rfl
    have h_eval2 : v_0 0 * 1 = v_0 0 * (c * c) := by linarith
    have h_eval3 : 1 = c * c := mul_left_cancel₀ h_v0_0_ne h_eval2
    exact h_eval3.symm
    
  have h_c_cases : c = 1 ∨ c = -1 := by
    have h_sq : c ^ 2 = 1 := by
      calc c ^ 2 = c * c := sq c
           _ = 1 := h_c_sq
    exact sq_eq_one_iff.mp h_sq
  
  cases h_c_cases with
  | inl h_c1 =>
    rw [h_c1, one_smul] at h_w
    exact h_w
  | inr h_c_neg1 =>
    exfalso
    have h_w_neg : tau_op v_0 = -v_0 := by
      rw [h_c_neg1] at h_w
      have h_neg : (-1 : ℝ) • v_0 = -v_0 := neg_one_smul ℝ v_0
      rw [h_neg] at h_w
      exact h_w
    have h_eval : (tau_op v_0) 0 = (-v_0) 0 := by rw [h_w_neg]
    have h_tau_0 : (tau_op v_0) 0 = v_0 (tau 0) := rfl
    have h_neg_0 : (-v_0) 0 = - (v_0 0) := rfl
    rw [h_tau_0, h_neg_0] at h_eval
    
    cases h_v0_pos with
    | inl h_pos =>
      have h_left : 0 < v_0 (tau 0) := h_pos (tau 0)
      have h_right : - (v_0 0) < 0 := neg_neg_of_pos (h_pos 0)
      linarith
    | inr h_neg =>
      have h_left : v_0 (tau 0) < 0 := h_neg (tau 0)
      have h_right : 0 < - (v_0 0) := neg_pos_of_neg (h_neg 0)
      linarith
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
noncomputable def real_A'_matrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℝ :=
  Matrix.reindex (sheetSplit hd) (sheetSplit hd) (@realAdjacencyMatrix d)

lemma real_A'_matrix_eq (u v : ZMod (2^(d-2)) × ZMod 2) :
    real_A'_matrix hd u v = (A'_matrix hd u v : ℝ) := by
  dsimp [real_A'_matrix, A'_matrix, realAdjacencyMatrix, adjacencyMatrix, Matrix.reindex_apply, Matrix.submatrix_apply, Matrix.map_apply]
  rfl

lemma real_A'_tau_sym_01_10 (u : ZMod (2^(d-2))) (v : ZMod (2^(d-2))) :
    real_A'_matrix hd (u, 1) (v, 0) = real_A'_matrix hd (u, 0) (v, 1) := by
  rw [real_A'_matrix_eq, real_A'_matrix_eq, A'_tau_sym_01_10 hd u v]

lemma real_A'_tau_sym_11_00 (u : ZMod (2^(d-2))) (v : ZMod (2^(d-2))) :
    real_A'_matrix hd (u, 1) (v, 1) = real_A'_matrix hd (u, 0) (v, 0) := by
  rw [real_A'_matrix_eq, real_A'_matrix_eq, A'_tau_sym_11_00 hd u v]

def antisym_ext_r (w : ZMod (2^(d-2)) → ℝ) : (ZMod (2^(d-2)) × ZMod 2) → ℝ :=
  fun p => if p.2 = 0 then w p.1 else - w p.1

lemma antisym_lift_eq_ext_comp_r (w : ZMod (2^(d-2)) → ℝ) (x : ZMod (2^(d-1))) :
    antisym_lift w x = antisym_ext_r w (sheetSplit hd x) := by
  change (if x.val < 2^(d-2) then w (pi x) else -w (pi x)) = if (if x.val < 2^(d-2) then (0 : ZMod 2) else 1) = 0 then w (pi x) else -w (pi x)
  by_cases h : x.val < 2^(d-2)
  · rw [if_pos h]
    have h_if : (if x.val < 2 ^ (d - 2) then (0 : ZMod 2) else 1) = 0 := if_pos h
    rw [h_if, if_pos rfl]
  · rw [if_neg h]
    have h_if : (if x.val < 2 ^ (d - 2) then (0 : ZMod 2) else 1) = 1 := if_neg h
    rw [h_if]
    have h_ne : ¬ (1 : ZMod 2) = 0 := by decide
    rw [if_neg h_ne]

lemma real_A'_matrix_mul_antisym_ext (w : ZMod (2^(d-2)) → ℝ) (u : ZMod (2^(d-2))) (b : ZMod 2) :
    Matrix.mulVec (real_A'_matrix hd) (antisym_ext_r w) (u, b) = antisym_ext_r (Matrix.mulVec (realSheetDiffMatrix hd) w) (u, b) := by
  dsimp [Matrix.mulVec, Matrix.dotProduct, antisym_ext_r]
  have h_sum : ∑ j : ZMod (2^(d-2)) × ZMod 2, real_A'_matrix hd (u, b) j * (if j.snd = 0 then w j.fst else -w j.fst) =
               ∑ v : ZMod (2^(d-2)), ∑ c : ZMod 2, real_A'_matrix hd (u, b) (v, c) * (if c = 0 then w v else -w v) := by
    exact Fintype.sum_prod_type
  rw [h_sum]
  have h_inner : ∀ v, ∑ c : ZMod 2, real_A'_matrix hd (u, b) (v, c) * (if c = 0 then w v else -w v) =
                 real_A'_matrix hd (u, b) (v, 0) * w v - real_A'_matrix hd (u, b) (v, 1) * w v := by
    intro v
    have h_univ : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
    rw [h_univ, Finset.sum_insert, Finset.sum_singleton]
    · simp only [if_true, eq_self_iff_true, if_false, one_ne_zero, neg_eq_zero]
      ring
    · decide
  simp only [h_inner]
  by_cases hb : b = 0
  · rw [if_pos hb, hb]
    dsimp [realSheetDiffMatrix, sheetDiffMatrix]
    have h_eq : ∑ v : ZMod (2 ^ (d - 2)), (real_A'_matrix hd (u, 0) (v, 0) * w v - real_A'_matrix hd (u, 0) (v, 1) * w v) =
                 ∑ v : ZMod (2 ^ (d - 2)), (real_A'_matrix hd (u, 0) (v, 0) - real_A'_matrix hd (u, 0) (v, 1)) * w v := by
      apply Finset.sum_congr rfl
      intro v _
      ring
    rw [h_eq]
    apply Finset.sum_congr rfl
    intro v _
    have h_map : (algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) - A'_matrix hd (u, 0) (v, 1))) =
                 (A'_matrix hd (u, 0) (v, 0) : ℝ) - (A'_matrix hd (u, 0) (v, 1) : ℝ) := by
      exact RingHom.map_sub (algebraMap ℚ ℝ) _ _
    rw [h_map, ← real_A'_matrix_eq, ← real_A'_matrix_eq]
  · have hb1 : b = 1 := by
      have h_cases : b = 0 ∨ b = 1 := by
        have h_univ : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
        have h_mem := Finset.mem_univ b
        rw [h_univ] at h_mem
        simp only [Finset.mem_insert, Finset.mem_singleton] at h_mem
        exact h_mem
      exact h_cases.resolve_left hb
    rw [if_neg hb, hb1]
    have h1 : ∀ v, real_A'_matrix hd (u, 1) (v, 0) = real_A'_matrix hd (u, 0) (v, 1) := real_A'_tau_sym_01_10 hd u
    have h2 : ∀ v, real_A'_matrix hd (u, 1) (v, 1) = real_A'_matrix hd (u, 0) (v, 0) := real_A'_tau_sym_11_00 hd u
    have h_eq : ∑ v : ZMod (2 ^ (d - 2)), (real_A'_matrix hd (u, 1) (v, 0) * w v - real_A'_matrix hd (u, 1) (v, 1) * w v) =
                 - ∑ v : ZMod (2 ^ (d - 2)), (real_A'_matrix hd (u, 0) (v, 0) - real_A'_matrix hd (u, 0) (v, 1)) * w v := by
      rw [← Finset.sum_neg_distrib]
      apply Finset.sum_congr rfl
      intro v _
      rw [h1 v, h2 v]
      ring
    rw [h_eq]
    have h_sum_map : ∑ v : ZMod (2 ^ (d - 2)), (real_A'_matrix hd (u, 0) (v, 0) - real_A'_matrix hd (u, 0) (v, 1)) * w v =
                     ∑ v : ZMod (2 ^ (d - 2)), (algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) - A'_matrix hd (u, 0) (v, 1))) * w v := by
      apply Finset.sum_congr rfl
      intro v _
      have h_map : (algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) - A'_matrix hd (u, 0) (v, 1))) =
                   (A'_matrix hd (u, 0) (v, 0) : ℝ) - (A'_matrix hd (u, 0) (v, 1) : ℝ) := by
        exact RingHom.map_sub (algebraMap ℚ ℝ) _ _
      rw [h_map, ← real_A'_matrix_eq, ← real_A'_matrix_eq]
    rw [h_sum_map]
    rfl

lemma realAdjacencyMatrix_mul_antisym_lift (w : ZMod (2^(d-2)) → ℝ) (x : ZMod (2^(d-1))) :
    Matrix.mulVec (@realAdjacencyMatrix d) (antisym_lift w) x =
    antisym_lift (Matrix.mulVec (realSheetDiffMatrix hd) w) x := by
  have h2 : antisym_lift (Matrix.mulVec (realSheetDiffMatrix hd) w) x = antisym_ext_r (Matrix.mulVec (realSheetDiffMatrix hd) w) (sheetSplit hd x) :=
    antisym_lift_eq_ext_comp_r hd (Matrix.mulVec (realSheetDiffMatrix hd) w) x
  rw [h2]
  dsimp [Matrix.mulVec, Matrix.dotProduct]
  have h_sum : ∑ j : ZMod (2^(d-1)), @realAdjacencyMatrix d x j * antisym_lift w j =
               ∑ j : ZMod (2^(d-1)), @realAdjacencyMatrix d x j * antisym_ext_r w (sheetSplit hd j) := by
    apply Finset.sum_congr rfl
    intro j _
    rw [antisym_lift_eq_ext_comp_r hd w j]
  rw [h_sum]
  have h_sum2 : ∑ j : ZMod (2^(d-1)), @realAdjacencyMatrix d x j * antisym_ext_r w (sheetSplit hd j) =
                ∑ j : ZMod (2^(d-2)) × ZMod 2, @realAdjacencyMatrix d x ((sheetSplit hd).symm j) * antisym_ext_r w j := by
    have heq := Equiv.sum_comp (sheetSplit hd).symm (fun j => @realAdjacencyMatrix d x j * antisym_ext_r w (sheetSplit hd j))
    rw [← heq]
    apply Finset.sum_congr rfl
    intro j _
    rw [Equiv.apply_symm_apply]
  rw [h_sum2]
  have h_A_matrix : ∀ j, @realAdjacencyMatrix d x ((sheetSplit hd).symm j) = real_A'_matrix hd (sheetSplit hd x) j := by
    intro j
    have hh : real_A'_matrix hd = Matrix.reindex (sheetSplit hd) (sheetSplit hd) (@realAdjacencyMatrix d) := rfl
    have h_eq : @realAdjacencyMatrix d = Matrix.reindex (sheetSplit hd).symm (sheetSplit hd).symm (real_A'_matrix hd) := by
      rw [hh]
      simp [Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_symm]
    rw [h_eq]
    simp only [Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_symm, Equiv.symm_apply_apply]
    rw [Equiv.apply_symm_apply]
  have h_sum3 : ∑ j : ZMod (2 ^ (d - 2)) × ZMod 2, @realAdjacencyMatrix d x ((sheetSplit hd).symm j) * antisym_ext_r w j =
                ∑ j : ZMod (2 ^ (d - 2)) × ZMod 2, real_A'_matrix hd (sheetSplit hd x) j * antisym_ext_r w j := by
    apply Finset.sum_congr rfl
    intro j _
    rw [h_A_matrix j]
  rw [h_sum3]
  have h3 : ∑ j : ZMod (2 ^ (d - 2)) × ZMod 2, real_A'_matrix hd (sheetSplit hd x) j * antisym_ext_r w j =
            Matrix.mulVec (real_A'_matrix hd) (antisym_ext_r w) (sheetSplit hd x) := rfl
  rw [h3]
  rcases sheetSplit hd x with ⟨u, b⟩
  exact real_A'_matrix_mul_antisym_ext hd w u b

lemma antisym_eigenvalues_strictly_below_top (v : ZMod (2^(d-1)) → ℝ) (μ : ℝ)
    (hv_ne : v ≠ 0)
    (h_eig : Matrix.mulVec (@realAdjacencyMatrix d) v = μ • v)
    (h_antisym : tau_op v = -v) :
    μ < (@realAdjacencyMatrix_isHermitian d).eigenvalues (Classical.choose (isPerronFrobeniusMax_realAdjacencyMatrix hd)) := by
  let A := @realAdjacencyMatrix d
  let hA := @realAdjacencyMatrix_isHermitian d
  let h_pf := isPerronFrobeniusMax_realAdjacencyMatrix hd
  let i_max := Classical.choose h_pf
  let h_pf_spec := Classical.choose_spec h_pf
  let max_eig := hA.eigenvalues i_max
  
  let evec := hA.eigenvectorBasis
  let b := evec.toBasis
  let eig := hA.eigenvalues

  have h_repr_eq : ∀ j, b.repr v j * eig j = μ * b.repr v j := by
    intro j
    have hw_sum : v = ∑ k, b.repr v k • evec k := (b.sum_repr v).symm
    have h2 : b.repr (A.mulVec v) j = b.repr v j * eig j := by
      have h_Aw_eq : A.mulVec v = ∑ k, (b.repr v k) • (eig k • evec k) := by
        calc A.mulVec v = Matrix.toLin' A v := rfl
             _ = Matrix.toLin' A (∑ k, b.repr v k • evec k) := by nth_rw 1 [hw_sum]
             _ = ∑ k, Matrix.toLin' A (b.repr v k • evec k) := by exact map_sum (Matrix.toLin' A) _ _
             _ = ∑ k, (b.repr v k) • A.mulVec (evec k) := by
               apply Finset.sum_congr rfl
               intro k _
               exact LinearMap.map_smul (Matrix.toLin' A) (b.repr v k) (evec k)
             _ = ∑ k, (b.repr v k) • (eig k • evec k) := by
               apply Finset.sum_congr rfl
               intro k _
               have hevec : A.mulVec (evec k) = eig k • evec k := hA.mulVec_eigenvectorBasis k
               rw [hevec]
      have h_sum_eq : b.repr (∑ k, (b.repr v k) • (eig k • evec k)) j = b.repr v j * eig j := by
        rw [map_sum b.repr]
        simp only [Finsupp.coe_finset_sum, Finset.sum_apply]
        have h_term : ∀ k, (b.repr ((b.repr v k) • (eig k • evec k))) j = b.repr v k * eig k * b.repr (evec k) j := by
          intro k
          rw [LinearEquiv.map_smul, LinearEquiv.map_smul]
          simp only [Finsupp.smul_apply, smul_eq_mul, b]
          ring
        have h_term2 : ∀ k, b.repr (evec k) j = if k = j then 1 else 0 := by
          intro k
          have h_repr_k : b.repr (evec k) = Finsupp.single k 1 := b.repr_self k
          rw [h_repr_k, Finsupp.single_apply]
        have h_sum_single : (∑ k, (b.repr ((b.repr v k) • (eig k • evec k))) j) = (b.repr ((b.repr v j) • (eig j • evec j))) j := by
          apply Finset.sum_eq_single_of_mem j (Finset.mem_univ j)
          intro k _ hk_neq
          rw [h_term k, h_term2 k, if_neg hk_neq]; ring
        rw [h_sum_single, h_term j, h_term2 j, if_pos rfl]; ring
      rw [h_Aw_eq]
      exact h_sum_eq
    have h1_Aw : b.repr (A.mulVec v) j = μ * b.repr v j := by
      have heq_w : A.mulVec v = μ • v := h_eig
      rw [heq_w]
      rw [LinearEquiv.map_smul, Finsupp.smul_apply, smul_eq_mul]
    rw [h1_Aw] at h2
    exact h2.symm

  have h_le : μ ≤ max_eig := by
    have h_repr_ne_zero : ∃ j, b.repr v j ≠ 0 := by
      by_contra h_all_zero
      push_neg at h_all_zero
      have h_v_zero : v = 0 := by
        have hw_sum : v = ∑ k, b.repr v k • evec k := (b.sum_repr v).symm
        calc v = ∑ k, b.repr v k • evec k := hw_sum
             _ = 0 := by
               apply Finset.sum_eq_zero
               intro k _
               rw [h_all_zero k, zero_smul]
      exact hv_ne h_v_zero
    rcases h_repr_ne_zero with ⟨j, hj⟩
    have h_eig_eq := h_repr_eq j
    have heq : eig j = μ := by
      have h_eig_eq2 : b.repr v j * eig j = b.repr v j * μ := by
        calc b.repr v j * eig j = μ * b.repr v j := h_eig_eq
             _ = b.repr v j * μ := mul_comm _ _
      exact mul_left_cancel₀ hj h_eig_eq2
    rw [← heq]
    exact (h_pf_spec j).1

  by_cases h_eq : μ = max_eig
  · exfalso
    have hw_zero : ∀ j, j ≠ i_max → b.repr v j = 0 := by
      intro j hj
      have h_eq_j := h_repr_eq j
      have heig_neq : eig j ≠ max_eig := by
        intro heq_eig
        have h_im := (h_pf_spec j).2.1 heq_eig
        exact hj h_im
      by_contra h_repr_ne
      have h_eq2 : eig j = μ := by
        have h_eq_j2 : b.repr v j * eig j = b.repr v j * μ := by
          calc b.repr v j * eig j = μ * b.repr v j := h_eq_j
               _ = b.repr v j * μ := mul_comm _ _
        exact mul_left_cancel₀ h_repr_ne h_eq_j2
      rw [h_eq] at h_eq2
      exact heig_neq h_eq2
    
    have h_v_prop : v = (b.repr v i_max) • evec i_max := by
      calc v = ∑ k, b.repr v k • evec k := (b.sum_repr v).symm
           _ = (b.repr v i_max) • evec i_max := by
             apply Finset.sum_eq_single_of_mem i_max (Finset.mem_univ i_max)
             intro k _ hk
             rw [hw_zero k hk, zero_smul]

    have h_tau_v0 : tau_op (evec i_max) = evec i_max := pf_eigenvector_symmetric hd
    have h_tau_v : tau_op v = v := by
      ext x
      have h1 : v (tau x) = (b.repr v i_max • evec i_max) (tau x) := congr_fun h_v_prop (tau x)
      have h2 : v x = (b.repr v i_max • evec i_max) x := congr_fun h_v_prop x
      change v (tau x) = v x
      rw [h1, h2]
      have h_tau_v0_x : evec i_max (tau x) = evec i_max x := congr_fun h_tau_v0 x
      calc (b.repr v i_max • evec i_max) (tau x) = b.repr v i_max * evec i_max (tau x) := rfl
           _ = b.repr v i_max * evec i_max x := by rw [h_tau_v0_x]
           _ = (b.repr v i_max • evec i_max) x := rfl
    have h_tau_v_eq : tau_op v = v := h_tau_v
    rw [h_antisym] at h_tau_v_eq
    have h_2v : (2:ℝ) • v = 0 := by
      calc (2:ℝ) • v = v + v := by rw [two_smul]
           _ = -v + v := by nth_rw 1 [← h_tau_v_eq]
           _ = 0 := add_left_neg v
    have h_v_zero : v = 0 := by
      exact smul_eq_zero.mp h_2v |>.resolve_left (by norm_num)
    exact hv_ne h_v_zero
  · exact lt_of_le_of_ne h_le h_eq

lemma antisym_block_bound : 
    ∀ i : ZMod (2^(d-2)), (@realSheetDiffMatrix_isHermitian d hd).eigenvalues i <
      (@realAdjacencyMatrix_isHermitian d).eigenvalues (Classical.choose (isPerronFrobeniusMax_realAdjacencyMatrix hd)) := by
  intro i
  let hA' := @realSheetDiffMatrix_isHermitian d hd
  let μ := hA'.eigenvalues i
  let v' := hA'.eigenvectorBasis i
  let v := antisym_lift v'
  have h_eig_v' : Matrix.mulVec (realSheetDiffMatrix hd) v' = μ • v' := hA'.mulVec_eigenvectorBasis i
  
  have h_antisym : tau_op v = -v := by
    ext x
    change v (tau x) = - v x
    exact antisym_lift_tau hd v' x

  have hv_ne : v ≠ 0 := by
    intro h_zero
    have hw_zero : v' = 0 := (antisym_lift_zero_iff hd v').mp h_zero
    have h_repr_k : hA'.eigenvectorBasis.toBasis.repr v' = Finsupp.single i 1 := hA'.eigenvectorBasis.toBasis.repr_self i
    rw [hw_zero, map_zero] at h_repr_k
    have h_eval : (0 : Finsupp _ _) i = (Finsupp.single i 1 : Finsupp _ _) i := Finsupp.ext_iff.1 h_repr_k i
    rw [Finsupp.single_apply, if_pos rfl, Finsupp.coe_zero, Pi.zero_apply] at h_eval
    exact zero_ne_one h_eval

  have h_eig : Matrix.mulVec (@realAdjacencyMatrix d) v = μ • v := by
    ext x
    rw [realAdjacencyMatrix_mul_antisym_lift]
    have h_v' : Matrix.mulVec (realSheetDiffMatrix hd) v' = μ • v' := h_eig_v'
    rw [h_v']
    change antisym_lift (μ • v') x = μ * antisym_lift v' x
    rw [antisym_lift_eq_ext_comp_r hd (μ • v') x]
    rw [antisym_lift_eq_ext_comp_r hd v' x]
    dsimp [antisym_ext_r]
    split_ifs
    · rfl
    · ring

  exact antisym_eigenvalues_strictly_below_top hd v μ hv_ne h_eig h_antisym

noncomputable def max_antisym_eig {d : ℕ} (hd : d ≥ 3) : ℝ :=
  let s := Finset.image (@realSheetDiffMatrix_isHermitian d hd).eigenvalues Finset.univ
  have hs_nonempty : s.Nonempty := ⟨_, Finset.mem_image_of_mem _ (Finset.mem_univ 0)⟩
  s.max' hs_nonempty

/-- Target 2: Rigorous Relative Gap
    The maximum eigenvalue of the antisymmetric block at depth d is strictly greater than
    the maximum eigenvalue of the antisymmetric block at depth d-1 (which equals lambda_{sym, 2} of depth d). -/
theorem relative_spectral_gap {d : ℕ} (hd : d ≥ 7) :
    max_antisym_eig (by omega : d - 1 ≥ 3) < max_antisym_eig (by omega : d ≥ 3) := by
  sorry

end SchreierSpectral
