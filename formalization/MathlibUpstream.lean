import MathlibUpstream.LinearAlgebra.Matrix.CyclicShift
import MathlibUpstream.Analysis.DFT
import MathlibUpstream.Algebra.Polynomial.CyclicBlockFactorization
import MathlibUpstream.Analysis.SpecialFunctions.LogBounds
import MathlibUpstream.LinearAlgebra.Matrix.Positivity
import MathlibUpstream.Combinatorics.PrefixSparsity

/-!
# MathlibUpstream Root Module

Generic, universally reusable mathematical components formatted strictly according to
Mathlib 4 conventions.

## Modules
- `MathlibUpstream.LinearAlgebra.Matrix.CyclicShift`: Characteristic polynomial of general
  weighted cyclic shift matrices over arbitrary commutative rings.
- `MathlibUpstream.Analysis.DFT`: Discrete Fourier Transform on finite cyclic groups and
  unitary DFT matrices.
- `MathlibUpstream.Algebra.Polynomial.CyclicBlockFactorization`: General polynomial cyclic
  block Fredholm determinant factorizations over commutative rings.
- `MathlibUpstream.Analysis.SpecialFunctions.LogBounds`: Properties of base-2 logarithms and
  real algebraic / logarithmic bounds.
- `MathlibUpstream.LinearAlgebra.Matrix.Positivity`: Spectral theory and Perron-Frobenius
  properties of non-negative symmetric matrices.
- `MathlibUpstream.Combinatorics.PrefixSparsity`: Exact combinatorial prefix sharing and
  path sparsity on p-ary trees.
-/
