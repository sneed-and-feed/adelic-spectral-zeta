import Mathlib.Data.Complex.Basic
import Mathlib.Data.Complex.Exponential
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Bounds
import Mathlib.Algebra.Group.AddChar
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.Asymptotics.Asymptotics
import Formalization.SchreierSpectral
import Formalization.TrigSum
import Formalization.FourierChain

open Complex
open Matrix
open Finset

namespace SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)
-- ...
