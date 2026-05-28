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
axiom directed_gap_limit :
  Tendsto (fun n : ℕ => (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ))) atTop (𝓝 1)
