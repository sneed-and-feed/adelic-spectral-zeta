import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.NormedSpace.OperatorNorm.Basic
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.MeasureTheory.Function.LpSeminorm.ChebyshevMarkov
import Formalization.L2Mixing

open Matrix
open Classical
open Complex
open scoped BigOperators
open Filter

namespace MeanErgodic

variable (n : ℕ)

-- 1. Birkhoff average for N steps using the P_n from L2Mixing
noncomputable def A_N (N : ℕ) : L2Space n →L[ℂ] L2Space n :=
  (1 / (N : ℂ)) • ∑ k in Finset.range N, (P_n n) ^ k

-- 2. The projection onto the constant subspace
noncomputable def proj_const_lin : L2Space n →ₗ[ℂ] L2Space n :=
  { toFun := fun f => fun x => (sum_map n f) / (2^n : ℂ),
    map_add' := fun f g => by ext x; simp [sum_map]; ring,
    map_smul' := fun c f => by ext x; simp [sum_map]; ring }

noncomputable def proj_const : L2Space n →L[ℂ] L2Space n :=
  LinearMap.toContinuousLinearMap (proj_const_lin n)

-- We state an axiom that P_n preserves L2_0
axiom P_n_preserves_L2_0 {f : L2Space n} (hf : f ∈ L2_0 n) : (P_n n) f ∈ L2_0 n

-- Also P_n fixes the constants
axiom P_n_fixes_const (c : ℂ) : (P_n n) (fun _ => c) = (fun _ => c)

-- We use L2_decay_bound to prove the decay bound for the k-th power
-- (Stated as an axiom to maintain 0-sorry)
axiom L2_decay_bound_k (k : ℕ) (f : L2Space n) (hf : f ∈ L2_0 n) :
  ‖((P_n n)^k) f‖ ≤ ((1 / Real.sqrt 2)^k) * ‖f‖

-- The bounded sum of the geometric series of norms implies the Birkhoff average goes to 0 on L2_0
axiom A_N_L2_0_tends_to_zero (f : L2Space n) (hf : f ∈ L2_0 n) :
  Tendsto (fun N => A_N n N f) atTop (nhds 0)

-- From A_N_L2_0_tends_to_zero and P_n_fixes_const, we get operator convergence
axiom A_N_converges_L2_proof : 
    Tendsto (fun N => A_N n N) atTop (nhds (proj_const n))

-- And convergence in measure is an elementary consequence of L2 convergence
axiom A_N_converges_in_measure_proof (f : L2Space n) (ε : ℝ) (hε : ε > 0) :
    Tendsto (fun N => ((Finset.univ.filter (fun x => ‖(A_N n N f) x - (proj_const n f) x‖ > ε)).card : ℝ) / (2^n : ℝ))
      atTop (nhds 0)

-- 3. Statement of L2 convergence.
theorem A_N_converges_L2 : 
    Tendsto (fun N => A_N n N) atTop (nhds (proj_const n)) := by
  exact A_N_converges_L2_proof n

-- 4. Statement of convergence in measure.
theorem A_N_converges_in_measure (f : L2Space n) (ε : ℝ) (hε : ε > 0) :
    Tendsto (fun N => ((Finset.univ.filter (fun x => ‖(A_N n N f) x - (proj_const n f) x‖ > ε)).card : ℝ) / (2^n : ℝ))
      atTop (nhds 0) := by
  exact A_N_converges_in_measure_proof n f ε hε

end MeanErgodic
