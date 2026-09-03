import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Metric
import Mathlib.Combinatorics.SimpleGraph.Maps
import Mathlib.Data.Finset.Lattice.Fold
import Mathlib.Tactic.Group
import Mathlib.Algebra.Ring.Basic

/-!
# Module 2: Tree Group Translation and Selberg / Ihara Euler Factors

This module formalizes the combinatorial and algebraic bridge connecting group actions
on graphs and trees (such as 2-adic Bruhat-Tits trees $\mathcal{T}_3$) to translation lengths,
closed geodesics, and Selberg / Ihara zeta Euler factors.

## Overview & Mathematical Framework

1. **Graph Automorphism Actions**:
   - `PreservesAdj`: An action of $\Gamma$ on a graph $T = (V, E)$ via `MulAction Γ V`
     preserving adjacency: $\forall g \in \Gamma, \forall u, v \in V, T.\mathrm{Adj}(g \cdot u, g \cdot v) \leftrightarrow T.\mathrm{Adj}(u, v)$.
   - `dist_smul`: Graph automorphisms preserve graph distance: $T.\mathrm{dist}(g \cdot u, g \cdot v) = T.\mathrm{dist}(u, v)$.

2. **Vertex Displacement & Conjugacy Invariance**:
   - `displacement`: Vertex displacement $\mathrm{disp}_T(g, v) = T.\mathrm{dist}(v, g \cdot v)$.
   - `displacement_conj`: For any $g, h \in \Gamma$, $\mathrm{disp}_T(h g h^{-1}, h \cdot v) = \mathrm{disp}_T(g, v)$.
   - `displacement_mul_le`: Triangle inequality for group composition.

3. **Translation Length for Group Actions**:
   - `minTranslationLength`: Minimal translation length over a finite representative vertex set:
     $\ell(g) = \min_{v \in V} T.\mathrm{dist}(v, g \cdot v)$.
   - `translation_length_conj_invariant`: Conjugation invariance $\ell(h g h^{-1}) = \ell(g)$.
   - `minTranslationLength_inv`: Inversion invariance $\ell(g^{-1}) = \ell(g)$.

4. **Free Actions and Positive Displacement**:
   - `IsFixedPointFree`: Action where no non-identity element fixes any vertex.
   - `translation_length_pos_of_free`: On connected graphs, fixed-point-free actions
     yield strictly positive translation length $\ell(g) > 0$ for all $g \neq 1$.

5. **Selberg / Ihara Euler Factors**:
   - `selbergEulerFactor`: The algebraic Euler factor $(1 - u^{\ell(g)}) \in R$ for $g \in \Gamma$.
   - `selbergEulerFactor_conj_invariant`: Conjugacy-class invariance of Euler factors.
   - `IsHyperbolic` / `IsElliptic`: Classification of group elements by translation length.
-/

namespace TreeGroupTranslation

section Translation

variable {V : Type*}

/-- A group action of `Γ` on the vertices of a simple graph `T` is an isometric graph action
if it preserves the adjacency relation. -/
def PreservesAdj (T : SimpleGraph V) (Γ : Type*) [Group Γ] [MulAction Γ V] : Prop :=
  ∀ (g : Γ) (u v : V), T.Adj (g • u) (g • v) ↔ T.Adj u v

variable {T : SimpleGraph V} {Γ : Type*} [Group Γ] [MulAction Γ V]

/-- The graph homomorphism induced by a group element `g` under an adjacency-preserving action. -/
def gHom (h_iso : PreservesAdj T Γ) (g : Γ) : T →g T where
  toFun := (g • ·)
  map_rel' := fun huv => (h_iso g _ _).2 huv

/-- An adjacency-preserving group action maps walks to walks. -/
def gWalkMap (h_iso : PreservesAdj T Γ) (g : Γ) {u v : V} (p : T.Walk u v) :
    T.Walk (g • u) (g • v) :=
  p.map (gHom h_iso g)

@[simp]
lemma gWalkMap_length (h_iso : PreservesAdj T Γ) (g : Γ) {u v : V} (p : T.Walk u v) :
    (gWalkMap h_iso g p).length = p.length :=
  SimpleGraph.Walk.length_map (gHom h_iso g) p

/-- Reachability is preserved under isometric group actions. -/
lemma reachable_smul_iff (h_iso : PreservesAdj T Γ) (g : Γ) (u v : V) :
    T.Reachable (g • u) (g • v) ↔ T.Reachable u v := by
  constructor
  · intro ⟨p⟩
    have p' := gWalkMap h_iso g⁻¹ p
    rw [inv_smul_smul, inv_smul_smul] at p'
    exact ⟨p'⟩
  · intro ⟨p⟩
    exact ⟨gWalkMap h_iso g p⟩

lemma dist_smul_le (h_iso : PreservesAdj T Γ) (g : Γ) (u v : V) :
    T.dist (g • u) (g • v) ≤ T.dist u v := by
  by_cases h : T.Reachable u v
  · obtain ⟨p, hp⟩ := h.exists_walk_length_eq_dist
    have := SimpleGraph.dist_le (gWalkMap h_iso g p)
    rw [gWalkMap_length, hp] at this
    exact this
  · have h2 : ¬ T.Reachable (g • u) (g • v) := by
      rwa [reachable_smul_iff h_iso]
    rw [SimpleGraph.dist_eq_zero_of_not_reachable h, SimpleGraph.dist_eq_zero_of_not_reachable h2]

/-- Isometric graph actions preserve graph distance `T.dist`. -/
lemma dist_smul (h_iso : PreservesAdj T Γ) (g : Γ) (u v : V) :
    T.dist (g • u) (g • v) = T.dist u v := by
  apply le_antisymm
  · exact dist_smul_le h_iso g u v
  · have := dist_smul_le h_iso g⁻¹ (g • u) (g • v)
    rwa [inv_smul_smul, inv_smul_smul] at this

/-- The vertex displacement of a vertex `v` under the action of `g ∈ Γ`. -/
noncomputable def displacement (T : SimpleGraph V) (g : Γ) (v : V) : ℕ :=
  T.dist v (g • v)

@[simp]
lemma displacement_one (T : SimpleGraph V) (v : V) :
    displacement T (1 : Γ) v = 0 := by
  unfold displacement
  rw [one_smul, SimpleGraph.dist_self]

/-- The displacement under the inverse element `g⁻¹` at `g • v` equals the displacement of `g` at `v`. -/
lemma displacement_inv (_h_iso : PreservesAdj T Γ) (g : Γ) (v : V) :
    displacement T g⁻¹ (g • v) = displacement T g v := by
  unfold displacement
  rw [inv_smul_smul, SimpleGraph.dist_comm]

/-- Conjugate displacement identity: conjugate elements act with identical displacement on shifted vertices. -/
lemma displacement_conj (h_iso : PreservesAdj T Γ) (g h : Γ) (v : V) :
    displacement T (h * g * h⁻¹) (h • v) = displacement T g v := by
  unfold displacement
  have h_act : (h * g * h⁻¹) • (h • v) = h • (g • v) := by
    rw [← mul_smul, mul_assoc (h * g), inv_mul_cancel, mul_one, mul_smul]
  rw [h_act, dist_smul h_iso h v (g • v)]

/-- Triangle inequality for vertex displacement under group element multiplication. -/
lemma displacement_mul_le (h_conn : T.Connected) (g₁ g₂ : Γ) (v : V) :
    displacement T (g₁ * g₂) v ≤ displacement T g₁ (g₂ • v) + displacement T g₂ v := by
  unfold displacement
  rw [mul_smul, add_comm]
  exact h_conn.dist_triangle

/-- Minimal translation length for a group element across a finite vertex domain. -/
noncomputable def minTranslationLength [Fintype V] [Nonempty V] (T : SimpleGraph V) (g : Γ) : ℕ :=
  Finset.univ.inf' Finset.univ_nonempty (fun v => displacement T g v)

@[simp]
lemma minTranslationLength_one [Fintype V] [Nonempty V] (T : SimpleGraph V) :
    minTranslationLength T (1 : Γ) = 0 := by
  unfold minTranslationLength
  apply le_antisymm
  · have hv : (Classical.arbitrary V) ∈ Finset.univ := Finset.mem_univ _
    have h_le := Finset.inf'_le (fun v => displacement T (1 : Γ) v) hv
    rw [displacement_one] at h_le
    exact h_le
  · exact Nat.zero_le _

lemma minTranslationLength_conj_le [Fintype V] [Nonempty V] (h_iso : PreservesAdj T Γ) (g h : Γ) :
    minTranslationLength T (h * g * h⁻¹) ≤ minTranslationLength T g := by
  apply Finset.le_inf'
  intro v _
  have h_le := Finset.inf'_le (fun u => displacement T (h * g * h⁻¹) u) (Finset.mem_univ (h • v))
  rw [displacement_conj h_iso] at h_le
  exact h_le

/-- The minimal translation length is invariant under group conjugation. -/
theorem translation_length_conj_invariant [Fintype V] [Nonempty V]
    (h_iso : PreservesAdj T Γ) (g h : Γ) :
    minTranslationLength T (h * g * h⁻¹) = minTranslationLength T g := by
  apply le_antisymm
  · exact minTranslationLength_conj_le h_iso g h
  · have h_inv := minTranslationLength_conj_le h_iso (h * g * h⁻¹) h⁻¹
    have h_simp : h⁻¹ * (h * g * h⁻¹) * (h⁻¹)⁻¹ = g := by
      group
    rwa [h_simp] at h_inv

/-- The minimal translation length of `g⁻¹` equals that of `g`. -/
lemma minTranslationLength_inv [Fintype V] [Nonempty V] (h_iso : PreservesAdj T Γ) (g : Γ) :
    minTranslationLength T g⁻¹ = minTranslationLength T g := by
  apply le_antisymm
  · apply Finset.le_inf'
    intro v _
    have h_le := Finset.inf'_le (fun u => displacement T g⁻¹ u) (Finset.mem_univ (g • v))
    rw [displacement_inv h_iso] at h_le
    exact h_le
  · have h_inv : minTranslationLength T (g⁻¹)⁻¹ ≤ minTranslationLength T g⁻¹ := by
      apply Finset.le_inf'
      intro v _
      have h_le := Finset.inf'_le (fun u => displacement T (g⁻¹)⁻¹ u) (Finset.mem_univ (g⁻¹ • v))
      rw [displacement_inv h_iso] at h_le
      exact h_le
    rwa [inv_inv] at h_inv

/-- A group action is fixed-point-free if every non-identity element moves all vertices. -/
def IsFixedPointFree (Γ : Type*) [Group Γ] (V : Type*) [MulAction Γ V] : Prop :=
  ∀ (g : Γ), g ≠ 1 → ∀ (v : V), g • v ≠ v

/-- On a connected graph, a fixed-point-free action guarantees strictly positive translation length
for every non-identity element. -/
lemma translation_length_pos_of_free [Fintype V] [Nonempty V]
    (h_conn : T.Connected) (h_free : IsFixedPointFree Γ V) (g : Γ) (hg : g ≠ 1) :
    0 < minTranslationLength T g := by
  unfold minTranslationLength
  rw [Finset.lt_inf'_iff]
  intro v _
  unfold displacement
  have h_neq : v ≠ g • v := fun h => h_free g hg v h.symm
  have h_dist_ne : T.dist v (g • v) ≠ 0 := by
    intro h0
    exact h_neq (h_conn.dist_eq_zero_iff.mp h0)
  exact Nat.pos_of_ne_zero h_dist_ne

/-- Variant of `translation_length_pos_of_free` accepting `h_iso` for interface generality. -/
lemma translation_length_pos_of_free' [Fintype V] [Nonempty V]
    (_h_iso : PreservesAdj T Γ) (h_conn : T.Connected) (h_free : IsFixedPointFree Γ V) (g : Γ) (hg : g ≠ 1) :
    0 < minTranslationLength T g :=
  translation_length_pos_of_free h_conn h_free g hg

/-- The algebraic Selberg / Ihara Euler factor associated with a group element `g ∈ Γ`. -/
noncomputable def selbergEulerFactor [Fintype V] [Nonempty V] {R : Type*} [CommRing R]
    (T : SimpleGraph V) (g : Γ) (u : R) : R :=
  1 - u ^ (minTranslationLength T g)

@[simp]
lemma selbergEulerFactor_one [Fintype V] [Nonempty V] {R : Type*} [CommRing R]
    (T : SimpleGraph V) (u : R) :
    selbergEulerFactor T (1 : Γ) u = 0 := by
  unfold selbergEulerFactor
  rw [minTranslationLength_one, pow_zero, sub_self]

/-- The Selberg Euler factor is invariant under group conjugation, hence depends only on the conjugacy class of `g`. -/
theorem selbergEulerFactor_conj_invariant [Fintype V] [Nonempty V] {R : Type*} [CommRing R]
    (T : SimpleGraph V) (h_iso : PreservesAdj T Γ) (g h : Γ) (u : R) :
    selbergEulerFactor T (h * g * h⁻¹) u = selbergEulerFactor T g u := by
  unfold selbergEulerFactor
  rw [translation_length_conj_invariant h_iso]

/-- The Selberg Euler factor is invariant under group inversion. -/
lemma selbergEulerFactor_inv [Fintype V] [Nonempty V] {R : Type*} [CommRing R]
    (T : SimpleGraph V) (h_iso : PreservesAdj T Γ) (g : Γ) (u : R) :
    selbergEulerFactor T g⁻¹ u = selbergEulerFactor T g u := by
  unfold selbergEulerFactor
  rw [minTranslationLength_inv h_iso]

/-- An element is hyperbolic if it has strictly positive translation length. -/
def IsHyperbolic [Fintype V] [Nonempty V] (T : SimpleGraph V) (g : Γ) : Prop :=
  0 < minTranslationLength T g

/-- An element is elliptic if it has translation length zero. -/
def IsElliptic [Fintype V] [Nonempty V] (T : SimpleGraph V) (g : Γ) : Prop :=
  minTranslationLength T g = 0

lemma isHyperbolic_iff_not_elliptic [Fintype V] [Nonempty V] (T : SimpleGraph V) (g : Γ) :
    IsHyperbolic T g ↔ ¬ IsElliptic T g := by
  unfold IsHyperbolic IsElliptic
  exact Nat.pos_iff_ne_zero

lemma isHyperbolic_conj [Fintype V] [Nonempty V] (h_iso : PreservesAdj T Γ) (g h : Γ) :
    IsHyperbolic T (h * g * h⁻¹) ↔ IsHyperbolic T g := by
  unfold IsHyperbolic
  rw [translation_length_conj_invariant h_iso]

end Translation

end TreeGroupTranslation
