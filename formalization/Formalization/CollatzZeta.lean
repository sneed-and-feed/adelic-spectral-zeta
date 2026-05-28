import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Complex.Basic
import Formalization.CollatzDirMatrix

open scoped BigOperators

namespace Collatz

noncomputable section

variable (n : ℕ)

-- We define the base ring as the Complex numbers for the zeta function
abbrev ℂ := Complex

-- The dimension of our truncated space is L = 2^(n+1)
local notation "L" => 2 ^ (n + 1)

-- The truncated transfer operator as a matrix over ℂ
def Sn : Matrix (Fin L) (Fin L) ℂ :=
  Matrix.map (twistedDirMatrix n) (fun x => (x : ℂ))

-- The sequence of traces a_k = Tr(Sn^k)
def trace_k (k : ℕ) : ℂ :=
  Matrix.trace (Sn n ^ k)

-- The formal power series S_n(t) = sum_{k=1}^infty (a_k / k) t^k
def Sn_series : PowerSeries ℂ :=
  PowerSeries.mk (fun k => if k = 0 then 0 else trace_k n k / (k : ℂ))

-- The truncated spectral zeta function Z_n(t) = exp(S_n(t))
def Zn_series : PowerSeries ℂ :=
  PowerSeries.exp ℂ (Sn_series n)

-- The statement of the rational zeta theorem for the finite truncations
theorem Zn_eq_det_inv :
  Zn_series n * (Matrix.charpoly (Sn n)).eval (PowerSeries.X : PowerSeries ℂ) = 1 := by
  sorry

end

end Collatz
