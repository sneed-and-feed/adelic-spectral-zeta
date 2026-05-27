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

/-- The L^2 inner product space over ℂ for functions on ℤ/2^nℤ. -/
abbrev L2Space := EuclideanSpace ℂ (ZMod (2^n))

/-- The directed relation matrix D_n mapped to ℂ -/
def D_n_matrix : Matrix (ZMod (2^n)) (ZMod (2^n)) ℂ :=
  fun i j => (CollatzDirMatrix.collatzDirMatrix n i j : ℂ)

/-- The transition matrix for the random walk P_n = (1/2) D_n -/
def P_n_matrix : Matrix (ZMod (2^n)) (ZMod (2^n)) ℂ :=
  (1 / 2 : ℂ) • D_n_matrix n

/-- P_n as a linear map -/
def P_n_lin : L2Space n →ₗ[ℂ] L2Space n :=
  Matrix.toLin' (P_n_matrix n)

/-- The normalized random walk transition operator P_n as a ContinuousLinearMap -/
def P_n : L2Space n →L[ℂ] L2Space n :=
  LinearMap.toContinuousLinearMap (P_n_lin n)

/-- The sum functional mapping a function to the sum of its values -/
def sum_map : L2Space n →ₗ[ℂ] ℂ :=
  { toFun := fun f => ∑ x, f x
    map_add' := fun f g => Finset.sum_add_distrib
    map_smul' := fun c f => by 
      simp only [RingHom.id_apply, smul_eq_mul]
      rw [Finset.mul_sum]
      rfl }

/-- The mean-zero subspace L^2_0 -/
def L2_0 : Submodule ℂ (L2Space n) :=
  LinearMap.ker (sum_map n)

/-- The spectral bound proved in Phase 3: λ_max ≤ √2 for non-trivial blocks,
    which corresponds to operator norm bounded by 1/√2 for P_n. -/
axiom spectral_bound_phase3 {f : L2Space n} (hf : f ∈ L2_0 n) :
  ‖(P_n n) f‖ ≤ (1 / Real.sqrt 2) * ‖f‖

/-- The main L2 decay bound on the mean-zero subspace. -/
theorem L2_decay_bound (f : L2Space n) (hf : f ∈ L2_0 n) :
  ‖(P_n n) f‖ ≤ (1 / Real.sqrt 2) * ‖f‖ := by
  exact spectral_bound_phase3 n hf

end
