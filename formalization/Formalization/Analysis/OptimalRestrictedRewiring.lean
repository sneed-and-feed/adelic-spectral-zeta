import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Finite
import Mathlib.Analysis.Matrix.Spectrum
import Formalization.Analysis.SpectralOracle

open Classical

noncomputable section OptimalRestrictedRewiring

variable {V : Type*} [Fintype V] [DecidableEq V]

/-- Decision problem for Minimum Bisection: Does there exist a partition of V 
    into two equal halves with at most k crossing edges? -/
def MinimumBisection (G : SimpleGraph V) (k : ℕ) : Prop :=
  ∃ S : Finset V, 2 * S.card = Fintype.card V ∧
    (S.sum (fun v => (G.neighborFinset v \ S).card)) / 2 ≤ k

/-- Decision problem for Restricted Rewiring: Is there a subgraph edge-deletion
    that matches the restrictedSpectralGap bounds? -/
def OptimalRestrictedRewiring (spectralGap : SimpleGraph V → ℝ) (G : SimpleGraph V) (d : ℕ) : Prop :=
  ∃ H : SimpleGraph V, H ≤ G ∧ 
    (∀ v, H.degree v ≤ d) ∧ 
    spectralGap H ≥ restrictedSpectralGap d

/-- Reduction predicate connecting Minimum Bisection to Restricted Rewiring -/
def HasBisectionToRewiringReduction : Prop :=
  ∀ (G : SimpleGraph V) (k d : ℕ), d ≥ 3 →
    ∃ (spectralGap : SimpleGraph (Sum V V) → ℝ) (reduce : SimpleGraph V → ℕ → SimpleGraph (Sum V V)),
      (MinimumBisection G k ↔ OptimalRestrictedRewiring spectralGap (reduce G k) d)

end OptimalRestrictedRewiring
