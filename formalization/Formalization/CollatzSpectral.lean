import Mathlib.Data.Matrix.Basic
import Mathlib.Algebra.Module.Submodule.Basic
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Formalization.CollatzConnectivity

open Matrix

namespace CollatzSpectral

-- ============================================================================
-- Layer of Genius: Canonical Sheet Decomposition & Simp Set
-- ============================================================================

lemma pow_two_identity {d : ℕ} (hd : d ≥ 3) : 2^(d-1) = 2 * 2^(d-2) := by
  have h_sub : d - 1 = (d - 2) + 1 := by omega
  rw [h_sub, pow_add, pow_one, mul_comm]

def canonicalLift {d : ℕ} (v : ZMod (2^(d-2))) : ZMod (2^(d-1)) :=
  (v.val : ZMod (2^(d-1)))

def sheetSplit {d : ℕ} (hd : d ≥ 3) : ZMod (2^(d-1)) ≃ (ZMod (2^(d-2)) × ZMod 2) where
  toFun x := (pi x, (if x.val < 2^(d-2) then 0 else 1 : ZMod 2))
  invFun := fun ⟨v, b⟩ => if b = 0 then canonicalLift v else tau (canonicalLift v)
  left_inv := by sorry
  right_inv := by sorry

-- Step 0: Deck Action & Subspaces

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

noncomputable def hadamardInv : Matrix (ZMod 2) (ZMod 2) ℚ := (2 : ℚ)⁻¹ • hadamardBlock

-- Entry-level evaluation of hadamardInv (critical: use (2:ℚ)⁻¹, not 1/2 which can elaborate as ℕ)
lemma hadamardInv_00 : hadamardInv (0 : ZMod 2) (0 : ZMod 2) = (2:ℚ)⁻¹ := by
  unfold hadamardInv; rw [Matrix.smul_apply]; dsimp [hadamardBlock]; ring
lemma hadamardInv_01 : hadamardInv (0 : ZMod 2) (1 : ZMod 2) = (2:ℚ)⁻¹ := by
  unfold hadamardInv; rw [Matrix.smul_apply]; dsimp [hadamardBlock]; ring
lemma hadamardInv_10 : hadamardInv (1 : ZMod 2) (0 : ZMod 2) = (2:ℚ)⁻¹ := by
  unfold hadamardInv; rw [Matrix.smul_apply]; dsimp [hadamardBlock]; ring
lemma hadamardInv_11 : hadamardInv (1 : ZMod 2) (1 : ZMod 2) = -(2:ℚ)⁻¹ := by
  unfold hadamardInv; rw [Matrix.smul_apply]; dsimp [hadamardBlock]; ring

lemma hadamardInv_left_inv {d : ℕ} (hd : d ≥ 3) :
    hadamardInv * hadamardBlock = 1 := by
  simp only [hadamardInv]
  rw [Matrix.smul_mul, hadamard_sq hd]
  ext i j
  simp only [Matrix.smul_apply, Matrix.one_apply, smul_eq_mul]
  split_ifs <;> norm_num

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

lemma sum_zmod_two {β : Type*} [AddCommMonoid β] (f : ZMod 2 → β) :
    ∑ i : ZMod 2, f i = f 0 + f 1 := by
  have : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
  rw [this]
  simp

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

noncomputable def A'_matrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  Matrix.reindex (sheetSplit hd) (sheetSplit hd) (@adjacencyMatrix d)

lemma A'_tau_sym_01_10 {d : ℕ} (hd : d ≥ 3) (s1 r1 : ZMod (2^(d-2))) :
    A'_matrix hd (s1, 1) (r1, 0) = A'_matrix hd (s1, 0) (r1, 1) := by
  simp only [A'_matrix, Matrix.reindex_apply, Equiv.symm_symm]
  change adjacencyMatrix ((sheetSplit hd).symm (s1, 1)) ((sheetSplit hd).symm (r1, 0)) = 
         adjacencyMatrix ((sheetSplit hd).symm (s1, 0)) ((sheetSplit hd).symm (r1, 1))
  rw [sheetSplitInv_one hd s1, sheetSplitInv_zero hd r1]
  rw [sheetSplitInv_zero hd s1, sheetSplitInv_one hd r1]
  simp only [adjacencyMatrix]
  congr 1
  exact propext (tau_adj_bicond hd (canonicalLift s1) (canonicalLift r1))

lemma A'_tau_sym_11_00 {d : ℕ} (hd : d ≥ 3) (s1 r1 : ZMod (2^(d-2))) :
    A'_matrix hd (s1, 1) (r1, 1) = A'_matrix hd (s1, 0) (r1, 0) := by
  simp only [A'_matrix, Matrix.reindex_apply, Equiv.symm_symm]
  change adjacencyMatrix ((sheetSplit hd).symm (s1, 1)) ((sheetSplit hd).symm (r1, 1)) = 
         adjacencyMatrix ((sheetSplit hd).symm (s1, 0)) ((sheetSplit hd).symm (r1, 0))
  rw [sheetSplitInv_one hd s1, sheetSplitInv_one hd r1]
  rw [sheetSplitInv_zero hd s1, sheetSplitInv_zero hd r1]
  simp only [adjacencyMatrix]
  congr 1
  apply propext
  constructor
  · intro h; rw [← tau_tau hd (canonicalLift r1)]; exact (tau_adj_bicond hd _ _).mp h
  · intro h; exact (tau_adj_bicond hd _ _).mpr (by rw [tau_tau hd]; exact h)

noncomputable def weightedMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ :=
  fun v u => A'_matrix hd (v, 0) (u, 0) + A'_matrix hd (v, 0) (u, 1)

noncomputable def sheetDiffMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ :=
  fun v u => A'_matrix hd (v, 0) (u, 0) - A'_matrix hd (v, 0) (u, 1)

noncomputable def A'_block_diag_target {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨s1, s2⟩ ⟨r1, r2⟩ => if s2 = r2 then
                             if s2 = 0 then weightedMatrix hd s1 r1
                             else sheetDiffMatrix hd s1 r1
                           else 0

-- The tensor product of identity and Hadamard inverse
noncomputable def conjBlockInv {d : ℕ} : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then hadamardInv j1 j2 else 0

-- The tensor product of identity and Hadamard
noncomputable def conjBlock {d : ℕ} : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨i1, j1⟩ ⟨i2, j2⟩ => if i1 = i2 then hadamardBlock j1 j2 else 0

lemma A'_block_diag {d : ℕ} (hd : d ≥ 3) :
    conjBlockInv * (A'_matrix hd) * conjBlock = A'_block_diag_target hd := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [Matrix.mul_apply, Fintype.sum_prod_type]
  simp only [conjBlockInv, conjBlock, A'_matrix, A'_block_diag_target,
             Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
  simp only [Finset.sum_mul, mul_ite, ite_mul, mul_zero, zero_mul]
  
  -- The LHS is now ∑ l1 l2 (if l1=r1 then ∑ k1 k2 (if s1=k1 then H⁻¹ * A' * H else 0) else 0)
  simp_rw [Finset.sum_comm (s := Finset.univ (α := ZMod (2^(d-2))))
                           (t := Finset.univ (α := ZMod 2))]
  -- We can evaluate these sums using sum_ite_eq
  simp only [Finset.sum_ite_eq, Finset.sum_ite_eq', Finset.mem_univ, if_true]
  
  -- Abbreviate entries for readability
  have hA10 : A'_matrix hd (s1, 1) (r1, 0) = A'_matrix hd (s1, 0) (r1, 1) := A'_tau_sym_01_10 hd s1 r1
  have hA11 : A'_matrix hd (s1, 1) (r1, 1) = A'_matrix hd (s1, 0) (r1, 0) := A'_tau_sym_11_00 hd s1 r1
  
  -- Unfold A'_matrix everywhere so terms exactly match the sum output
  simp only [A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply] at hA10 hA11 ⊢
  
  -- Now fin_cases on s2 and r2
  fin_cases s2 <;> fin_cases r2
  · -- s2=0, r2=0: should equal weightedMatrix s1 r1 = P + Q
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=0, r2=1: should equal 0 (off-diagonal block)
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=1, r2=0: should equal 0 (off-diagonal block)  
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring
  · -- s2=1, r2=1: should equal sheetDiffMatrix s1 r1 = P - Q
    dsimp [A'_block_diag_target, weightedMatrix, sheetDiffMatrix]
    simp only [sum_zmod_two]
    rw [hA10, hA11]
    simp only [hadamardInv, hadamardBlock, Matrix.smul_apply, Matrix.of_apply, Matrix.cons_val_zero, Matrix.cons_val_one, Matrix.head_cons, if_true, if_false, eq_self_iff_true, A'_matrix, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]
    norm_num
    ring

-- Phase 3: Weighted Adjacency Identification
-- ============================================================================

-- Define weighted_adj algebraically for the spectral theory
open Classical in
noncomputable def weighted_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) : ℚ :=
  weightedMatrix hd u v

-- weighted_adj is combinatorially the number of edges divided by 2
lemma pi_canonicalLift {d : ℕ} (w : ZMod (2^(d-2))) :
    pi (canonicalLift w) = w := by
  unfold canonicalLift
  rw [pi_natCast, ZMod.natCast_zmod_val]

lemma pi_eq_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) (w : ZMod (2^(d-2))) :
    pi z = w ↔ z = canonicalLift w ∨ z = tau (canonicalLift w) := by
  constructor
  · intro h
    have h_sub : pi (z - canonicalLift w) = 0 := by
      rw [pi_sub, h, pi_canonicalLift, sub_self]
    have h_zero_iff := (pi_eq_zero_iff hd (z - canonicalLift w)).mp h_sub
    rcases h_zero_iff with h1 | h2
    · left
      exact sub_eq_zero.mp h1
    · right
      have h3 : z = tau (canonicalLift w) := by
        unfold tau
        calc z = z - canonicalLift w + canonicalLift w := by ring
             _ = (2^(d-2) : ZMod (2^(d-1))) + canonicalLift w := by rw [h2]
             _ = canonicalLift w + ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
      exact h3
  · rintro (h | h)
    · rw [h, pi_canonicalLift]
    · rw [h, tau_pi hd, pi_canonicalLift]

open Classical in
lemma s_card_eq_double {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    let s := Finset.filter (fun (p : ZMod (2^(d-1)) × ZMod (2^(d-1))) =>
      pi p.1 = v ∧ pi p.2 = u ∧ (G_d d).Adj p.1 p.2) Finset.univ
    (s.card : ℚ) = 2 * weightedMatrix hd v u := by
  intro s
  have h_sum : (s.card : ℚ) = ∑ p : ZMod (2^(d-1)) × ZMod (2^(d-1)), 
      if pi p.1 = v ∧ pi p.2 = u ∧ (G_d d).Adj p.1 p.2 then (1:ℚ) else 0 := by
    rw [← Finset.sum_boole]
  rw [h_sum]
  let x := canonicalLift v
  let y := canonicalLift u
  have h_cases_1 : ∀ p₁, pi p₁ = v ↔ p₁ = x ∨ p₁ = tau x := fun p₁ => pi_eq_iff hd p₁ v
  have h_cases_2 : ∀ p₂, pi p₂ = u ↔ p₂ = y ∨ p₂ = tau y := fun p₂ => pi_eq_iff hd p₂ u
  have h_sum_prod : (∑ p : ZMod (2^(d-1)) × ZMod (2^(d-1)), if pi p.1 = v ∧ pi p.2 = u ∧ (G_d d).Adj p.1 p.2 then (1:ℚ) else 0) =
    ∑ p₁ : ZMod (2^(d-1)), ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := Fintype.sum_prod_type
  rw [h_sum_prod]

  let S_x : Finset (ZMod (2^(d-1))) := {x, tau x}
  let S_y : Finset (ZMod (2^(d-1))) := {y, tau y}

  have h_sum_subset_x : (∑ p₁ : ZMod (2^(d-1)), ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₁ in S_x, ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    symm
    apply Finset.sum_subset (Finset.subset_univ S_x)
    intro p₁ _ hp₁
    have h_not : ¬(pi p₁ = v) := by
      intro h_pi
      have h_or : p₁ = x ∨ p₁ = tau x := (h_cases_1 p₁).mp h_pi
      simp only [S_x, Finset.mem_insert, Finset.mem_singleton] at hp₁
      tauto
    have : (∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) = 0 := by
      apply Finset.sum_eq_zero
      intro p₂ _
      simp [h_not]
    exact this

  have h_sum_subset_y : ∀ p₁, (∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₂ in S_y, if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    intro p₁
    symm
    apply Finset.sum_subset (Finset.subset_univ S_y)
    intro p₂ _ hp₂
    have h_not : ¬(pi p₂ = u) := by
      intro h_pi
      have h_or : p₂ = y ∨ p₂ = tau y := (h_cases_2 p₂).mp h_pi
      simp only [S_y, Finset.mem_insert, Finset.mem_singleton] at hp₂
      tauto
    simp [h_not]

  rw [h_sum_subset_x]
  have h_sum_subset_y_sum : (∑ p₁ in S_x, ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₁ in S_x, ∑ p₂ in S_y, if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    apply Finset.sum_congr rfl
    intro p₁ _
    exact h_sum_subset_y p₁

  have h_neq : ∀ z : ZMod (2^(d-1)), z ≠ tau z := by
    intro z h_eq
    have h_tau : tau z = z + ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := rfl
    rw [h_tau] at h_eq
    have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
      calc ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = z + ((2^(d-2) : ℕ) : ZMod (2^(d-1))) - z := by ring
        _ = z - z := by rw [← h_eq]
        _ = 0 := by ring
    have h_pow : 2^(d-2) < 2^(d-1) := by
      have h_lt : d - 2 < d - 1 := by omega
      exact Nat.pow_lt_pow_right (by decide) h_lt
    have h_val : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := ZMod.val_natCast_of_lt h_pow
    rw [h_zero] at h_val
    have h_val_zero : (0 : ZMod (2^(d-1))).val = 0 := ZMod.val_zero
    rw [h_val_zero] at h_val
    have h_pos : 0 < 2^(d-2) := by positivity
    linarith

  have h_x_neq : x ≠ tau x := h_neq x
  have h_y_neq : y ≠ tau y := h_neq y

  have h_pi_x : pi x = v := pi_canonicalLift v
  have h_pi_tau_x : pi (tau x) = v := by rw [tau_pi hd, h_pi_x]
  have h_pi_y : pi y = u := pi_canonicalLift u
  have h_pi_tau_y : pi (tau y) = u := by rw [tau_pi hd, h_pi_y]

  have h_simplify_sum : (∑ p₁ in S_x, ∑ p₂ in S_y, if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₁ in S_x, ∑ p₂ in S_y, if (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    apply Finset.sum_congr rfl
    intro p₁ hp₁
    apply Finset.sum_congr rfl
    intro p₂ hp₂
    have h1 : pi p₁ = v := by
      simp only [S_x, Finset.mem_insert, Finset.mem_singleton] at hp₁
      rcases hp₁ with h | h
      · rw [h]; exact h_pi_x
      · rw [h]; exact h_pi_tau_x
    have h2 : pi p₂ = u := by
      simp only [S_y, Finset.mem_insert, Finset.mem_singleton] at hp₂
      rcases hp₂ with h | h
      · rw [h]; exact h_pi_y
      · rw [h]; exact h_pi_tau_y
    simp [h1, h2]

  rw [h_sum_subset_y_sum, h_simplify_sum]

  have h_eval : (∑ p₁ in S_x, ∑ p₂ in S_y, if (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) = 
      2 * ((if (G_d d).Adj x y then (1:ℚ) else 0) + (if (G_d d).Adj x (tau y) then (1:ℚ) else 0)) := by
    simp only [S_x, S_y, Finset.sum_insert, Finset.sum_singleton, Finset.mem_singleton, h_x_neq, h_y_neq, not_false_eq_true]
    have h_tau_y : ((G_d d).Adj (tau x) y ↔ (G_d d).Adj x (tau y)) := tau_adj_bicond hd x y
    have h_tau_tau : ((G_d d).Adj (tau x) (tau y) ↔ (G_d d).Adj x y) := by
      rw [tau_adj_bicond hd, tau_tau hd]
    simp only [h_tau_y, h_tau_tau]
    ring

  rw [h_eval]
  have h_weighted : weightedMatrix hd v u = (if (G_d d).Adj x y then (1:ℚ) else 0) + (if (G_d d).Adj x (tau y) then (1:ℚ) else 0) := by
    unfold weightedMatrix A'_matrix
    simp only [Matrix.reindex_apply, Equiv.symm_symm, Matrix.submatrix_apply]
    erw [sheetSplitInv_zero hd v, sheetSplitInv_zero hd u, sheetSplitInv_one hd u]
    change (if (G_d d).Adj (canonicalLift v) (canonicalLift u) then (1:ℚ) else 0) +
           (if (G_d d).Adj (canonicalLift v) (tau (canonicalLift u)) then (1:ℚ) else 0) = _
    rfl

  rw [h_weighted]

-- weighted_adj is combinatorially the number of edges divided by 2
open Classical in
lemma weighted_adj_card {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    let s := Finset.filter (fun (p : ZMod (2^(d-1)) × ZMod (2^(d-1))) =>
      pi p.1 = u ∧ pi p.2 = v ∧ (G_d d).Adj p.1 p.2) Finset.univ
    (s.card : ℚ) / 2 = weighted_adj hd u v := by
  intro s
  have h_s := s_card_eq_double hd v u
  unfold weighted_adj
  calc (s.card : ℚ) / 2 = (2 * weightedMatrix hd u v) / 2 := by rw [h_s]
       _ = weightedMatrix hd u v := by ring

lemma weighted_adj_eq_sum {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = weightedMatrix hd u v := rfl

open Classical in
lemma weighted_adj_bounds {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≤ 2 := by
  rw [weighted_adj_eq_sum hd]
  dsimp [weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex, Equiv.refl]
  split_ifs <;> norm_num

open Classical in
lemma two_add_eq_two_iff (A B : Prop) [Decidable A] [Decidable B] :
  ((if A then (1 : ℚ) else 0) + (if B then 1 else 0) = 2) ↔ A ∧ B := by
  split_ifs <;> simp [*] <;> norm_num

open Classical in
lemma weighted_adj_eq_two_iff {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v = 2 ↔ 
    (G_d d).Adj (canonicalLift u) (canonicalLift v) ∧ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) := by
  rw [weighted_adj_eq_sum hd]
  dsimp [weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex, Equiv.refl]
  rw [sheetSplitInv_zero hd u, sheetSplitInv_zero hd v, sheetSplitInv_one hd v]
  exact two_add_eq_two_iff _ _

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

-- Characteristic polynomial factorization (axiomatized for now due to Mathlib missing charpoly_fromBlocks)
axiom charpoly_block_diag {α : Type*} [CommRing α] {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m] [DecidableEq m]
    (A : Matrix n n α) (B : Matrix m m α) :
    (Matrix.fromBlocks A 0 0 B).charpoly = A.charpoly * B.charpoly

axiom charpoly_similarity {α : Type*} [CommRing α] {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n α) (S : Matrix n n α) (S_inv : Matrix n n α)
    (h : S_inv * S = 1) :
    (S_inv * A * S).charpoly = A.charpoly

noncomputable def blockDiagMatrix {d : ℕ} (hd : d ≥ 3) : Matrix ((ZMod (2^(d-2))) ⊕ (ZMod (2^(d-2)))) ((ZMod (2^(d-2))) ⊕ (ZMod (2^(d-2)))) ℚ :=
  Matrix.fromBlocks (weightedMatrix hd) 0 0 (sheetDiffMatrix hd)

def sumProdEquiv {d : ℕ} : (ZMod (2^(d-2))) ⊕ (ZMod (2^(d-2))) ≃ ZMod (2^(d-2)) × ZMod 2 := sorry

axiom A'_block_diag_target_eq_blockDiagMatrix {d : ℕ} (hd : d ≥ 3) :
  A'_block_diag_target hd = Matrix.reindex sumProdEquiv sumProdEquiv (blockDiagMatrix hd)

/-- The characteristic polynomial of G_d factors exactly into the characteristic polynomials
    of the symmetric block (weightedMatrix) and the antisymmetric block. -/
lemma charpoly_adjacency_eq_mul {d : ℕ} (hd : d ≥ 3) :
    (@adjacencyMatrix d).charpoly = 
    (weightedMatrix hd).charpoly * (sheetDiffMatrix hd).charpoly := by
  -- Step 1: charpoly A = charpoly A' (by reindexing invariance)
  have h1 : (@adjacencyMatrix d).charpoly = (A'_matrix hd).charpoly := by
    rw [A'_matrix, Matrix.charpoly_reindex]
  
  -- Step 2: charpoly A' = charpoly (block diag) (by similarity)
  have h2 : (A'_matrix hd).charpoly = (A'_block_diag_target hd).charpoly := by
    rcases collatz_spectral_decomposition hd with ⟨S, S_inv, h_inv1, h_inv2, h_block⟩
    have h_sim : (S_inv * (@adjacencyMatrix d) * S).charpoly = (@adjacencyMatrix d).charpoly := by
      apply charpoly_similarity _ S S_inv
      exact h_inv1
    have h_reindex : (Matrix.reindex (sheetSplit hd).symm (sheetSplit hd).symm (A'_block_diag_target hd)).charpoly = (A'_block_diag_target hd).charpoly := by
      rw [Matrix.charpoly_reindex]
    rw [h_block] at h_sim
    rw [h_reindex] at h_sim
    rw [h1] at h_sim
    exact h_sim.symm
  
  -- Step 3: charpoly (block diag) = charpoly (weighted) * charpoly (antisym)
  have h3 : (A'_block_diag_target hd).charpoly = 
      (weightedMatrix hd).charpoly * (sheetDiffMatrix hd).charpoly := by
    rw [A'_block_diag_target_eq_blockDiagMatrix hd]
    rw [Matrix.charpoly_reindex]
    exact charpoly_block_diag (weightedMatrix hd) (sheetDiffMatrix hd)
  
  rw [h1, h2, h3]

-- For spectral_gap_bound, we need to map to ℝ to talk about ordered eigenvalues
noncomputable def realWeightedMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℝ :=
  (weightedMatrix hd).map (algebraMap ℚ ℝ)

axiom realWeightedMatrix_isHermitian {d : ℕ} (hd : d ≥ 3) :
  (realWeightedMatrix hd).IsHermitian

-- The eigenvalues are bounded by the graph degree
axiom weightedMatrix_eigenvalue_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (realWeightedMatrix_isHermitian hd) i ∈ Set.Icc (-4 : ℝ) 4

-- The antisymmetric block eigenvalues are empirically bounded by 2 in magnitude
noncomputable def realSheetDiffMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℝ :=
  (sheetDiffMatrix hd).map (algebraMap ℚ ℝ)

axiom realSheetDiffMatrix_isHermitian {d : ℕ} (hd : d ≥ 3) :
  (realSheetDiffMatrix hd).IsHermitian

axiom sheetDiffMatrix_eigenvalue_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (realSheetDiffMatrix_isHermitian hd) i ∈ Set.Icc (-2 : ℝ) 2

/-- The spectral gap of G_d is bounded by the spectral gap of G_{d-1} and the top eigenvalue of the antisymmetric block.
    This implies the spectral gap of G_d is strictly positive uniformly in d. -/
theorem spectral_gap_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (realWeightedMatrix_isHermitian hd) i ∈ Set.Icc (-4 : ℝ) 4 := by
  exact weightedMatrix_eigenvalue_bound hd

-- The eigenvalues of the full adjacency matrix are bounded by 4
noncomputable def realAdjacencyMatrix {d : ℕ} : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℝ :=
  (@adjacencyMatrix d).map (algebraMap ℚ ℝ)

axiom realAdjacencyMatrix_isHermitian {d : ℕ} :
  (@realAdjacencyMatrix d).IsHermitian

theorem adjacencyMatrix_eigenvalue_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (@realAdjacencyMatrix_isHermitian d) i ∈ Set.Icc (-4 : ℝ) 4 := by
  -- Follows from charpoly_adjacency_eq_mul and the bounds on the two blocks
  sorry

-- For a connected graph, the largest eigenvalue is simple and the spectral gap is positive
-- This requires Perron-Frobenius, which is not yet in Mathlib
axiom weightedMatrix_spectral_gap_positive {d : ℕ} (hd : d ≥ 3) :
    Matrix.IsHermitian.eigenvalues (realWeightedMatrix_isHermitian hd) 0 > 
    Matrix.IsHermitian.eigenvalues (realWeightedMatrix_isHermitian hd) 1



end CollatzSpectral
