import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.CategoryTheory.Limits.Types
import Mathlib.Algebra.Category.Ring.Limits
import Mathlib.Algebra.Category.AlgebraCat.Limits
import Mathlib.CategoryTheory.Opposites
import Formalization.CollatzRelMatrix

open scoped BigOperators
open CategoryTheory Limits
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
  sorry

-- The n-th truncation ring: ℂ[[t]] / (t^L)
def TruncRing (n : ℕ) :=
  PowerSeries ℂ ⧸ Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(n+1)) }

instance (n : ℕ) : CommRing (TruncRing n) :=
  Ideal.Quotient.commRing _

instance (n : ℕ) : Algebra ℂ (TruncRing n) :=
  Ideal.Quotient.algebra ℂ

-- Truncation map: ℂ[[t]]/(t^m) ⟶ ℂ[[t]]/(t^n)
noncomputable def truncMap {n m : ℕ} (h : n ≤ m) : TruncRing m →ₐ[ℂ] TruncRing n :=
  sorry

-- The Projective System
noncomputable def Z_functor : ℕᵒᵖ ⥤ AlgebraCat ℂ where
  obj n := AlgebraCat.of ℂ (TruncRing n.unop)
  map {m n} f := AlgebraCat.ofHom (truncMap f.unop.le)
  map_id := sorry
  map_comp := sorry

-- The abstract inverse limit algebra: 
noncomputable def Z_limit_algebra : AlgebraCat ℂ := limit Z_functor

variable (Z_seq : ∀ n : ℕ, TruncRing n)
variable (Z_compat : ∀ {m n : ℕ} (h : n ≤ m), truncMap h (Z_seq m) = Z_seq n)

-- Define Z(t) strictly as this infinite limit
noncomputable def Z_element : Z_limit_algebra :=
  sorry

end

end Collatz
