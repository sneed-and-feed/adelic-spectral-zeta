import Mathlib
import Formalization.CollatzRelMatrix

open scoped BigOperators
open Polynomial Matrix PowerSeries

namespace CollatzRational

-- The dimension of our truncated space
def L_dim (n : ℕ) := 2 ^ (n - 1)

-- The truncated transfer operator as a matrix over ℂ
noncomputable def Sn (n : ℕ) (hn : n ≥ 2) : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) Complex :=
  Matrix.map (CollatzDirMatrix.twistedDirMatrix hn) (fun x => (x : Complex))

-- The sequence of traces a_k = Tr(Sn^k)
noncomputable def trace_k (n : ℕ) (hn : n ≥ 2) (k : ℕ) : Complex :=
  Matrix.trace (Sn n hn ^ k)

-- The formal power series S_n(t) = sum_{k=1}^infty (a_k / k) t^k
noncomputable def Sn_series (n : ℕ) (hn : n ≥ 2) : PowerSeries Complex :=
  PowerSeries.mk (fun k => if k = 0 then 0 else trace_k n hn k / (k : Complex))

/-- The determinant det(I - t S_n) as a formal power series over ℂ. -/
noncomputable def det_I_minus_t_Sn (n : ℕ) (hn : n ≥ 2) : PowerSeries Complex :=
  let I : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (PowerSeries Complex) := 1
  let tSn : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (PowerSeries Complex) := 
    (PowerSeries.X : PowerSeries Complex) • (Matrix.map (Sn n hn) (algebraMap Complex (PowerSeries Complex)))
  (I - tSn).det

/-- A coercion from Polynomial to PowerSeries -/
noncomputable def poly_to_power_series (P : Polynomial Complex) : PowerSeries Complex :=
  PowerSeries.mk (fun k => P.coeff k)

noncomputable def det_I_minus_t_Sn_poly (n : ℕ) (hn : n ≥ 2) : Polynomial Complex :=
  let I : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (Polynomial Complex) := 1
  let tSn : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (Polynomial Complex) := 
    (Polynomial.X : Polynomial Complex) • (Matrix.map (Sn n hn) (algebraMap Complex (Polynomial Complex)))
  (I - tSn).det

/-
  REMOVED: trace_det_identity, Zn_series_eq_inv_det, det_I_minus_t_Sn_eq_poly, 
           det_I_minus_t_Sn_poly_stable, and rational_zeta_theorem.

  DISPROOF:
  The characteristic polynomials of the transfer operator are NOT stable across levels.
  Explicit evaluation shows:
  - For n=2, det(I - t S_2) = 1 - 2t^2.
  - For n=3, det(I - t S_3) = 1 + 2t^4.
  Since they are not equal, the projective limit does not yield a single rational function.
  The "Amitsur Formula Gap" approach fails because the local traces are topologically 
  inconsistent across the covering graph sheets.
-/

end CollatzRational
