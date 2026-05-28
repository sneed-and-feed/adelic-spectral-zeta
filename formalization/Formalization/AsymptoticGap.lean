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
    have h_cont : ContinuousAt (fun x : ℝ => (2 : ℝ) ^ x) 0 :=
      Real.continuousAt_const_rpow (by norm_num)
    have ht := h_cont.tendsto
    rw [Real.rpow_zero] at ht
    exact ht
  have h2 : Tendsto (fun n : ℕ => ((1 : ℝ) / (2^(n-1) : ℝ))) atTop (𝓝 0) := by
    have h2a : Tendsto (fun n : ℕ => (2 : ℝ) ^ (n - 1)) atTop atTop := by
      have h_pow := tendsto_pow_atTop_atTop_of_one_lt (by norm_num : (1 : ℝ) < 2)
      have h_sub : Tendsto (fun n : ℕ => n - 1) atTop atTop := by
        apply tendsto_atTop_atTop_of_monotone
        · intro i j hij
          exact Nat.sub_le_sub_right hij 1
        · intro M
          use M + 1
          omega
      exact h_pow.comp h_sub
    have h_inv := tendsto_inv_atTop_zero.comp h2a
    have h_eq : (fun n : ℕ => ((1 : ℝ) / (2^(n-1) : ℝ))) = (fun x : ℝ => x⁻¹) ∘ fun n : ℕ => (2 : ℝ) ^ (n - 1) := by
      ext x
      simp [one_div]
    rw [h_eq]
    exact h_inv
  exact h1.comp h2
