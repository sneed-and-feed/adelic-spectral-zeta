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
import Formalization.Buildings.BuildingPGL3

open BigOperators

/-!
# Abstract Simplicial Affine Buildings of Type Ã_{n-1} and Adjacency Operators

This module formalizes:
1. **Gaussian q-Binomial Coefficients**:
   - Explicit recursive definition `qBinomial n r q`.
   - Base values `qBinomial n 0 q = 1`, `qBinomial n 1 q = ∑ i ∈ Finset.range n, q^i`.
   - Pascal recurrences and symmetry `qBinomial n r q = qBinomial n (n - r) q`.
   - Exact evaluations for low ranks $n = 2, 3, 4$.

2. **Simplicial Building Structure of Type Ã_{n-1}**:
   - $n$-colored vertex partition `color : V → Fin n`.
   - Type-$r$ directed adjacency relations `adj r : V → V → Prop` for $r \in \text{Fin } n$.
   - Color shifting: `adj r u v → color v = color u + r`.
   - Adjacency duality: `adj r u v ↔ adj (-r) v u`.
   - Degree regularity: `(neighbors r v).card = qBinomial n r.val q`.

3. **Type-Preserving Adjacency Operators and Discrete Multi-Laplacian**:
   - Adjacency operators $A_r f(v) = \sum_{w \sim_r v} f(w)$.
   - Additivity, $\mathbb{R}$-linearity, and constant evaluation.
   - Discrete multi-Laplacian $\Delta = \sum_{r \neq 0} A_r - \left(\sum_{r \neq 0} \binom{n}{r}_q\right) I$.
   - Proof of $\Delta(\text{const}) = 0$.

4. **Low-Rank Specialization**:
   - Canonical projection from `BuildingAn V 3 q` to the rank-3 `BuildingA2 V q`.

All theorems are proved with **zero sorries** and **zero custom axioms**.
-/

-- ============================================================================
-- Section 1: Gaussian q-Binomial Coefficients and Recurrences
-- ============================================================================

/-- Gaussian q-binomial coefficient (q-ary Gaussian polynomial) `[n choose r]_q`.
    Counts the number of r-dimensional subspaces in an n-dimensional vector space over 𝔽_q. -/
def qBinomial : ℕ → ℕ → ℕ → ℕ
  | _, 0, _ => 1
  | 0, _ + 1, _ => 0
  | n + 1, r + 1, q =>
    if r + 1 > n + 1 then 0
    else qBinomial n (r + 1) q + q^(n - r) * qBinomial n r q

/-- Base case: `[n choose 0]_q = 1`. -/
@[simp]
theorem qBinomial_zero (n q : ℕ) : qBinomial n 0 q = 1 := by
  cases n <;> rfl

/-- Vanishing for `r > n`: `[n choose r]_q = 0`. -/
theorem qBinomial_gt {n r : ℕ} (h : n < r) (q : ℕ) : qBinomial n r q = 0 := by
  induction' n with n ih generalizing r
  · cases r <;> [omega; rfl]
  · cases r; · omega
    dsimp [qBinomial]; split_ifs <;> [rfl; omega]

/-- Diagonal case: `[n choose n]_q = 1`. -/
@[simp]
theorem qBinomial_self (n q : ℕ) : qBinomial n n q = 1 := by
  induction' n with n ih
  · rfl
  · dsimp [qBinomial]; rw [qBinomial_gt (by omega)]; simp [ih]

/-- Standard Pascal-type recurrence for Gaussian q-binomial coefficients:
    `[n+1 choose r+1]_q = [n choose r+1]_q + q^(n-r) * [n choose r]_q`. -/
theorem qBinomial_succ_succ (n r q : ℕ) (h : r ≤ n) :
    qBinomial (n + 1) (r + 1) q = qBinomial n (r + 1) q + q^(n - r) * qBinomial n r q := by
  dsimp [qBinomial]; split_ifs <;> [omega; rfl]

/-- Value at `r = 1`: `[n choose 1]_q = ∑_{i=0}^{n-1} q^i`. -/
theorem qBinomial_one (n q : ℕ) : qBinomial n 1 q = ∑ i ∈ Finset.range n, q^i := by
  induction' n with n ih
  · simp [qBinomial]
  · dsimp [qBinomial]; rw [ih, qBinomial_zero, mul_one, Finset.sum_range_succ]

/-- Dual recurrence and symmetry of Gaussian q-binomial coefficients by simultaneous induction:
    (1) `[n choose r]_q = [n choose n - r]_q`
    (2) `[n+1 choose r+1]_q = q^(r+1) * [n choose r+1]_q + [n choose r]_q`. -/
theorem qBinomial_dual_and_symm (n : ℕ) (q : ℕ) :
    (∀ r ≤ n, qBinomial n r q = qBinomial n (n - r) q) ∧
    (∀ r ≤ n, qBinomial (n + 1) (r + 1) q = q^(r + 1) * qBinomial n (r + 1) q + qBinomial n r q) := by
  induction' n with n ih
  · exact ⟨fun r _ => by interval_cases r; rfl, fun r _ => by interval_cases r; rfl⟩
  · rcases ih with ⟨ih_symm, ih_dual⟩
    have h_dual_succ : ∀ r ≤ n + 1, qBinomial (n + 2) (r + 1) q = q^(r + 1) * qBinomial (n + 1) (r + 1) q + qBinomial (n + 1) r q := by
      intro r hr
      rcases r with _|r
      · rw [qBinomial_one, qBinomial_one, qBinomial_zero, Finset.sum_range_succ', pow_zero, Finset.mul_sum]
        congr 1; exact Finset.sum_congr rfl (fun i _ => by rw [pow_succ', pow_one])
      · by_cases hr_eq : r + 1 = n + 1
        · obtain rfl : r = n := by omega
          rw [qBinomial_self, qBinomial_gt (by omega), mul_zero, zero_add, qBinomial_self]
        · have hr_lt : r + 1 ≤ n := by omega
          have hpow : q ^ (n - r) * q ^ (r + 1) = q ^ (r + 2) * q ^ (n - (r + 1)) := by
            rw [← pow_add, ← pow_add]; congr 1; omega
          have h_sub_1 : (n + 1) - (r + 1) = n - r := by omega
          have h1 : qBinomial (n + 2) (r + 2) q = (q ^ (r + 2) * qBinomial n (r + 2) q + qBinomial n (r + 1) q) +
              q ^ (n - r) * (q ^ (r + 1) * qBinomial n (r + 1) q + qBinomial n r q) := by
            rw [qBinomial_succ_succ (n + 1) (r + 1) q (by omega), h_sub_1, ih_dual (r + 1) hr_lt, ih_dual r (by omega)]
          have h2 : q ^ (r + 2) * qBinomial (n + 1) (r + 2) q + qBinomial (n + 1) (r + 1) q =
              (q ^ (r + 2) * qBinomial n (r + 2) q + (q ^ (r + 2) * q ^ (n - (r + 1))) * qBinomial n (r + 1) q) +
              (qBinomial n (r + 1) q + q ^ (n - r) * qBinomial n r q) := by
            rw [qBinomial_succ_succ n (r + 1) q (by omega), qBinomial_succ_succ n r q (by omega)]; ring
          rw [h1, h2, ← hpow]; ring
    refine ⟨fun r hr => ?_, h_dual_succ⟩
    rcases r with _|r
    · rw [tsub_zero, qBinomial_zero, qBinomial_self]
    · by_cases hr_eq : r + 1 = n + 1
      · rw [hr_eq, tsub_self, qBinomial_zero, qBinomial_self]
      · have hr_lt : r ≤ n := by omega
        rw [ih_dual r hr_lt, ih_symm (r + 1) (by omega), ih_symm r hr_lt]
        have hsub : n + 1 - (r + 1) = (n - r - 1) + 1 := by omega
        have hsub2 : n - (n - r - 1) = r + 1 := by omega
        have hsub3 : (n - r - 1) + 1 = n - r := by omega
        have hsub4 : n - (r + 1) = n - r - 1 := by omega
        rw [hsub, qBinomial_succ_succ n (n - r - 1) q (by omega), hsub2, hsub3, hsub4]
        ring

/-- Symmetry of Gaussian q-binomial coefficients: `[n choose r]_q = [n choose n - r]_q`. -/
theorem qBinomial_symm (n r q : ℕ) (h : r ≤ n) : qBinomial n r q = qBinomial n (n - r) q :=
  (qBinomial_dual_and_symm n q).1 r h

/-- Dual Pascal recurrence: `[n+1 choose r+1]_q = q^(r+1) * [n choose r+1]_q + [n choose r]_q`. -/
theorem qBinomial_succ_succ_dual (n r q : ℕ) (h : r ≤ n) :
    qBinomial (n + 1) (r + 1) q = q^(r + 1) * qBinomial n (r + 1) q + qBinomial n r q :=
  (qBinomial_dual_and_symm n q).2 r h

/-- Evaluation: `[2 choose 1]_q = q + 1`. -/
theorem qBinomial_two_one (q : ℕ) : qBinomial 2 1 q = q + 1 := by
  rw [qBinomial_one]; simp [Finset.sum_range_succ]; ring

/-- Evaluation: `[3 choose 1]_q = q² + q + 1`. -/
theorem qBinomial_three_one (q : ℕ) : qBinomial 3 1 q = q^2 + q + 1 := by
  rw [qBinomial_one]; simp [Finset.sum_range_succ]; ring

/-- Evaluation: `[3 choose 2]_q = q² + q + 1`. -/
theorem qBinomial_three_two (q : ℕ) : qBinomial 3 2 q = q^2 + q + 1 := by
  rw [qBinomial_symm 3 2 q (by omega), show 3 - 2 = 1 from rfl, qBinomial_three_one]

/-- Evaluation: `[4 choose 1]_q = q³ + q² + q + 1`. -/
theorem qBinomial_four_one (q : ℕ) : qBinomial 4 1 q = q^3 + q^2 + q + 1 := by
  rw [qBinomial_one]; simp [Finset.sum_range_succ]; ring

/-- Evaluation: `[4 choose 3]_q = q³ + q² + q + 1`. -/
theorem qBinomial_four_three (q : ℕ) : qBinomial 4 3 q = q^3 + q^2 + q + 1 := by
  rw [qBinomial_symm 4 3 q (by omega), show 4 - 3 = 1 from rfl, qBinomial_four_one]

/-- Evaluation: `[4 choose 2]_q = q⁴ + q³ + 2q² + q + 1`. -/
theorem qBinomial_four_two (q : ℕ) : qBinomial 4 2 q = q^4 + q^3 + 2 * q^2 + q + 1 := by
  rw [qBinomial_succ_succ 3 1 q (by omega), qBinomial_three_two, qBinomial_three_one]; ring

-- ============================================================================
-- Section 2: Abstract Simplicial Affine Building Structure of type Ã_{n-1}
-- ============================================================================

/-- Structure representing an abstract simplicial affine Bruhat-Tits building of type Ã_{n-1}
    with prime-power parameter q and rank n ≥ 1. -/
structure BuildingAn (V : Type*) (n : ℕ) [NeZero n] (q : ℕ) where
  /-- Vertex coloring / type map τ : V → ℤ/nℤ (represented by `Fin n`) -/
  color : V → Fin n
  /-- Directed type-r adjacency relation on vertices for each type index r : Fin n -/
  adj : Fin n → V → V → Prop
  /-- Type-r adjacency advances vertex color by r (mod n) -/
  color_adj : ∀ (r : Fin n) {u v : V}, adj r u v → color v = color u + r
  /-- Duality between type-r and type-(-r) adjacencies: u ∼_r v ↔ v ∼_{-r} u -/
  adj_dual : ∀ (r : Fin n) {u v : V}, adj r u v ↔ adj (-r) v u
  /-- Finite neighbor set of type-r neighbors for each vertex -/
  neighbors : Fin n → V → Finset V
  /-- Correctness of the type-r neighbor set -/
  mem_neighbors : ∀ (r : Fin n) (u v : V), v ∈ neighbors r u ↔ adj r u v
  /-- Degree regularity: each vertex has exactly [n choose r]_q neighbors of type r -/
  card_neighbors : ∀ (r : Fin n) (v : V), (neighbors r v).card = qBinomial n r.val q

namespace BuildingAn

variable {V : Type*} {n : ℕ} [NeZero n] {q : ℕ} (B : BuildingAn V n q) {R : Type*} [CommRing R]

/-- The number of type-(-r) neighbors equals the number of type-r neighbors. -/
theorem card_neighbors_neg (r : Fin n) (v : V) (hr : r ≠ 0) :
    (B.neighbors (-r) v).card = (B.neighbors r v).card := by
  rw [B.card_neighbors, B.card_neighbors, Fin.val_neg]
  split_ifs with h0
  · contradiction
  · exact (qBinomial_symm n r.val q (by omega)).symm

-- ============================================================================
-- Section 3: Adjacency Operators on Function Spaces
-- ============================================================================

/-- Type-r adjacency operator A_r acting on vertex functions f : V → R:
    (A_r f)(v) = ∑_{w ∈ neighbors r v} f(w). -/
def adjOp (r : Fin n) (f : V → R) (v : V) : R :=
  ∑ w ∈ B.neighbors r v, f w

/-- Additivity of the adjacency operator A_r. -/
theorem adjOp_add (r : Fin n) (f g : V → R) (v : V) :
    B.adjOp r (f + g) v = B.adjOp r f v + B.adjOp r g v := by
  simp [adjOp, Finset.sum_add_distrib]

/-- Scalar multiplication linearity of the adjacency operator A_r. -/
theorem adjOp_smul (r : Fin n) (c : R) (f : V → R) (v : V) :
    B.adjOp r (fun x => c * f x) v = c * B.adjOp r f v := by
  simp [adjOp, Finset.mul_sum]

/-- Action of the adjacency operator A_r on constant functions:
    (A_r c)(v) = [n choose r]_q * c. -/
theorem adjOp_const (r : Fin n) (c : R) (v : V) :
    B.adjOp r (fun _ => c) v = (qBinomial n r.val q : R) * c := by
  simp [adjOp, B.card_neighbors, nsmul_eq_mul]

-- ============================================================================
-- Section 4: Discrete Multi-Laplacian Operator
-- ============================================================================

/-- Total regular degree of the building: d_{reg}(n, q) = ∑_{r ≠ 0} [n choose r]_q. -/
def totalDegree (n : ℕ) [NeZero n] (q : ℕ) : ℕ :=
  ∑ r : Fin n, if r.val ≠ 0 then qBinomial n r.val q else 0

/-- Discrete multi-Laplacian operator Δ acting on functions f : V → R:
    (Δ f)(v) = (∑_{r ≠ 0} A_r f)(v) - (∑_{r ≠ 0} [n choose r]_q) f(v). -/
def discreteLaplacian (f : V → R) (v : V) : R :=
  (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r f v else 0) -
    (∑ r : Fin n, if r.val ≠ 0 then (qBinomial n r.val q : R) else 0) * f v

/-- Additivity of the discrete multi-Laplacian: Δ(f + g) = Δ f + Δ g. -/
theorem discreteLaplacian_add (f g : V → R) (v : V) :
    B.discreteLaplacian (f + g) v = B.discreteLaplacian f v + B.discreteLaplacian g v := by
  dsimp [discreteLaplacian]
  rw [show (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r (f + g) v else (0 : R)) =
      (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r f v else 0) +
      (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r g v else 0) by
    rw [← Finset.sum_add_distrib]; exact Finset.sum_congr rfl (fun r _ => by split_ifs with hr <;> simp [B.adjOp_add])]
  ring

/-- Scalar linearity of the discrete multi-Laplacian: Δ(c • f) = c • Δ f. -/
theorem discreteLaplacian_smul (c : R) (f : V → R) (v : V) :
    B.discreteLaplacian (fun x => c * f x) v = c * B.discreteLaplacian f v := by
  dsimp [discreteLaplacian]
  rw [show (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r (fun x => c * f x) v else (0 : R)) =
      c * (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r f v else 0) by
    rw [Finset.mul_sum]; exact Finset.sum_congr rfl (fun r _ => by split_ifs with hr <;> simp [B.adjOp_smul])]
  ring

/-- Annihilation of constant functions: Δ(c) = 0 for any constant c ∈ R. -/
theorem discreteLaplacian_const (c : R) (v : V) :
    B.discreteLaplacian (fun _ => c) v = 0 := by
  dsimp [discreteLaplacian]
  rw [show (∑ r : Fin n, if r.val ≠ 0 then B.adjOp r (fun _ => c) v else (0 : R)) =
      (∑ r : Fin n, if r.val ≠ 0 then (qBinomial n r.val q : R) else 0) * c by
    rw [Finset.sum_mul]; exact Finset.sum_congr rfl (fun r _ => by split_ifs with hr <;> simp [B.adjOp_const])]
  ring

end BuildingAn

-- ============================================================================
-- Section 5: Specialization and Bridges to Low-Rank Buildings
-- ============================================================================

/-- **Theorem (Rank-3 Specialization)**:
    Every affine building `BuildingAn V 3 q` of rank 3 canonically induces
    a 2D affine building `BuildingA2 V q`. -/
def BuildingAn.toBuildingA2 {V : Type*} {q : ℕ} (B : BuildingAn V 3 q) : BuildingA2 V q where
  color := B.color
  adj1 := B.adj 1
  adj2 := B.adj 2
  color_adj1 := B.color_adj 1
  color_adj2 := B.color_adj 2
  adj_dual := (B.adj_dual 1).symm
  neighbors1 := B.neighbors 1
  neighbors2 := B.neighbors 2
  mem_neighbors1 := B.mem_neighbors 1
  mem_neighbors2 := B.mem_neighbors 2
  card_neighbors1 v := by simp [B.card_neighbors, qBinomial_three_one]
  card_neighbors2 v := by simp [B.card_neighbors, qBinomial_three_two]

