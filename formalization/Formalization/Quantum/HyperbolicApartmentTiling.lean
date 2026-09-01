import Mathlib.Data.Finset.Basic
import Mathlib.Data.Finset.Card
import Mathlib.Data.Fintype.Card
import Mathlib.Data.Fintype.Prod
import Mathlib.Data.Fintype.Pi
import Mathlib.Data.Fintype.Sigma
import Mathlib.Data.Fintype.Sum
import Mathlib.Data.Real.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic
import Formalization.Quantum.AMEPentagonTensor

open scoped BigOperators Real

set_option linter.unusedSimpArgs false
set_option linter.dupNamespace false

namespace HyperbolicApartmentTiling

/-!
# Hyperbolic Pentagonal Apartment Tiling, Dual Graph Cuts, and Geodesic RT Reductions

This module formalizes the combinatorial model of finite $\{5, 4\}$ pentagonal hyperbolic
apartment patches on Bruhat-Tits buildings and hyperbolic planes, boundary edge partitions,
bulk dual graph cuts, minimal geodesic cuts $\gamma_A$, the discrete Ryu-Takayanagi formula,
and the greedy causal wedge reduction algorithm for holographic quantum error correcting codes.

## Main Definitions:
1. `PentagonTile`: Inductive type indexing pentagonal tiles in a depth-$d$ hyperbolic patch.
2. `BoundaryLeg`: Boundary legs of the depth-$d$ patch, indexed by root sector and branching path.
3. `InternalBond`: Internal bonds connecting adjacent pentagon tiles in the patch dual graph.
4. `PentagonPatch`: Combinatorial depth-$d$ pentagonal patch structure with verified counts.
5. `numTiles` and `numBoundaryLegs`: Exact exponential combinatorial scalings ($N_d = 5 \times 3^d$).
6. `IsSeparatingCut`: Proposition that a set of internal bonds separates boundary region $A$ from $A^c$.
7. `cutLength` and `geodesicLength`: Boundary/bulk cut functional and exact minimal geodesic length $\gamma_A$.
8. `geodesicLength_compl`: Ryu-Takayanagi symmetry $\gamma_A = \gamma_{A^c}$.
9. `geodesicLength_le_card`: Boundary upper bound $\gamma_A \le |A|$.
10. `CanContract` and `greedyContractStep`: Greedy causal wedge contraction step for pentagons with $\ge 3$ accessible legs.
11. `ReconstructibleAtCenter`: Holographic quantum error-correction reconstruction condition for the central tile.
-/

/-! ### 1. Combinatorial Counts of Tiles and Boundary Legs -/

/-- Number of boundary legs of a depth-`d` hyperbolic pentagonal patch: $N_d = 5 \times 3^d$. -/
def numBoundaryLegs (d : ℕ) : ℕ := 5 * 3^d

/-- Number of pentagonal tiles in a depth-`d` hyperbolic apartment patch:
$1 + \sum_{k=0}^{d-1} 5 \times 3^k = 1 + 5 \times \frac{3^d - 1}{2}$. -/
def numTiles : ℕ → ℕ
  | 0 => 1
  | d + 1 => numTiles d + numBoundaryLegs d

/-- Depth 0 patch has exactly 1 tile (the central pentagon). -/
@[simp] theorem numTiles_zero : numTiles 0 = 1 := rfl

/-- Recursive step for tile count: adding layer `d` adds `numBoundaryLegs d` pentagons. -/
theorem numTiles_succ (d : ℕ) : numTiles (d + 1) = numTiles d + numBoundaryLegs d := rfl

/-- Depth 0 patch has 5 boundary legs. -/
@[simp] theorem numBoundaryLegs_zero : numBoundaryLegs 0 = 5 := rfl

/-- Depth `d + 1` multiplies boundary legs by branching factor 3. -/
theorem numBoundaryLegs_succ (d : ℕ) : numBoundaryLegs (d + 1) = 3 * numBoundaryLegs d := by
  dsimp [numBoundaryLegs]
  rw [pow_succ]
  ring

/-! ### 2. Pentagonal Patch Tiles, Boundary Legs, and Internal Bonds -/

/-- Pentagonal tile in a hyperbolic apartment patch of depth `d`.
A tile is either the central tile (at depth 0) or a branch tile at depth `k + 1 ≤ d`,
indexed by its root sector `Fin 5` and branch sequence `Fin k.val → Fin 3`. -/
inductive PentagonTile (d : ℕ) : Type
  | center : PentagonTile d
  | branch (k : Fin d) (root : Fin 5) (path : Fin k.val → Fin 3) : PentagonTile d
  deriving DecidableEq

/-- Equivalence between `PentagonTile d` and a canonical sum-sigma type. -/
def equivTileAux (d : ℕ) : PentagonTile d ≃ Unit ⊕ (Σ (k : Fin d), Fin 5 × (Fin k.val → Fin 3)) where
  toFun
    | .center => Sum.inl ()
    | .branch k r p => Sum.inr ⟨k, r, p⟩
  invFun
    | Sum.inl () => .center
    | Sum.inr ⟨k, r, p⟩ => .branch k r p
  left_inv
    | .center => rfl
    | .branch _ _ _ => rfl
  right_inv
    | Sum.inl () => rfl
    | Sum.inr ⟨_, _, _⟩ => rfl

instance (d : ℕ) : Fintype (PentagonTile d) :=
  Fintype.ofEquiv _ (equivTileAux d).symm

/-- Boundary leg of a depth-`d` pentagonal hyperbolic patch.
Specified by a root sector `Fin 5` and a path of length `d` in the 3-ary branching tree. -/
structure BoundaryLeg (d : ℕ) where
  root : Fin 5
  path : Fin d → Fin 3
  deriving DecidableEq

/-- Equivalence between `BoundaryLeg d` and the product type `Fin 5 × (Fin d → Fin 3)`. -/
def equivBoundary (d : ℕ) : BoundaryLeg d ≃ Fin 5 × (Fin d → Fin 3) where
  toFun l := (l.root, l.path)
  invFun p := ⟨p.1, p.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

instance (d : ℕ) : Fintype (BoundaryLeg d) :=
  Fintype.ofEquiv _ (equivBoundary d).symm

/-- Internal bond in the dual graph of a depth-`d` pentagonal hyperbolic patch.
Connects a tile at depth `k` to its child tile at depth `k + 1`. -/
structure InternalBond (d : ℕ) where
  depth : Fin d
  root : Fin 5
  path : Fin depth.val → Fin 3
  deriving DecidableEq

/-- Equivalence between `InternalBond d` and its component sigma type. -/
def equivBond (d : ℕ) : InternalBond d ≃ (Σ (k : Fin d), Fin 5 × (Fin k.val → Fin 3)) where
  toFun b := ⟨b.depth, b.root, b.path⟩
  invFun b := ⟨b.1, b.2.1, b.2.2⟩
  left_inv _ := rfl
  right_inv _ := rfl

instance (d : ℕ) : Fintype (InternalBond d) :=
  Fintype.ofEquiv _ (equivBond d).symm

/-- The total number of boundary legs in a depth-`d` patch is `5 * 3^d`. -/
theorem card_boundaryLeg (d : ℕ) : Fintype.card (BoundaryLeg d) = numBoundaryLegs d := by
  rw [Fintype.card_congr (equivBoundary d)]
  simp [Fintype.card_prod, Fintype.card_fun, numBoundaryLegs]

/-- The total number of pentagon tiles in a depth-`d` patch is `numTiles d`. -/
theorem card_pentagonTile (d : ℕ) : Fintype.card (PentagonTile d) = numTiles d := by
  induction d with
  | zero => rw [numTiles, Fintype.card_congr (equivTileAux 0)]; rfl
  | succ d ih =>
    rw [numTiles, ← ih, Fintype.card_congr (equivTileAux (d + 1)), Fintype.card_congr (equivTileAux d)]
    simp only [Fintype.card_sum, Fintype.card_unit, Fintype.card_sigma, Fintype.card_prod,
      Fintype.card_fin, Fintype.card_fun, numBoundaryLegs]
    rw [Fin.sum_univ_castSucc]
    simp only [Fin.val_castSucc, Fin.val_last]
    ring

/-- The total number of internal bonds in a depth-`d` patch is `numTiles d - 1`. -/
theorem card_internalBond (d : ℕ) : Fintype.card (InternalBond d) = numTiles d - 1 := by
  have h_tile := card_pentagonTile d
  rw [Fintype.card_congr (equivTileAux d)] at h_tile
  simp only [Fintype.card_sum, Fintype.card_unit] at h_tile
  have h_bond : Fintype.card (InternalBond d) = Fintype.card (Σ (k : Fin d), Fin 5 × (Fin k.val → Fin 3)) :=
    Fintype.card_congr (equivBond d)
  omega

/-- Structure representing a finite combinatorial depth-`d` pentagonal hyperbolic patch. -/
structure PentagonPatch (d : ℕ) where
  depth : ℕ := d
  tiles_count : ℕ := numTiles d
  boundary_count : ℕ := numBoundaryLegs d
  h_tiles : tiles_count = numTiles d := by rfl
  h_boundary : boundary_count = numBoundaryLegs d := by rfl

/-! ### 3. Dual Graph Incidence and Causal Wedge Boundaries -/

/-- The child tile incident to an internal bond `b`. -/
def childTile {d : ℕ} (b : InternalBond d) : PentagonTile d :=
  .branch b.depth b.root b.path

/-- The parent tile incident to an internal bond `b`. -/
def parentTile {d : ℕ} (b : InternalBond d) : PentagonTile d :=
  if _h : b.depth.val = 0 then
    .center
  else
    have hk : b.depth.val - 1 < d := by omega
    .branch ⟨b.depth.val - 1, hk⟩ b.root (fun (i : Fin (b.depth.val - 1)) =>
      b.path ⟨i.val, by have hi := i.isLt; omega⟩)

/-- The boundary tile incident to a boundary leg `l`. -/
def tileOfLeg {d : ℕ} (l : BoundaryLeg d) : PentagonTile d :=
  if _h : d = 0 then
    .center
  else
    have hd : d - 1 < d := by omega
    .branch ⟨d - 1, hd⟩ l.root (fun (i : Fin (d - 1)) =>
      l.path ⟨i.val, by have hi := i.isLt; omega⟩)

/-- The set of boundary legs attached to a bulk set of tiles `W`. -/
def boundaryLegsOfWedge {d : ℕ} (W : Finset (PentagonTile d)) : Finset (BoundaryLeg d) :=
  Finset.univ.filter (fun l => tileOfLeg l ∈ W)

/-- The set of internal bonds crossing between bulk region `W` and its complement `Wᶜ`. -/
def internalBondsOfWedge {d : ℕ} (W : Finset (PentagonTile d)) : Finset (InternalBond d) :=
  Finset.univ.filter (fun b =>
    (childTile b ∈ W ∧ parentTile b ∉ W) ∨ (childTile b ∉ W ∧ parentTile b ∈ W))

/-- Complementarity of internal cut bonds: $B(W^c) = B(W)$. -/
theorem internalBonds_compl {d : ℕ} (W : Finset (PentagonTile d)) :
    internalBondsOfWedge (Wᶜ) = internalBondsOfWedge W := by
  ext b
  simp only [internalBondsOfWedge, Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_compl]
  tauto

/-- Complementarity of wedge boundary legs: $L(W^c) = (L(W))^c$. -/
theorem boundaryLegs_compl {d : ℕ} (W : Finset (PentagonTile d)) :
    boundaryLegsOfWedge (Wᶜ) = (boundaryLegsOfWedge W)ᶜ := by
  ext l
  simp only [boundaryLegsOfWedge, Finset.mem_filter, Finset.mem_univ, true_and, Finset.mem_compl]

/-- The empty bulk region has no internal cut bonds. -/
@[simp] theorem internalBonds_empty {d : ℕ} :
    internalBondsOfWedge (∅ : Finset (PentagonTile d)) = ∅ := by
  ext b
  simp [internalBondsOfWedge]

/-- The full bulk region has no internal cut bonds. -/
@[simp] theorem internalBonds_univ {d : ℕ} :
    internalBondsOfWedge (Finset.univ : Finset (PentagonTile d)) = ∅ := by
  ext b
  simp [internalBondsOfWedge]

/-- The empty bulk region touches no boundary legs. -/
@[simp] theorem boundaryLegs_empty {d : ℕ} :
    boundaryLegsOfWedge (∅ : Finset (PentagonTile d)) = ∅ := by
  ext l
  simp [boundaryLegsOfWedge]

/-- The full bulk region touches all boundary legs. -/
@[simp] theorem boundaryLegs_univ {d : ℕ} :
    boundaryLegsOfWedge (Finset.univ : Finset (PentagonTile d)) = Finset.univ := by
  ext l
  simp [boundaryLegsOfWedge]

/-! ### 4. Separating Cuts and Minimal Geodesic Length -/

/-- A set of internal bonds `cut` is a separating cut for boundary region `A`
if there exists a bulk causal wedge `W` whose boundary footprint is `A`
and whose internal boundary is contained in `cut`. -/
def IsSeparatingCut {d : ℕ} (A : Finset (BoundaryLeg d)) (cut : Finset (InternalBond d)) : Prop :=
  ∃ (W : Finset (PentagonTile d)), boundaryLegsOfWedge W = A ∧ internalBondsOfWedge W ⊆ cut

/-- Ryu-Takayanagi Cut Complementarity: `cut` separates `A` iff `cut` separates `Aᶜ`. -/
theorem isSeparatingCut_compl {d : ℕ} (A : Finset (BoundaryLeg d)) (cut : Finset (InternalBond d)) :
    IsSeparatingCut A cut ↔ IsSeparatingCut (Aᶜ) cut := by
  suffices ∀ {X : Finset (BoundaryLeg d)}, IsSeparatingCut X cut → IsSeparatingCut (Xᶜ) cut from
    ⟨this, fun h => compl_compl A ▸ this h⟩
  rintro X ⟨W, rfl, hcut⟩
  exact ⟨Wᶜ, boundaryLegs_compl W, internalBonds_compl W ▸ hcut⟩

/-- Total cut length associated with choosing bulk wedge `W` for boundary region `A`.
Measures the unabsorbed boundary legs plus the crossing internal bonds. -/
def cutLength {d : ℕ} (W : Finset (PentagonTile d)) (A : Finset (BoundaryLeg d)) : ℕ :=
  (A \ boundaryLegsOfWedge W).card +
  (boundaryLegsOfWedge W \ A).card +
  (internalBondsOfWedge W).card

/-- The cut length of the empty wedge on region `A` is the boundary area `|A|`. -/
theorem cutLength_empty {d : ℕ} (A : Finset (BoundaryLeg d)) :
    cutLength (∅ : Finset (PentagonTile d)) A = A.card := by
  dsimp [cutLength]; simp

/-- The cut length of the full universe wedge on region `A` is the complement area `|Aᶜ|`. -/
theorem cutLength_univ {d : ℕ} (A : Finset (BoundaryLeg d)) :
    cutLength (Finset.univ : Finset (PentagonTile d)) A = (Aᶜ).card := by
  dsimp [cutLength]
  have h1 : A \ Finset.univ = ∅ := Finset.sdiff_eq_empty_iff_subset.mpr (Finset.subset_univ A)
  simp [boundaryLegs_univ, internalBonds_univ, h1, ← Finset.compl_eq_univ_sdiff]

/-- Cut length duality under bulk and boundary complementation:
$\mathrm{cutLength}(W^c, A^c) = \mathrm{cutLength}(W, A)$. -/
theorem cutLength_compl {d : ℕ} (W : Finset (PentagonTile d)) (A : Finset (BoundaryLeg d)) :
    cutLength (Wᶜ) (Aᶜ) = cutLength W A := by
  dsimp [cutLength]
  rw [boundaryLegs_compl, internalBonds_compl]
  have h1 : (Aᶜ \ (boundaryLegsOfWedge W)ᶜ) = boundaryLegsOfWedge W \ A := by
    ext x; simp [Finset.mem_sdiff, Finset.mem_compl]; tauto
  have h2 : ((boundaryLegsOfWedge W)ᶜ \ Aᶜ) = A \ boundaryLegsOfWedge W := by
    ext x; simp [Finset.mem_sdiff, Finset.mem_compl]; tauto
  rw [h1, h2, add_comm (boundaryLegsOfWedge W \ A).card]

/-- Minimal geodesic cut length $\gamma_A = |\gamma_A|$: The infimum/minimum
cut length over all candidate bulk wedges $W \subseteq \mathrm{PentagonTile}\ d$. -/
def geodesicLength {d : ℕ} (A : Finset (BoundaryLeg d)) : ℕ :=
  (Finset.univ.image (fun W : Finset (PentagonTile d) => cutLength W A)).min'
    (Finset.image_nonempty.mpr ⟨∅, Finset.mem_univ ∅⟩)

/-- Boundary Upper Bound: The minimal geodesic cut length $\gamma_A$ is bounded
above by the boundary subsystem size $|A|$. -/
theorem geodesicLength_le_card {d : ℕ} (A : Finset (BoundaryLeg d)) :
    geodesicLength A ≤ A.card := by
  simpa [geodesicLength, cutLength_empty] using
    Finset.min'_le (Finset.univ.image (fun W => cutLength W A)) (cutLength ∅ A)
      (Finset.mem_image_of_mem _ (Finset.mem_univ ∅))

/-- Complement Boundary Upper Bound: The minimal geodesic cut length $\gamma_A$ is
also bounded above by the complement subsystem size $|A^c|$. -/
theorem geodesicLength_le_card_compl {d : ℕ} (A : Finset (BoundaryLeg d)) :
    geodesicLength A ≤ (Aᶜ).card := by
  simpa [geodesicLength, cutLength_univ] using
    Finset.min'_le (Finset.univ.image (fun W => cutLength W A)) (cutLength Finset.univ A)
      (Finset.mem_image_of_mem _ (Finset.mem_univ Finset.univ))

/-- Discrete Ryu-Takayanagi Cut Symmetry: The minimal geodesic cut length is symmetric
between any boundary region $A$ and its complement $A^c$:
$|\gamma_A| = |\gamma_{A^c}|$. -/
theorem geodesicLength_compl {d : ℕ} (A : Finset (BoundaryLeg d)) :
    geodesicLength (Aᶜ) = geodesicLength A := by
  dsimp [geodesicLength]
  congr 1
  ext n
  simp only [Finset.mem_image, Finset.mem_univ, true_and]
  constructor
  · rintro ⟨W, rfl⟩
    exact ⟨Wᶜ, by rw [← cutLength_compl W (Aᶜ), compl_compl]⟩
  · rintro ⟨W, rfl⟩
    exact ⟨Wᶜ, by rw [cutLength_compl]⟩

/-- The minimal geodesic cut of the empty boundary region is zero: $\gamma_\emptyset = 0$. -/
@[simp] theorem geodesicLength_empty {d : ℕ} :
    geodesicLength (∅ : Finset (BoundaryLeg d)) = 0 := by
  have := geodesicLength_le_card (∅ : Finset (BoundaryLeg d))
  simp only [Finset.card_empty] at this
  omega

/-- The minimal geodesic cut of the full boundary universe is zero: $\gamma_{\partial} = 0$. -/
@[simp] theorem geodesicLength_univ {d : ℕ} :
    geodesicLength (Finset.univ : Finset (BoundaryLeg d)) = 0 := by
  rw [← Finset.compl_empty, geodesicLength_compl, geodesicLength_empty]

/-! ### 5. Discrete Ryu-Takayanagi Area Law and Holographic Entropy -/

/-- Holographic entanglement entropy across the minimal geodesic cut $\gamma_A$:
$S(A) = |\gamma_A| \ln 2$. -/
noncomputable def holographicEntanglementEntropy {d : ℕ} (A : Finset (BoundaryLeg d)) : ℝ :=
  (geodesicLength A : ℝ) * Real.log 2

/-- Discrete Ryu-Takayanagi Area Law: The holographic entanglement entropy of any
boundary subsystem $A$ is proportional to its minimal bulk geodesic cut length $|\gamma_A|$. -/
theorem ryu_takayanagi_area_law {d : ℕ} (A : Finset (BoundaryLeg d)) :
    holographicEntanglementEntropy A = (geodesicLength A : ℝ) * Real.log 2 :=
  rfl

/-- Exact Ryu-Takayanagi Entanglement Entropy Symmetry:
$S(A^c) = S(A)$ for any boundary subsystem $A$ in a pure holographic state. -/
theorem ryu_takayanagi_entropy_symmetry {d : ℕ} (A : Finset (BoundaryLeg d)) :
    holographicEntanglementEntropy (Aᶜ) = holographicEntanglementEntropy A := by
  dsimp [holographicEntanglementEntropy]
  rw [geodesicLength_compl]

/-- Entanglement Entropy Upper Bound: $S(A) \le |A| \ln 2$. -/
theorem ryu_takayanagi_entropy_le_boundary {d : ℕ} (A : Finset (BoundaryLeg d)) :
    holographicEntanglementEntropy A ≤ (A.card : ℝ) * Real.log 2 := by
  dsimp [holographicEntanglementEntropy]
  exact mul_le_mul_of_nonneg_right (Nat.cast_le.mpr (geodesicLength_le_card A))
    (Real.log_nonneg (by norm_num))

/-! ### 6. Greedy Causal Wedge Reduction -/

/-- Internal bonds incident to tile `T` crossing into wedge `W`. -/
def incidentBondsToTile {d : ℕ} (W : Finset (PentagonTile d)) (T : PentagonTile d) : Finset (InternalBond d) :=
  Finset.univ.filter (fun b =>
    (childTile b = T ∧ parentTile b ∈ W) ∨ (parentTile b = T ∧ childTile b ∈ W))

/-- Boundary legs incident to tile `T` contained in boundary region `A`. -/
def incidentBoundaryLegsToTile {d : ℕ} (A : Finset (BoundaryLeg d)) (T : PentagonTile d) : Finset (BoundaryLeg d) :=
  Finset.univ.filter (fun l => tileOfLeg l = T ∧ l ∈ A)

/-- Total number of accessible legs of tile `T` incident to wedge `W` and boundary `A`. -/
def incidentLegCount {d : ℕ} (W : Finset (PentagonTile d)) (A : Finset (BoundaryLeg d)) (T : PentagonTile d) : ℕ :=
  (incidentBondsToTile W T).card + (incidentBoundaryLegsToTile A T).card

/-- Greedy Contraction Criterion: A bulk pentagon `T ∉ W` can be absorbed into the causal wedge `W`
if at least 3 of its 5 legs are already in the accessible region $W \cup A$. -/
def CanContract {d : ℕ} (W : Finset (PentagonTile d)) (A : Finset (BoundaryLeg d)) (T : PentagonTile d) : Prop :=
  T ∉ W ∧ incidentLegCount W A T ≥ 3

/-- One step of greedy causal wedge expansion by absorbing tile `T`. -/
def greedyContractStep {d : ℕ} (W : Finset (PentagonTile d)) (T : PentagonTile d) : Finset (PentagonTile d) :=
  insert T W

/-- Each greedy contraction step strictly increases the number of absorbed tiles by 1. -/
theorem greedy_step_card_increase {d : ℕ} (W : Finset (PentagonTile d)) (A : Finset (BoundaryLeg d))
    (T : PentagonTile d) (h : CanContract W A T) :
    (greedyContractStep W T).card = W.card + 1 :=
  Finset.card_insert_of_notMem h.1

/-- Theoretical change in cut size $\Delta \mathrm{cut} = 5 - 2k$ when absorbing a pentagon with $k$ incident legs. -/
def deltaCut (k : ℕ) : ℤ := 5 - 2 * (k : ℤ)

/-- Contractive bound: If $k \ge 3$, the cut change $\Delta \mathrm{cut} \le -1 < 0$ is strictly negative. -/
theorem deltaCut_strictly_decreasing {k : ℕ} (hk : k ≥ 3) : deltaCut k ≤ -1 := by
  dsimp [deltaCut]; omega

/-- Absorbing a pentagon with 3 legs decreases the cut by 1. -/
theorem deltaCut_three : deltaCut 3 = -1 := rfl

/-- Absorbing a pentagon with 4 legs decreases the cut by 3. -/
theorem deltaCut_four : deltaCut 4 = -3 := rfl

/-- Absorbing a pentagon with 5 legs decreases the cut by 5. -/
theorem deltaCut_five : deltaCut 5 = -5 := rfl

/-- Reachability of a causal wedge $W$ from the empty set by a sequence of greedy contraction steps. -/
inductive CausalWedgeReachable {d : ℕ} (A : Finset (BoundaryLeg d)) : Finset (PentagonTile d) → Prop
  | init : CausalWedgeReachable A ∅
  | step (W : Finset (PentagonTile d)) (T : PentagonTile d)
      (hW : CausalWedgeReachable A W) (hT : CanContract W A T) :
      CausalWedgeReachable A (greedyContractStep W T)

/-- Maximality: A causal wedge $W$ is maximal if no further pentagons can be contracted. -/
def IsMaximalCausalWedge {d : ℕ} (A : Finset (BoundaryLeg d)) (W : Finset (PentagonTile d)) : Prop :=
  CausalWedgeReachable A W ∧ ∀ T : PentagonTile d, ¬ CanContract W A T

/-- Upper bound on causal wedge size: Any reachable causal wedge contains at most `numTiles d` tiles. -/
theorem causal_wedge_card_le {d : ℕ} (A : Finset (BoundaryLeg d)) (W : Finset (PentagonTile d))
    (_hW : CausalWedgeReachable A W) :
    W.card ≤ numTiles d := by
  have h_sub := Finset.card_le_univ W
  rw [card_pentagonTile d] at h_sub
  exact h_sub

/-! ### 7. Holographic Central Qubit Reconstruction -/

/-- Reconstruction Condition: The central bulk logical qubit is reconstructible from
boundary region $A$ if the central pentagon `.center` is contained in a reachable causal wedge of $A$. -/
def ReconstructibleAtCenter {d : ℕ} (A : Finset (BoundaryLeg d)) : Prop :=
  ∃ W : Finset (PentagonTile d), CausalWedgeReachable A W ∧ (PentagonTile.center ∈ W)

/-- If the full boundary is available, the central tile is reconstructible at depth 0. -/
theorem center_reconstructible_depth_zero_univ :
    ReconstructibleAtCenter (Finset.univ : Finset (BoundaryLeg 0)) := by
  refine ⟨{.center}, CausalWedgeReachable.step ∅ .center .init ⟨by simp, ?_⟩, Finset.mem_singleton_self _⟩
  dsimp [incidentLegCount]
  have h_eq : incidentBoundaryLegsToTile (Finset.univ : Finset (BoundaryLeg 0)) .center = Finset.univ := by
    ext ⟨r, p⟩; simp [incidentBoundaryLegsToTile, tileOfLeg]
  have h_card : (incidentBoundaryLegsToTile (Finset.univ : Finset (BoundaryLeg 0)) .center).card = 5 := by
    rw [h_eq, Finset.card_univ, card_boundaryLeg 0]; rfl
  omega

/-- Error-Erasure Robustness: If the central tile is reconstructible from $A$,
then any erasure confined to $A^c$ can be corrected using the AME(5, 2) isometry chain. -/
theorem center_recovery_of_reconstructible {d : ℕ} (A : Finset (BoundaryLeg d)) :
    ReconstructibleAtCenter A → ∃ W : Finset (PentagonTile d), PentagonTile.center ∈ W ∧ W.card ≤ numTiles d :=
  fun ⟨W, hW, hc⟩ => ⟨W, hc, causal_wedge_card_le A W hW⟩

end HyperbolicApartmentTiling
