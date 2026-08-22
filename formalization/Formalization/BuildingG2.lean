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

open BigOperators

/-!
# Adjacency and Radial Macdonald Difference Operators on Exceptional 2D Affine Buildings of Type G̃₂

This module formalizes the discrete geometric and representation-theoretic structure
of 2D affine Bruhat-Tits buildings of exceptional Lie type G̃₂:

1. **Building Geometry of Type G̃₂**:
   - Short root adjacency relation `adjShort` and long root adjacency relation `adjLong`.
   - Adjacency operators `adjOpShort` and `adjOpLong` on functions `f : V → R`.
   - 12-point discrete building Laplacian `Δ_G2 = A_short + A_long - d_reg(q) I`.
   - Vanishing of the discrete Laplacian on constant functions `Δ_G2(c) = 0`.

2. **2D Apartment Model and 12 Root Displacement Vectors**:
   - The triangular/hexagonal apartment lattice site `V(A) ≅ ℤ²`.
   - The 6 short root displacement vectors: `±(1, 0), ±(0, 1), ±(1, -1)`.
   - The 6 long root displacement vectors: `±(2, -1), ±(1, 1), ±(1, -2)`.
   - Root system relations linking long roots as sums of short roots.

3. **Radial Weyl Chamber Difference Operators**:
   - Short-root radial Hecke difference operator `T_short`:
     `(T_short f)(m, n) = q² f(m+1, n) + q f(m-1, n+1) + f(m, n-1) + q² f(m, n+1) + q f(m+1, n-1) + f(m-1, n)`
   - Long-root radial Hecke difference operator `T_long`:
     `(T_long f)(m, n) = q⁴ f(m+1, n+1) + q³ f(m+2, n-1) + q³ f(m-1, n+2) + q f(m+1, n-2) + q f(m-2, n+1) + f(m-1, n-1)`
   - Proof of exact algebraic commutation `[T_short, T_long] = 0` (`radial_g2_commute`).
   - Identical vanishing of the radial commutator `radialG2Commutator_eq_zero`.

4. **G₂ Satake Parameter System and Macdonald Spherical Recurrence**:
   - Unramified G₂ Satake parameters `(z₁, z₂, z₃)` with `z₁ z₂ z₃ = 1`.
   - Elementary symmetric invariants `e₁(z)`, `e₂(z)`, and character polynomials `χ_short(z)`, `χ_long(z)`.
   - Macdonald spherical wave shifts along the 12 root directions.
   - Exact eigenvalue theorems:
     `T_short ψ = q (e₁ + e₂) ψ`
     `T_long ψ = q² (e₁ e₂ - 3) ψ`
     `Δ_G2 ψ = (q(e₁ + e₂) + q²(e₁ e₂ - 3) - d_reg(q)) ψ`.

5. **Weyl Group W(G₂) ≅ D₆ (Dihedral Group of Order 12)**:
   - Full 12-element Weyl group action on G₂ Satake systems.
   - Exact Weyl invariance of the fundamental character invariants `χ_short` and `χ_long`.
   - Symmetrized Macdonald spherical wavefunctions `symmetrizedMacdonaldG2`.
   - Joint eigenbasis theorems for symmetrized Macdonald functions under `T_short`, `T_long`, and `Δ_G2`.

6. **Non-Archimedean Ramanujan Spectral Gap on G̃₂ Buildings**:
   - Regular degree `d_reg(q) = 2(q² + q + 1) + (q⁴ + 2q³ + 2q + 1) = q⁴ + 2q³ + 2q² + 4q + 3`.
   - Maximum tempered eigenvalue `λ_{temp, max}(q) = (6q + 6q²) - d_reg(q)`.
   - Exact non-Archimedean Ramanujan spectral gap identity:
     `Gap(Δ_G2) = 0 - λ_{temp, max} = (q - 1)² (q + 1) (q + 3)`.

All theorems are proved with **zero sorrys**.
-/

-- ============================================================================
-- Section 1: Abstract Building Structure of Type G̃₂ and Adjacency Operators
-- ============================================================================

/-- Structure representing a 2D affine Bruhat-Tits building of type G̃₂ with parameter q. -/
structure BuildingG2 (V : Type*) (q : ℕ) where
  /-- Short-root adjacency relation between neighboring vertices -/
  adjShort : V → V → Prop
  /-- Long-root adjacency relation between neighboring vertices -/
  adjLong : V → V → Prop
  /-- Symmetry of short adjacency -/
  adjShort_symm : ∀ {u v : V}, adjShort u v ↔ adjShort v u
  /-- Symmetry of long adjacency -/
  adjLong_symm : ∀ {u v : V}, adjLong u v ↔ adjLong v u
  /-- Finite neighbor sets along short roots -/
  neighborsShort : V → Finset V
  /-- Finite neighbor sets along long roots -/
  neighborsLong : V → Finset V
  /-- Correctness of short neighbor set -/
  mem_neighborsShort : ∀ (u v : V), v ∈ neighborsShort u ↔ adjShort u v
  /-- Correctness of long neighbor set -/
  mem_neighborsLong : ∀ (u v : V), v ∈ neighborsLong u ↔ adjLong u v
  /-- Regularity of short-root degree: d_short(q) = 2(q² + q + 1) -/
  card_neighborsShort : ∀ (v : V), (neighborsShort v).card = 2 * (q^2 + q + 1)
  /-- Regularity of long-root degree: d_long(q) = q⁴ + 2q³ + 2q + 1 -/
  card_neighborsLong : ∀ (v : V), (neighborsLong v).card = q^4 + 2 * q^3 + 2 * q + 1

namespace BuildingG2

variable {V : Type*} {q : ℕ} (B : BuildingG2 V q) {R : Type*} [CommRing R]

/-- Short-root adjacency operator A_short f(v) = ∑_{w ∼_short v} f(w) -/
def adjOpShort (f : V → R) (v : V) : R :=
  ∑ w in B.neighborsShort v, f w

/-- Long-root adjacency operator A_long f(v) = ∑_{w ∼_long v} f(w) -/
def adjOpLong (f : V → R) (v : V) : R :=
  ∑ w in B.neighborsLong v, f w

/-- Discrete Laplacian operator on the G̃₂ building:
    Δ_G2 f(v) = (A_short f)(v) + (A_long f)(v) - (2(q² + q + 1) + (q⁴ + 2q³ + 2q + 1)) f(v) -/
def discreteLaplacian (f : V → R) (v : V) : R :=
  B.adjOpShort f v + B.adjOpLong f v - (2 * (q^2 + q + 1 : R) + (q^4 + 2 * q^3 + 2 * q + 1 : R)) * f v

theorem adjOpShort_add (f g : V → R) (v : V) :
    B.adjOpShort (f + g) v = B.adjOpShort f v + B.adjOpShort g v := by
  dsimp [adjOpShort]
  rw [← Finset.sum_add_distrib]

theorem adjOpLong_add (f g : V → R) (v : V) :
    B.adjOpLong (f + g) v = B.adjOpLong f v + B.adjOpLong g v := by
  dsimp [adjOpLong]
  rw [← Finset.sum_add_distrib]

theorem adjOpShort_smul (c : R) (f : V → R) (v : V) :
    B.adjOpShort (fun x => c * f x) v = c * B.adjOpShort f v := by
  dsimp [adjOpShort]
  rw [Finset.mul_sum]

theorem adjOpLong_smul (c : R) (f : V → R) (v : V) :
    B.adjOpLong (fun x => c * f x) v = c * B.adjOpLong f v := by
  dsimp [adjOpLong]
  rw [Finset.mul_sum]

theorem adjOpShort_const (c : R) (v : V) :
    B.adjOpShort (fun _ => c) v = (2 * (q^2 + q + 1 : R)) * c := by
  dsimp [adjOpShort]
  rw [Finset.sum_const, B.card_neighborsShort]
  simp [nsmul_eq_mul]

theorem adjOpLong_const (c : R) (v : V) :
    B.adjOpLong (fun _ => c) v = (q^4 + 2 * q^3 + 2 * q + 1 : R) * c := by
  dsimp [adjOpLong]
  rw [Finset.sum_const, B.card_neighborsLong]
  simp [nsmul_eq_mul]

/-- The discrete Laplacian on the G̃₂ building annihilates constant functions identically. -/
theorem discreteLaplacian_const (c : R) (v : V) :
    B.discreteLaplacian (fun _ => c) v = 0 := by
  dsimp [discreteLaplacian]
  rw [adjOpShort_const, adjOpLong_const]
  ring

end BuildingG2

-- ============================================================================
-- Section 2: 2D G₂ Apartment Model and 12 Root Displacement Vectors
-- ============================================================================

/-- Apartment lattice site in ℤ². -/
abbrev ApartmentSiteG2 := ℤ × ℤ

/-- The 6 short root displacement vectors in the standard weight basis:
    v_s1 = (1, 0)
    v_s2 = (-1, 0)
    v_s3 = (0, 1)
    v_s4 = (0, -1)
    v_s5 = (1, -1)
    v_s6 = (-1, 1) -/
def v_s1 : ApartmentSiteG2 := (1, 0)
def v_s2 : ApartmentSiteG2 := (-1, 0)
def v_s3 : ApartmentSiteG2 := (0, 1)
def v_s4 : ApartmentSiteG2 := (0, -1)
def v_s5 : ApartmentSiteG2 := (1, -1)
def v_s6 : ApartmentSiteG2 := (-1, 1)

/-- The 6 long root displacement vectors in the standard weight basis:
    v_l1 = (2, -1)
    v_l2 = (-2, 1)
    v_l3 = (1, 1)
    v_l4 = (-1, -1)
    v_l5 = (1, -2)
    v_l6 = (-1, 2) -/
def v_l1 : ApartmentSiteG2 := (2, -1)
def v_l2 : ApartmentSiteG2 := (-2, 1)
def v_l3 : ApartmentSiteG2 := (1, 1)
def v_l4 : ApartmentSiteG2 := (-1, -1)
def v_l5 : ApartmentSiteG2 := (1, -2)
def v_l6 : ApartmentSiteG2 := (-1, 2)

/-- Addition of displacement vectors on apartment sites. -/
def siteShift (v : ApartmentSiteG2) (d : ApartmentSiteG2) : ApartmentSiteG2 :=
  (v.1 + d.1, v.2 + d.2)

/-- Root relation: long root v_l1 is the sum of short roots v_s1 and v_s5. -/
theorem root_rel_l1 : v_l1 = (v_s1.1 + v_s5.1, v_s1.2 + v_s5.2) := rfl

/-- Root relation: long root v_l2 is the sum of short roots v_s2 and v_s6. -/
theorem root_rel_l2 : v_l2 = (v_s2.1 + v_s6.1, v_s2.2 + v_s6.2) := rfl

/-- Root relation: long root v_l3 is the sum of short roots v_s1 and v_s3. -/
theorem root_rel_l3 : v_l3 = (v_s1.1 + v_s3.1, v_s1.2 + v_s3.2) := rfl

/-- Root relation: long root v_l4 is the sum of short roots v_s2 and v_s4. -/
theorem root_rel_l4 : v_l4 = (v_s2.1 + v_s4.1, v_s2.2 + v_s4.2) := rfl

/-- Root relation: long root v_l5 is the sum of short roots v_s4 and v_s5. -/
theorem root_rel_l5 : v_l5 = (v_s4.1 + v_s5.1, v_s4.2 + v_s5.2) := rfl

/-- Root relation: long root v_l6 is the sum of short roots v_s3 and v_s6. -/
theorem root_rel_l6 : v_l6 = (v_s3.1 + v_s6.1, v_s3.2 + v_s6.2) := rfl

/-- The Finset of 6 short root displacement vectors. -/
def aptShortRoots : Finset ApartmentSiteG2 :=
  { v_s1, v_s2, v_s3, v_s4, v_s5, v_s6 }

/-- The Finset of 6 long root displacement vectors. -/
def aptLongRoots : Finset ApartmentSiteG2 :=
  { v_l1, v_l2, v_l3, v_l4, v_l5, v_l6 }

/-- The total root system of G₂ consisting of 12 roots. -/
def aptAllRoots : Finset ApartmentSiteG2 :=
  aptShortRoots ∪ aptLongRoots

/-- The 6 short root displacement vectors are pairwise distinct. -/
theorem card_aptShortRoots : aptShortRoots.card = 6 := by
  decide

/-- The 6 long root displacement vectors are pairwise distinct. -/
theorem card_aptLongRoots : aptLongRoots.card = 6 := by
  decide

/-- The short roots and long roots are disjoint. -/
theorem disjoint_short_long_roots : Disjoint aptShortRoots aptLongRoots := by
  decide

/-- The total G₂ root system has exactly 12 roots. -/
theorem card_aptAllRoots : aptAllRoots.card = 12 := by
  decide

-- ============================================================================
-- Section 3: Radial Difference Operators T_short and T_long
-- ============================================================================

variable {R : Type*} [CommRing R]

/-- Radial Hecke difference operator T_short acting on functions f : ℤ × ℤ → R:
    (T_short f)(m, n) = q² f(m+1, n) + q f(m-1, n+1) + f(m, n-1) +
                        q² f(m, n+1) + q f(m+1, n-1) + f(m-1, n). -/
def radialT_short (q : R) (f : ℤ × ℤ → R) : ℤ × ℤ → R :=
  fun ⟨m, n⟩ =>
    q^2 * f (m + 1, n) +
    q * f (m - 1, n + 1) +
    f (m, n - 1) +
    q^2 * f (m, n + 1) +
    q * f (m + 1, n - 1) +
    f (m - 1, n)

/-- Radial Hecke difference operator T_long acting on functions f : ℤ × ℤ → R:
    (T_long f)(m, n) = q⁴ f(m+1, n+1) + q³ f(m+2, n-1) + q³ f(m-1, n+2) +
                       q f(m+1, n-2) + q f(m-2, n+1) + f(m-1, n-1). -/
def radialT_long (q : R) (f : ℤ × ℤ → R) : ℤ × ℤ → R :=
  fun ⟨m, n⟩ =>
    q^4 * f (m + 1, n + 1) +
    q^3 * f (m + 2, n - 1) +
    q^3 * f (m - 1, n + 2) +
    q * f (m + 1, n - 2) +
    q * f (m - 2, n + 1) +
    f (m - 1, n - 1)

/-- Regular vertex degree on the G̃₂ building:
    d_reg(q) = 2(q² + q + 1) + (q⁴ + 2q³ + 2q + 1) = q⁴ + 2q³ + 2q² + 4q + 3. -/
def regularDegreeG2 (q : R) : R :=
  2 * (q^2 + q + 1) + (q^4 + 2 * q^3 + 2 * q + 1)

/-- Radial discrete Laplacian Δ_G2 = T_short + T_long - d_reg(q) I. -/
def radialLaplacianG2 (q : R) (f : ℤ × ℤ → R) : ℤ × ℤ → R :=
  fun v => radialT_short q f v + radialT_long q f v - regularDegreeG2 q * f v

theorem radialT_short_add (q : R) (f g : ℤ × ℤ → R) :
    radialT_short q (f + g) = radialT_short q f + radialT_short q g := by
  ext ⟨m, n⟩
  dsimp [radialT_short]
  ring

theorem radialT_long_add (q : R) (f g : ℤ × ℤ → R) :
    radialT_long q (f + g) = radialT_long q f + radialT_long q g := by
  ext ⟨m, n⟩
  dsimp [radialT_long]
  ring

theorem radialT_short_smul (q : R) (c : R) (f : ℤ × ℤ → R) :
    radialT_short q (fun v => c * f v) = fun v => c * radialT_short q f v := by
  ext ⟨m, n⟩
  dsimp [radialT_short]
  ring

theorem radialT_long_smul (q : R) (c : R) (f : ℤ × ℤ → R) :
    radialT_long q (fun v => c * f v) = fun v => c * radialT_long q f v := by
  ext ⟨m, n⟩
  dsimp [radialT_long]
  ring

theorem radialT_short_const (q : R) (c : R) (v : ℤ × ℤ) :
    radialT_short q (fun _ => c) v = 2 * (q^2 + q + 1) * c := by
  dsimp [radialT_short]
  ring

theorem radialT_long_const (q : R) (c : R) (v : ℤ × ℤ) :
    radialT_long q (fun _ => c) v = (q^4 + 2 * q^3 + 2 * q + 1) * c := by
  dsimp [radialT_long]
  ring

/-- The radial discrete Laplacian annihilates constant functions identically. -/
theorem radialLaplacianG2_const (q : R) (c : R) (v : ℤ × ℤ) :
    radialLaplacianG2 q (fun _ => c) v = 0 := by
  dsimp [radialLaplacianG2, regularDegreeG2]
  rw [radialT_short_const, radialT_long_const]
  ring

/-- Commutator [T_short, T_long] = T_short ∘ T_long - T_long ∘ T_short. -/
def radialG2Commutator (q : R) (f : ℤ × ℤ → R) : ℤ × ℤ → R :=
  fun v => radialT_short q (radialT_long q f) v - radialT_long q (radialT_short q f) v

/-- **Main Commutation Theorem**: The short-root and long-root radial Hecke difference
    operators commute identically: [T_short, T_long] = 0. -/
theorem radial_g2_commute (q : R) (f : ℤ × ℤ → R) :
    radialT_short q (radialT_long q f) = radialT_long q (radialT_short q f) := by
  ext ⟨m, n⟩
  dsimp [radialT_short, radialT_long]
  ring

/-- The radial G₂ commutator is identically zero on all lattice functions. -/
theorem radialG2Commutator_eq_zero (q : R) (f : ℤ × ℤ → R) :
    radialG2Commutator q f = 0 := by
  ext ⟨m, n⟩
  dsimp [radialG2Commutator, radialT_short, radialT_long]
  ring

/-- Exact symmetric convolution stencil identity for T_short ∘ T_long. -/
theorem radial_g2_comp_stencil (q : R) (f : ℤ × ℤ → R) (m n : ℤ) :
    radialT_short q (radialT_long q f) (m, n) =
      radialT_long q (radialT_short q f) (m, n) := by
  dsimp [radialT_short, radialT_long]
  ring

-- ============================================================================
-- Section 4: G₂ Satake Parameter System and Macdonald Spherical Recurrence
-- ============================================================================

/-- A system of Satake parameters for G₂ with base parameter q.
    z₁, z₂, z₃ represent the unramified spherical character with z₁ * z₂ * z₃ = 1. -/
structure SatakeSystemG2 (R : Type*) [CommRing R] where
  q : R
  z1 : R
  z2 : R
  z3 : R
  z1_inv : R
  z2_inv : R
  z3_inv : R
  q_inv : R
  mul_q_inv : q * q_inv = 1
  mul_z1_inv : z1 * z1_inv = 1
  mul_z2_inv : z2 * z2_inv = 1
  mul_z3_inv : z3 * z3_inv = 1
  det_one : z1 * z2 * z3 = 1

namespace SatakeSystemG2

variable (S : SatakeSystemG2 R)

/-- First elementary invariant e₁(z) = z₁ + z₂ + z₃ -/
def e1 : R := S.z1 + S.z2 + S.z3

/-- Second elementary invariant e₂(z) = z₁ z₂ + z₂ z₃ + z₃ z₁ -/
def e2 : R := S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1

/-- Third elementary invariant e₃(z) = z₁ z₂ z₃ = 1 -/
def e3 : R := S.z1 * S.z2 * S.z3

theorem e3_eq_one : S.e3 = 1 := S.det_one

/-- Fundamental short root character χ_short(z) = e₁(z) + e₂(z) -/
def chiShort : R := S.e1 + S.e2

/-- Fundamental long root character χ_long(z) = e₁(z) e₂(z) - 3 -/
def chiLong : R := S.e1 * S.e2 - 3

end SatakeSystemG2

/-- A radial Macdonald plane wave component associated with the G₂ Satake system S.
    Satisfies the 6 short root shift relations and 6 long root shift relations. -/
structure MacdonaldWaveG2 (S : SatakeSystemG2 R) (ψ : ℤ × ℤ → R) : Prop where
  -- Short root shifts
  shift_s1 : ∀ m n : ℤ, ψ (m + 1, n) = S.q_inv * S.z1 * ψ (m, n)
  shift_s2 : ∀ m n : ℤ, ψ (m - 1, n + 1) = S.z2 * ψ (m, n)
  shift_s3 : ∀ m n : ℤ, ψ (m, n - 1) = S.q * S.z3 * ψ (m, n)
  shift_s4 : ∀ m n : ℤ, ψ (m, n + 1) = S.q_inv * (S.z1 * S.z2) * ψ (m, n)
  shift_s5 : ∀ m n : ℤ, ψ (m + 1, n - 1) = (S.z1 * S.z3) * ψ (m, n)
  shift_s6 : ∀ m n : ℤ, ψ (m - 1, n) = S.q * (S.z2 * S.z3) * ψ (m, n)
  -- Long root shifts
  shift_l1 : ∀ m n : ℤ, ψ (m + 1, n + 1) = S.q_inv^2 * (S.z1^2 * S.z2) * ψ (m, n)
  shift_l2 : ∀ m n : ℤ, ψ (m + 2, n - 1) = S.q_inv * (S.z1^2 * S.z3) * ψ (m, n)
  shift_l3 : ∀ m n : ℤ, ψ (m - 1, n + 2) = S.q_inv * (S.z2^2 * S.z3) * ψ (m, n)
  shift_l4 : ∀ m n : ℤ, ψ (m + 1, n - 2) = S.q * (S.z1 * S.z3^2) * ψ (m, n)
  shift_l5 : ∀ m n : ℤ, ψ (m - 2, n + 1) = S.q * (S.z2^2 * S.z1) * ψ (m, n)
  shift_l6 : ∀ m n : ℤ, ψ (m - 1, n - 1) = S.q^2 * (S.z2 * S.z3^2) * ψ (m, n)

/-- **Theorem (Macdonald Recurrence for T_short)**:
    Under the short-root radial Hecke operator T_short, every Macdonald wave ψ satisfies:
    (T_short ψ)(m, n) = q (e₁(z) + e₂(z)) ψ(m, n). -/
theorem macdonald_eigenvalue_T_short (S : SatakeSystemG2 R) (ψ : ℤ × ℤ → R)
    (h : MacdonaldWaveG2 S ψ) (m n : ℤ) :
    radialT_short S.q ψ (m, n) = S.q * (S.e1 + S.e2) * ψ (m, n) := by
  dsimp [radialT_short, SatakeSystemG2.e1, SatakeSystemG2.e2]
  rw [h.shift_s1, h.shift_s2, h.shift_s3, h.shift_s4, h.shift_s5, h.shift_s6]
  have hq1 : S.q^2 * (S.q_inv * S.z1 * ψ (m, n)) = S.q * S.z1 * ψ (m, n) := by
    calc
      S.q^2 * (S.q_inv * S.z1 * ψ (m, n)) = (S.q * (S.q * S.q_inv)) * S.z1 * ψ (m, n) := by ring
      _ = (S.q * 1) * S.z1 * ψ (m, n) := by rw [S.mul_q_inv]
      _ = S.q * S.z1 * ψ (m, n) := by ring
  have hq2 : S.q^2 * (S.q_inv * (S.z1 * S.z2) * ψ (m, n)) = S.q * (S.z1 * S.z2) * ψ (m, n) := by
    calc
      S.q^2 * (S.q_inv * (S.z1 * S.z2) * ψ (m, n)) = (S.q * (S.q * S.q_inv)) * (S.z1 * S.z2) * ψ (m, n) := by ring
      _ = (S.q * 1) * (S.z1 * S.z2) * ψ (m, n) := by rw [S.mul_q_inv]
      _ = S.q * (S.z1 * S.z2) * ψ (m, n) := by ring
  rw [hq1, hq2]
  ring

/-- Helper lemma for T_long eigenvalue: simplifying the 6 long root terms. -/
theorem macdonald_eigenvalue_T_long (S : SatakeSystemG2 R) (ψ : ℤ × ℤ → R)
    (h : MacdonaldWaveG2 S ψ) (m n : ℤ) :
    radialT_long S.q ψ (m, n) = S.q^2 * (S.e1 * S.e2 - 3) * ψ (m, n) := by
  dsimp [radialT_long, SatakeSystemG2.e1, SatakeSystemG2.e2]
  rw [h.shift_l1, h.shift_l2, h.shift_l3, h.shift_l4, h.shift_l5, h.shift_l6]
  have hq4 : S.q^4 * (S.q_inv^2 * (S.z1^2 * S.z2) * ψ (m, n)) =
      S.q^2 * (S.z1^2 * S.z2) * ψ (m, n) := by
    calc
      S.q^4 * (S.q_inv^2 * (S.z1^2 * S.z2) * ψ (m, n)) =
        (S.q^2 * (S.q * S.q_inv)^2) * (S.z1^2 * S.z2) * ψ (m, n) := by ring
      _ = (S.q^2 * 1^2) * (S.z1^2 * S.z2) * ψ (m, n) := by rw [S.mul_q_inv]
      _ = S.q^2 * (S.z1^2 * S.z2) * ψ (m, n) := by ring
  have hq3a : S.q^3 * (S.q_inv * (S.z1^2 * S.z3) * ψ (m, n)) =
      S.q^2 * (S.z1^2 * S.z3) * ψ (m, n) := by
    calc
      S.q^3 * (S.q_inv * (S.z1^2 * S.z3) * ψ (m, n)) =
        (S.q^2 * (S.q * S.q_inv)) * (S.z1^2 * S.z3) * ψ (m, n) := by ring
      _ = (S.q^2 * 1) * (S.z1^2 * S.z3) * ψ (m, n) := by rw [S.mul_q_inv]
      _ = S.q^2 * (S.z1^2 * S.z3) * ψ (m, n) := by ring
  have hq3b : S.q^3 * (S.q_inv * (S.z2^2 * S.z3) * ψ (m, n)) =
      S.q^2 * (S.z2^2 * S.z3) * ψ (m, n) := by
    calc
      S.q^3 * (S.q_inv * (S.z2^2 * S.z3) * ψ (m, n)) =
        (S.q^2 * (S.q * S.q_inv)) * (S.z2^2 * S.z3) * ψ (m, n) := by ring
      _ = (S.q^2 * 1) * (S.z2^2 * S.z3) * ψ (m, n) := by rw [S.mul_q_inv]
      _ = S.q^2 * (S.z2^2 * S.z3) * ψ (m, n) := by ring
  rw [hq4, hq3a, hq3b]
  have hdet := S.det_one
  calc
    S.q^2 * (S.z1^2 * S.z2) * ψ (m, n) +
    S.q^2 * (S.z1^2 * S.z3) * ψ (m, n) +
    S.q^2 * (S.z2^2 * S.z3) * ψ (m, n) +
    S.q * (S.q * (S.z1 * S.z3^2) * ψ (m, n)) +
    S.q * (S.q * (S.z2^2 * S.z1) * ψ (m, n)) +
    (S.q^2 * (S.z2 * S.z3^2) * ψ (m, n))
      = S.q^2 * ((S.z1 + S.z2 + S.z3) * (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) - 3 * (S.z1 * S.z2 * S.z3)) * ψ (m, n) := by ring
    _ = S.q^2 * ((S.z1 + S.z2 + S.z3) * (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) - 3 * 1) * ψ (m, n) := by rw [hdet]
    _ = S.q^2 * ((S.z1 + S.z2 + S.z3) * (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) - 3) * ψ (m, n) := by ring

/-- **Theorem (Discrete Laplacian Eigenvalue on G̃₂ Buildings)**:
    The discrete Laplacian Δ_G2 = T_short + T_long - d_reg(q) I acts on Macdonald waves with eigenvalue:
    λ_Δ(z) = q(e₁ + e₂) + q²(e₁ e₂ - 3) - d_reg(q). -/
theorem macdonald_eigenvalue_laplacian_g2 (S : SatakeSystemG2 R) (ψ : ℤ × ℤ → R)
    (h : MacdonaldWaveG2 S ψ) (m n : ℤ) :
    radialLaplacianG2 S.q ψ (m, n) =
      (S.q * (S.e1 + S.e2) + S.q^2 * (S.e1 * S.e2 - 3) - regularDegreeG2 S.q) * ψ (m, n) := by
  dsimp [radialLaplacianG2]
  rw [macdonald_eigenvalue_T_short S ψ h, macdonald_eigenvalue_T_long S ψ h]
  ring

-- ============================================================================
-- Section 5: Weyl Group W(G₂) ≅ D₆ (Order 12) Symmetries and Invariance
-- ============================================================================

/-- The 12 elements of the Weyl group W(G₂) ≅ D₆ acting on Satake parameters.
    Generated by the S₃ permutation subgroup (6 elements) and the inversion duality (6 elements). -/
inductive WeylG2
  | id       : WeylG2  -- identity
  | s12      : WeylG2  -- transposition (1 2)
  | s23      : WeylG2  -- transposition (2 3)
  | s13      : WeylG2  -- transposition (1 3)
  | c123     : WeylG2  -- 3-cycle (1 2 3)
  | c132     : WeylG2  -- 3-cycle (1 3 2)
  | inv_id   : WeylG2  -- inversion: (z₁⁻¹, z₂⁻¹, z₃⁻¹)
  | inv_s12  : WeylG2  -- inversion * s12
  | inv_s23  : WeylG2  -- inversion * s23
  | inv_s13  : WeylG2  -- inversion * s13
  | inv_c123 : WeylG2  -- inversion * c123
  | inv_c132 : WeylG2  -- inversion * c132

/-- Action of the Weyl group W(G₂) on a Satake parameter system. -/
def weylActG2 (w : WeylG2) (S : SatakeSystemG2 R) : SatakeSystemG2 R :=
  match w with
  | WeylG2.id => S
  | WeylG2.s12 =>
    { q := S.q, z1 := S.z2, z2 := S.z1, z3 := S.z3
      z1_inv := S.z2_inv, z2_inv := S.z1_inv, z3_inv := S.z3_inv, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := S.mul_z2_inv, mul_z2_inv := S.mul_z1_inv, mul_z3_inv := S.mul_z3_inv
      det_one := by
        have h := S.det_one
        calc S.z2 * S.z1 * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h }
  | WeylG2.s23 =>
    { q := S.q, z1 := S.z1, z2 := S.z3, z3 := S.z2
      z1_inv := S.z1_inv, z2_inv := S.z3_inv, z3_inv := S.z2_inv, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := S.mul_z1_inv, mul_z2_inv := S.mul_z3_inv, mul_z3_inv := S.mul_z2_inv
      det_one := by
        have h := S.det_one
        calc S.z1 * S.z3 * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h }
  | WeylG2.s13 =>
    { q := S.q, z1 := S.z3, z2 := S.z2, z3 := S.z1
      z1_inv := S.z3_inv, z2_inv := S.z2_inv, z3_inv := S.z1_inv, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := S.mul_z3_inv, mul_z2_inv := S.mul_z2_inv, mul_z3_inv := S.mul_z1_inv
      det_one := by
        have h := S.det_one
        calc S.z3 * S.z2 * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h }
  | WeylG2.c123 =>
    { q := S.q, z1 := S.z2, z2 := S.z3, z3 := S.z1
      z1_inv := S.z2_inv, z2_inv := S.z3_inv, z3_inv := S.z1_inv, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := S.mul_z2_inv, mul_z2_inv := S.mul_z3_inv, mul_z3_inv := S.mul_z1_inv
      det_one := by
        have h := S.det_one
        calc S.z2 * S.z3 * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h }
  | WeylG2.c132 =>
    { q := S.q, z1 := S.z3, z2 := S.z1, z3 := S.z2
      z1_inv := S.z3_inv, z2_inv := S.z1_inv, z3_inv := S.z2_inv, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := S.mul_z3_inv, mul_z2_inv := S.mul_z1_inv, mul_z3_inv := S.mul_z2_inv
      det_one := by
        have h := S.det_one
        calc S.z3 * S.z1 * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h }
  | WeylG2.inv_id =>
    { q := S.q, z1 := S.z2 * S.z3, z2 := S.z1 * S.z3, z3 := S.z1 * S.z2
      z1_inv := S.z1, z2_inv := S.z2, z3_inv := S.z3, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := by
        have h := S.det_one
        calc (S.z2 * S.z3) * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z2_inv := by
        have h := S.det_one
        calc (S.z1 * S.z3) * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z3_inv := by
        have h := S.det_one
        calc (S.z1 * S.z2) * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      det_one := by
        have h := S.det_one
        calc (S.z2 * S.z3) * (S.z1 * S.z3) * (S.z1 * S.z2) = (S.z1 * S.z2 * S.z3) * (S.z1 * S.z2 * S.z3) := by ring
        _ = 1 * 1 := by rw [h]
        _ = 1 := by ring }
  | WeylG2.inv_s12 =>
    { q := S.q, z1 := S.z1 * S.z3, z2 := S.z2 * S.z3, z3 := S.z1 * S.z2
      z1_inv := S.z2, z2_inv := S.z1, z3_inv := S.z3, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := by
        have h := S.det_one
        calc (S.z1 * S.z3) * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z2_inv := by
        have h := S.det_one
        calc (S.z2 * S.z3) * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z3_inv := by
        have h := S.det_one
        calc (S.z1 * S.z2) * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      det_one := by
        have h := S.det_one
        calc (S.z1 * S.z3) * (S.z2 * S.z3) * (S.z1 * S.z2) = (S.z1 * S.z2 * S.z3) * (S.z1 * S.z2 * S.z3) := by ring
        _ = 1 * 1 := by rw [h]
        _ = 1 := by ring }
  | WeylG2.inv_s23 =>
    { q := S.q, z1 := S.z2 * S.z3, z2 := S.z1 * S.z2, z3 := S.z1 * S.z3
      z1_inv := S.z1, z2_inv := S.z3, z3_inv := S.z2, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := by
        have h := S.det_one
        calc (S.z2 * S.z3) * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z2_inv := by
        have h := S.det_one
        calc (S.z1 * S.z2) * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z3_inv := by
        have h := S.det_one
        calc (S.z1 * S.z3) * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      det_one := by
        have h := S.det_one
        calc (S.z2 * S.z3) * (S.z1 * S.z2) * (S.z1 * S.z3) = (S.z1 * S.z2 * S.z3) * (S.z1 * S.z2 * S.z3) := by ring
        _ = 1 * 1 := by rw [h]
        _ = 1 := by ring }
  | WeylG2.inv_s13 =>
    { q := S.q, z1 := S.z1 * S.z2, z2 := S.z1 * S.z3, z3 := S.z2 * S.z3
      z1_inv := S.z3, z2_inv := S.z2, z3_inv := S.z1, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := by
        have h := S.det_one
        calc (S.z1 * S.z2) * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z2_inv := by
        have h := S.det_one
        calc (S.z1 * S.z3) * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z3_inv := by
        have h := S.det_one
        calc (S.z2 * S.z3) * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      det_one := by
        have h := S.det_one
        calc (S.z1 * S.z2) * (S.z1 * S.z3) * (S.z2 * S.z3) = (S.z1 * S.z2 * S.z3) * (S.z1 * S.z2 * S.z3) := by ring
        _ = 1 * 1 := by rw [h]
        _ = 1 := by ring }
  | WeylG2.inv_c123 =>
    { q := S.q, z1 := S.z1 * S.z3, z2 := S.z1 * S.z2, z3 := S.z2 * S.z3
      z1_inv := S.z2, z2_inv := S.z3, z3_inv := S.z1, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := by
        have h := S.det_one
        calc (S.z1 * S.z3) * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z2_inv := by
        have h := S.det_one
        calc (S.z1 * S.z2) * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z3_inv := by
        have h := S.det_one
        calc (S.z2 * S.z3) * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      det_one := by
        have h := S.det_one
        calc (S.z1 * S.z3) * (S.z1 * S.z2) * (S.z2 * S.z3) = (S.z1 * S.z2 * S.z3) * (S.z1 * S.z2 * S.z3) := by ring
        _ = 1 * 1 := by rw [h]
        _ = 1 := by ring }
  | WeylG2.inv_c132 =>
    { q := S.q, z1 := S.z1 * S.z2, z2 := S.z2 * S.z3, z3 := S.z1 * S.z3
      z1_inv := S.z3, z2_inv := S.z1, z3_inv := S.z2, q_inv := S.q_inv
      mul_q_inv := S.mul_q_inv
      mul_z1_inv := by
        have h := S.det_one
        calc (S.z1 * S.z2) * S.z3 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z2_inv := by
        have h := S.det_one
        calc (S.z2 * S.z3) * S.z1 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      mul_z3_inv := by
        have h := S.det_one
        calc (S.z1 * S.z3) * S.z2 = S.z1 * S.z2 * S.z3 := by ring
        _ = 1 := h
      det_one := by
        have h := S.det_one
        calc (S.z1 * S.z2) * (S.z2 * S.z3) * (S.z1 * S.z3) = (S.z1 * S.z2 * S.z3) * (S.z1 * S.z2 * S.z3) := by ring
        _ = 1 * 1 := by rw [h]
        _ = 1 := by ring }

/-- The parameter q is preserved under all 12 Weyl actions. -/
theorem weyl_q_g2 (w : WeylG2) (S : SatakeSystemG2 R) : (weylActG2 w S).q = S.q := by
  cases w <;> rfl

/-- The short root invariant (e₁ + e₂) is invariant under the entire Weyl group W(G₂). -/
theorem weyl_invar_short (w : WeylG2) (S : SatakeSystemG2 R) :
    (weylActG2 w S).e1 + (weylActG2 w S).e2 = S.e1 + S.e2 := by
  have hdet := S.det_one
  cases w
  · rfl
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_id
    calc (weylActG2 WeylG2.inv_id S).e1 + (weylActG2 WeylG2.inv_id S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) + (S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 + 1 * S.e1 := by rw [hdet]; rfl
      _ = S.e1 + S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_s12
    calc (weylActG2 WeylG2.inv_s12 S).e1 + (weylActG2 WeylG2.inv_s12 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) + (S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 + 1 * S.e1 := by rw [hdet]; rfl
      _ = S.e1 + S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_s23
    calc (weylActG2 WeylG2.inv_s23 S).e1 + (weylActG2 WeylG2.inv_s23 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) + (S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 + 1 * S.e1 := by rw [hdet]; rfl
      _ = S.e1 + S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_s13
    calc (weylActG2 WeylG2.inv_s13 S).e1 + (weylActG2 WeylG2.inv_s13 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) + (S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 + 1 * S.e1 := by rw [hdet]; rfl
      _ = S.e1 + S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_c123
    calc (weylActG2 WeylG2.inv_c123 S).e1 + (weylActG2 WeylG2.inv_c123 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) + (S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 + 1 * S.e1 := by rw [hdet]; rfl
      _ = S.e1 + S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_c132
    calc (weylActG2 WeylG2.inv_c132 S).e1 + (weylActG2 WeylG2.inv_c132 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) + (S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 + 1 * S.e1 := by rw [hdet]; rfl
      _ = S.e1 + S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring

/-- The long root invariant (e₁ e₂) is invariant under the entire Weyl group W(G₂). -/
theorem weyl_invar_long (w : WeylG2) (S : SatakeSystemG2 R) :
    (weylActG2 w S).e1 * (weylActG2 w S).e2 = S.e1 * S.e2 := by
  have hdet := S.det_one
  cases w
  · rfl
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_id
    calc (weylActG2 WeylG2.inv_id S).e1 * (weylActG2 WeylG2.inv_id S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) * ((S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3)) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 * (1 * S.e1) := by rw [hdet]; rfl
      _ = S.e1 * S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_s12
    calc (weylActG2 WeylG2.inv_s12 S).e1 * (weylActG2 WeylG2.inv_s12 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) * ((S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3)) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 * (1 * S.e1) := by rw [hdet]; rfl
      _ = S.e1 * S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_s23
    calc (weylActG2 WeylG2.inv_s23 S).e1 * (weylActG2 WeylG2.inv_s23 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) * ((S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3)) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 * (1 * S.e1) := by rw [hdet]; rfl
      _ = S.e1 * S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_s13
    calc (weylActG2 WeylG2.inv_s13 S).e1 * (weylActG2 WeylG2.inv_s13 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) * ((S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3)) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 * (1 * S.e1) := by rw [hdet]; rfl
      _ = S.e1 * S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_c123
    calc (weylActG2 WeylG2.inv_c123 S).e1 * (weylActG2 WeylG2.inv_c123 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) * ((S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3)) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 * (1 * S.e1) := by rw [hdet]; rfl
      _ = S.e1 * S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
  · -- inv_c132
    calc (weylActG2 WeylG2.inv_c132 S).e1 * (weylActG2 WeylG2.inv_c132 S).e2
        = (S.z1 * S.z2 + S.z2 * S.z3 + S.z3 * S.z1) * ((S.z1 * S.z2 * S.z3) * (S.z1 + S.z2 + S.z3)) := by
          dsimp [weylActG2, SatakeSystemG2.e1, SatakeSystemG2.e2]; ring
      _ = S.e2 * (1 * S.e1) := by rw [hdet]; rfl
      _ = S.e1 * S.e2 := by dsimp [SatakeSystemG2.e1, SatakeSystemG2.e2]; ring

/-- The fundamental short root character χ_short is invariant under the entire Weyl group W(G₂). -/
theorem weyl_invar_chiShort (w : WeylG2) (S : SatakeSystemG2 R) :
    (weylActG2 w S).chiShort = S.chiShort := by
  dsimp [SatakeSystemG2.chiShort]
  exact weyl_invar_short w S

/-- The fundamental long root character χ_long is invariant under the entire Weyl group W(G₂). -/
theorem weyl_invar_chiLong (w : WeylG2) (S : SatakeSystemG2 R) :
    (weylActG2 w S).chiLong = S.chiLong := by
  dsimp [SatakeSystemG2.chiLong]
  rw [weyl_invar_long w S]

/-- A symmetrized Macdonald spherical wavefunction formed by summing 12 Weyl components. -/
def symmetrizedMacdonaldG2
    (waves : (w : WeylG2) → (ℤ × ℤ → R))
    (weights : WeylG2 → R) : ℤ × ℤ → R :=
  fun v =>
    weights WeylG2.id * waves WeylG2.id v +
    weights WeylG2.s12 * waves WeylG2.s12 v +
    weights WeylG2.s23 * waves WeylG2.s23 v +
    weights WeylG2.s13 * waves WeylG2.s13 v +
    weights WeylG2.c123 * waves WeylG2.c123 v +
    weights WeylG2.c132 * waves WeylG2.c132 v +
    weights WeylG2.inv_id * waves WeylG2.inv_id v +
    weights WeylG2.inv_s12 * waves WeylG2.inv_s12 v +
    weights WeylG2.inv_s23 * waves WeylG2.inv_s23 v +
    weights WeylG2.inv_s13 * waves WeylG2.inv_s13 v +
    weights WeylG2.inv_c123 * waves WeylG2.inv_c123 v +
    weights WeylG2.inv_c132 * waves WeylG2.inv_c132 v

/-- **Theorem (Joint Macdonald Recurrence for Symmetrized Function under T_short)**:
    The symmetrized Macdonald function Φ is an exact eigenfunction of T_short with eigenvalue q (e₁ + e₂). -/
theorem symmetrized_eigenvalue_T_short (S : SatakeSystemG2 R)
    (waves : (w : WeylG2) → (ℤ × ℤ → R))
    (hw : ∀ w, MacdonaldWaveG2 (weylActG2 w S) (waves w))
    (weights : WeylG2 → R) (m n : ℤ) :
    radialT_short S.q (symmetrizedMacdonaldG2 waves weights) (m, n) =
      S.q * (S.e1 + S.e2) * symmetrizedMacdonaldG2 waves weights (m, n) := by
  dsimp [symmetrizedMacdonaldG2, radialT_short]
  have h_id := macdonald_eigenvalue_T_short (weylActG2 WeylG2.id S) (waves WeylG2.id) (hw WeylG2.id) m n
  have h_s12 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.s12 S) (waves WeylG2.s12) (hw WeylG2.s12) m n
  have h_s23 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.s23 S) (waves WeylG2.s23) (hw WeylG2.s23) m n
  have h_s13 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.s13 S) (waves WeylG2.s13) (hw WeylG2.s13) m n
  have h_c123 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.c123 S) (waves WeylG2.c123) (hw WeylG2.c123) m n
  have h_c132 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.c132 S) (waves WeylG2.c132) (hw WeylG2.c132) m n
  have h_inv_id := macdonald_eigenvalue_T_short (weylActG2 WeylG2.inv_id S) (waves WeylG2.inv_id) (hw WeylG2.inv_id) m n
  have h_inv_s12 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.inv_s12 S) (waves WeylG2.inv_s12) (hw WeylG2.inv_s12) m n
  have h_inv_s23 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.inv_s23 S) (waves WeylG2.inv_s23) (hw WeylG2.inv_s23) m n
  have h_inv_s13 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.inv_s13 S) (waves WeylG2.inv_s13) (hw WeylG2.inv_s13) m n
  have h_inv_c123 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.inv_c123 S) (waves WeylG2.inv_c123) (hw WeylG2.inv_c123) m n
  have h_inv_c132 := macdonald_eigenvalue_T_short (weylActG2 WeylG2.inv_c132 S) (waves WeylG2.inv_c132) (hw WeylG2.inv_c132) m n
  rw [weyl_invar_short WeylG2.id, weyl_q_g2 WeylG2.id] at h_id
  rw [weyl_invar_short WeylG2.s12, weyl_q_g2 WeylG2.s12] at h_s12
  rw [weyl_invar_short WeylG2.s23, weyl_q_g2 WeylG2.s23] at h_s23
  rw [weyl_invar_short WeylG2.s13, weyl_q_g2 WeylG2.s13] at h_s13
  rw [weyl_invar_short WeylG2.c123, weyl_q_g2 WeylG2.c123] at h_c123
  rw [weyl_invar_short WeylG2.c132, weyl_q_g2 WeylG2.c132] at h_c132
  rw [weyl_invar_short WeylG2.inv_id, weyl_q_g2 WeylG2.inv_id] at h_inv_id
  rw [weyl_invar_short WeylG2.inv_s12, weyl_q_g2 WeylG2.inv_s12] at h_inv_s12
  rw [weyl_invar_short WeylG2.inv_s23, weyl_q_g2 WeylG2.inv_s23] at h_inv_s23
  rw [weyl_invar_short WeylG2.inv_s13, weyl_q_g2 WeylG2.inv_s13] at h_inv_s13
  rw [weyl_invar_short WeylG2.inv_c123, weyl_q_g2 WeylG2.inv_c123] at h_inv_c123
  rw [weyl_invar_short WeylG2.inv_c132, weyl_q_g2 WeylG2.inv_c132] at h_inv_c132
  dsimp [radialT_short] at h_id h_s12 h_s23 h_s13 h_c123 h_c132 h_inv_id h_inv_s12 h_inv_s23 h_inv_s13 h_inv_c123 h_inv_c132
  linear_combination
    weights WeylG2.id * h_id +
    weights WeylG2.s12 * h_s12 +
    weights WeylG2.s23 * h_s23 +
    weights WeylG2.s13 * h_s13 +
    weights WeylG2.c123 * h_c123 +
    weights WeylG2.c132 * h_c132 +
    weights WeylG2.inv_id * h_inv_id +
    weights WeylG2.inv_s12 * h_inv_s12 +
    weights WeylG2.inv_s23 * h_inv_s23 +
    weights WeylG2.inv_s13 * h_inv_s13 +
    weights WeylG2.inv_c123 * h_inv_c123 +
    weights WeylG2.inv_c132 * h_inv_c132

/-- **Theorem (Joint Macdonald Recurrence for Symmetrized Function under T_long)**:
    The symmetrized Macdonald function Φ is an exact eigenfunction of T_long with eigenvalue q² (e₁ e₂ - 3). -/
theorem symmetrized_eigenvalue_T_long (S : SatakeSystemG2 R)
    (waves : (w : WeylG2) → (ℤ × ℤ → R))
    (hw : ∀ w, MacdonaldWaveG2 (weylActG2 w S) (waves w))
    (weights : WeylG2 → R) (m n : ℤ) :
    radialT_long S.q (symmetrizedMacdonaldG2 waves weights) (m, n) =
      S.q^2 * (S.e1 * S.e2 - 3) * symmetrizedMacdonaldG2 waves weights (m, n) := by
  dsimp [symmetrizedMacdonaldG2, radialT_long]
  have h_id := macdonald_eigenvalue_T_long (weylActG2 WeylG2.id S) (waves WeylG2.id) (hw WeylG2.id) m n
  have h_s12 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.s12 S) (waves WeylG2.s12) (hw WeylG2.s12) m n
  have h_s23 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.s23 S) (waves WeylG2.s23) (hw WeylG2.s23) m n
  have h_s13 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.s13 S) (waves WeylG2.s13) (hw WeylG2.s13) m n
  have h_c123 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.c123 S) (waves WeylG2.c123) (hw WeylG2.c123) m n
  have h_c132 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.c132 S) (waves WeylG2.c132) (hw WeylG2.c132) m n
  have h_inv_id := macdonald_eigenvalue_T_long (weylActG2 WeylG2.inv_id S) (waves WeylG2.inv_id) (hw WeylG2.inv_id) m n
  have h_inv_s12 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.inv_s12 S) (waves WeylG2.inv_s12) (hw WeylG2.inv_s12) m n
  have h_inv_s23 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.inv_s23 S) (waves WeylG2.inv_s23) (hw WeylG2.inv_s23) m n
  have h_inv_s13 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.inv_s13 S) (waves WeylG2.inv_s13) (hw WeylG2.inv_s13) m n
  have h_inv_c123 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.inv_c123 S) (waves WeylG2.inv_c123) (hw WeylG2.inv_c123) m n
  have h_inv_c132 := macdonald_eigenvalue_T_long (weylActG2 WeylG2.inv_c132 S) (waves WeylG2.inv_c132) (hw WeylG2.inv_c132) m n
  rw [weyl_invar_long WeylG2.id, weyl_q_g2 WeylG2.id] at h_id
  rw [weyl_invar_long WeylG2.s12, weyl_q_g2 WeylG2.s12] at h_s12
  rw [weyl_invar_long WeylG2.s23, weyl_q_g2 WeylG2.s23] at h_s23
  rw [weyl_invar_long WeylG2.s13, weyl_q_g2 WeylG2.s13] at h_s13
  rw [weyl_invar_long WeylG2.c123, weyl_q_g2 WeylG2.c123] at h_c123
  rw [weyl_invar_long WeylG2.c132, weyl_q_g2 WeylG2.c132] at h_c132
  rw [weyl_invar_long WeylG2.inv_id, weyl_q_g2 WeylG2.inv_id] at h_inv_id
  rw [weyl_invar_long WeylG2.inv_s12, weyl_q_g2 WeylG2.inv_s12] at h_inv_s12
  rw [weyl_invar_long WeylG2.inv_s23, weyl_q_g2 WeylG2.inv_s23] at h_inv_s23
  rw [weyl_invar_long WeylG2.inv_s13, weyl_q_g2 WeylG2.inv_s13] at h_inv_s13
  rw [weyl_invar_long WeylG2.inv_c123, weyl_q_g2 WeylG2.inv_c123] at h_inv_c123
  rw [weyl_invar_long WeylG2.inv_c132, weyl_q_g2 WeylG2.inv_c132] at h_inv_c132
  dsimp [radialT_long] at h_id h_s12 h_s23 h_s13 h_c123 h_c132 h_inv_id h_inv_s12 h_inv_s23 h_inv_s13 h_inv_c123 h_inv_c132
  linear_combination
    weights WeylG2.id * h_id +
    weights WeylG2.s12 * h_s12 +
    weights WeylG2.s23 * h_s23 +
    weights WeylG2.s13 * h_s13 +
    weights WeylG2.c123 * h_c123 +
    weights WeylG2.c132 * h_c132 +
    weights WeylG2.inv_id * h_inv_id +
    weights WeylG2.inv_s12 * h_inv_s12 +
    weights WeylG2.inv_s23 * h_inv_s23 +
    weights WeylG2.inv_s13 * h_inv_s13 +
    weights WeylG2.inv_c123 * h_inv_c123 +
    weights WeylG2.inv_c132 * h_inv_c132

/-- **Theorem (Symmetrized Discrete Laplacian Eigenvalue on G̃₂ Buildings)**:
    The symmetrized Macdonald function Φ is an exact eigenfunction of the G̃₂ Laplacian Δ_G2
    with eigenvalue λ_Δ(z) = q(e₁ + e₂) + q²(e₁ e₂ - 3) - d_reg(q). -/
theorem symmetrized_eigenvalue_laplacian_g2 (S : SatakeSystemG2 R)
    (waves : (w : WeylG2) → (ℤ × ℤ → R))
    (hw : ∀ w, MacdonaldWaveG2 (weylActG2 w S) (waves w))
    (weights : WeylG2 → R) (m n : ℤ) :
    radialLaplacianG2 S.q (symmetrizedMacdonaldG2 waves weights) (m, n) =
      (S.q * (S.e1 + S.e2) + S.q^2 * (S.e1 * S.e2 - 3) - regularDegreeG2 S.q) *
        symmetrizedMacdonaldG2 waves weights (m, n) := by
  dsimp [radialLaplacianG2]
  rw [symmetrized_eigenvalue_T_short S waves hw weights m n,
      symmetrized_eigenvalue_T_long S waves hw weights m n]
  ring

-- ============================================================================
-- Section 6: Non-Archimedean Ramanujan Spectral Gap on G̃₂ Buildings
-- ============================================================================

/-- The maximum tempered eigenvalue for the discrete Laplacian on G̃₂ buildings:
    When Re(e₁ + e₂) ≤ 6 and Re(e₁ e₂ - 3) ≤ 6, the maximum tempered eigenvalue is
    λ_{temp, max}(q) = 6q + 6q² - d_reg(q). -/
def maxTemperedG2Eigenvalue (q : R) : R :=
  (6 * q + 6 * q^2) - regularDegreeG2 q

/-- **Theorem (Non-Archimedean Ramanujan Spectral Gap on G̃₂ Buildings)**:
    The spectral gap separating the trivial bound state λ₀ = 0 from the continuous tempered
    spectrum band is given by the exact polynomial identity:
    Gap(Δ_G2) = 0 - λ_{temp, max} = (q - 1)² (q + 1) (q + 3). -/
theorem ramanujan_spectral_gap_identity_g2 (q : R) :
    0 - ((6 * q + 6 * q^2) - (2 * (q^2 + q + 1) + (q^4 + 2 * q^3 + 2 * q + 1))) =
      (q - 1)^2 * (q + 1) * (q + 3) := by
  ring

/-- Exact formula for the Ramanujan spectral gap using defined operators. -/
theorem ramanujan_gap_formula_g2 (q : R) :
    0 - maxTemperedG2Eigenvalue q = (q - 1)^2 * (q + 1) * (q + 3) := by
  dsimp [maxTemperedG2Eigenvalue, regularDegreeG2]
  ring
