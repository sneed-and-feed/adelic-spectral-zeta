/-
Copyright (c) 2026 Adelic Spectral Zeta Research Group. All rights reserved.
Released under Apache 2.0 license as described in the file LICENSE.
Authors: Adelic Spectral Zeta Research Group
-/
import Mathlib.NumberTheory.LegendreSymbol.Basic
import Mathlib.NumberTheory.LegendreSymbol.QuadraticReciprocity
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Complex.Basic
import Formalization.Buildings.BuildingPGL3

/-!
# Horizon 2: Arithmetic Chern-Simons Theory, Arithmetic Topology & Adelic TQFT

This module formalizes:
1. **Arithmetic Topology Dictionary (Mazur, Kapranov, Reznikov, Morishita, Kim, Ueki)**:
   - Arithmetic knots $K_p \hookrightarrow \mathrm{Spec}(\mathbb{Z})$ associated with prime ideals $(p)$.
   - The arithmetic linking number $\mathrm{Lk}(p, q) \in \mathbb{Z}/2\mathbb{Z}$ via the Legendre symbol.
   - Exact Legendre symbol evaluation theorem: $\left(\frac{q}{p}\right) = (-1)^{\mathrm{Lk}(p, q)}$.
   - **Arithmetic Linking Reciprocity Theorem**:
     $\mathrm{Lk}(p, q) + \mathrm{Lk}(q, p) \equiv \frac{p-1}{2} \frac{q-1}{2} \pmod 2$.
   - Symmetric arithmetic linking when $p \equiv 1 \pmod 4$ or $q \equiv 1 \pmod 4$.
   - Skew-symmetric arithmetic linking when $p \equiv q \equiv 3 \pmod 4$.

2. **1-Loop Arithmetic Chern-Simons Holonomy & Unitary Phase**:
   - Arithmetic Chern-Simons holonomy $\mathrm{Hol}(p, q) = (-1)^{\mathrm{Lk}(p, q)} \in \mathrm{U}(1) \subset \mathbb{C}^\times$.
   - Unitarity proof: $\mathrm{normSq}(\mathrm{Hol}(p, q)) = 1$.
   - Holonomy-Legendre identification: $\mathrm{Hol}(p, q) = \left(\frac{q}{p}\right)$.
   - Holonomy reciprocity product: $\mathrm{Hol}(p, q) \cdot \mathrm{Hol}(q, p) = (-1)^{\frac{p-1}{2} \frac{q-1}{2}}$.

3. **Discrete Chern-Simons Theory on the Bruhat-Tits 2-Skeleton $\mathcal{B}(\mathrm{PGL}_3(\mathbb{Q}_p))$**:
   - Oriented 2-simplices (triangles / chamber faces) on `BuildingA2`.
   - Discrete 1-cochains / abelian gauge fields $A : V \times V \to R$.
   - Gauge transformations $A \mapsto A + d\chi$.
   - Discrete gauge curvature $F_A = dA$ and proof of exact gauge invariance.
   - Discrete Stokes' theorem: line integrals around triangles equal the curvature.
   - Wilson loop operators $W_A(C)$ in $\mathbb{Z}/2\mathbb{Z}$ gauge theory and proof of $U(1)$-unitarity.
   - Discrete abelian Chern-Simons action $S_{CS}(A)$ and finite partition function $Z_{CS}$.
   - Exact vanishing of CS action on flat gauge configurations.

4. **Euler Product Phase Duality**:
   - Local Euler factors in the global Fredholm determinant.
   - Exact identification of the odd-prime unitary phase with the 1-loop arithmetic CS holonomy.
   - Pairwise Fredholm Euler product factor $\mathcal{Z}_{\mathrm{Euler}}(s; p, q)$.
   - Euler phase symmetry for primes $1 \pmod 4$ and chiral phase anti-symmetry for primes $3 \pmod 4$.
   - Global phase duality product connecting arithmetic topology to adelic TQFT S-matrix phases.

All theorems are formally verified with **zero sorrys**.
-/

open BigOperators

namespace ArithmeticTopology

-- ============================================================================
-- Section 1: Arithmetic Topology Dictionary & Arithmetic Linking Numbers
-- ============================================================================

/-- An arithmetic knot K_p in arithmetic topology, representing the closed immersion
    Spec(𝔽_p) ↪ Spec(ℤ) as an arithmetic analogue of a knot S¹ ↪ S³. -/
structure ArithmeticKnot where
  p : ℕ
  [prime : Fact p.Prime]

/-- The arithmetic linking number Lk(p, q) ∈ ℤ/2ℤ of two primes p and q,
    defined via the Legendre symbol (q / p). -/
def arithmeticLinking (p q : ℕ) [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] : ZMod 2 :=
  if legendreSym p (q : ℤ) = -1 then 1 else 0

/-- Arithmetic linking number between two arithmetic knots. -/
def arithmeticLinkingKnots (K₁ K₂ : ArithmeticKnot) : ZMod 2 :=
  @arithmeticLinking K₁.p K₂.p K₁.prime K₂.prime

lemma zmod2_cases (a : ZMod 2) : a = 0 ∨ a = 1 := by
  revert a; decide

lemma prime_intCast_ne_zero_of_ne {p q : ℕ} [hp : Fact (Nat.Prime p)] [hq : Fact (Nat.Prime q)] (hpq : p ≠ q) :
    ((q : ℤ) : ZMod p) ≠ 0 := by
  rw [Ne, ZMod.intCast_zmod_eq_zero_iff_dvd, Int.natCast_dvd_natCast]
  exact (hq.out.dvd_iff_eq hp.out.ne_one).not.mpr hpq.symm

/-- Identification of Legendre symbol with parity exponent of arithmetic linking number. -/
theorem legendreSym_eq_neg_one_pow_arithmeticLinking
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] (hpq : p ≠ q) :
    legendreSym p (q : ℤ) = (-1 : ℤ) ^ (arithmeticLinking p q).val := by
  obtain h | h := legendreSym.eq_one_or_neg_one p (prime_intCast_ne_zero_of_ne hpq) <;>
    simp [arithmeticLinking, h, ZMod.val_one]

lemma neg_one_pow_eq_iff_zmod2_eq (a b : ZMod 2) :
    (-1 : ℤ) ^ a.val = (-1 : ℤ) ^ b.val ↔ a = b := by
  revert a b; decide

lemma neg_one_pow_zmod2_add (a b : ZMod 2) :
    (-1 : ℤ) ^ (a + b).val = (-1 : ℤ) ^ a.val * (-1 : ℤ) ^ b.val := by
  revert a b; decide

lemma neg_one_pow_nat_eq_neg_one_pow_zmod2_val (n : ℕ) :
    (-1 : ℤ) ^ (n : ZMod 2).val = (-1 : ℤ) ^ n := by
  rw [ZMod.val_natCast (n := 2)]
  exact (neg_one_pow_eq_pow_mod_two n).symm

/-- **Arithmetic Linking Reciprocity Theorem**:
    For distinct odd primes p and q, the sum of their arithmetic linking numbers in ℤ/2ℤ
    equals (p - 1)/2 * (q - 1)/2 mod 2, matching Gauss's Quadratic Reciprocity Law. -/
theorem arithmetic_linking_reciprocity
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    arithmeticLinking p q + arithmeticLinking q p = ((p / 2 * (q / 2) : ℕ) : ZMod 2) := by
  rw [← neg_one_pow_eq_iff_zmod2_eq, neg_one_pow_zmod2_add,
    neg_one_pow_nat_eq_neg_one_pow_zmod2_val,
    ← legendreSym_eq_neg_one_pow_arithmeticLinking hpq,
    ← legendreSym_eq_neg_one_pow_arithmeticLinking hpq.symm, mul_comm]
  exact legendreSym.quadratic_reciprocity hp hq hpq

lemma zmod2_add_eq_zero_iff (a b : ZMod 2) : a + b = 0 ↔ a = b := by
  revert a b; decide

/-- **Symmetric Arithmetic Linking**:
    If at least one prime is 1 mod 4, the arithmetic linking number is symmetric. -/
theorem arithmetic_linking_symmetric_of_one_mod_four
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q)
    (h4 : p % 4 = 1 ∨ q % 4 = 1) :
    arithmeticLinking p q = arithmeticLinking q p := by
  have h0 : ((p / 2 * (q / 2) : ℕ) : ZMod 2) = 0 := by
    apply ZMod.val_injective
    rw [ZMod.val_natCast (n := 2), Nat.mul_mod]
    rcases h4 with hp1 | hq1
    · have : p / 2 % 2 = 0 := by omega
      rw [this, zero_mul, Nat.zero_mod]
      rfl
    · have : q / 2 % 2 = 0 := by omega
      rw [this, mul_zero, Nat.zero_mod]
      rfl
  rw [← zmod2_add_eq_zero_iff, arithmetic_linking_reciprocity hp hq hpq, h0]

/-- **Skew-Symmetric Arithmetic Linking**:
    If both primes are 3 mod 4, the sum of their arithmetic linking numbers is 1 mod 2. -/
theorem arithmetic_linking_skew_symmetric_of_three_mod_four
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q)
    (h3 : p % 4 = 3 ∧ q % 4 = 3) :
    arithmeticLinking p q + arithmeticLinking q p = 1 := by
  rw [arithmetic_linking_reciprocity hp hq hpq]
  apply ZMod.val_injective
  rw [ZMod.val_natCast (n := 2), Nat.mul_mod, show p / 2 % 2 = 1 by omega, show q / 2 % 2 = 1 by omega]
  rfl

-- ============================================================================
-- Section 2: 1-Loop Arithmetic Chern-Simons Holonomy & Unitary Phase
-- ============================================================================

/-- 1-loop Arithmetic Chern-Simons Holonomy / Unitary Phase associated with the link (p, q). -/
def arithmeticHolonomy (p q : ℕ) [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] : ℂ :=
  (-1 : ℂ) ^ (arithmeticLinking p q).val

/-- Arithmetic Chern-Simons holonomy between two arithmetic knots. -/
def arithmeticHolonomyKnots (K₁ K₂ : ArithmeticKnot) : ℂ :=
  @arithmeticHolonomy K₁.p K₂.p K₁.prime K₂.prime

/-- Unitarity in terms of complex norm square. -/
theorem arithmeticHolonomy_normSq (p q : ℕ) [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] :
    Complex.normSq (arithmeticHolonomy p q) = 1 := by
  simp [arithmeticHolonomy]

/-- Identification theorem: The 1-loop Chern-Simons holonomy equals the Legendre symbol. -/
theorem arithmetic_holonomy_eq_legendre
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] (hpq : p ≠ q) :
    arithmeticHolonomy p q = (legendreSym p (q : ℤ) : ℂ) := by
  simp [arithmeticHolonomy, legendreSym_eq_neg_one_pow_arithmeticLinking hpq]

/-- **Holonomy Reciprocity Product Theorem**:
    The product of mutual arithmetic Chern-Simons holonomies satisfies
    Hol(p, q) * Hol(q, p) = (-1)^((p-1)/2 * (q-1)/2). -/
theorem arithmetic_holonomy_reciprocity_product
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    arithmeticHolonomy p q * arithmeticHolonomy q p = (-1 : ℂ) ^ (p / 2 * (q / 2)) := by
  rw [arithmetic_holonomy_eq_legendre hpq, arithmetic_holonomy_eq_legendre hpq.symm, mul_comm,
    ← Int.cast_mul, legendreSym.quadratic_reciprocity hp hq hpq, Int.cast_pow, Int.cast_neg,
    Int.cast_one]

-- ============================================================================
-- Section 3: Discrete Chern-Simons Theory on Bruhat-Tits 2-Skeleton B(PGL₃(ℚ_p))
-- ============================================================================

variable {V : Type*} {q : ℕ} (B : BuildingA2 V q)

/-- An oriented triangle (chamber / 2-simplex) in the 2-skeleton of B(PGL₃(ℚ_p)). -/
structure OrientedTriangle (V : Type*) (q : ℕ) (B : BuildingA2 V q) where
  u : V
  v : V
  w : V
  adj_uv : B.adj1 u v
  adj_vw : B.adj1 v w
  adj_wu : B.adj1 w u

/-- Directed edge in the 1-skeleton of the building. -/
structure DirectedEdge (V : Type*) (q : ℕ) (B : BuildingA2 V q) where
  src : V
  tgt : V
  adj : B.adj1 src tgt

/-- An oriented triangle has all three vertices of distinct colors. -/
theorem oriented_triangle_colors_distinct (t : OrientedTriangle V q B) :
    B.color t.v = B.color t.u + 1 ∧
    B.color t.w = B.color t.u + 2 :=
  ⟨B.color_adj1 t.adj_uv, by rw [B.color_adj1 t.adj_vw, B.color_adj1 t.adj_uv, add_assoc]; rfl⟩

/-- A discrete 1-cochain / abelian gauge field A on the vertices. -/
structure GaugeField1 (V : Type*) (R : Type*) [AddCommGroup R] where
  A : V → V → R
  skew : ∀ u v, A v u = - A u v

/-- Gauge transformation parameter χ : V → R (0-cochain). -/
def gaugeTransform {R : Type*} [AddCommGroup R] (χ : V → R) (A : GaugeField1 V R) : GaugeField1 V R where
  A := fun u v => A.A u v + χ v - χ u
  skew u v := by
    simp [A.skew u v]
    abel

/-- Discrete gauge curvature (field strength) F_A = dA on an oriented triangle. -/
def curvature {R : Type*} [CommRing R] (A : GaugeField1 V R) (t : OrientedTriangle V q B) : R :=
  A.A t.u t.v + A.A t.v t.w + A.A t.w t.u

/-- Gauge invariance of the discrete curvature / field strength F_A. -/
theorem curvature_gauge_invariant {R : Type*} [CommRing R] (χ : V → R) (A : GaugeField1 V R)
    (t : OrientedTriangle V q B) :
    curvature B (gaugeTransform χ A) t = curvature B A t := by
  dsimp [curvature, gaugeTransform]
  abel

/-- Discrete line integral / holonomy along an ordered path of vertices. -/
def pathIntegral {R : Type*} [AddCommGroup R] (A : GaugeField1 V R) : List V → R
  | [] => 0
  | [_] => 0
  | u :: v :: rest => A.A u v + pathIntegral A (v :: rest)

/-- Stokes' theorem on a single triangle: The boundary line integral equals the curvature. -/
theorem pathIntegral_triangle {R : Type*} [CommRing R] (A : GaugeField1 V R) (t : OrientedTriangle V q B) :
    pathIntegral A [t.u, t.v, t.w, t.u] = curvature B A t := by
  dsimp [pathIntegral, curvature]
  abel

/-- Wilson loop phase along a closed cycle for a ℤ/2ℤ gauge field A. -/
def wilsonLoopPhase (A : GaugeField1 V (ZMod 2)) (loop : List V) : ℂ :=
  (-1 : ℂ) ^ (pathIntegral A loop).val

/-- Unitarity of the Wilson loop phase in terms of norm square. -/
theorem wilsonLoopPhase_normSq (A : GaugeField1 V (ZMod 2)) (loop : List V) :
    Complex.normSq (wilsonLoopPhase A loop) = 1 := by
  simp [wilsonLoopPhase]

/-- Discrete Chern-Simons action on a finite collection of oriented triangles at level k. -/
def discreteChernSimonsAction {R : Type*} [CommRing R] (faces : Finset (OrientedTriangle V q B)) (k : R) (A : GaugeField1 V R) : R :=
  k * ∑ t ∈ faces, A.A t.u t.v * curvature B A t

/-- Finite discrete Chern-Simons partition function with sign weighting. -/
def discreteChernSimonsPartitionFunction
    (faces : Finset (OrientedTriangle V q B)) (k : ZMod 2) (configs : Finset (GaugeField1 V (ZMod 2))) : ℂ :=
  ∑ A ∈ configs, (-1 : ℂ) ^ (discreteChernSimonsAction B faces k A).val

/-- Vanishing curvature implies vanishing CS action for flat connections. -/
theorem discreteChernSimonsAction_of_flat {R : Type*} [CommRing R]
    (faces : Finset (OrientedTriangle V q B)) (k : R) (A : GaugeField1 V R)
    (h_flat : ∀ t ∈ faces, curvature B A t = 0) :
    discreteChernSimonsAction B faces k A = 0 := by
  dsimp [discreteChernSimonsAction]
  rw [Finset.sum_eq_zero (fun t ht => by simp [h_flat t ht]), mul_zero]

-- ============================================================================
-- Section 4: Euler Product Phase Duality
-- ============================================================================

/-- Local Euler factor at prime p associated with the arithmetic knot q, evaluated at weight factor z : ℂ. -/
def localEulerFactor (p q : ℕ) [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] (z : ℂ) : ℂ :=
  1 - arithmeticHolonomy p q * z

/-- Pairwise Fredholm Euler product factor for the mutual link of two arithmetic knots. -/
def pairwiseFredholmFactor (p q : ℕ) [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] (z_p z_q : ℂ) : ℂ :=
  (localEulerFactor p q z_p) * (localEulerFactor q p z_q)

/-- The unitary phase in the local Euler factor is precisely the 1-loop CS holonomy. -/
theorem euler_factor_phase_eq_legendre
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)] (hpq : p ≠ q) (z : ℂ) :
    1 - localEulerFactor p q z = (legendreSym p (q : ℤ) : ℂ) * z := by
  simp [localEulerFactor, arithmetic_holonomy_eq_legendre hpq]

/-- **Euler Phase Symmetry Theorem**:
    When p ≡ 1 mod 4 or q ≡ 1 mod 4, the Euler product phases for the mutual link
    are symmetric: Hol(p, q) = Hol(q, p). -/
theorem euler_phase_symmetry_of_one_mod_four
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q)
    (h4 : p % 4 = 1 ∨ q % 4 = 1) :
    arithmeticHolonomy p q = arithmeticHolonomy q p := by
  dsimp [arithmeticHolonomy]
  rw [arithmetic_linking_symmetric_of_one_mod_four hp hq hpq h4]

lemma zmod2_add_eq_one_iff (a b : ZMod 2) :
    a + b = 1 ↔ (a = 0 ∧ b = 1) ∨ (a = 1 ∧ b = 0) := by
  revert a b; decide

/-- **Euler Phase Anti-Symmetry Theorem**:
    When p ≡ q ≡ 3 mod 4, the Euler product phases are anti-symmetric:
    Hol(p, q) = - Hol(q, p) (chiral / anti-symmetric phase duality). -/
theorem euler_phase_antisymmetry_of_three_mod_four
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q)
    (h3 : p % 4 = 3 ∧ q % 4 = 3) :
    arithmeticHolonomy p q = - arithmeticHolonomy q p := by
  rcases (zmod2_add_eq_one_iff _ _).mp
    (arithmetic_linking_skew_symmetric_of_three_mod_four hp hq hpq h3) with ⟨h0, h1⟩ | ⟨h1, h0⟩ <;>
    simp [arithmeticHolonomy, h0, h1, ZMod.val_one]

/-- **Global Fredholm Euler Phase Duality**:
    The product of phases in the pairwise Fredholm determinant matches the
    arithmetic Chern-Simons S-matrix reciprocity phase. -/
theorem euler_phase_duality_product
    {p q : ℕ} [Fact (Nat.Prime p)] [Fact (Nat.Prime q)]
    (hp : p ≠ 2) (hq : q ≠ 2) (hpq : p ≠ q) :
    arithmeticHolonomy p q * arithmeticHolonomy q p = (-1 : ℂ) ^ (p / 2 * (q / 2)) :=
  arithmetic_holonomy_reciprocity_product hp hq hpq

end ArithmeticTopology
