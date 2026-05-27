import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Topology.ContinuousFunction.Basic
import Mathlib.Analysis.NormedSpace.BoundedLinearMaps

open Complex
open scoped ComplexConjugate
open InnerProductSpace

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

structure DiracDecomposition (H : Type*) [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H] where
  V : H →L[ℂ] H
  W : H →L[ℂ] H
  bulk_boundary_sum : ContinuousLinearMap.adjoint V * V + ContinuousLinearMap.adjoint W * W = 1
  ortho_VW : ContinuousLinearMap.adjoint V * W = 0
  ortho_WV : ContinuousLinearMap.adjoint W * V = 0

namespace DiracDecomposition
variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H] (D : DiracDecomposition H)

noncomputable def V_adj : H →L[ℂ] H := ContinuousLinearMap.adjoint D.V
noncomputable def W_adj : H →L[ℂ] H := ContinuousLinearMap.adjoint D.W

noncomputable def deformed_U (C : ℂ) (x : H) : H :=
  D.V x + C • D.W x

lemma inner_V_W_eq_zero (x y : H) : @inner ℂ _ _ (D.V x) (D.W y) = 0 := by
  have h1 : @inner ℂ _ _ (D.V x) (D.W y) = @inner ℂ _ _ x (D.V_adj (D.W y)) := by
    exact (ContinuousLinearMap.adjoint_inner_right D.V x (D.W y)).symm
  rw [h1]
  have h2 : D.V_adj (D.W y) = (D.V_adj * D.W) y := rfl
  rw [h2]
  unfold V_adj
  rw [D.ortho_VW]
  exact inner_zero_right x

lemma inner_W_V_eq_zero (x y : H) : @inner ℂ _ _ (D.W x) (D.V y) = 0 := by
  have h1 : @inner ℂ _ _ (D.W x) (D.V y) = @inner ℂ _ _ x (D.W_adj (D.V y)) := by
    exact (ContinuousLinearMap.adjoint_inner_right D.W x (D.V y)).symm
  rw [h1]
  have h2 : D.W_adj (D.V y) = (D.W_adj * D.V) y := rfl
  rw [h2]
  unfold W_adj
  rw [D.ortho_WV]
  exact inner_zero_right x

lemma inner_sum_eq_inner (x : H) : 
    @inner ℂ _ _ (D.V x) (D.V x) + @inner ℂ _ _ (D.W x) (D.W x) = @inner ℂ _ _ x x := by
  have h1 : @inner ℂ _ _ (D.V x) (D.V x) = @inner ℂ _ _ x (D.V_adj (D.V x)) := by
    exact (ContinuousLinearMap.adjoint_inner_right D.V x (D.V x)).symm
  have h2 : @inner ℂ _ _ (D.W x) (D.W x) = @inner ℂ _ _ x (D.W_adj (D.W x)) := by
    exact (ContinuousLinearMap.adjoint_inner_right D.W x (D.W x)).symm
  rw [h1, h2, ← inner_add_right]
  have h3 : D.V_adj (D.V x) + D.W_adj (D.W x) = (D.V_adj * D.V + D.W_adj * D.W) x := rfl
  rw [h3]
  unfold V_adj W_adj
  rw [D.bulk_boundary_sum]
  rfl

lemma inner_deformed_U_self (C : ℂ) (x : H) : 
    @inner ℂ _ _ (D.deformed_U C x) (D.deformed_U C x) = 
    @inner ℂ _ _ (D.V x) (D.V x) + (conj C * C) * @inner ℂ _ _ (D.W x) (D.W x) := by
  unfold deformed_U
  rw [inner_add_left, inner_add_right, inner_add_right]
  -- First cross term: ⟪V x, C • W x⟫
  rw [inner_smul_right, inner_V_W_eq_zero D x x, mul_zero, add_zero]
  -- Second cross term: ⟪C • W x, V x⟫
  rw [inner_smul_left, inner_W_V_eq_zero D x x, mul_zero, zero_add]
  -- Last term: ⟪C • W x, C • W x⟫
  rw [inner_smul_left, inner_smul_right, mul_assoc]
  rfl

end DiracDecomposition
