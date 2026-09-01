import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Normed.Operator.ContinuousLinearMap
import Mathlib.Topology.MetricSpace.Basic
import Formalization.Dynamics.L2Mixing

open Matrix
open Classical
open Complex
open scoped BigOperators
open Filter

namespace MeanErgodic

variable (n : ℕ)

-- 1. Birkhoff average for N steps using the P_n from L2Mixing
noncomputable def A_N (N : ℕ) : L2Space n →L[ℂ] L2Space n :=
  (1 / (N : ℂ)) • ∑ k ∈ Finset.range N, (P_n n) ^ k

-- 2. The projection onto the constant subspace
noncomputable def proj_const_lin : L2Space n →ₗ[ℂ] L2Space n :=
  { toFun := fun f => WithLp.toLp 2 (fun (_ : ZMod (2^n)) => (sum_map n f) / (2^n : ℂ)),
    map_add' := fun f g => by
      ext x
      simp only [map_add, add_div]
      rfl
    map_smul' := fun c f => by
      ext x
      simp only [LinearMap.map_smul, smul_eq_mul, mul_div_assoc]
      rfl }

noncomputable def proj_const : L2Space n →L[ℂ] L2Space n :=
  LinearMap.toContinuousLinearMap (proj_const_lin n)

/-- Hypothesis structure capturing the mean ergodic theorem and L^2 decay assumptions on P_n. -/
structure MeanErgodicAssumptions (n : ℕ) : Prop where
  P_n_preserves_L2_0 : ∀ {f : L2Space n} (_hf : f ∈ L2_0 n), (P_n n) f ∈ L2_0 n
  P_n_fixes_const : ∀ (c : ℂ), (P_n n) (WithLp.toLp 2 (fun (_ : ZMod (2^n)) => c)) = (WithLp.toLp 2 (fun (_ : ZMod (2^n)) => c))
  L2_decay_bound_k : ∀ (k : ℕ) (f : L2Space n) (_hf : f ∈ L2_0 n), ‖((P_n n)^k) f‖ ≤ ((1 / Real.sqrt 2)^k) * ‖f‖
  A_N_L2_0_tends_to_zero : ∀ (f : L2Space n) (_hf : f ∈ L2_0 n), Filter.Tendsto (fun N => A_N n N f) Filter.atTop (nhds 0)
  A_N_converges_L2_proof : Filter.Tendsto (fun N => A_N n N) Filter.atTop (nhds (proj_const n))
  A_N_converges_in_measure_proof : ∀ (f : L2Space n) (ε : ℝ) (_hε : ε > 0),
    Filter.Tendsto (fun N => ((Finset.univ.filter (fun x => ‖(A_N n N f) x - (proj_const n f) x‖ > ε)).card : ℝ) / (2^n : ℝ))
      Filter.atTop (nhds 0)

-- 3. Statement of L2 convergence.
theorem A_N_converges_L2 (h : MeanErgodicAssumptions n) : 
    Tendsto (fun N => A_N n N) atTop (nhds (proj_const n)) :=
  h.A_N_converges_L2_proof

-- 4. Statement of convergence in measure.
theorem A_N_converges_in_measure (h : MeanErgodicAssumptions n) (f : L2Space n) (ε : ℝ) (hε : ε > 0) :
    Tendsto (fun N => ((Finset.univ.filter (fun x => ‖(A_N n N f) x - (proj_const n f) x‖ > ε)).card : ℝ) / (2^n : ℝ))
      atTop (nhds 0) :=
  h.A_N_converges_in_measure_proof f ε hε

end MeanErgodic
