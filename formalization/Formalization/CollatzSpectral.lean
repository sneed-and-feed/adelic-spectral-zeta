import Mathlib.Data.Matrix.Basic
import Mathlib.Algebra.Module.Submodule.Basic
import Mathlib.LinearAlgebra.Matrix.Hermitian
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.LinearAlgebra.Matrix.Gershgorin
import Formalization.CollatzConnectivity

open Matrix
open Classical

namespace CollatzSpectral

-- ============================================================================
-- Layer of Genius: Canonical Sheet Decomposition & Simp Set
-- ============================================================================

lemma pow_two_identity {d : ℕ} (hd : d ≥ 3) : 2^(d-1) = 2 * 2^(d-2) := by
  have h_sub : d - 1 = (d - 2) + 1 := by omega
  rw [h_sub, pow_add, pow_one, mul_comm]

def canonicalLift {d : ℕ} (v : ZMod (2^(d-2))) : ZMod (2^(d-1)) :=
  (v.val : ZMod (2^(d-1)))

lemma pi_canonicalLift {d : ℕ} (w : ZMod (2^(d-2))) :
    pi (canonicalLift w) = w := by
  unfold canonicalLift
  rw [pi_natCast, ZMod.natCast_zmod_val]

lemma val_pi {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) :
    (pi x).val = x.val % 2^(d-2) := by
  have h1 : x = (x.val : ZMod (2^(d-1))) := (ZMod.natCast_zmod_val x).symm
  nth_rw 1 [h1]
  rw [pi_natCast]
  exact ZMod.val_natCast x.val

def sheetSplit {d : ℕ} (hd : d ≥ 3) : ZMod (2^(d-1)) ≃ (ZMod (2^(d-2)) × ZMod 2) where
  toFun x := (pi x, (if x.val < 2^(d-2) then 0 else 1 : ZMod 2))
  invFun := fun p => if p.2 = 0 then canonicalLift p.1 else tau (canonicalLift p.1)
  left_inv := by
    intro x
    have h_pow : 2^(d-1) = 2^(d-2) + 2^(d-2) := by rw [pow_two_identity hd, two_mul]
    have h_x_lt : x.val < 2^(d-1) := ZMod.val_lt x
    by_cases h : x.val < 2^(d-2)
    · have h_if : (if x.val < 2^(d-2) then (0:ZMod 2) else 1) = 0 := if_pos h
      change (if (if x.val < 2^(d-2) then (0:ZMod 2) else 1) = 0 then canonicalLift (pi x) else tau (canonicalLift (pi x))) = x
      rw [h_if, if_pos rfl]
      apply ZMod.val_injective
      change ((pi x).val : ZMod (2^(d-1))).val = x.val
      have h1 : (pi x).val = x.val % 2^(d-2) := val_pi hd x
      have h2 : x.val % 2^(d-2) = x.val := Nat.mod_eq_of_lt h
      rw [h1, h2]
      exact ZMod.val_natCast_of_lt (by omega)
    · have h_ge : x.val ≥ 2^(d-2) := by omega
      have h_if : (if x.val < 2^(d-2) then (0:ZMod 2) else 1) = 1 := if_neg h
      change (if (if x.val < 2^(d-2) then (0:ZMod 2) else 1) = 0 then canonicalLift (pi x) else tau (canonicalLift (pi x))) = x
      rw [h_if]
      have h_one_ne_zero : ¬((1:ZMod 2) = 0) := by decide
      rw [if_neg h_one_ne_zero]
      apply ZMod.val_injective
      change (tau (canonicalLift (pi x))).val = x.val
      unfold tau canonicalLift
      have h1 : (pi x).val = x.val - 2^(d-2) := by
        rw [val_pi hd x]
        have h_eq : x.val = (x.val - 2^(d-2)) + 2^(d-2) := by omega
        nth_rw 1 [h_eq]
        rw [Nat.add_mod_right]
        apply Nat.mod_eq_of_lt
        omega
      have h2 : ((pi x).val : ZMod (2^(d-1))).val = (pi x).val := by
        apply ZMod.val_natCast_of_lt
        omega
      have h3 : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := by
        apply ZMod.val_natCast_of_lt
        omega
      rw [ZMod.val_add, h2, h3, h1]
      have h4 : x.val - 2^(d-2) + 2^(d-2) = x.val := by omega
      rw [h4]
      exact Nat.mod_eq_of_lt (by omega)

  right_inv := by
    rintro ⟨v, b⟩
    have h_pow : 2^(d-1) = 2^(d-2) + 2^(d-2) := by rw [pow_two_identity hd, two_mul]
    have h_v_lt : v.val < 2^(d-2) := ZMod.val_lt v
    fin_cases b
    · change (pi (if (0:ZMod 2) = 0 then canonicalLift v else tau (canonicalLift v)),
                if (if (0:ZMod 2) = 0 then canonicalLift v else tau (canonicalLift v)).val < 2^(d-2) then (0:ZMod 2) else 1) = (v, 0)
      rw [if_pos rfl]
      have h1 : (canonicalLift v).val = v.val := by
        unfold canonicalLift
        apply ZMod.val_natCast_of_lt
        omega
      have h2 : (canonicalLift v).val < 2^(d-2) := by omega
      rw [if_pos h2, pi_canonicalLift]
    · change (pi (if (1:ZMod 2) = 0 then canonicalLift v else tau (canonicalLift v)),
                if (if (1:ZMod 2) = 0 then canonicalLift v else tau (canonicalLift v)).val < 2^(d-2) then (0:ZMod 2) else 1) = (v, 1)
      have h_one_ne_zero : ¬((1:ZMod 2) = 0) := by decide
      rw [if_neg h_one_ne_zero]
      have h1 : (canonicalLift v).val = v.val := by
        unfold canonicalLift
        apply ZMod.val_natCast_of_lt
        omega
      have h2 : (tau (canonicalLift v)).val = v.val + 2^(d-2) := by
        unfold tau
        rw [ZMod.val_add]
        have h3 : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := by
          apply ZMod.val_natCast_of_lt
          omega
        rw [h1, h3, Nat.mod_eq_of_lt]
        omega
      have h3 : ¬((tau (canonicalLift v)).val < 2^(d-2)) := by omega
      rw [if_neg h3, tau_pi hd, pi_canonicalLift]

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

lemma tau_eq_of_sub_eq_pow {d : ℕ} (hd : d ≥ 3) (x y : ZMod (2^(d-1))) 
    (h : x - y = (2^(d-2) : ZMod (2^(d-1)))) : tau x = y := by
  have h_pow : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h2 : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
    have h4 : 2 * 2^(d-2) = 2^(d-1) := by
      calc 2 * 2^(d-2) = 2^1 * 2^(d-2) := by ring
        _ = 2^(1 + (d - 2)) := by rw [← pow_add]
        _ = 2^(d-1) := by
          have : 1 + (d - 2) = d - 1 := by omega
          rw [this]
    rw [h4] at h2
    rw [h2]
    exact CharP.cast_eq_zero (ZMod (2^(d-1))) (2^(d-1))
  have h_tau : tau x = x + (2^(d-2) : ZMod (2^(d-1))) := by unfold tau; push_cast; rfl
  calc tau x = x + (2^(d-2) : ZMod (2^(d-1))) := h_tau
    _ = (y + (2^(d-2) : ZMod (2^(d-1)))) + (2^(d-2) : ZMod (2^(d-1))) := by
      have hxy : x = y + (2^(d-2) : ZMod (2^(d-1))) := by
        calc x = x - y + y := by ring
             _ = (2^(d-2) : ZMod (2^(d-1))) + y := by rw [h]
             _ = y + (2^(d-2) : ZMod (2^(d-1))) := by ring
      rw [hxy]
    _ = y + ((2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) := by ring
    _ = y + 0 := by rw [h_pow]
    _ = y := by ring

lemma three_mul_tau {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) :
    3 * tau x = 3 * x + (2^(d-2) : ZMod (2^(d-1))) := by
  have h_tau : tau x = x + (2^(d-2) : ZMod (2^(d-1))) := by unfold tau; push_cast; rfl
  have h_pow : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h2 : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
    have h4 : 2 * 2^(d-2) = 2^(d-1) := by
      calc 2 * 2^(d-2) = 2^1 * 2^(d-2) := by ring
        _ = 2^(1 + (d - 2)) := by rw [← pow_add]
        _ = 2^(d-1) := by
          have : 1 + (d - 2) = d - 1 := by omega
          rw [this]
    rw [h4] at h2
    rw [h2]
    exact CharP.cast_eq_zero (ZMod (2^(d-1))) (2^(d-1))
  calc 3 * tau x = 3 * (x + (2^(d-2) : ZMod (2^(d-1)))) := by rw [h_tau]
    _ = 3 * x + 3 * (2^(d-2) : ZMod (2^(d-1))) := by ring
    _ = 3 * x + (2^(d-2) : ZMod (2^(d-1))) + ((2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1)))) := by ring
    _ = 3 * x + (2^(d-2) : ZMod (2^(d-1))) + 0 := by rw [h_pow]
    _ = 3 * x + (2^(d-2) : ZMod (2^(d-1))) := by ring

lemma lift_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    (G_d (d-1)).Adj u v →
    (G_d d).Adj (canonicalLift u) (canonicalLift v) ∨ (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) := by
  intro h_adj
  rcases h_adj with ⟨h_ne, h_cases⟩
  have hx : canonicalLift u ≠ canonicalLift v := by
    intro h
    have h2 : pi (canonicalLift u) = pi (canonicalLift v) := by rw [h]
    rw [pi_canonicalLift, pi_canonicalLift] at h2
    exact h_ne h2
  have hy : canonicalLift u ≠ tau (canonicalLift v) := by
    intro h
    have h2 : pi (canonicalLift u) = pi (tau (canonicalLift v)) := by rw [h]
    rw [pi_canonicalLift, tau_pi hd, pi_canonicalLift] at h2
    exact h_ne h2
  rcases h_cases with h | h | h | h
  · -- v = 3u
    have h_pi : pi (canonicalLift v - 3 * canonicalLift u) = 0 := by
      rw [pi_sub, pi_mul_three, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inl ?_⟩
      calc canonicalLift v = canonicalLift v - 3 * canonicalLift u + 3 * canonicalLift u := by ring
        _ = 0 + 3 * canonicalLift u := by rw [h0]
        _ = 3 * canonicalLift u := by ring
    · right
      refine ⟨hy, Or.inl ?_⟩
      exact tau_eq_of_sub_eq_pow hd (canonicalLift v) (3 * canonicalLift u) h2
  · -- v = 3u - 1
    have h_pi : pi (canonicalLift v - (3 * canonicalLift u - 1)) = 0 := by
      rw [pi_sub, pi_mul_three_sub_one, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inr (Or.inl ?_)⟩
      calc canonicalLift v = canonicalLift v - (3 * canonicalLift u - 1) + (3 * canonicalLift u - 1) := by ring
        _ = 0 + (3 * canonicalLift u - 1) := by rw [h0]
        _ = 3 * canonicalLift u - 1 := by ring
    · right
      refine ⟨hy, Or.inr (Or.inl ?_)⟩
      exact tau_eq_of_sub_eq_pow hd (canonicalLift v) (3 * canonicalLift u - 1) h2
  · -- u = 3v
    have h_pi : pi (canonicalLift u - 3 * canonicalLift v) = 0 := by
      rw [pi_sub, pi_mul_three, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inr (Or.inr (Or.inl ?_))⟩
      calc canonicalLift u = canonicalLift u - 3 * canonicalLift v + 3 * canonicalLift v := by ring
        _ = 0 + 3 * canonicalLift v := by rw [h0]
        _ = 3 * canonicalLift v := by ring
    · right
      refine ⟨hy, Or.inr (Or.inr (Or.inl ?_))⟩
      calc canonicalLift u = canonicalLift u - 3 * canonicalLift v + 3 * canonicalLift v := by ring
        _ = (2^(d-2) : ZMod (2^(d-1))) + 3 * canonicalLift v := by rw [h2]
        _ = 3 * canonicalLift v + (2^(d-2) : ZMod (2^(d-1))) := by ring
        _ = 3 * tau (canonicalLift v) := (three_mul_tau hd (canonicalLift v)).symm
  · -- u = 3v - 1
    have h_pi : pi (canonicalLift u - (3 * canonicalLift v - 1)) = 0 := by
      rw [pi_sub, pi_mul_three_sub_one, pi_canonicalLift, pi_canonicalLift, h, sub_self]
    rcases (pi_eq_zero_iff hd _).mp h_pi with h0 | h2
    · left
      refine ⟨hx, Or.inr (Or.inr (Or.inr ?_))⟩
      calc canonicalLift u = canonicalLift u - (3 * canonicalLift v - 1) + (3 * canonicalLift v - 1) := by ring
        _ = 0 + (3 * canonicalLift v - 1) := by rw [h0]
        _ = 3 * canonicalLift v - 1 := by ring
    · right
      refine ⟨hy, Or.inr (Or.inr (Or.inr ?_))⟩
      calc canonicalLift u = canonicalLift u - (3 * canonicalLift v - 1) + (3 * canonicalLift v - 1) := by ring
        _ = (2^(d-2) : ZMod (2^(d-1))) + (3 * canonicalLift v - 1) := by rw [h2]
        _ = 3 * canonicalLift v + (2^(d-2) : ZMod (2^(d-1))) - 1 := by ring
        _ = 3 * tau (canonicalLift v) - 1 := by rw [three_mul_tau hd (canonicalLift v)]

open Classical in
lemma weighted_adj_ge_adj {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    weighted_adj hd u v ≥ if (G_d (d-1)).Adj u v then 1 else 0 := by
  by_cases h_adj : (G_d (d-1)).Adj u v
  · rw [if_pos h_adj]
    rw [weighted_adj_eq_sum hd]
    dsimp [weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex, Equiv.refl]
    rw [sheetSplitInv_zero hd u, sheetSplitInv_zero hd v, sheetSplitInv_one hd v]
    have h_lift := lift_adj hd u v h_adj
    rcases h_lift with h1 | h2
    · have h_eq1 : (if (G_d d).Adj (canonicalLift u) (canonicalLift v) then (1:ℚ) else 0) = 1 := if_pos h1
      have h_eq2 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) then 1 else 0 := by split_ifs <;> norm_num
      linarith
    · have h_eq1 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (canonicalLift v) then 1 else 0 := by split_ifs <;> norm_num
      have h_eq2 : (if (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) then (1:ℚ) else 0) = 1 := if_pos h2
      linarith
  · rw [if_neg h_adj]
    rw [weighted_adj_eq_sum hd]
    dsimp [weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex, Equiv.refl]
    rw [sheetSplitInv_zero hd u, sheetSplitInv_zero hd v, sheetSplitInv_one hd v]
    have hp1 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (canonicalLift v) then 1 else 0 := by split_ifs <;> norm_num
    have hp2 : (0 : ℚ) ≤ if (G_d d).Adj (canonicalLift u) (tau (canonicalLift v)) then 1 else 0 := by split_ifs <;> norm_num
    exact add_nonneg hp1 hp2

-- Phase 4: Spectral Decomposition & The Main Bound
-- ============================================================================

/-- The fundamental theorem of the Collatz Schreier graphs.
    The adjacency operator of G_d decomposes completely into two orthogonal sectors:
    1. A symmetric block identical to the weighted adjacency of G_{d-1}.
    2. An antisymmetric block capturing the sheet-exchange dynamics. -/
lemma hadamard_inv_mul {d : ℕ} (hd : d ≥ 3) :
    hadamardInv * hadamardBlock = 1 := by
  unfold hadamardInv
  rw [Matrix.smul_mul, hadamard_sq hd]
  ext i j
  simp [Matrix.smul_apply, Matrix.one_apply]

lemma hadamard_mul_inv {d : ℕ} (hd : d ≥ 3) :
    hadamardBlock * hadamardInv = 1 := by
  unfold hadamardInv
  rw [Matrix.mul_smul, hadamard_sq hd]
  ext i j
  simp [Matrix.smul_apply, Matrix.one_apply]

lemma conjBlockInv_mul_conjBlock {d : ℕ} (hd : d ≥ 3) :
    @conjBlockInv d * @conjBlock d = 1 := by
  ext ⟨i1, j1⟩ ⟨i2, j2⟩
  simp only [conjBlockInv, conjBlock, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i1 = i2
  · subst h
    have : ∀ k1, (∑ k2, (if i1 = k1 then hadamardInv j1 k2 else 0) * (if k1 = i1 then hadamardBlock k2 j2 else 0))
        = if i1 = k1 then ∑ k2, hadamardInv j1 k2 * hadamardBlock k2 j2 else 0 := by
      intro k1
      by_cases hk : i1 = k1 <;> simp [hk]
    simp_rw [this]
    have h_inv : (∑ k2 : ZMod 2, hadamardInv j1 k2 * hadamardBlock k2 j2) = if j1 = j2 then (1 : ℚ) else 0 := by
      calc (∑ k2 : ZMod 2, hadamardInv j1 k2 * hadamardBlock k2 j2)
        _ = (hadamardInv * hadamardBlock) j1 j2 := rfl
        _ = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) j1 j2 := by rw [hadamard_inv_mul hd]
        _ = if j1 = j2 then (1 : ℚ) else 0 := by rw [Matrix.one_apply]
    simp_rw [h_inv]
    simp
  · -- i1 ≠ i2
    have : ∀ k1 k2, (if i1 = k1 then hadamardInv j1 k2 else 0) * (if k1 = i2 then hadamardBlock k2 j2 else 0) = (0 : ℚ) := by
      intro k1 k2
      by_cases hk1 : i1 = k1
      · subst hk1; simp [h]
      · simp [hk1]
    simp_rw [this]
    simp [h]

lemma conjBlock_mul_conjBlockInv {d : ℕ} (hd : d ≥ 3) :
    @conjBlock d * @conjBlockInv d = 1 := by
  ext ⟨i1, j1⟩ ⟨i2, j2⟩
  simp only [conjBlock, conjBlockInv, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i1 = i2
  · subst h
    have : ∀ k1, (∑ k2, (if i1 = k1 then hadamardBlock j1 k2 else 0) * (if k1 = i1 then hadamardInv k2 j2 else 0))
        = if i1 = k1 then ∑ k2, hadamardBlock j1 k2 * hadamardInv k2 j2 else 0 := by
      intro k1
      by_cases hk : i1 = k1 <;> simp [hk]
    simp_rw [this]
    have h_inv : (∑ k2 : ZMod 2, hadamardBlock j1 k2 * hadamardInv k2 j2) = if j1 = j2 then (1 : ℚ) else 0 := by
      calc (∑ k2 : ZMod 2, hadamardBlock j1 k2 * hadamardInv k2 j2)
        _ = (hadamardBlock * hadamardInv) j1 j2 := rfl
        _ = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) j1 j2 := by rw [hadamard_mul_inv hd]
        _ = if j1 = j2 then (1 : ℚ) else 0 := by rw [Matrix.one_apply]
    simp_rw [h_inv]
    simp
  · -- i1 ≠ i2
    have : ∀ k1 k2, (if i1 = k1 then hadamardBlock j1 k2 else 0) * (if k1 = i2 then hadamardInv k2 j2 else 0) = (0 : ℚ) := by
      intro k1 k2
      by_cases hk1 : i1 = k1
      · subst hk1; simp [h]
      · simp [hk1]
    simp_rw [this]
    simp [h]

lemma reindex_mul {α : Type*} [CommRing α] {m m' n n' o o' : Type*} [Fintype m'] [Fintype n] [Fintype n'] [Fintype o] [Fintype o']
    [DecidableEq n] [DecidableEq n']
    (eₘ : m ≃ m') (eₙ : n ≃ n') (eₒ : o ≃ o')
    (M : Matrix m n α) (N : Matrix n o α) :
    Matrix.reindex eₘ eₙ M * Matrix.reindex eₙ eₒ N = Matrix.reindex eₘ eₒ (M * N) := by
  ext i j
  simp [Matrix.reindex_apply, Matrix.mul_apply, Matrix.submatrix_apply]
  exact Equiv.sum_comp eₙ.symm (fun x => M (eₘ.symm i) x * N x (eₒ.symm j))

theorem collatz_spectral_decomposition {d : ℕ} (hd : d ≥ 3) :
    ∃ (S : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ) (S_inv : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℚ),
      S_inv * S = 1 ∧ S * S_inv = 1 ∧
      S_inv * (@adjacencyMatrix d) * S = 
        Matrix.reindex (sheetSplit hd).symm (sheetSplit hd).symm (A'_block_diag_target hd) := by
  let e := sheetSplit hd
  use Matrix.reindex e.symm e.symm (@conjBlock d)
  use Matrix.reindex e.symm e.symm (@conjBlockInv d)
  have h_reindex_one : Matrix.reindex e.symm e.symm (1 : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ) = 1 := by
    ext i j
    have : e i = e j ↔ i = j := e.injective.eq_iff
    simp [Matrix.reindex_apply, Matrix.one_apply, this]
  constructor
  · -- S_inv * S = 1
    rw [reindex_mul]
    rw [conjBlockInv_mul_conjBlock hd]
    rw [h_reindex_one]
  · constructor
    · -- S * S_inv = 1
      rw [reindex_mul]
      rw [conjBlock_mul_conjBlockInv hd]
      rw [h_reindex_one]
    · -- S_inv * A * S = block diag
      have hA : @adjacencyMatrix d = Matrix.reindex e.symm e.symm (A'_matrix hd) := by
        rw [A'_matrix]
        ext i j
        simp [Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_symm]
      rw [hA]
      rw [reindex_mul, reindex_mul]
      rw [A'_block_diag hd]

-- Phase 5: Spectral Gap Bounds
-- ============================================================================

-- Characteristic polynomial factorization (axiomatized for now due to Mathlib missing charpoly_fromBlocks)
lemma charpoly_block_diag {α : Type*} [CommRing α] {n m : Type*} [Fintype n] [DecidableEq n] [Fintype m] [DecidableEq m]
    (A : Matrix n n α) (B : Matrix m m α) :
    (Matrix.fromBlocks A 0 0 B).charpoly = A.charpoly * B.charpoly := by
  unfold Matrix.charpoly
  rw [Matrix.charmatrix_fromBlocks]
  simp [Matrix.det_fromBlocks_zero₂₁]

theorem charpoly_similarity {α : Type*} [CommRing α] {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n α) (S : Matrix n n α) (S_inv : Matrix n n α)
    (h : S_inv * S = 1) :
    (S_inv * A * S).charpoly = A.charpoly := by
  let f : α →+* Polynomial α := Polynomial.C
  let F : Matrix n n α →+* Matrix n n (Polynomial α) := RingHom.mapMatrix f
  have h_map : F (S_inv * S) = F 1 := by rw [h]
  rw [map_mul F] at h_map
  have h_one : F 1 = 1 := map_one F
  rw [h_one] at h_map
  have h_map_comm : F S * F S_inv = 1 := by rw [Matrix.mul_eq_one_comm, h_map]
  unfold Matrix.charpoly
  have h_eq : Matrix.charmatrix (S_inv * A * S) = F S_inv * Matrix.charmatrix A * F S := by
    unfold Matrix.charmatrix
    rw [map_mul F, map_mul F, Matrix.mul_sub, Matrix.sub_mul]
    congr 1
    have h1 : F S_inv * Matrix.scalar n (Polynomial.X : Polynomial α) = Matrix.scalar n (Polynomial.X : Polynomial α) * F S_inv := by
      change F S_inv * algebraMap (Polynomial α) (Matrix n n (Polynomial α)) Polynomial.X = algebraMap (Polynomial α) (Matrix n n (Polynomial α)) Polynomial.X * F S_inv
      exact (Algebra.commutes _ _).symm
    rw [h1, Matrix.mul_assoc, h_map, Matrix.mul_one]
  rw [h_eq, Matrix.det_mul, Matrix.det_mul, mul_comm]
  have h_det : (F S).det * (F S_inv).det = 1 := by
    rw [← Matrix.det_mul, h_map_comm, Matrix.det_one]
  calc (F S).det * ((F S_inv).det * (Matrix.charmatrix A).det)
    _ = ((F S).det * (F S_inv).det) * (Matrix.charmatrix A).det := by rw [mul_assoc]
    _ = 1 * (Matrix.charmatrix A).det := by rw [h_det]
    _ = (Matrix.charmatrix A).det := by rw [one_mul]

noncomputable def blockDiagMatrix {d : ℕ} (hd : d ≥ 3) : Matrix ((ZMod (2^(d-2))) ⊕ (ZMod (2^(d-2)))) ((ZMod (2^(d-2))) ⊕ (ZMod (2^(d-2)))) ℚ :=
  Matrix.fromBlocks (weightedMatrix hd) 0 0 (sheetDiffMatrix hd)

def sumProdEquiv {d : ℕ} : (ZMod (2^(d-2))) ⊕ (ZMod (2^(d-2))) ≃ ZMod (2^(d-2)) × ZMod 2 where
  toFun := fun x => match x with
    | Sum.inl a => (a, 0)
    | Sum.inr a => (a, 1)
  invFun := fun p => match p.2 with
    | 0 => Sum.inl p.1
    | 1 => Sum.inr p.1
  left_inv := by intro x; cases x <;> rfl
  right_inv := by rintro ⟨v, b⟩; fin_cases b <;> rfl

lemma A'_block_diag_target_eq_blockDiagMatrix {d : ℕ} (hd : d ≥ 3) :
  A'_block_diag_target hd = Matrix.reindex sumProdEquiv sumProdEquiv (blockDiagMatrix hd) := by
  ext ⟨v1, b1⟩ ⟨v2, b2⟩
  fin_cases b1 <;> fin_cases b2 <;> simp [A'_block_diag_target, blockDiagMatrix, Matrix.fromBlocks, sumProdEquiv, Matrix.reindex_apply, Matrix.submatrix_apply, Equiv.symm_apply_apply]

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

theorem realWeightedMatrix_isHermitian {d : ℕ} (hd : d ≥ 3) :
  (realWeightedMatrix hd).IsHermitian := by
  ext i j
  dsimp [Matrix.IsHermitian, realWeightedMatrix, weightedMatrix, Matrix.map_apply]
  apply congrArg (algebraMap ℚ ℝ)
  have h1 : A'_matrix hd (j, 0) (i, 0) = A'_matrix hd (i, 0) (j, 0) := by
    unfold A'_matrix
    simp only [Matrix.reindex_apply, Equiv.symm_symm]
    dsimp [adjacencyMatrix]
    have h_symm : (G_d d).Adj ((sheetSplit hd).symm (j, 0)) ((sheetSplit hd).symm (i, 0)) ↔ (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 0)) := ⟨fun h => (G_d d).symm h, fun h => (G_d d).symm h⟩
    have h_eq : (G_d d).Adj ((sheetSplit hd).symm (j, 0)) ((sheetSplit hd).symm (i, 0)) = (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 0)) := propext h_symm
    simp only [h_eq]
  have h2 : A'_matrix hd (j, 0) (i, 1) = A'_matrix hd (i, 0) (j, 1) := by
    rw [← A'_tau_sym_01_10 hd j i]
    unfold A'_matrix
    simp only [Matrix.reindex_apply, Equiv.symm_symm]
    dsimp [adjacencyMatrix]
    have h_symm : (G_d d).Adj ((sheetSplit hd).symm (j, 1)) ((sheetSplit hd).symm (i, 0)) ↔ (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 1)) := ⟨fun h => (G_d d).symm h, fun h => (G_d d).symm h⟩
    have h_eq : (G_d d).Adj ((sheetSplit hd).symm (j, 1)) ((sheetSplit hd).symm (i, 0)) = (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 1)) := propext h_symm
    simp only [h_eq]
  rw [h1, h2]

-- The eigenvalues are bounded by the graph degree
lemma hasEigenvalue_eigenvalues {n : Type*} [Fintype n] [DecidableEq n] {A : Matrix n n ℝ}
    (hA : A.IsHermitian) (j : n) :
    Module.End.HasEigenvalue (Matrix.toLin' A) (hA.eigenvalues j) := by
  rw [Module.End.HasEigenvalue, Submodule.ne_bot_iff]
  use (hA.eigenvectorBasis j : n → ℝ)
  constructor
  · rw [Module.End.mem_eigenspace_iff, toLin'_apply]
    exact hA.mulVec_eigenvectorBasis j
  · intro h
    have h_ne := hA.eigenvectorBasis.toBasis.ne_zero j
    exact h_ne h

lemma eigenvalue_bound_of_gershgorin {n : Type*} [Fintype n] [DecidableEq n] {A : Matrix n n ℝ}
    (hA : A.IsHermitian) (j : n) (B : ℝ)
    (h_row : ∀ i, ∑ k, ‖A i k‖ ≤ B) :
    (hA.eigenvalues j) ∈ Set.Icc (-B) B := by
  have h_eig := hasEigenvalue_eigenvalues hA j
  have h_ball := eigenvalue_mem_ball h_eig
  rcases h_ball with ⟨k, hk⟩
  rw [mem_closedBall_iff_norm'] at hk
  have h_symm : ‖A k k - hA.eigenvalues j‖ = ‖hA.eigenvalues j - A k k‖ := norm_sub_rev _ _
  rw [h_symm] at hk
  have h1 : ‖hA.eigenvalues j‖ - ‖A k k‖ ≤ ‖hA.eigenvalues j - A k k‖ := norm_sub_norm_le _ _
  have h2 : ‖hA.eigenvalues j‖ ≤ ‖A k k‖ + ∑ y ∈ Finset.univ.erase k, ‖A k y‖ := by linarith
  have h3 : ‖A k k‖ + ∑ y ∈ Finset.univ.erase k, ‖A k y‖ = ∑ y, ‖A k y‖ := by
    exact Finset.add_sum_erase (s := Finset.univ) (f := fun y => ‖A k y‖) (h := Finset.mem_univ k)
  have hk2 : ‖hA.eigenvalues j‖ ≤ B := h2.trans (by rw [h3]; exact h_row k)
  rw [Real.norm_eq_abs, abs_le] at hk2
  exact hk2

lemma A'_matrix_val {d : ℕ} (hd : d ≥ 3) (x y : (ZMod (2^(d-2))) × ZMod 2) :
    A'_matrix hd x y = if (G_d d).Adj ((sheetSplit hd).symm x) ((sheetSplit hd).symm y) then (1 : ℚ) else (0 : ℚ) := rfl

lemma sum_A'_matrix_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    ∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) ≤ 4 := by
  have h_sum : ∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) = ∑ v, ∑ b : ZMod 2, A'_matrix hd (u, 0) (v, b) := by
    apply Finset.sum_congr rfl
    intro v _
    have h_zmod2 : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
    have h_not_mem : (0 : ZMod 2) ∉ ({1} : Finset (ZMod 2)) := by decide
    rw [h_zmod2, Finset.sum_insert h_not_mem, Finset.sum_singleton]
  rw [h_sum, ← Finset.sum_product']
  have h_univ_prod : (Finset.univ : Finset (ZMod (2^(d-2)))) ×ˢ (Finset.univ : Finset (ZMod 2)) = Finset.univ := rfl
  rw [h_univ_prod]
  have h_eq : ∑ p : (ZMod (2^(d-2))) × ZMod 2, A'_matrix hd (u, 0) p = ∑ y : ZMod (2^(d-1)), if (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y then (1 : ℚ) else (0 : ℚ) := by
    have h_equiv := Equiv.sum_comp (sheetSplit hd).symm (fun y => if (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y then (1 : ℚ) else (0 : ℚ))
    rw [← h_equiv]
    apply Finset.sum_congr rfl
    intro p _
    rw [A'_matrix_val]
  rw [h_eq]
  have h_filter : ∑ y : ZMod (2^(d-1)), (if (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y then (1 : ℚ) else (0 : ℚ)) = ((Finset.univ.filter (fun y => (G_d d).Adj ((sheetSplit hd).symm (u, 0)) y)).card : ℚ) := by
    rw [Finset.sum_ite]
    simp only [Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul, mul_one]
  rw [h_filter]
  have h_bound := G_d_degree_le hd ((sheetSplit hd).symm (u, 0))
  exact_mod_cast h_bound

lemma realWeightedMatrix_row_sum_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    ∑ v, ‖realWeightedMatrix hd u v‖ ≤ 4 := by
  have h_sum : ∑ v, ‖realWeightedMatrix hd u v‖ = ∑ v, (realWeightedMatrix hd u v) := by
    apply Finset.sum_congr rfl
    intro v _
    unfold realWeightedMatrix
    rw [Matrix.map_apply]
    have h_nonneg : (0 : ℝ) ≤ algebraMap ℚ ℝ (weightedMatrix hd u v) := by
      unfold weightedMatrix
      rw [map_add]
      have h1 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0)) := by
        rw [A'_matrix_val]
        split_ifs
        · norm_num
        · norm_num
      have h2 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1)) := by
        rw [A'_matrix_val]
        split_ifs
        · norm_num
        · norm_num
      exact add_nonneg h1 h2
    exact Real.norm_of_nonneg h_nonneg
  rw [h_sum]
  have h_map : ∑ v, realWeightedMatrix hd u v = algebraMap ℚ ℝ (∑ v, weightedMatrix hd u v) := by
    unfold realWeightedMatrix
    rw [map_sum]
    apply Finset.sum_congr rfl
    intro v _
    rw [Matrix.map_apply]
  rw [h_map]
  have h_sum_q : ∑ v, weightedMatrix hd u v = ∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) := by
    apply Finset.sum_congr rfl
    intro v _
    unfold weightedMatrix
    rfl
  rw [h_sum_q]
  have h_le := sum_A'_matrix_le hd u
  have h_alg : algebraMap ℚ ℝ (∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) = ∑ v : ZMod (2^(d-2)), ((A'_matrix hd (u, 0) (v, 0) : ℝ) + (A'_matrix hd (u, 0) (v, 1) : ℝ)) := by
    rw [map_sum]
    apply Finset.sum_congr rfl
    intro v _
    rw [map_add]
    rfl
  rw [h_alg]
  exact_mod_cast h_le

-- The eigenvalues are bounded by the graph degree
theorem weightedMatrix_eigenvalue_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (realWeightedMatrix_isHermitian hd) i ∈ Set.Icc (-4 : ℝ) 4 := by
  intro i
  apply eigenvalue_bound_of_gershgorin (realWeightedMatrix_isHermitian hd) i 4
  exact fun u => realWeightedMatrix_row_sum_le hd u

-- The antisymmetric block eigenvalues are empirically bounded by 2 in magnitude
noncomputable def realSheetDiffMatrix {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℝ :=
  (sheetDiffMatrix hd).map (algebraMap ℚ ℝ)

theorem realSheetDiffMatrix_isHermitian {d : ℕ} (hd : d ≥ 3) :
  (realSheetDiffMatrix hd).IsHermitian := by
  ext i j
  dsimp [Matrix.IsHermitian, realSheetDiffMatrix, sheetDiffMatrix, Matrix.map_apply]
  apply congrArg (algebraMap ℚ ℝ)
  have h1 : A'_matrix hd (j, 0) (i, 0) = A'_matrix hd (i, 0) (j, 0) := by
    unfold A'_matrix
    simp only [Matrix.reindex_apply, Equiv.symm_symm]
    dsimp [adjacencyMatrix]
    have h_symm : (G_d d).Adj ((sheetSplit hd).symm (j, 0)) ((sheetSplit hd).symm (i, 0)) ↔ (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 0)) := ⟨fun h => (G_d d).symm h, fun h => (G_d d).symm h⟩
    have h_eq : (G_d d).Adj ((sheetSplit hd).symm (j, 0)) ((sheetSplit hd).symm (i, 0)) = (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 0)) := propext h_symm
    simp only [h_eq]
  have h2 : A'_matrix hd (j, 0) (i, 1) = A'_matrix hd (i, 0) (j, 1) := by
    rw [← A'_tau_sym_01_10 hd j i]
    unfold A'_matrix
    simp only [Matrix.reindex_apply, Equiv.symm_symm]
    dsimp [adjacencyMatrix]
    have h_symm : (G_d d).Adj ((sheetSplit hd).symm (j, 1)) ((sheetSplit hd).symm (i, 0)) ↔ (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 1)) := ⟨fun h => (G_d d).symm h, fun h => (G_d d).symm h⟩
    have h_eq : (G_d d).Adj ((sheetSplit hd).symm (j, 1)) ((sheetSplit hd).symm (i, 0)) = (G_d d).Adj ((sheetSplit hd).symm (i, 0)) ((sheetSplit hd).symm (j, 1)) := propext h_symm
    simp only [h_eq]
  rw [h1, h2]

lemma realSheetDiffMatrix_row_sum_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-2))) :
    ∑ v, ‖realSheetDiffMatrix hd u v‖ ≤ 4 := by
  have h_le : ∀ v, ‖realSheetDiffMatrix hd u v‖ ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) := by
    intro v
    unfold realSheetDiffMatrix sheetDiffMatrix
    rw [Matrix.map_apply, map_sub, map_add]
    have h1 : ‖algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0)) - algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1))‖ ≤ ‖algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0))‖ + ‖algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1))‖ := norm_sub_le _ _
    have hp1 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0)) := by
      rw [A'_matrix_val]
      split_ifs
      · norm_num
      · norm_num
    have hp2 : (0 : ℝ) ≤ algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 1)) := by
      rw [A'_matrix_val]
      split_ifs
      · norm_num
      · norm_num
    rw [Real.norm_of_nonneg hp1, Real.norm_of_nonneg hp2] at h1
    exact h1
  have h_sum_le : ∑ v, ‖realSheetDiffMatrix hd u v‖ ≤ ∑ v, algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) := Finset.sum_le_sum (fun v _ => h_le v)
  have h_map : ∑ v, algebraMap ℚ ℝ (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1)) = algebraMap ℚ ℝ (∑ v, (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) := by
    rw [map_sum]
  rw [h_map] at h_sum_le
  have h_le2 := sum_A'_matrix_le hd u
  have h_le3 : algebraMap ℚ ℝ (∑ v, (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) ≤ 4 := by
    have h_alg : algebraMap ℚ ℝ (∑ v : ZMod (2^(d-2)), (A'_matrix hd (u, 0) (v, 0) + A'_matrix hd (u, 0) (v, 1))) = ∑ v : ZMod (2^(d-2)), ((A'_matrix hd (u, 0) (v, 0) : ℝ) + (A'_matrix hd (u, 0) (v, 1) : ℝ)) := by
      rw [map_sum]
      apply Finset.sum_congr rfl
      intro v _
      rw [map_add]
      rfl
    rw [h_alg]
    exact_mod_cast h_le2
  exact h_sum_le.trans h_le3

theorem sheetDiffMatrix_eigenvalue_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (realSheetDiffMatrix_isHermitian hd) i ∈ Set.Icc (-4 : ℝ) 4 := by
  intro i
  apply eigenvalue_bound_of_gershgorin (realSheetDiffMatrix_isHermitian hd) i 4
  exact fun u => realSheetDiffMatrix_row_sum_le hd u

lemma symm_of_herm {n : Type*} {A : Matrix n n ℝ} (h : A.IsHermitian) (i j : n) : A i j = A j i := by
  have h1 : A.conjTranspose j i = A j i := by rw [h]
  dsimp [Matrix.conjTranspose] at h1
  simp only [starRingEnd_apply, star_trivial] at h1
  exact h1

def supportGraph {n : Type*} [Fintype n] [DecidableEq n] (A : Matrix n n ℝ)
    (h_symm : ∀ i j, A i j = A j i) : SimpleGraph n where
  Adj i j := 0 < A i j ∧ i ≠ j
  symm := by
    intro i j h
    exact ⟨by rw [h_symm j i]; exact h.1, h.2.symm⟩
  loopless := by intro i h; exact h.2 rfl

/--
Perron–Frobenius simplicity for connected finite symmetric nonnegative matrices.

This is the only external spectral fact required by the Collatz decomposition
formalization. It should ultimately be discharged by a Mathlib Perron–Frobenius
development.
-/
axiom perron_frobenius_simple_max {n : Type*} [Fintype n] [DecidableEq n]
    (A : Matrix n n ℝ)
    (h_herm : A.IsHermitian)
    (h_symm : ∀ i j, A i j = A j i)
    (h_nonneg : ∀ i j, 0 ≤ A i j)
    (h_conn : (supportGraph A h_symm).Connected) :
    ∃ (i : n), ∀ (j : n), 
      h_herm.eigenvalues j ≤ h_herm.eigenvalues i
      ∧ (h_herm.eigenvalues j = h_herm.eigenvalues i → j = i)

lemma weightedMatrix_nonneg {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    0 ≤ realWeightedMatrix hd u v := by
  dsimp [realWeightedMatrix, Matrix.map_apply]
  have h1 : 0 ≤ weightedMatrix hd u v := by
    dsimp [weightedMatrix, A'_matrix, adjacencyMatrix, Matrix.reindex, Equiv.refl]
    apply add_nonneg <;> split_ifs <;> norm_num
  have h2 : (0:ℝ) = algebraMap ℚ ℝ 0 := by norm_num
  rw [h2]
  exact Rat.cast_le.mpr h1

lemma realWeightedMatrix_symm {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    realWeightedMatrix hd u v = realWeightedMatrix hd v u := 
  symm_of_herm (realWeightedMatrix_isHermitian hd) u v

theorem weighted_support_lift
  {d : ℕ} (hd : d ≥ 3)
  {u v : ZMod (2^(d-2))}
  (h : (G_d (d-1)).Adj u v) :
  (supportGraph (realWeightedMatrix hd) (realWeightedMatrix_symm hd)).Adj u v := by
  dsimp [supportGraph]
  constructor
  · have h1 := weighted_adj_ge_adj hd u v
    have h2 : (if (G_d (d - 1)).Adj u v then (1 : ℚ) else 0) = 1 := if_pos h
    rw [h2] at h1
    dsimp [realWeightedMatrix, Matrix.map_apply]
    have h3 : (1:ℝ) = algebraMap ℚ ℝ 1 := by norm_num
    have h4 : (0:ℝ) < 1 := by norm_num
    have h5 : algebraMap ℚ ℝ 1 ≤ algebraMap ℚ ℝ (weightedMatrix hd u v) := 
      Rat.cast_le.mpr h1
    rw [←h3] at h5
    exact lt_of_lt_of_le h4 h5
  · exact h.ne

theorem weighted_support_connected {d : ℕ} (hd : d ≥ 3) :
    (supportGraph (realWeightedMatrix hd) (realWeightedMatrix_symm hd)).Connected := by
  constructor
  intro u v
  have hd2 : d - 1 ≥ 2 := by omega
  have h_conn := (G_d_connected hd2).preconnected u v
  let f : (G_d (d-1)) →g (supportGraph (realWeightedMatrix hd) (realWeightedMatrix_symm hd)) := {
    toFun := id
    map_rel' := by
      intro x y hxy
      exact weighted_support_lift hd hxy
  }
  exact h_conn.map f

theorem weightedMatrix_spectral_gap_positive {d : ℕ} (hd : d ≥ 3) :
    ∃ (i : ZMod (2^(d-2))), ∀ (j : ZMod (2^(d-2))),
      (realWeightedMatrix_isHermitian hd).eigenvalues j ≤ (realWeightedMatrix_isHermitian hd).eigenvalues i
      ∧ ((realWeightedMatrix_isHermitian hd).eigenvalues j = (realWeightedMatrix_isHermitian hd).eigenvalues i → j = i) := by
  exact perron_frobenius_simple_max (realWeightedMatrix hd)
    (realWeightedMatrix_isHermitian hd)
    (realWeightedMatrix_symm hd)
    (weightedMatrix_nonneg hd)
    (weighted_support_connected hd)

/-- The spectral gap of G_d is bounded by the spectral gap of G_{d-1} and the top eigenvalue of the antisymmetric block.
    This implies the spectral gap of G_d is strictly positive uniformly in d. -/
theorem spectral_gap_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (realWeightedMatrix_isHermitian hd) i ∈ Set.Icc (-4 : ℝ) 4 := by
  exact weightedMatrix_eigenvalue_bound hd

-- The eigenvalues of the full adjacency matrix are bounded by 4
noncomputable def realAdjacencyMatrix {d : ℕ} : Matrix (ZMod (2^(d-1))) (ZMod (2^(d-1))) ℝ :=
  (@adjacencyMatrix d).map (algebraMap ℚ ℝ)

theorem realAdjacencyMatrix_isHermitian {d : ℕ} :
  (@realAdjacencyMatrix d).IsHermitian := by
  ext i j
  dsimp [Matrix.IsHermitian, realAdjacencyMatrix, adjacencyMatrix, Matrix.map_apply]
  apply congrArg (algebraMap ℚ ℝ)
  have h_symm : (G_d d).Adj i j ↔ (G_d d).Adj j i := ⟨fun h => (G_d d).symm h, fun h => (G_d d).symm h⟩
  have h_eq : (G_d d).Adj i j = (G_d d).Adj j i := propext h_symm
  simp only [h_eq]

lemma realAdjacencyMatrix_row_sum_le {d : ℕ} (hd : d ≥ 3) (u : ZMod (2^(d-1))) :
    ∑ v, ‖(@realAdjacencyMatrix d) u v‖ ≤ 4 := by
  have h_sum : ∑ v, ‖(@realAdjacencyMatrix d) u v‖ = ∑ v, (@realAdjacencyMatrix d) u v := by
    apply Finset.sum_congr rfl
    intro v _
    unfold realAdjacencyMatrix
    rw [Matrix.map_apply]
    have h_nonneg : (0 : ℝ) ≤ algebraMap ℚ ℝ (@adjacencyMatrix d u v) := by
      dsimp [adjacencyMatrix]
      split_ifs <;> norm_num
    exact Real.norm_of_nonneg h_nonneg
  rw [h_sum]
  have h_map : ∑ v, (@realAdjacencyMatrix d) u v = algebraMap ℚ ℝ (∑ v, @adjacencyMatrix d u v) := by
    unfold realAdjacencyMatrix
    rw [map_sum]
    apply Finset.sum_congr rfl
    intro v _
    rw [Matrix.map_apply]
  rw [h_map]
  have h_filter : ∑ v, @adjacencyMatrix d u v = ((Finset.univ.filter (fun v => (G_d d).Adj u v)).card : ℚ) := by
    dsimp [adjacencyMatrix]
    rw [Finset.sum_ite]
    simp only [Finset.sum_const_zero, add_zero, Finset.sum_const, nsmul_eq_mul, mul_one]
  rw [h_filter]
  have h_bound := G_d_degree_le hd u
  have h_bound_real : algebraMap ℚ ℝ ((Finset.univ.filter (fun v => (G_d d).Adj u v)).card : ℚ) ≤ 4 := by
    have h_eq : algebraMap ℚ ℝ ((Finset.univ.filter (fun v => (G_d d).Adj u v)).card : ℚ) = ((Finset.univ.filter (fun v => (G_d d).Adj u v)).card : ℝ) := rfl
    rw [h_eq]
    exact_mod_cast h_bound
  exact h_bound_real

theorem adjacencyMatrix_eigenvalue_bound {d : ℕ} (hd : d ≥ 3) :
    ∀ i, Matrix.IsHermitian.eigenvalues (@realAdjacencyMatrix_isHermitian d) i ∈ Set.Icc (-4 : ℝ) 4 := by
  intro i
  apply eigenvalue_bound_of_gershgorin (@realAdjacencyMatrix_isHermitian d) i 4
  exact fun u => realAdjacencyMatrix_row_sum_le hd u



end CollatzSpectral
