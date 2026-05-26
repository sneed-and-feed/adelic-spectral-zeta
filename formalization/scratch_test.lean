import Formalization.SchreierSpectral

/-!
# Scratch file — previous proof attempts removed

The two theorems that were here (`weightedMatrix_eq_two_smul_adj_plus_monodromy`
and `spectral_radius_exactly_four`) were found to be **mathematically false**:

1. The factor-of-2 recursive formula fails because not every G_{d-1} edge
   lifts to both sheets. (Counterexample: d=4, entry (1,3).)

2. G_d is never 4-regular (vertex 0 has degree ≤ 2 due to self-loops at
   generators 3·0=0 and inv3·0=0), so the spectral radius is strictly < 4.

See the comments in `SchreierSpectral.lean` for the correct proven results.
-/
