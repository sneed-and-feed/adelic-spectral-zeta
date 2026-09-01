/-
Copyright (c) 2026 Antigravity Mathematical Research Team. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Antigravity Mathematical Research Team
-/
import Mathlib.RingTheory.PowerSeries.Basic
import Mathlib.RingTheory.PowerSeries.WellKnown
import Mathlib.LinearAlgebra.Trace
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Nat.Factorial.Basic
import Formalization.Dynamics.CollatzRelMatrix

/-!
# Truncated Transfer Operators, Trace Power Series, and Dynamical Zeta Functions

This module formalizes the finite-level truncated transfer operator matrix $S_n$ over $\mathbb{C}$,
its trace sequence $a_k = \operatorname{Tr}(S_n^k)$, the associated formal trace power series
$S_n(t) = \sum_{k=1}^\infty \frac{a_k}{k} t^k$, the dynamical zeta function $Z_n(t) = \exp(S_n(t))$,
the Fredholm determinant $\det(I - t S_n)$, and the Rational Zeta Conjecture relating them.

It also formalizes the truncation quotient rings $\mathbb{C}[[t]] / (t^{2^{n+1}})$ and their
canonical projection homomorphisms.

### Mathematical Notes
- **Rational Zeta Formulation:** The dynamical zeta function $Z_n(t)$ is defined as the formal
  power series exponential of the trace series $S_n(t)$. The Rational Zeta Conjecture states that
  $Z_n(t) \cdot \det(I - t S_n) = 1$, representing the Fredholm determinant identity at level $n$.
- **Projective Limit Inconsistency:** As documented below, local trace cycles do not form a
  compatible projective system across covering sheet levels (e.g. $a_2(S_2) = 4$ while $a_2(S_3) = 0$),
  so global dynamical zeta behavior is analyzed via the factored Fredholm determinant tower rather
  than naive projective limits of trace series.
-/

open scoped BigOperators
open CollatzDirMatrix

namespace Collatz

noncomputable section

/-- The truncated transfer operator at level $n$ as a matrix over $\mathbb{C}$. -/
def Sn (n : ℕ) (hn : n ≥ 2) : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ :=
  Matrix.map (twistedDirMatrix hn) (fun x => (x : ℂ))

/-- The sequence of traces $a_k = \operatorname{Tr}(S_n^k)$. -/
def trace_k (n : ℕ) (hn : n ≥ 2) (k : ℕ) : ℂ :=
  Matrix.trace (Sn n hn ^ k)

open PowerSeries

/-- The formal trace power series $S_n(t) = \sum_{k=1}^\infty \frac{\operatorname{Tr}(S_n^k)}{k} t^k$. -/
def Sn_series (n : ℕ) (hn : n ≥ 2) : PowerSeries ℂ :=
  PowerSeries.mk (fun k => if k = 0 then 0 else trace_k n hn k / (k : ℂ))

/-- Formal power series exponential for power series over a commutative $\mathbb{Q}$-algebra.
    Given $f(t) \in R[[t]]$ with $f(0) = 0$, $\exp(f(t)) = \sum_{j=0}^\infty \frac{f(t)^j}{j!}$.
    Since the $m$-th coefficient only depends on $j \le m$, this is a well-defined formal power series. -/
def PowerSeries.exp (R : Type*) [CommRing R] [Algebra ℚ R] (f : PowerSeries R) : PowerSeries R :=
  PowerSeries.mk fun m => ∑ j ∈ Finset.range (m + 1), (algebraMap ℚ R (1 / Nat.factorial j)) * (coeff m) (f ^ j)

/-- The finite-level dynamical zeta function $Z_n(t) = \exp(S_n(t))$ defined via the trace series. -/
def DynamicalZeta (n : ℕ) (hn : n ≥ 2) : PowerSeries ℂ :=
  PowerSeries.exp ℂ (Sn_series n hn)

/-- The Fredholm determinant $\det(I - t S_n)$ as a formal power series over $\mathbb{C}$. -/
def det_I_minus_t_Sn (n : ℕ) (hn : n ≥ 2) : PowerSeries ℂ :=
  let I : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (PowerSeries ℂ) := 1
  let tSn : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) (PowerSeries ℂ) :=
    (PowerSeries.X : PowerSeries ℂ) • (Matrix.map (Sn n hn) (algebraMap ℂ (PowerSeries ℂ)))
  (I - tSn).det

/-- The Rational Zeta Conjecture stating that the dynamical zeta function agrees with the
inverse Fredholm determinant $\det(I - t S_n)^{-1}$, i.e., $Z_n(t) \cdot \det(I - t S_n) = 1$. -/
def RationalZetaConjecture (n : ℕ) (hn : n ≥ 2) : Prop :=
  DynamicalZeta n hn * det_I_minus_t_Sn n hn = 1

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
