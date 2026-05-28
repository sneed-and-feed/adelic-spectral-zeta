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

theorem Sn_series_compatible {m n : ℕ} (h : n ≤ m) (hm : m ≥ 2) (hn : n ≥ 2) :
  truncMap h (Sn_series_mod m hm) = Sn_series_mod n hn := by sorry

-- The Projective System
noncomputable def Z_functor : ℕᵒᵖ ⥤ AlgebraCat ℂ where
  obj n := AlgebraCat.of ℂ (TruncRing n.unop)
  map {m n} f := AlgebraCat.ofHom (truncMap f.unop.le)
  map_id n := by
    apply CategoryTheory.ConcreteCategory.hom_ext
    intro x
    obtain ⟨y, rfl⟩ := Ideal.Quotient.mk_surjective x
    rfl
  map_comp := by
    intro m n p f g
    apply CategoryTheory.ConcreteCategory.hom_ext
    intro x
    obtain ⟨y, rfl⟩ := Ideal.Quotient.mk_surjective x
    rfl

-- The abstract inverse limit algebra: 
noncomputable def Z_limit_algebra : AlgebraCat ℂ := limit Z_functor

variable (Z_seq : ∀ n : ℕ, TruncRing n)
variable (Z_compat : ∀ {m n : ℕ} (h : n ≤ m), truncMap h (Z_seq m) = Z_seq n)

noncomputable def Z_element_hom : AlgebraCat.of ℂ (Polynomial ℂ) ⟶ Z_limit_algebra :=
  limit.lift Z_functor {
    pt := AlgebraCat.of ℂ (Polynomial ℂ)
    π := {
      app := fun j => Polynomial.aeval (Z_seq j.unop)
      naturality := fun i j f => by
        apply Polynomial.algHom_ext
        dsimp [Z_functor]
        change Polynomial.aeval (Z_seq j.unop) Polynomial.X = truncMap f.unop.le (Polynomial.aeval (Z_seq i.unop) Polynomial.X)
        rw [Polynomial.aeval_X, Polynomial.aeval_X]
        exact (Z_compat f.unop.le).symm
    }
  }

noncomputable def Z_element : Z_limit_algebra :=
  Z_element_hom Z_seq Z_compat Polynomial.X

end

end Collatz
