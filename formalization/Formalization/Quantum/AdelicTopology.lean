import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.InnerProductSpace.Adjoint
import Mathlib.Topology.ContinuousMap.Basic
import Mathlib.Analysis.Normed.Operator.BoundedLinearMaps

open Complex
open scoped ComplexConjugate
open InnerProductSpace

/-!
# Adelic Topology & Dirac Operator Cayley Decomposition

This module formalizes an abstract Hilbert space model for the algebraic decomposition of a
deformed Cayley transform.

## Structural Hypotheses:
The structure `DiracDecomposition` axiomatizes two bounded linear operators `V` and `W` satisfying:
- `bulk_boundary_sum`: $V^* V + W^* W = 1$ (orthogonal resolution of identity / norm conservation)
- `ortho_VW`: $V^* W = 0$ (mutual orthogonality)
- `ortho_WV`: $W^* V = 0$ (adjoint mutual orthogonality)

These algebraic conditions capture an abstract orthogonal decomposition (e.g. bulk vs. boundary modes)
rather than an explicit geometric Dirac operator on a specific manifold or adelic space.
Under these structural hypotheses, deformation by a complex parameter $C$ yields
`‖D.deformed_U C x‖² = ‖D.V x‖² + |C|² ‖D.W x‖²`.
-/

section AdelicTopology

variable {H : Type*} [NormedAddCommGroup H] [InnerProductSpace ℂ H] [CompleteSpace H]

/-- Abstract orthogonal decomposition model for the Cayley transform of an operator.
The operators `V` and `W` act on a Hilbert space `H` subject to structural algebraic hypotheses:
- `bulk_boundary_sum` ($V^* V + W^* W = 1$): abstract resolution of identity / isometry condition on the critical line.
- `ortho_VW` ($V^* W = 0$) and `ortho_WV` ($W^* V = 0$): abstract mutual orthogonality between the two subspaces.

These hypotheses model the algebraic structure of bulk and boundary components. -/
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

/-- The deformed Cayley transform, shifted off the critical line by a factor `C`.
On the critical line, `|C| = 1`. Off the critical line, `|C| ≠ 1`. -/
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

/-- Algebraic identity for the deformed operator inner product:
Under the structural orthogonality and decomposition hypotheses of `DiracDecomposition`,
evaluating the inner product of `deformed_U C x` with itself yields `‖V x‖² + |C|² ‖W x‖²`.
When `|C| ≠ 1`, this shows algebraically that the deformed operator deviates from isometry. -/
lemma inner_deformed_U_self (C : ℂ) (x : H) : 
    @inner ℂ _ _ (D.deformed_U C x) (D.deformed_U C x) = 
    @inner ℂ _ _ (D.V x) (D.V x) + (conj C * C) * @inner ℂ _ _ (D.W x) (D.W x) := by
  unfold deformed_U
  rw [inner_add_left, inner_add_right, inner_add_right]
  rw [inner_smul_right, inner_V_W_eq_zero D x x, mul_zero, add_zero]
  rw [inner_smul_left, inner_W_V_eq_zero D x x, mul_zero, zero_add]
  rw [inner_smul_left, inner_smul_right, mul_assoc]

end DiracDecomposition

end AdelicTopology
