import Lake
open Lake DSL

package «formalization» where
  -- Settings applied to both builds and targets

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.8.0"

@[default_target]
lean_lib «Formalization» where
  -- add any library configuration options here

lean_lib «SpectralPositivity» where


