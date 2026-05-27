import Lake
open Lake DSL

package «spectral-positivity-ext» where

require mathlib from git "https://github.com/leanprover-community/mathlib4" @ "v4.8.0"

@[default_target]
lean_lib «SpectralPositivityExt» where
