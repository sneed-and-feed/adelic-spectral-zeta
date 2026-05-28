import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.CategoryTheory.Limits.Types
import Mathlib.Algebra.Category.Ring.Limits
import Mathlib.Algebra.Category.AlgebraCat.Limits
import Mathlib.CategoryTheory.Opposites
import Mathlib.CategoryTheory.Limits.Preserves.Basic
import Mathlib.CategoryTheory.Limits.Preserves.Limits

open scoped BigOperators
open CategoryTheory Limits
open PowerSeries

namespace Collatz

noncomputable section

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

noncomputable def truncMap {n m : ℕ} (h : n ≤ m) : TruncRing m →ₐ[ℂ] TruncRing n :=
  Ideal.Quotient.liftₐ (Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(m+1)) }) 
    (Ideal.Quotient.mkₐ ℂ (Ideal.span { (PowerSeries.X : PowerSeries ℂ)^(2^(n+1)) })) 
    (by
      intro x hx
      change Ideal.Quotient.mk _ x = 0
      rw [Ideal.Quotient.eq_zero_iff_mem]
      exact truncIdeal_mono h hx
    )

noncomputable def Z_functor : ℕᵒᵖ ⥤ AlgebraCat ℂ where
  obj n := AlgebraCat.of ℂ (TruncRing n.unop)
  map {m n} f := AlgebraCat.ofHom (truncMap f.unop.le)
  map_id n := by
    change AlgebraCat.ofHom _ = 𝟙 _
    apply AlgHom.ext
    intro x
    change truncMap (le_refl n.unop) x = x
    induction x using Quotient.inductionOn
    rfl
  map_comp := by
    intro m n p f g
    change AlgebraCat.ofHom _ = AlgebraCat.ofHom _ ≫ AlgebraCat.ofHom _
    apply AlgHom.ext
    intro x
    change truncMap (f ≫ g).unop.le x = truncMap g.unop.le (truncMap f.unop.le x)
    induction x using Quotient.inductionOn
    rfl

end
end Collatz
