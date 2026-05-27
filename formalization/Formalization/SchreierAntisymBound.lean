import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2
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
  rw [tau_tau]

lemma tau_op_commutes (v : ZMod (2^(d-1)) → ℝ) :
    (@realAdjacencyMatrix d).mulVec (tau_op v) = tau_op ((@realAdjacencyMatrix d).mulVec v) := by
  ext i
  dsimp [tau_op, mulVec, dotProduct]
  let e : ZMod (2^(d-1)) ≃ ZMod (2^(d-1)) := {
    toFun := tau
    invFun := tau
    left_inv := tau_tau
    right_inv := tau_tau
  }
  have h_sum : ∑ j : ZMod (2^(d-1)), (@realAdjacencyMatrix d) i j * v (tau j) =
               ∑ j : ZMod (2^(d-1)), (@realAdjacencyMatrix d) i (e j) * v (tau (e j)) := by
    exact (Equiv.sum_comp e (fun x => (@realAdjacencyMatrix d) i x * v (tau x))).symm
  rw [h_sum]
  apply Finset.sum_congr rfl
  intro j _
  have h2 : v (tau (tau j)) = v j := by rw [tau_tau]
  rw [h2]
  have h3 : (@realAdjacencyMatrix d) i (tau j) = (@realAdjacencyMatrix d) (tau i) j := by
    dsimp [realAdjacencyMatrix, adjacencyMatrix, Matrix.map_apply]
    apply congrArg
    have h_adj : (G_d d).Adj i (tau j) ↔ (G_d d).Adj (tau i) j := by
      constructor
      · intro h
        have := tau_preserves_edges h
        rw [tau_tau] at this
        exact this
      · intro h
        have := tau_preserves_edges h
        rw [tau_tau] at this
        exact this
    simp only [propext h_adj]
  rw [h3]

lemma pf_eigenvector_symmetric :
    let A := @realAdjacencyMatrix d
    let hA := @realAdjacencyMatrix_isHermitian d
    let eig := hA.eigenvalues
    let evec := hA.eigenvectorBasis
    let max_eig := Finset.max' (Finset.univ.image eig) ⟨eig 0, Finset.mem_image_of_mem eig (Finset.mem_univ 0)⟩
    let i_max := Classical.choose (isPerronFrobeniusMax_realAdjacencyMatrix hd)
    tau_op (evec i_max) = evec i_max := by
  intro A hA eig evec max_eig i_max
  have h_pf := isPerronFrobeniusMax_realAdjacencyMatrix hd
  have h_imax_def : i_max = Classical.choose h_pf := rfl
  have h_pf_spec := Classical.choose_spec h_pf
  let v_0 := evec i_max
  have h_v0_eig : A.mulVec v_0 = max_eig • v_0 := by
    sorry
  sorry

end SchreierSpectral
