/-
Copyright (c) 2026 Adelic Spectral Zeta Research Group. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adelic Spectral Zeta Research Group
-/
import Mathlib.Algebra.Ring.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.Tactic
import Formalization.Buildings.BuildingAn

open BigOperators

/-!
# Radial Macdonald-Hecke Difference Operators on Affine Buildings of Type Ã_{n-1}

This module formalizes:
1. **Apartment Models for Affine Buildings of Type Ã_{n-1}**:
   - Explicit root coordinate sites for rank 3 (`ApartmentSite3 ≅ ℤ × ℤ`) and rank 4 (`ApartmentSite4 ≅ ℤ × ℤ × ℤ`).
   - Coordinate representations for general rank $n$: `ApartmentSiteN n := Fin (n - 1) → ℤ` and `FullApartmentSite n := Fin n → ℤ`.
   - Coweight displacement vectors $\mathbf{1}_S$ corresponding to fundamental weight directions $\varpi_r$.
   - Canonical root-coordinate projections and verification of rank-4 coweight shifts.

2. **Rank-3 ($\mathrm{PGL}_3$ / $\tilde{\mathrm{A}}_2$) Radial Hecke Operators**:
   - Difference operators $T_1, T_2$ on $\mathbb{Z} \times \mathbb{Z} \to R$.
   - Proof of exact commutation $[T_1, T_2] = 0$ (`radial_commute_A2`).
   - Discrete Laplacian $\Delta_{\tilde{\mathrm{A}}_2} = T_1 + T_2 - 2(q^2 + q + 1)I$ and constant annihilation.

3. **Rank-4 ($\mathrm{PGL}_4$ / $\tilde{\mathrm{A}}_3$) Radial Hecke Operators**:
   - Explicit 4-point difference operator $T_1$, 6-point difference operator $T_2$, and 4-point difference operator $T_3$ on $\mathbb{Z} \times \mathbb{Z} \times \mathbb{Z} \to R$.
   - Exact degree checks matching Gaussian $q$-binomials $\binom{4}{1}_q$, $\binom{4}{2}_q$, $\binom{4}{3}_q$.
   - Proof of all three pairwise commutations:
     * $[T_1, T_2] = 0$ (`radial_commute_T1_T2_A3`)
     * $[T_1, T_3] = 0$ (`radial_commute_T1_T3_A3`)
     * $[T_2, T_3] = 0$ (`radial_commute_T2_T3_A3`)
   - Vanishing of the commutators $[T_1, T_2] = 0$, $[T_1, T_3] = 0$, $[T_2, T_3] = 0$.
   - Discrete multi-Laplacian $\Delta_{\tilde{\mathrm{A}}_3} = T_1 + T_2 + T_3 - d_{reg}(4, q)I$ and constant annihilation.

4. **Universal Commutative Difference Stencil Framework (Arbitrary Rank $n$)**:
   - Universal coweight operators $T_r$ acting on functions $(\text{Fin } n \to \mathbb{Z}) \to R$ via subsets $S \subseteq \text{Fin } n$ of cardinality $r$.
   - Linearity, additivity, and constant evaluation.
   - Proof of universal commutation $[T_r, T_s] = 0$ for any subset sizes $r, s$ over arbitrary commutative rings $R$.
   - Preservation of uniform diagonal translation invariance: $f(x + c \mathbf{1}) = f(x)$.

5. **Multi-Laplacian Dispersion Relations**:
   - Discrete radial Laplacian $\Delta = \sum_{r=1}^{n-1} T_r - d_{reg}(n, w) I$.
   - General proof that $\Delta(\text{const}) = 0$.
   - Joint eigenfunction relation for unramified plane waves (Macdonald spherical functions).

All theorems are proved with **zero sorries** and **zero custom axioms**.
-/

-- ============================================================================
-- Section 1: Apartment Models and Coweight Displacement Vectors
-- ============================================================================

/-- Explicit apartment site coordinates for rank-3 building (PGL₃ / Ã₂): (m, n) ∈ ℤ². -/
abbrev ApartmentSite3 := ℤ × ℤ

/-- Explicit apartment site coordinates for rank-4 building (PGL₄ / Ã₃): (m, n, k) ∈ ℤ³. -/
abbrev ApartmentSite4 := ℤ × ℤ × ℤ

/-- Reduced root-coordinate apartment site for rank n: Fin (n - 1) → ℤ. -/
abbrev ApartmentSiteN (n : ℕ) := Fin (n - 1) → ℤ

/-- Full cocharacter lattice site for rank n before quotienting: Fin n → ℤ. -/
abbrev FullApartmentSite (n : ℕ) := Fin n → ℤ

/-- The coweight displacement vector 𝟏_S ∈ (Fin n → ℤ) associated with a subset S ⊆ Fin n. -/
def coweightShift {n : ℕ} (S : Finset (Fin n)) : FullApartmentSite n :=
  fun i => if i ∈ S then 1 else 0

@[simp]
theorem coweightShift_empty (n : ℕ) : coweightShift (∅ : Finset (Fin n)) = 0 := by
  ext i; simp [coweightShift]

@[simp]
theorem coweightShift_apply_mem {n : ℕ} {S : Finset (Fin n)} {i : Fin n} (h : i ∈ S) :
    coweightShift S i = 1 := by
  simp [coweightShift, h]

@[simp]
theorem coweightShift_apply_not_mem {n : ℕ} {S : Finset (Fin n)} {i : Fin n} (h : i ∉ S) :
    coweightShift S i = 0 := by
  simp [coweightShift, h]

/-- Canonical projection from full coordinates in ℤ⁴ to root coordinates (m, n, k) in ℤ³. -/
def projectA3 (x : FullApartmentSite 4) : ApartmentSite4 :=
  (x 0 - x 1, x 1 - x 2, x 2 - x 3)

/-- The 4 standard basis singletons in Fin 4 corresponding to coweights for T₁. -/
theorem projectA3_shift_e0 : projectA3 (coweightShift {0}) = (1, 0, 0) := rfl
theorem projectA3_shift_e1 : projectA3 (coweightShift {1}) = (-1, 1, 0) := rfl
theorem projectA3_shift_e2 : projectA3 (coweightShift {2}) = (0, -1, 1) := rfl
theorem projectA3_shift_e3 : projectA3 (coweightShift {3}) = (0, 0, -1) := rfl

/-- The 6 two-element subsets in Fin 4 corresponding to coweights for T₂. -/
theorem projectA3_shift_e01 : projectA3 (coweightShift {0, 1}) = (0, 1, 0) := rfl
theorem projectA3_shift_e02 : projectA3 (coweightShift {0, 2}) = (1, -1, 1) := rfl
theorem projectA3_shift_e03 : projectA3 (coweightShift {0, 3}) = (1, 0, -1) := rfl
theorem projectA3_shift_e12 : projectA3 (coweightShift {1, 2}) = (-1, 0, 1) := rfl
theorem projectA3_shift_e13 : projectA3 (coweightShift {1, 3}) = (-1, 1, -1) := rfl
theorem projectA3_shift_e23 : projectA3 (coweightShift {2, 3}) = (0, -1, 0) := rfl

/-- The 4 three-element subsets in Fin 4 corresponding to coweights for T₃. -/
theorem projectA3_shift_e012 : projectA3 (coweightShift {0, 1, 2}) = (0, 0, 1) := rfl
theorem projectA3_shift_e013 : projectA3 (coweightShift {0, 1, 3}) = (0, 1, -1) := rfl
theorem projectA3_shift_e023 : projectA3 (coweightShift {0, 2, 3}) = (1, -1, 0) := rfl
theorem projectA3_shift_e123 : projectA3 (coweightShift {1, 2, 3}) = (-1, 0, 0) := rfl

-- ============================================================================
-- Section 2: Rank-3 (PGL₃ / Ã₂) Radial Hecke Difference Operators
-- ============================================================================

section RadialA2

variable {R : Type*} [CommRing R]

/-- Alias for the rank-3 radial Hecke operator T₁ on ApartmentSite3 := ℤ × ℤ. -/
abbrev radialT1_A2 (q : R) (f : ApartmentSite3 → R) : ApartmentSite3 → R :=
  radialT1 q f

/-- Alias for the rank-3 radial Hecke operator T₂ on ApartmentSite3 := ℤ × ℤ. -/
abbrev radialT2_A2 (q : R) (f : ApartmentSite3 → R) : ApartmentSite3 → R :=
  radialT2 q f

/-- Action of T₁ on constant functions on Ã₂: T₁ c = (q² + q + 1) c. -/
theorem radialT1_const_A2 (q : R) (c : R) (v : ApartmentSite3) :
    radialT1 q (fun _ => c) v = (q^2 + q + 1) * c := by
  cases v; dsimp [radialT1]; ring

/-- Action of T₂ on constant functions on Ã₂: T₂ c = (q² + q + 1) c. -/
theorem radialT2_const_A2 (q : R) (c : R) (v : ApartmentSite3) :
    radialT2 q (fun _ => c) v = (q^2 + q + 1) * c := by
  cases v; dsimp [radialT2]; ring

/-- **Theorem (Commutation of Radial Hecke Operators for Ã₂)**:
    [T₁, T₂] = 0 identically on all apartment functions f : ℤ × ℤ → R. -/
theorem radial_commute_A2 (q : R) (f : ApartmentSite3 → R) :
    radialT1 q (radialT2 q f) = radialT2 q (radialT1 q f) :=
  radial_commute q f

/-- Discrete radial Laplacian for Ã₂: Δ = T₁ + T₂ - 2(q² + q + 1)I. -/
def radialLaplacian_A2 (q : R) (f : ApartmentSite3 → R) : ApartmentSite3 → R :=
  fun v => radialT1 q f v + radialT2 q f v - 2 * (q^2 + q + 1) * f v

/-- Annihilation of constant functions under the Ã₂ radial Laplacian: Δ(c) = 0. -/
theorem radialLaplacian_A2_const (q : R) (c : R) (v : ApartmentSite3) :
    radialLaplacian_A2 q (fun _ => c) v = 0 := by
  dsimp [radialLaplacian_A2]
  rw [radialT1_const_A2, radialT2_const_A2]
  ring

end RadialA2

-- ============================================================================
-- Section 3: Rank-4 (PGL₄ / Ã₃) Radial Hecke Difference Operators
-- ============================================================================

section RadialA3

variable {R : Type*} [CommRing R]

/-- Radial Hecke difference operator T₁ for Ã₃ (PGL₄) acting on f : ℤ × ℤ × ℤ → R:
    (T₁ f)(m, n, k) = q³ f(m+1, n, k) + q² f(m-1, n+1, k) + q f(m, n-1, k+1) + f(m, n, k-1). -/
def radialT1_A3 (q : R) (f : ApartmentSite4 → R) : ApartmentSite4 → R :=
  fun ⟨m, n, k⟩ =>
    q^3 * f (m + 1, n, k) +
    q^2 * f (m - 1, n + 1, k) +
    q * f (m, n - 1, k + 1) +
    f (m, n, k - 1)

/-- Radial Hecke difference operator T₂ for Ã₃ (PGL₄) acting on f : ℤ × ℤ × ℤ → R:
    (T₂ f)(m, n, k) = q⁴ f(m, n+1, k) + q³ f(m+1, n-1, k+1) + q² f(m+1, n, k-1) +
                      q² f(m-1, n, k+1) + q f(m-1, n+1, k-1) + f(m, n-1, k). -/
def radialT2_A3 (q : R) (f : ApartmentSite4 → R) : ApartmentSite4 → R :=
  fun ⟨m, n, k⟩ =>
    q^4 * f (m, n + 1, k) +
    q^3 * f (m + 1, n - 1, k + 1) +
    q^2 * f (m + 1, n, k - 1) +
    q^2 * f (m - 1, n, k + 1) +
    q * f (m - 1, n + 1, k - 1) +
    f (m, n - 1, k)

/-- Radial Hecke difference operator T₃ for Ã₃ (PGL₄) acting on f : ℤ × ℤ × ℤ → R:
    (T₃ f)(m, n, k) = q³ f(m, n, k+1) + q² f(m, n+1, k-1) + q f(m+1, n-1, k) + f(m-1, n, k). -/
def radialT3_A3 (q : R) (f : ApartmentSite4 → R) : ApartmentSite4 → R :=
  fun ⟨m, n, k⟩ =>
    q^3 * f (m, n, k + 1) +
    q^2 * f (m, n + 1, k - 1) +
    q * f (m + 1, n - 1, k) +
    f (m - 1, n, k)

/-- Additivity of T₁ on Ã₃. -/
theorem radialT1_A3_add (q : R) (f g : ApartmentSite4 → R) :
    radialT1_A3 q (f + g) = radialT1_A3 q f + radialT1_A3 q g := by
  ext ⟨m, n, k⟩; dsimp [radialT1_A3]; ring

/-- Additivity of T₂ on Ã₃. -/
theorem radialT2_A3_add (q : R) (f g : ApartmentSite4 → R) :
    radialT2_A3 q (f + g) = radialT2_A3 q f + radialT2_A3 q g := by
  ext ⟨m, n, k⟩; dsimp [radialT2_A3]; ring

/-- Additivity of T₃ on Ã₃. -/
theorem radialT3_A3_add (q : R) (f g : ApartmentSite4 → R) :
    radialT3_A3 q (f + g) = radialT3_A3 q f + radialT3_A3 q g := by
  ext ⟨m, n, k⟩; dsimp [radialT3_A3]; ring

/-- Scalar linearity of T₁ on Ã₃. -/
theorem radialT1_A3_smul (q : R) (c : R) (f : ApartmentSite4 → R) :
    radialT1_A3 q (fun v => c * f v) = fun v => c * radialT1_A3 q f v := by
  ext ⟨m, n, k⟩; dsimp [radialT1_A3]; ring

/-- Scalar linearity of T₂ on Ã₃. -/
theorem radialT2_A3_smul (q : R) (c : R) (f : ApartmentSite4 → R) :
    radialT2_A3 q (fun v => c * f v) = fun v => c * radialT2_A3 q f v := by
  ext ⟨m, n, k⟩; dsimp [radialT2_A3]; ring

/-- Scalar linearity of T₃ on Ã₃. -/
theorem radialT3_A3_smul (q : R) (c : R) (f : ApartmentSite4 → R) :
    radialT3_A3 q (fun v => c * f v) = fun v => c * radialT3_A3 q f v := by
  ext ⟨m, n, k⟩; dsimp [radialT3_A3]; ring

/-- Action of T₁ on constant functions on Ã₃: T₁ c = [4 choose 1]_q * c. -/
theorem radialT1_A3_const (q : R) (c : R) (v : ApartmentSite4) :
    radialT1_A3 q (fun _ => c) v = (q^3 + q^2 + q + 1) * c := by
  cases v; dsimp [radialT1_A3]; ring

/-- Action of T₂ on constant functions on Ã₃: T₂ c = [4 choose 2]_q * c. -/
theorem radialT2_A3_const (q : R) (c : R) (v : ApartmentSite4) :
    radialT2_A3 q (fun _ => c) v = (q^4 + q^3 + 2 * q^2 + q + 1) * c := by
  cases v; dsimp [radialT2_A3]; ring

/-- Action of T₃ on constant functions on Ã₃: T₃ c = [4 choose 3]_q * c. -/
theorem radialT3_A3_const (q : R) (c : R) (v : ApartmentSite4) :
    radialT3_A3 q (fun _ => c) v = (q^3 + q^2 + q + 1) * c := by
  cases v; dsimp [radialT3_A3]; ring

/-- **Theorem (Commutation of T₁ and T₂ on Ã₃)**:
    [T₁, T₂] = 0 identically on all apartment functions f : ℤ × ℤ × ℤ → R. -/
theorem radial_commute_T1_T2_A3 (q : R) (f : ApartmentSite4 → R) :
    radialT1_A3 q (radialT2_A3 q f) = radialT2_A3 q (radialT1_A3 q f) := by
  ext ⟨m, n, k⟩; dsimp [radialT1_A3, radialT2_A3]; ring_nf

/-- **Theorem (Commutation of T₁ and T₃ on Ã₃)**:
    [T₁, T₃] = 0 identically on all apartment functions f : ℤ × ℤ × ℤ → R. -/
theorem radial_commute_T1_T3_A3 (q : R) (f : ApartmentSite4 → R) :
    radialT1_A3 q (radialT3_A3 q f) = radialT3_A3 q (radialT1_A3 q f) := by
  ext ⟨m, n, k⟩; dsimp [radialT1_A3, radialT3_A3]; ring_nf

/-- **Theorem (Commutation of T₂ and T₃ on Ã₃)**:
    [T₂, T₃] = 0 identically on all apartment functions f : ℤ × ℤ × ℤ → R. -/
theorem radial_commute_T2_T3_A3 (q : R) (f : ApartmentSite4 → R) :
    radialT2_A3 q (radialT3_A3 q f) = radialT3_A3 q (radialT2_A3 q f) := by
  ext ⟨m, n, k⟩; dsimp [radialT2_A3, radialT3_A3]; ring_nf

/-- Commutator [T₁, T₂] = T₁ ∘ T₂ - T₂ ∘ T₁ vanishes identically on Ã₃. -/
theorem radialCommutator_T1_T2_A3 (q : R) (f : ApartmentSite4 → R) :
    radialT1_A3 q (radialT2_A3 q f) - radialT2_A3 q (radialT1_A3 q f) = 0 := by
  rw [radial_commute_T1_T2_A3, sub_self]

/-- Commutator [T₁, T₃] = T₁ ∘ T₃ - T₃ ∘ T₁ vanishes identically on Ã₃. -/
theorem radialCommutator_T1_T3_A3 (q : R) (f : ApartmentSite4 → R) :
    radialT1_A3 q (radialT3_A3 q f) - radialT3_A3 q (radialT1_A3 q f) = 0 := by
  rw [radial_commute_T1_T3_A3, sub_self]

/-- Commutator [T₂, T₃] = T₂ ∘ T₃ - T₃ ∘ T₂ vanishes identically on Ã₃. -/
theorem radialCommutator_T2_T3_A3 (q : R) (f : ApartmentSite4 → R) :
    radialT2_A3 q (radialT3_A3 q f) - radialT3_A3 q (radialT2_A3 q f) = 0 := by
  rw [radial_commute_T2_T3_A3, sub_self]

/-- Total regular degree polynomial on the Ã₃ apartment:
    d_{reg}(4, q) = [4 choose 1]_q + [4 choose 2]_q + [4 choose 3]_q
                  = 2(q³ + q² + q + 1) + (q⁴ + q³ + 2q² + q + 1). -/
def regularDegreeA3 (q : R) : R :=
  2 * (q^3 + q^2 + q + 1) + (q^4 + q^3 + 2 * q^2 + q + 1)

/-- Simplified formula for the total regular degree polynomial:
    d_{reg}(4, q) = q⁴ + 3q³ + 4q² + 3q + 3. -/
theorem regularDegreeA3_eq (q : R) :
    regularDegreeA3 q = q^4 + 3 * q^3 + 4 * q^2 + 3 * q + 3 := by
  dsimp [regularDegreeA3]; ring

/-- Discrete radial multi-Laplacian for Ã₃:
    Δ = T₁ + T₂ + T₃ - d_{reg}(4, q) I. -/
def radialLaplacian_A3 (q : R) (f : ApartmentSite4 → R) : ApartmentSite4 → R :=
  fun v => radialT1_A3 q f v + radialT2_A3 q f v + radialT3_A3 q f v - regularDegreeA3 q * f v

/-- Annihilation of constant functions under the Ã₃ discrete multi-Laplacian: Δ(c) = 0. -/
theorem radialLaplacian_A3_const (q : R) (c : R) (v : ApartmentSite4) :
    radialLaplacian_A3 q (fun _ => c) v = 0 := by
  dsimp [radialLaplacian_A3, regularDegreeA3]
  rw [radialT1_A3_const, radialT2_A3_const, radialT3_A3_const]
  ring

end RadialA3

-- ============================================================================
-- Section 4: General Rank Commutative Difference Stencil Framework
-- ============================================================================

section GeneralRank

variable {R : Type*} [CommRing R]

/-- The radial Hecke difference operator T_r of type r acting on functions f : (Fin n → ℤ) → R.
    Constructed by summing over all r-element subsets S ⊆ Fin n with weight function w(S):
    (T_r f)(x) = ∑_{S ⊆ Fin n, |S| = r} w(S) f(x + 𝟏_S). -/
def radialTr (n : ℕ) (r : ℕ) (w : Finset (Fin n) → R)
    (f : FullApartmentSite n → R) (x : FullApartmentSite n) : R :=
  ∑ S ∈ Finset.powersetCard r (Finset.univ : Finset (Fin n)), w S * f (x + coweightShift S)

/-- Additivity of the general radial Hecke operator T_r. -/
theorem radialTr_add (n r : ℕ) (w : Finset (Fin n) → R)
    (f g : FullApartmentSite n → R) (x : FullApartmentSite n) :
    radialTr n r w (f + g) x = radialTr n r w f x + radialTr n r w g x := by
  dsimp [radialTr]
  rw [← Finset.sum_add_distrib]
  refine Finset.sum_congr rfl fun S _ => by ring

/-- Scalar linearity of the general radial Hecke operator T_r. -/
theorem radialTr_smul (n r : ℕ) (w : Finset (Fin n) → R) (c : R)
    (f : FullApartmentSite n → R) (x : FullApartmentSite n) :
    radialTr n r w (fun v => c * f v) x = c * radialTr n r w f x := by
  dsimp [radialTr]
  rw [Finset.mul_sum]
  refine Finset.sum_congr rfl fun S _ => by ring

/-- Action of the general radial Hecke operator T_r on constant functions:
    (T_r c)(x) = (∑_{|S|=r} w(S)) * c. -/
theorem radialTr_const (n r : ℕ) (w : Finset (Fin n) → R) (c : R) (x : FullApartmentSite n) :
    radialTr n r w (fun _ => c) x =
      (∑ S ∈ Finset.powersetCard r (Finset.univ : Finset (Fin n)), w S) * c := by
  simp_rw [radialTr, ← Finset.sum_mul]

/-- **Main Theorem (Universal Commutation of Radial Difference Operators)**:
    For any two subset sizes r and s in arbitrary rank n, the convolution difference
    stencils T_r and T_s commute identically:
    T_r ∘ T_s = T_s ∘ T_r. -/
theorem radial_commute_general (n r s : ℕ) (w : Finset (Fin n) → R)
    (f : FullApartmentSite n → R) :
    radialTr n r w (radialTr n s w f) = radialTr n s w (radialTr n r w f) := by
  ext x
  simp_rw [radialTr, Finset.mul_sum]
  rw [Finset.sum_comm]
  refine Finset.sum_congr rfl fun S _ => Finset.sum_congr rfl fun T _ => ?_
  rw [mul_left_comm, add_right_comm]

/-- A function on FullApartmentSite n is invariant under uniform diagonal translations. -/
def IsTranslationInvariant {n : ℕ} (f : FullApartmentSite n → R) : Prop :=
  ∀ (x : FullApartmentSite n) (c : ℤ), f (fun i => x i + c) = f x

/-- **Theorem (Preservation of Translation Invariance)**:
    Radial Hecke operators preserve uniform diagonal translation invariance,
    and hence descend canonically to the quotient apartment ℤⁿ / ℤ(1,...,1). -/
theorem radialTr_preserves_translation_invariance (n r : ℕ) (w : Finset (Fin n) → R)
    (f : FullApartmentSite n → R) (hf : IsTranslationInvariant f) :
    IsTranslationInvariant (radialTr n r w f) := fun x c => by
  dsimp [radialTr]
  refine Finset.sum_congr rfl fun S _ => ?_
  congr 1
  have h_arg : (fun i => x i + c) + coweightShift S = fun i => (x + coweightShift S) i + c :=
    funext fun i => add_right_comm (x i) c (coweightShift S i)
  rw [h_arg, hf]

end GeneralRank

-- ============================================================================
-- Section 5: Discrete Multi-Laplacian Dispersion Relation
-- ============================================================================

section MultiLaplacian

variable {R : Type*} [CommRing R]

/-- The total regular degree of the general radial building model:
    d_{reg}(n, w) = ∑_{r=1}^{n-1} ∑_{|S|=r} w(S). -/
def totalRadialDegree (n : ℕ) (w : Finset (Fin n) → R) : R :=
  ∑ r ∈ Finset.Ico 1 n, ∑ S ∈ Finset.powersetCard r (Finset.univ : Finset (Fin n)), w S

/-- The general discrete radial multi-Laplacian operator:
    Δ f(x) = (∑_{r=1}^{n-1} T_r f)(x) - d_{reg}(n, w) f(x). -/
def radialLaplacianGeneral (n : ℕ) (w : Finset (Fin n) → R)
    (f : FullApartmentSite n → R) (x : FullApartmentSite n) : R :=
  (∑ r ∈ Finset.Ico 1 n, radialTr n r w f x) - totalRadialDegree n w * f x

/-- Additivity of the general discrete radial multi-Laplacian. -/
theorem radialLaplacianGeneral_add (n : ℕ) (w : Finset (Fin n) → R)
    (f g : FullApartmentSite n → R) (x : FullApartmentSite n) :
    radialLaplacianGeneral n w (f + g) x =
      radialLaplacianGeneral n w f x + radialLaplacianGeneral n w g x := by
  dsimp [radialLaplacianGeneral]
  simp_rw [radialTr_add, Finset.sum_add_distrib]
  ring

/-- Scalar linearity of the general discrete radial multi-Laplacian. -/
theorem radialLaplacianGeneral_smul (n : ℕ) (w : Finset (Fin n) → R) (c : R)
    (f : FullApartmentSite n → R) (x : FullApartmentSite n) :
    radialLaplacianGeneral n w (fun v => c * f v) x =
      c * radialLaplacianGeneral n w f x := by
  dsimp [radialLaplacianGeneral]
  simp_rw [radialTr_smul, ← Finset.mul_sum]
  ring

/-- **Theorem (Multi-Laplacian Annihilation on Constant Functions)**:
    For any constant function f(x) = c, the discrete multi-Laplacian vanishes identically:
    Δ(c) = 0. -/
theorem radialLaplacianGeneral_const (n : ℕ) (w : Finset (Fin n) → R) (c : R)
    (x : FullApartmentSite n) :
    radialLaplacianGeneral n w (fun _ => c) x = 0 := by
  dsimp [radialLaplacianGeneral, totalRadialDegree]
  simp_rw [radialTr_const, ← Finset.sum_mul]
  ring

/-- Structure capturing an unramified exponential plane wave ψ_z with shift factors z_i. -/
structure PlaneWave (n : ℕ) (z : Fin n → R) (ψ : FullApartmentSite n → R) : Prop where
  shift_coweight : ∀ (S : Finset (Fin n)) (x : FullApartmentSite n),
    ψ (x + coweightShift S) = (∏ i ∈ S, z i) * ψ x

/-- **Theorem (Macdonald Joint Eigenvalue Equation for General Radial Hecke Operators)**:
    Every unramified exponential plane wave ψ_z is an exact eigenfunction of every radial
    Hecke operator T_r, with eigenvalue given by the weighted elementary symmetric sum
    E_r(w, z) = ∑_{|S|=r} w(S) ∏_{i ∈ S} z_i. -/
theorem radialTr_eigenvalue (n r : ℕ) (w : Finset (Fin n) → R) (z : Fin n → R)
    (ψ : FullApartmentSite n → R) (hψ : PlaneWave n z ψ) (x : FullApartmentSite n) :
    radialTr n r w ψ x =
      (∑ S ∈ Finset.powersetCard r (Finset.univ : Finset (Fin n)), w S * (∏ i ∈ S, z i)) * ψ x := by
  simp_rw [radialTr, hψ.shift_coweight, ← mul_assoc, ← Finset.sum_mul]

/-- **Theorem (Discrete Multi-Laplacian Dispersion Relation)**:
    Under the discrete multi-Laplacian Δ, an unramified plane wave ψ_z has exact eigenvalue:
    λ_Δ(w, z) = ∑_{r=1}^{n-1} E_r(w, z) - d_{reg}(n, w). -/
theorem radialLaplacianGeneral_eigenvalue (n : ℕ) (w : Finset (Fin n) → R) (z : Fin n → R)
    (ψ : FullApartmentSite n → R) (hψ : PlaneWave n z ψ) (x : FullApartmentSite n) :
    radialLaplacianGeneral n w ψ x =
      ((∑ r ∈ Finset.Ico 1 n,
          ∑ S ∈ Finset.powersetCard r (Finset.univ : Finset (Fin n)), w S * (∏ i ∈ S, z i)) -
        totalRadialDegree n w) * ψ x := by
  simp only [radialLaplacianGeneral, radialTr_eigenvalue _ _ _ _ _ hψ, ← Finset.sum_mul, sub_mul]

end MultiLaplacian
