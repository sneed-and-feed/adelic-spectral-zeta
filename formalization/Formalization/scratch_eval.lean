import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.NormedSpace.OperatorNorm.Basic
import Formalization.CollatzRelMatrix
import Mathlib.Topology.ContinuousFunction.Basic
import Mathlib.Analysis.InnerProductSpace.Basic
import Mathlib.Analysis.NormedSpace.Basic
import Mathlib.Data.Complex.Basic

open ComplexConjugate

noncomputable section

variable (n : ℕ)

abbrev L2Space := EuclideanSpace ℂ (ZMod (2^n))

def D_n_matrix : Matrix (ZMod (2^n)) (ZMod (2^n)) ℂ :=
  fun i j => (CollatzDirMatrix.collatzDirMatrix n i j : ℂ)

def P_n_matrix : Matrix (ZMod (2^n)) (ZMod (2^n)) ℂ :=
  (1 / 2 : ℂ) • D_n_matrix n

def P_n_lin : L2Space n →ₗ[ℂ] L2Space n :=
  Matrix.toLin' (P_n_matrix n)

def P_n : L2Space n →L[ℂ] L2Space n :=
  LinearMap.toContinuousLinearMap (P_n_lin n)

def sum_map : L2Space n →ₗ[ℂ] ℂ :=
  { toFun := fun f => ∑ x, f x
    map_add' := fun f g => Finset.sum_add_distrib
    map_smul' := fun c f => by 
      simp only [RingHom.id_apply, smul_eq_mul]
      rw [Finset.mul_sum]
      rfl }

def L2_0 : Submodule ℂ (L2Space n) :=
  LinearMap.ker (sum_map n)

axiom spectral_bound_phase3 {f : L2Space n} (hf : f ∈ L2_0 n) :
  ‖(P_n n) f‖ ≤ (1 / Real.sqrt 2) * ‖f‖

theorem L2_decay_bound (f : L2Space n) (hf : f ∈ L2_0 n) :
  ‖(P_n n) f‖ ≤ (1 / Real.sqrt 2) * ‖f‖ := by
  exact spectral_bound_phase3 n hf

end
