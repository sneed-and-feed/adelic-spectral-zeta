import Mathlib.Data.Matrix.Basic
import Mathlib.Algebra.Module.Submodule.Basic
import Formalization.CollatzConnectivity

open Matrix

namespace CollatzSpectral

-- ============================================================================
-- Layer of Genius: Canonical Sheet Decomposition & Simp Set
-- ============================================================================

lemma pow_two_identity {d : ℕ} (hd : d ≥ 3) : 2^(d-1) = 2 * 2^(d-2) := by
  have h_sub : d - 1 = (d - 2) + 1 := by omega
  rw [h_sub, pow_add, pow_one, mul_comm]

def sheetSplit {d : ℕ} (hd : d ≥ 3) : ZMod (2^(d-1)) ≃ (ZMod (2^(d-2)) × ZMod 2) where
  toFun x := (pi x, (if x.val < 2^(d-2) then 0 else 1 : ZMod 2))
  invFun := fun ⟨v, b⟩ => if b = 0 then (v.val : ZMod (2^(d-1))) else tau (v.val : ZMod (2^(d-1)))
  left_inv := by sorry
  right_inv := by sorry

-- Step 0: Deck Action & Subspaces

def canonicalLift {d : ℕ} (v : ZMod (2^(d-2))) : ZMod (2^(d-1)) :=
  (v.val : ZMod (2^(d-1)))

def symSubspace {d : ℕ} (_hd : d ≥ 3) : Submodule ℚ (ZMod (2^(d-1)) → ℚ) where
  carrier := {f | ∀ x, f (tau x) = f x}
  zero_mem' := by simp
  add_mem' := by intros f g hf hg x; simp [hf x, hg x]
  smul_mem' := by intros c f hf x; simp [hf x]

def antisymSubspace {d : ℕ} (_hd : d ≥ 3) : Submodule ℚ (ZMod (2^(d-1)) → ℚ) where
  carrier := {f | ∀ x, f (tau x) = - f x}
  zero_mem' := by simp
  add_mem' := by intros f g hf hg x; simp [hf x, hg x]; ring
  smul_mem' := by intros c f hf x; simp [hf x]

-- Phase 0: The Biconditional and Weighted Adjacency
-- ============================================================================

theorem tau_adj_bicond {d : ℕ} (hd : d ≥ 3) (x y : ZMod (2^(d-1))) :
    (G_d d).Adj (tau x) y ↔ (G_d d).Adj x (tau y) := by
  constructor
  · intro h; rw [← tau_tau hd x]; exact tau_is_hom hd h
  · intro h; rw [← tau_tau hd y]; exact tau_is_hom hd h

lemma sheetSplitInv_zero {d : ℕ} (hd : d ≥ 3) (v : ZMod (2^(d-2))) :
    (sheetSplit hd).symm (v, 0) = canonicalLift v := by
  dsimp [sheetSplit, canonicalLift]
  have h0 : (0 : ZMod 2) = 0 := rfl
  simp [h0]

lemma sheetSplitInv_one {d : ℕ} (hd : d ≥ 3) (v : ZMod (2^(d-2))) :
    (sheetSplit hd).symm (v, 1) = tau (canonicalLift v) := by
  dsimp [sheetSplit, canonicalLift]
  have h1 : ¬((1 : ZMod 2) = 0) := by decide
  simp [h1]

open Classical in
noncomputable def weighted_adj {d : ℕ} (_hd : d ≥ 3) (u v : ZMod (2^(d-2))) : ℚ :=
  let s := Finset.filter (fun (p : ZMod (2^(d-1)) × ZMod (2^(d-1))) =>
    pi p.1 = u ∧ pi p.2 = v ∧ (G_d d).Adj p.1 p.2) Finset.univ
  (s.card : ℚ) / 2

-- Phase 1a: Matrix Infrastructure
-- ============================================================================

open Classical in
noncomputable def adjacencyMatrix {d : ℕ} : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ :=
  fun x y => if (G_d d).Adj x y then 1 else 0

open Classical in
noncomputable def tauMatrix {d : ℕ} : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ :=
  fun x y => if y = tau x then 1 else 0

lemma tauMatrix_involutive {d : ℕ} (hd : d ≥ 3) :
    (@tauMatrix d) * (@tauMatrix d) = 1 := by
  ext i j
  simp only [tauMatrix, Matrix.mul_apply, Matrix.one_apply]
  by_cases h : i = j
  · subst h
    have : ∀ x, (if x = tau i then (1 : ℚ) else 0) * (if i = tau x then 1 else 0) = if x = tau i then 1 else 0 := by
      intro x
      by_cases hx : x = tau i
      · subst hx
        simp [tau_tau hd]
      · simp [hx]
    simp_rw [this]
    rw [Finset.sum_eq_single (tau i)]
    · simp
    · intro b _ hb
      simp [hb]
    · intro h_not_mem
      have := Finset.mem_univ (tau i)
      contradiction
  · have : ∀ x, (if x = tau i then (1 : ℚ) else 0) * (if j = tau x then 1 else 0) = 0 := by
      intro x
      by_cases hx : x = tau i
      · subst hx
        have : j ≠ i := Ne.symm h
        have hj_tau : j ≠ tau (tau i) := by rwa [tau_tau hd i]
        simp [hj_tau]
      · simp [hx]
    simp_rw [this]
    simp [h]

-- Phase 1b: Adjacency Commutation
-- ============================================================================

open Classical in
lemma tau_adjacency_commute {d : ℕ} (hd : d ≥ 3) :
    @adjacencyMatrix d * @tauMatrix d = @tauMatrix d * @adjacencyMatrix d := by
  ext i j
  have lhs_simp : (∑ k : ZMod (2 ^ (d - 1)), (if (G_d d).Adj i k then (1 : ℚ) else 0) * if j = tau k then 1 else 0)
      = if (G_d d).Adj i (tau j) then 1 else 0 := by
    rw [Finset.sum_eq_single (tau j)]
    · simp [tau_tau hd j]
    · intro k _ hk
      have : j ≠ tau k := by
        intro h
        have : tau j = tau (tau k) := by rw [h]
        rw [tau_tau hd k] at this
        exact hk this.symm
      simp [this]
    · intro h
      exact (h (Finset.mem_univ (tau j))).elim
  
  have rhs_simp : (∑ k : ZMod (2 ^ (d - 1)), (if k = tau i then (1 : ℚ) else 0) * if (G_d d).Adj k j then 1 else 0)
      = if (G_d d).Adj (tau i) j then 1 else 0 := by
    rw [Finset.sum_eq_single (tau i)]
    · simp
    · intro k _ hk
      have : k ≠ tau i := hk
      simp [this]
    · intro h
      exact (h (Finset.mem_univ (tau i))).elim
  
  simp only [adjacencyMatrix, tauMatrix, Matrix.mul_apply]
  rw [lhs_simp, rhs_simp]
  simp only [tau_adj_bicond hd i j]

-- Phase 1c: Hadamard Transformation
-- ============================================================================

noncomputable def hadamardBlock : Matrix (ZMod 2) (ZMod 2) ℚ :=
  !![1, 1; 1, -1]

lemma hadamard_sq {d : ℕ} (hd : d ≥ 3) :
    hadamardBlock * hadamardBlock = (2 : ℚ) • (1 : Matrix (ZMod 2) (ZMod 2) ℚ) := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [hadamardBlock, Matrix.mul_apply, Matrix.one_apply] <;> norm_num

noncomputable def hadamardInv : Matrix (ZMod 2) (ZMod 2) ℚ := (1/2) • hadamardBlock

lemma hadamardInv_left_inv {d : ℕ} (hd : d ≥ 3) :
    hadamardInv * hadamardBlock = 1 := by
  sorry

-- Phase 2a: Block Indices
-- ============================================================================

def toBlockIndices {d : ℕ} (hd : d ≥ 3) :
    ZMod (2^(d-1)) ≃ ZMod (2^(d-2)) × ZMod 2 :=
  sheetSplit hd

lemma toBlockIndices_equiv {d : ℕ} (hd : d ≥ 3) :
    (toBlockIndices hd).symm ∘ toBlockIndices hd = id ∧
    (toBlockIndices hd) ∘ (toBlockIndices hd).symm = id := by
  simp [toBlockIndices]

-- Phase 2b: Reindexing and Conjugation
-- ============================================================================

noncomputable def A'_matrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  Matrix.reindex (sheetSplit hd) (sheetSplit hd) (@adjacencyMatrix d)

noncomputable def weightedMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ :=
  fun v u => A'_matrix hd (v, 0) (u, 0) + A'_matrix hd (v, 0) (u, 1)

noncomputable def antisymMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ :=
  fun v u => A'_matrix hd (v, 0) (u, 0) - A'_matrix hd (v, 0) (u, 1)

noncomputable def A'_block_diag_target {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨s1, s2⟩ ⟨r1, r2⟩ => if s2 = r2 then
                             if s2 = 0 then weightedMatrix hd s1 r1
                             else antisymMatrix hd s1 r1
                           else 0

-- The tensor product of identity and Hadamard inverse
noncomputable def conjBlockInv {d : ℕ} : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then hadamardInv j1 j2 else 0

-- The tensor product of identity and Hadamard
noncomputable def conjBlock {d : ℕ} : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then hadamardBlock j1 j2 else 0

lemma A'_block_diag {d : ℕ} (hd : d ≥ 3) :
    conjBlockInv * (A'_matrix hd) * conjBlock = A'_block_diag_target hd := by
  sorry

-- Phase 3: Weighted Adjacency Identification
-- ============================================================================

lemma weighted_adj_eq_sum {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = weightedMatrix hd u v := by
  dsimp [weighted_adj, weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex]
  rw [sheetSplitInv_zero hd u, sheetSplitInv_zero hd v, sheetSplitInv_one hd v]
  -- Goal is now about Finset.card / 2 and the if statements.
  sorry

open Classical in
lemma weighted_adj_bounds {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≤ 2 := by
  rw [weighted_adj_eq_sum hd]
  sorry

open Classical in
lemma weighted_adj_eq_two_iff {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = 2 ↔ 
    (G_d d).Adj (canonicalLift u) (canonicalLift v) ∧ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) := by
  sorry

open Classical in
lemma weighted_adj_ge_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≥ if (G_d (d-1)).Adj u v then 1 else 0 := by
  sorry

-- Phase 4: Spectral Decomposition & The Main Bound
-- ============================================================================

/-- The fundamental theorem of the Collatz Schreier graphs.
    The adjacency operator of G_d decomposes completely into two orthogonal sectors:
    1. A symmetric block identical to the weighted adjacency of G_{d-1}.
    2. An antisymmetric block capturing the sheet-exchange dynamics. -/
theorem collatz_spectral_decomposition {d : ℕ} (hd : d ≥ 3) :
    ∃ (S : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ) (S_inv : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ),
      S_inv * S = 1 ∧ S * S_inv = 1 ∧
      S_inv * (@adjacencyMatrix d) * S = 
        Matrix.reindex (sheetSplit hd).symm (sheetSplit hd).symm (A'_block_diag_target hd) := by
  let e := sheetSplit hd
  use Matrix.reindex e.symm e.symm conjBlock
  use Matrix.reindex e.symm e.symm conjBlockInv
  constructor
  · -- S_inv * S = 1
    sorry
  · constructor
    · -- S * S_inv = 1
      sorry
    · -- S_inv * A * S = block diag
      sorry

-- Phase 5: Spectral Gap Bounds
-- ============================================================================

/-- The characteristic polynomial of G_d factors exactly into the characteristic polynomials
    of the symmetric block (weightedMatrix) and the antisymmetric block. -/
lemma charpoly_adjacency_eq_mul {d : ℕ} (hd : d ≥ 3) :
    (@adjacencyMatrix d).charpoly = 
    (weightedMatrix hd).charpoly * (antisymMatrix hd).charpoly := by
  sorry

end CollatzSpectral
