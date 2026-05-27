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

end SchreierSpectral
