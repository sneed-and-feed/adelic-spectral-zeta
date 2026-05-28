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

/-- Amitsur's Formula / MacMahon Master Theorem analogue:
    The trace-determinant relation for a matrix A.
    exp(sum_k Tr(A^k)/k t^k) = 1 / det(I - tA)
    Since exp of power series is tricky in Mathlib without topology, we state it 
    as the logarithmic derivative identity. 
    Here we just leave a placeholder statement. -/
theorem trace_det_identity (n : ℕ) (hn : n ≥ 2) :
  PowerSeries.derivative Complex (det_I_minus_t_Sn n hn) = 
  - (det_I_minus_t_Sn n hn) * PowerSeries.derivative Complex (Sn_series n hn) := by sorry

/-- The truncated zeta function Z_n(t). -/
noncomputable def Zn_series (n : ℕ) (hn : n ≥ 2) : PowerSeries Complex :=
  (det_I_minus_t_Sn n hn)⁻¹

/-- Theorem: The truncated zeta function Z_n(t) equals 1 / det(I - t S_n). -/
theorem Zn_series_eq_inv_det (n : ℕ) (hn : n ≥ 2) : 
  Zn_series n hn * det_I_minus_t_Sn n hn = 1 := by
  sorry

/-- A coercion from Polynomial to PowerSeries -/
noncomputable def poly_to_power_series (P : Polynomial Complex) : PowerSeries Complex :=
  PowerSeries.mk (fun k => P.coeff k)

noncomputable def det_I_minus_t_Sn_poly (n : ℕ) (hn : n ≥ 2) : Polynomial Complex :=
  let I : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (Polynomial Complex) := 1
  let tSn : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (Polynomial Complex) := 
    (Polynomial.X : Polynomial Complex) • (Matrix.map (Sn n hn) (algebraMap Complex (Polynomial Complex)))
  (I - tSn).det

lemma det_I_minus_t_Sn_eq_poly (n : ℕ) (hn : n ≥ 2) :
    det_I_minus_t_Sn n hn = poly_to_power_series (det_I_minus_t_Sn_poly n hn) := by
  sorry

lemma det_I_minus_t_Sn_poly_stable (n : ℕ) (hn : n ≥ 2) :
    det_I_minus_t_Sn_poly n hn = det_I_minus_t_Sn_poly 2 (by omega) := by
  sorry

/-- The property that the limit zeta function is rational. 
    There exist polynomials P and Q such that their ratio represents the limit. -/
def IsRationalZeta : Prop :=
  ∃ (P Q : Polynomial Complex), Q ≠ 0 ∧
    ∀ (n : ℕ) (hn : n ≥ 2), Zn_series n hn * poly_to_power_series Q = poly_to_power_series P

/-- The Rational Zeta Theorem: the projective limit zeta function is rational. -/
theorem rational_zeta_theorem : IsRationalZeta := by
  use (1 : Polynomial Complex), (det_I_minus_t_Sn_poly 2 (by omega))
  constructor
  · sorry
  · intro n hn
    have h_stable := det_I_minus_t_Sn_poly_stable n hn
    have h_eq := det_I_minus_t_Sn_eq_poly n hn
    rw [← h_stable]
    rw [← h_eq]
    have h_inv := Zn_series_eq_inv_det n hn
    have h_one : poly_to_power_series (1 : Polynomial Complex) = 1 := by sorry
    rw [h_one]
    exact h_inv

end CollatzRational
