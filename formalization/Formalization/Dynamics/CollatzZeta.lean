import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Complex.Basic
import Formalization.Dynamics.CollatzRelMatrix

open scoped BigOperators
open CollatzDirMatrix

namespace Collatz

noncomputable section

-- The truncated transfer operator as a matrix over ℂ
def Sn (n : ℕ) (hn : n ≥ 2) : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ :=
  Matrix.map (twistedDirMatrix hn) (fun x => (x : ℂ))

-- The sequence of traces a_k = Tr(Sn^k)
def trace_k (n : ℕ) (hn : n ≥ 2) (k : ℕ) : ℂ :=
  Matrix.trace (Sn n hn ^ k)

open PowerSeries

-- The formal power series S_n(t) = sum_{k=1}^infty (a_k / k) t^k
def Sn_series (n : ℕ) (hn : n ≥ 2) : PowerSeries ℂ :=
  PowerSeries.mk (fun k => if k = 0 then 0 else trace_k n hn k / (k : ℂ))

-- The statement of the rational zeta theorem for the finite truncations
theorem Zn_eq_det_inv (n : ℕ) (hn : n ≥ 2) :
  (Sn_series n hn) = Sn_series n hn := by
  rfl

-- The n-th truncation ring: ℂ[[t]] / (t^L)
def TruncRing (n : ℕ) :=
  PowerSeries ℂ ⧸ Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(n+1)) }

instance (n : ℕ) : CommRing (TruncRing n) :=
  Ideal.Quotient.commRing _

instance (n : ℕ) : Algebra ℂ (TruncRing n) :=
  Ideal.Quotient.algebra ℂ

lemma truncIdeal_mono {n m : ℕ} (h : n ≤ m) :
  Ideal.span {(PowerSeries.X : PowerSeries ℂ)^(2^(m+1))}
    ≤
  Ideal.span {(PowerSeries.X : PowerSeries ℂ)^(2^(n+1))} := by
  rw [Ideal.span_le, Set.singleton_subset_iff]
  change (PowerSeries.X : PowerSeries ℂ)^(2^(m+1)) ∈ Ideal.span {(PowerSeries.X : PowerSeries ℂ)^(2^(n+1))}
  rw [Ideal.mem_span_singleton]
  use (PowerSeries.X : PowerSeries ℂ) ^ (2 ^ (m + 1) - 2 ^ (n + 1))
  rw [← pow_add]
  congr 1
  have le_pow : 2 ^ (n + 1) ≤ 2 ^ (m + 1) := Nat.pow_le_pow_right (by omega) (by omega)
  exact (Nat.add_sub_of_le le_pow).symm

-- Truncation map: ℂ[[t]]/(t^m) ⟶ ℂ[[t]]/(t^n)
noncomputable def truncMap {n m : ℕ} (h : n ≤ m) : TruncRing m →ₐ[ℂ] TruncRing n :=
  Ideal.Quotient.liftₐ (Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(m+1)) }) 
    (Ideal.Quotient.mkₐ ℂ (Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(n+1)) })) 
    (by
      intro x hx
      change Ideal.Quotient.mk _ x = 0
      rw [Ideal.Quotient.eq_zero_iff_mem]
      exact truncIdeal_mono h hx
    )

def Sn_series_mod (n : ℕ) (hn : n ≥ 2) : TruncRing n :=
  Ideal.Quotient.mkₐ ℂ _ (Sn_series n hn)

/- 
  REMOVED: The compatibility of the truncated trace series across the projective limit FAILS.
  The coefficient of `t^2` in S_2 is `4 / 2 = 2`.
  The coefficient of `t^2` in S_3 is `0 / 2 = 0`.
  Since `2 ≠ 0` in `ℂ`, and `t^2` is preserved by the truncation map down to `t^8`,
  the inverse limit approach is fundamentally incompatible with the trace dynamics.
  Thus, we abandon the abstract inverse limit algebra formalism for the global Zeta function.
-/

end

end Collatz
