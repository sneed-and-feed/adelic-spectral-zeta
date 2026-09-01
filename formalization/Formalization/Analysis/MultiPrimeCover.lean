import Mathlib.Data.Nat.Log
import Mathlib.Data.Rat.Cast.CharZero
import Mathlib.Algebra.Order.Field.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Positivity
import Mathlib.Data.Nat.GCD.Basic
import Mathlib.Data.List.Pairwise

open Nat

/-!
# Multi-Prime Ultrametric Tree Covering Bounds for DAG Computation Graphs

This file formalizes the mathematical theory of Multi-Prime Adèlic Tree Routing,
Hierarchical Separator Cuts, DAG Treewidth Covering, and Sparsity Scaling as
documented in `papers/learning_to_skip_blocks.md` (Section 3.9).

## Mathematical Overview

1. **Tree Depth & Routing Capacity**:
   - For a sequence of length `N` and prime branching factor `p`, the tree depth is
     `treeDepth p N = Nat.log p N = ⌊log_p N⌋`.
   - For a collection of prime bases `P = [p₁, ..., p_G]`, the Multi-Prime Routing Capacity is
     `multiPrimeCapacity P N = ∑_{g=1}^G ⌊log_{p_g} N⌋`.

2. **DAG Computation Graphs**:
   - Computation graphs over sequence vertices `Fin N` with causal acyclic dependencies
     (`(u, v) ∈ E ⟹ u < v`).

3. **Hierarchical Vertex Separator Cuts & Ultrametric Visibility**:
   - The `p`-ary tree visibility neighborhood `treeNeighborhood p N u` captures tokens `v`
     sharing hierarchical ancestral cuts up to depth `treeDepth p N`.
   - The Adèlic Multi-Prime Visibility Union `multiPrimeNeighborhood primes N u` is
     `⋃_{p ∈ primes} treeNeighborhood p N u`.

4. **DAG Treewidth Covering Theorem**:
   - Any DAG computation graph `G` whose dependencies admit a multi-prime hierarchical
     separator decomposition of capacity bounded by `multiPrimeCapacity primes N` is
     fully covered by the multi-prime tree visibility union:
     `∀ (u, v) ∈ E(G), v ∈ multiPrimeNeighborhood primes N u`.

5. **Coprime Independence & Dimension Additivity**:
   - Distinct prime/coprime bases provide independent ultrametric hierarchical dimensions.
   - The total routing capacity is additive: `Capacity(P, N) = ∑ ⌊log_{p_g} N⌋`, strictly
     exceeding any single prime tree capacity.

6. **Sparsity Scaling**:
   - While the multi-prime cover accommodates hierarchical treewidth `∑ ⌊log_{p_g} N⌋`,
     the active attention fraction per head group scales as `p_g^{-r_g}`, ensuring
     exponential sparsity in routing depth.
-/

section Definitions

/-- Tree depth of a `p`-ary tree over `N` tokens: `⌊log_p N⌋`. -/
def treeDepth (p N : ℕ) : ℕ := Nat.log p N

/-- Multi-Prime Tree Routing Capacity for a list of prime bases `primes = [p₁, ..., p_G]`
    over `N` tokens: `∑_{g=1}^G ⌊log_{p_g} N⌋`. -/
def multiPrimeCapacity (primes : List ℕ) (N : ℕ) : ℕ :=
  (primes.map (Nat.log · N)).sum

/-- A Directed Acyclic Graph (DAG) computation graph over a sequence of length `N`.
    Edges represent causal dependencies where a later token `v` depends on an earlier token `u`. -/
structure DAG (N : ℕ) where
  /-- Adjacency / directed edge relation: `adj u v` means `u → v`. -/
  adj : Fin N → Fin N → Prop
  /-- Causal acyclicity: all directed dependencies satisfy `u < v`. -/
  causal : ∀ {u v : Fin N}, adj u v → (u : ℕ) < (v : ℕ)

/-- Ancestor block index of token `u` at tree level `k` in base `p`. -/
def treeAncestor (p : ℕ) (k : ℕ) (u : Fin N) : ℕ :=
  (u : ℕ) / p ^ k

/-- Ultrametric tree visibility at scale `k` in base `p`: tokens `u` and `v` share
    the same `p`-ary ancestor cluster at level `k`. -/
def treeVisibleAt (p : ℕ) (k : ℕ) (u v : Fin N) : Prop :=
  treeAncestor p k u = treeAncestor p k v

/-- The Ultrametric Tree Visibility Neighborhood `𝒩_p(u)` for a `p`-ary tree over `N` tokens.
    Contains all tokens `v` sharing an ancestor cut with `u` at some level `k ≤ treeDepth p N`. -/
def treeNeighborhood (p N : ℕ) (u : Fin N) : Set (Fin N) :=
  { v | ∃ k ≤ treeDepth p N, treeVisibleAt p k u v }

/-- The Ultrametric Tree Visibility Neighborhood at a specific routing depth `r`. -/
def treeNeighborhoodAtDepth (p : ℕ) (r : ℕ) (u : Fin N) : Set (Fin N) :=
  { v | ∃ k ≤ r, treeVisibleAt p k u v }

/-- The Adèlic Multi-Prime Visibility Union `𝒩_multi(u) = ⋃_{p ∈ primes} 𝒩_p(u)`. -/
def multiPrimeNeighborhood (primes : List ℕ) (N : ℕ) (u : Fin N) : Set (Fin N) :=
  { v | ∃ p ∈ primes, v ∈ treeNeighborhood p N u }

/-- Multi-Prime Visibility Neighborhood with per-prime routing depth budgets. -/
def multiPrimeNeighborhoodWithDepths (primes : List ℕ) (depths : List ℕ) (u : Fin N) : Set (Fin N) :=
  { v | ∃ (p : ℕ) (r : ℕ), (p, r) ∈ primes.zip depths ∧ v ∈ treeNeighborhoodAtDepth p r u }

/-- Pairwise coprime prime bases property. -/
def CoprimeList (primes : List ℕ) : Prop :=
  primes.Pairwise Nat.Coprime

end Definitions

section GraphProperties

variable {N : ℕ}

/-- Every DAG computation graph is irreflexive (no self-loops). -/
theorem DAG.irrefl (G : DAG N) (u : Fin N) : ¬ G.adj u u :=
  fun h => lt_irrefl _ (G.causal h)

/-- Every DAG computation graph is asymmetric (no 2-cycles). -/
theorem DAG.asymm (G : DAG N) {u v : Fin N} (h : G.adj u v) : ¬ G.adj v u :=
  fun hvu => lt_asymm (G.causal h) (G.causal hvu)

/-- Visibility at scale `k` is reflexive. -/
theorem treeVisibleAt_refl (p k : ℕ) (u : Fin N) : treeVisibleAt p k u u := rfl

/-- Visibility at scale `k` is symmetric. -/
theorem treeVisibleAt_symm (p k : ℕ) {u v : Fin N} (h : treeVisibleAt p k u v) :
    treeVisibleAt p k v u := h.symm

/-- Visibility at scale `k` is transitive. -/
theorem treeVisibleAt_trans (p k : ℕ) {u v w : Fin N}
    (h1 : treeVisibleAt p k u v) (h2 : treeVisibleAt p k v w) :
    treeVisibleAt p k u w := h1.trans h2

/-- Every token is in its own ultrametric tree neighborhood. -/
theorem mem_treeNeighborhood_self (p N : ℕ) (u : Fin N) :
    u ∈ treeNeighborhood p N u :=
  ⟨0, Nat.zero_le _, rfl⟩

/-- Monotonicity of tree visibility with respect to routing depth. -/
theorem treeNeighborhood_mono (p : ℕ) {r₁ r₂ : ℕ} (hr : r₁ ≤ r₂) (u : Fin N) :
    treeNeighborhoodAtDepth p r₁ u ⊆ treeNeighborhoodAtDepth p r₂ u :=
  fun _ ⟨k, hk, hvis⟩ => ⟨k, hk.trans hr, hvis⟩

/-- Single-prime neighborhood is a subset of the multi-prime visibility union. -/
theorem treeNeighborhood_subset_multiPrime (primes : List ℕ) (p : ℕ) (hp : p ∈ primes)
    (N : ℕ) (u : Fin N) :
    treeNeighborhood p N u ⊆ multiPrimeNeighborhood primes N u :=
  fun _ hv => ⟨p, hp, hv⟩

/-- Every token is in its own multi-prime neighborhood (for non-empty prime lists). -/
theorem mem_multiPrimeNeighborhood_self (primes : List ℕ) (p : ℕ) (hp : p ∈ primes)
    (N : ℕ) (u : Fin N) :
    u ∈ multiPrimeNeighborhood primes N u :=
  ⟨p, hp, mem_treeNeighborhood_self p N u⟩

end GraphProperties

section TreewidthCovering

variable {N : ℕ}

/-- A Multi-Prime Tree Decomposition of a DAG `G` over `Fin N` with respect to `primes`.
    Certifies that every dependency edge `u → v` is assigned to a prime hierarchy `p ∈ primes`
    and a hierarchical cut level `k ≤ treeDepth p N` sharing ancestor clusters. -/
structure MultiPrimeTreeDecomposition (N : ℕ) (primes : List ℕ) (G : DAG N) where
  /-- Active prime base assigned to dependency edge `u → v`. -/
  edgePrime : ∀ {u v : Fin N}, G.adj u v → ℕ
  /-- The chosen prime belongs to the prime list `primes`. -/
  prime_mem : ∀ {u v : Fin N} (h : G.adj u v), edgePrime h ∈ primes
  /-- Active hierarchical cut level assigned to dependency edge `u → v`. -/
  edgeLevel : ∀ {u v : Fin N}, G.adj u v → ℕ
  /-- The cut level respects the tree depth bound for that prime base. -/
  level_le : ∀ {u v : Fin N} (h : G.adj u v), edgeLevel h ≤ treeDepth (edgePrime h) N
  /-- Hierarchical containment: endpoints share the ancestor cut at that level. -/
  edge_covered : ∀ {u v : Fin N} (h : G.adj u v),
    treeVisibleAt (edgePrime h) (edgeLevel h) u v

/-- Predicate asserting that a DAG `G` admits a multi-prime tree decomposition. -/
def HasMultiPrimeTreeDecomposition (N : ℕ) (primes : List ℕ) (G : DAG N) : Prop :=
  Nonempty (MultiPrimeTreeDecomposition N primes G)

/-- **DAG Treewidth Covering Theorem**:
    Any DAG computation graph `G` admitting a Multi-Prime Tree Decomposition over `primes`
    is fully covered by the Adèlic Multi-Prime Visibility Union:
    `∀ (u, v) ∈ E(G), v ∈ 𝒩_multi(u)`. -/
theorem dag_treewidth_covering (N : ℕ) (primes : List ℕ) (G : DAG N)
    (decomp : MultiPrimeTreeDecomposition N primes G) :
    ∀ ⦃u v : Fin N⦄, G.adj u v → v ∈ multiPrimeNeighborhood primes N u :=
  fun _ _ huv => ⟨decomp.edgePrime huv, decomp.prime_mem huv, decomp.edgeLevel huv, decomp.level_le huv, decomp.edge_covered huv⟩

/-- Non-constructive corollary of the DAG Treewidth Covering Theorem. -/
theorem dag_treewidth_covering_of_exists (N : ℕ) (primes : List ℕ) (G : DAG N)
    (h : HasMultiPrimeTreeDecomposition N primes G) :
    ∀ ⦃u v : Fin N⦄, G.adj u v → v ∈ multiPrimeNeighborhood primes N u :=
  let ⟨decomp⟩ := h; dag_treewidth_covering N primes G decomp

/-- Multi-Prime Tree Decomposition with explicit depth bounds. -/
structure MultiPrimeTreeDecompositionWithDepths (N : ℕ) (primes : List ℕ) (depths : List ℕ) (G : DAG N) where
  /-- Active prime base. -/
  edgePrime : ∀ {u v : Fin N}, G.adj u v → ℕ
  /-- Active depth bound. -/
  edgeDepth : ∀ {u v : Fin N}, G.adj u v → ℕ
  /-- Pair `(p, r)` is in `primes.zip depths`. -/
  pair_mem : ∀ {u v : Fin N} (h : G.adj u v), (edgePrime h, edgeDepth h) ∈ primes.zip depths
  /-- Active cut level. -/
  edgeLevel : ∀ {u v : Fin N}, G.adj u v → ℕ
  /-- Cut level bounded by depth budget. -/
  level_le : ∀ {u v : Fin N} (h : G.adj u v), edgeLevel h ≤ edgeDepth h
  /-- Hierarchical containment. -/
  edge_covered : ∀ {u v : Fin N} (h : G.adj u v),
    treeVisibleAt (edgePrime h) (edgeLevel h) u v

/-- DAG Treewidth Covering Theorem with explicit routing depth budgets. -/
theorem dag_treewidth_covering_with_depths (N : ℕ) (primes : List ℕ) (depths : List ℕ) (G : DAG N)
    (decomp : MultiPrimeTreeDecompositionWithDepths N primes depths G) :
    ∀ ⦃u v : Fin N⦄, G.adj u v → v ∈ multiPrimeNeighborhoodWithDepths primes depths u :=
  fun _ _ huv => ⟨decomp.edgePrime huv, decomp.edgeDepth huv, decomp.pair_mem huv,
    decomp.edgeLevel huv, decomp.level_le huv, decomp.edge_covered huv⟩

end TreewidthCovering

section DimensionAdditivity

/-- Empty prime list capacity is 0. -/
theorem multiPrimeCapacity_nil (N : ℕ) : multiPrimeCapacity [] N = 0 := rfl

/-- Multi-Prime Capacity expands additively upon prepending a prime base. -/
theorem multiPrimeCapacity_cons (p : ℕ) (primes : List ℕ) (N : ℕ) :
    multiPrimeCapacity (p :: primes) N = treeDepth p N + multiPrimeCapacity primes N := rfl

/-- Dimension Additivity under list concatenation:
    `Capacity(l₁ ++ l₂, N) = Capacity(l₁, N) + Capacity(l₂, N)`. -/
theorem multiPrimeCapacity_append (l₁ l₂ : List ℕ) (N : ℕ) :
    multiPrimeCapacity (l₁ ++ l₂) N = multiPrimeCapacity l₁ N + multiPrimeCapacity l₂ N := by
  simp [multiPrimeCapacity]

/-- The multi-prime capacity is greater than or equal to any constituent prime's tree capacity. -/
theorem multiPrimeCapacity_ge_single (primes : List ℕ) (p : ℕ) (hp : p ∈ primes) (N : ℕ) :
    treeDepth p N ≤ multiPrimeCapacity primes N := by
  induction primes with
  | nil => contradiction
  | cons head tail ih =>
    cases hp with
    | head => exact Nat.le_add_right _ _
    | tail _ hp => exact (ih hp).trans (Nat.le_add_left _ _)

/-- Additivity for a pair of prime bases: `Capacity([p₁, p₂], N) = ⌊log_{p₁} N⌋ + ⌊log_{p₂} N⌋`. -/
theorem multiPrimeCapacity_pair (p₁ p₂ N : ℕ) :
    multiPrimeCapacity [p₁, p₂] N = treeDepth p₁ N + treeDepth p₂ N := by
  simp [multiPrimeCapacity, treeDepth]

/-- Additivity for a triple of prime bases: `Capacity([p₁, p₂, p₃], N) = ⌊log_{p₁} N⌋ + ⌊log_{p₂} N⌋ + ⌊log_{p₃} N⌋`. -/
theorem multiPrimeCapacity_triple (p₁ p₂ p₃ N : ℕ) :
    multiPrimeCapacity [p₁, p₂, p₃] N = treeDepth p₁ N + treeDepth p₂ N + treeDepth p₃ N := by
  simp [multiPrimeCapacity, treeDepth, Nat.add_assoc]

/-- Strict capacity gain: when multiple primes contribute non-zero tree depth,
    multi-prime capacity strictly exceeds any single constituent prime's capacity. -/
theorem multiPrimeCapacity_strict_gain (primes : List ℕ) (p : ℕ) (hp : p ∈ primes)
    (q : ℕ) (hq : q ∈ primes) (hne : p ≠ q) (N : ℕ) (hq_pos : 0 < treeDepth q N) :
    treeDepth p N < multiPrimeCapacity primes N := by
  induction primes with
  | nil => contradiction
  | cons head tail ih =>
    rw [multiPrimeCapacity_cons]
    cases hp with
    | head =>
      cases hq with
      | head => contradiction
      | tail _ hq_tail =>
        have := multiPrimeCapacity_ge_single tail q hq_tail N
        omega
    | tail _ hp_tail =>
      cases hq with
      | head =>
        have := multiPrimeCapacity_ge_single tail p hp_tail N
        omega
      | tail _ hq_tail =>
        have := ih hp_tail hq_tail
        omega

/-- Pairwise coprime verification for prime bases 2, 3, 5. -/
theorem coprime_2_3_5 : CoprimeList [2, 3, 5] := by
  dsimp [CoprimeList]
  decide

/-- Quantitative evaluation: multi-prime capacity for primes `[2, 3]` at `N = 4096` equals 19. -/
theorem multiPrimeCapacity_eval_2_3_4096 : multiPrimeCapacity [2, 3] 4096 = 19 := by
  decide

/-- Single-tree depth for base 2 at `N = 4096` equals 12. -/
theorem single_tree_eval_2_4096 : treeDepth 2 4096 = 12 := by
  decide

/-- Single-tree depth for base 3 at `N = 4096` equals 7. -/
theorem single_tree_eval_3_4096 : treeDepth 3 4096 = 7 := by
  decide

/-- Multi-prime capacity strictly exceeds single-prime depth for `[2, 3]` at `N = 4096`. -/
theorem multiPrime_exceeds_single_2_3_4096 : treeDepth 2 4096 < multiPrimeCapacity [2, 3] 4096 := by
  decide

/-- Quantitative evaluation: multi-prime capacity for primes `[2, 3, 5]` at `N = 1024` equals 20. -/
theorem multiPrimeCapacity_eval_2_3_5_1024 : multiPrimeCapacity [2, 3, 5] 1024 = 20 := by
  decide

end DimensionAdditivity

section SparsityScaling

/-- Active attention fraction for a `p`-ary tree at routing depth `r`: `p^{-r}`. -/
def activeFraction (p r : ℕ) : ℚ := (1 : ℚ) / (p : ℚ) ^ r

/-- Total active attention upper bound across multi-prime router groups: `∑_{g=1}^G p_g^{-r_g}`. -/
def multiPrimeActiveBound (primes : List ℕ) (depths : List ℕ) : ℚ :=
  ((primes.zip depths).map (fun pr => activeFraction pr.1 pr.2)).sum

/-- Average active attention fraction across multi-prime router groups. -/
def multiPrimeAvgActiveFraction (primes : List ℕ) (depths : List ℕ) : ℚ :=
  multiPrimeActiveBound primes depths / (primes.length : ℚ)

/-- Multi-prime overall sparsity fraction: `1 - multiPrimeAvgActiveFraction`. -/
def multiPrimeSparsity (primes : List ℕ) (depths : List ℕ) : ℚ :=
  1 - multiPrimeAvgActiveFraction primes depths

/-- Active attention fraction is strictly positive for positive prime bases. -/
theorem activeFraction_pos (p r : ℕ) (hp : 0 < p) : 0 < activeFraction p r := by
  dsimp [activeFraction]; positivity

/-- Active attention fraction is bounded above by 1. -/
theorem activeFraction_le_one (p r : ℕ) (hp : 1 ≤ p) : activeFraction p r ≤ 1 :=
  div_le_one_of_le₀ (one_le_pow₀ (Nat.one_le_cast.mpr hp)) (by positivity)

/-- Non-negativity of the multi-prime active attention bound. -/
theorem multiPrimeActiveBound_nonneg (primes : List ℕ) (depths : List ℕ) :
    0 ≤ multiPrimeActiveBound primes depths :=
  List.sum_nonneg fun _ hx => by
    rcases List.mem_map.mp hx with ⟨⟨p, r⟩, _, rfl⟩
    dsimp [activeFraction]
    positivity

/-- Non-negativity of the multi-prime average active attention fraction. -/
theorem multiPrimeAvgActiveFraction_nonneg (primes : List ℕ) (depths : List ℕ) :
    0 ≤ multiPrimeAvgActiveFraction primes depths :=
  div_nonneg (multiPrimeActiveBound_nonneg primes depths) (Nat.cast_nonneg _)

/-- Multi-prime sparsity is bounded above by 1. -/
theorem multiPrimeSparsity_le_one (primes : List ℕ) (depths : List ℕ) :
    multiPrimeSparsity primes depths ≤ 1 :=
  sub_le_self 1 (multiPrimeAvgActiveFraction_nonneg primes depths)

/-- Quantitative evaluation: active attention bound for `[2, 3]` with depths `[3, 2]` is `17 / 72`. -/
theorem activeBound_eval_2_3_r3_r2 : multiPrimeActiveBound [2, 3] [3, 2] = 17 / 72 := by
  dsimp [multiPrimeActiveBound, activeFraction]; norm_num

/-- Quantitative evaluation: average active attention fraction for `[2, 3]` with depths `[3, 2]` is `17 / 144`. -/
theorem avgActiveFraction_eval_2_3_r3_r2 : multiPrimeAvgActiveFraction [2, 3] [3, 2] = 17 / 144 := by
  dsimp [multiPrimeAvgActiveFraction, multiPrimeActiveBound, activeFraction]; norm_num

/-- Quantitative evaluation: overall sparsity for `[2, 3]` with depths `[3, 2]` is `127 / 144` (~88.19%). -/
theorem sparsity_eval_2_3_r3_r2 : multiPrimeSparsity [2, 3] [3, 2] = 127 / 144 := by
  dsimp [multiPrimeSparsity, multiPrimeAvgActiveFraction, multiPrimeActiveBound, activeFraction]; norm_num

end SparsityScaling
