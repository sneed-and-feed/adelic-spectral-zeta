import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.CategoryTheory.Limits.Types
import Mathlib.Algebra.Category.Ring.Limits
import Mathlib.Algebra.Category.AlgebraCat.Limits
import Mathlib.CategoryTheory.Opposites

open scoped BigOperators
open CategoryTheory Limits

namespace Collatz

noncomputable def TruncRing (n : ℕ) :=
  PowerSeries ℂ ⧸ Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(n+1)) }

noncomputable instance (n : ℕ) : CommRing (TruncRing n) :=
  Ideal.Quotient.commRing _

noncomputable instance (n : ℕ) : Algebra ℂ (TruncRing n) :=
  Ideal.Quotient.algebra ℂ

lemma le_pow (h : n ≤ m) : 2 ^ (n + 1) ≤ 2 ^ (m + 1) := by
  gcongr
  omega

noncomputable def truncMap {n m : ℕ} (h : n ≤ m) : TruncRing m →ₐ[ℂ] TruncRing n :=
  Ideal.Quotient.liftₐ (Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(m+1)) }) 
    (Ideal.Quotient.mkₐ ℂ (Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(n+1)) })) 
    (by
      intro x hx
      rw [Ideal.mem_span_singleton] at hx
      rcases hx with ⟨y, rfl⟩
      rw [map_mul]
      have H : (Ideal.Quotient.mkₐ ℂ (Ideal.span {(PowerSeries.X : PowerSeries ℂ) ^ 2 ^ (n + 1)})) ((PowerSeries.X : PowerSeries ℂ) ^ 2 ^ (m + 1)) = 0 := by
        change Ideal.Quotient.mk (Ideal.span {(PowerSeries.X : PowerSeries ℂ) ^ 2 ^ (n + 1)}) ((PowerSeries.X : PowerSeries ℂ) ^ 2 ^ (m + 1)) = 0
        rw [Ideal.Quotient.eq_zero_iff_mem, Ideal.mem_span_singleton]
        use (PowerSeries.X : PowerSeries ℂ) ^ (2 ^ (m + 1) - 2 ^ (n + 1))
        rw [← pow_add]
        congr 1
        exact Nat.sub_add_cancel (le_pow h)
      rw [mul_comm, H, zero_mul]
    )

end Collatz
