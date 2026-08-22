import Lake
open Lake DSL

package «formalization» where
  -- Settings applied to both builds and targets

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.8.0"

@[default_target]
lean_lib «MathlibUpstream» where
  -- Generic, universally reusable mathematical components

@[default_target]
lean_lib «Formalization» where
  -- Project-specific adelic spectral triples, Aronszajn-Krein deficiency indexing, and Collatz / 2-adic dynamics


