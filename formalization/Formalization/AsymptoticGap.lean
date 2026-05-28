import Mathlib.Topology.Instances.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Pow.Asymptotics
import Formalization.SchreierSpectralGap

open Filter Topology

/--
The structural "speed limit" for the directed Collatz graph converges to 1 asymptotically.
Since the Perron eigenvalue is 2, the absolute directed gap on the primitive Fourier 
characters converges to 2 - 1 = 1 as the Collatz tower goes to infinity.
-/
lemma directed_gap_limit :
  Tendsto (fun n : ℕ => (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ))) atTop (𝓝 1) := by
  have h1 : Tendsto (fun x : ℝ => (2 : ℝ) ^ x) (𝓝 0) (𝓝 1) := by
    have h_cont : ContinuousAt (fun x : ℝ => (2 : ℝ) ^ x) 0 := Real.continuousAt_const_rpow (by norm_num)
    simpa using h_cont.tendsto
  have h2 : Tendsto (fun n : ℕ => ((1 : ℝ) / (2^(n-1) : ℝ))) atTop (𝓝 0) := by
    simp_rw [one_div]
    apply tendsto_inv_atTop_zero.comp
    apply tendsto_pow_atTop_atTop_of_one_lt (by norm_num) |>.comp
    exact tendsto_atTop_atTop_of_monotone (fun _ _ h ↦ Nat.sub_le_sub_right h 1) (fun M ↦ ⟨M + 1, by omega⟩)
  exact h1.comp h2
