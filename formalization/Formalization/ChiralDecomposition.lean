import Mathlib
import Formalization.SchreierSpectral

open BigOperators Matrix
open SchreierSpectral

-- 1. Define the chiral operator `chiralOp d` (the J matrix: [0, -I; I, 0]).
noncomputable def chiralOp {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨s1, s2⟩ ⟨r1, r2⟩ =>
    if s1 = r1 then
      if s2 = 0 ∧ r2 = 1 then -1
      else if s2 = 1 ∧ r2 = 0 then 1
      else 0
    else 0

-- Define sheetDiffMatrix_block using A'_matrix
noncomputable def sheetDiffMatrix_block {d : ℕ} (hd : d ≥ 3) : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun ⟨s1, s2⟩ ⟨r1, r2⟩ =>
    if s2 = r2 then
      if s2 = 0 then A'_matrix hd (s1, 0) (r1, 0)
      else -A'_matrix hd (s1, 1) (r1, 1)
    else A'_matrix hd (s1, s2) (r1, r2)

-- 2. Prove that the block `fun ⟨s1,s2⟩ ⟨r1,r2⟩ => if s2=r2 then (if s2=0 then A else -A) else B` is precisely the structure
lemma sheetDiffMatrix_block_structure {d : ℕ} (hd : d ≥ 3) (s1 s2 r1 r2) :
  sheetDiffMatrix_block hd (s1, s2) (r1, r2) =
    if s2 = r2 then
      if s2 = 0 then A'_matrix hd (s1, 0) (r1, 0)
      else -A'_matrix hd (s1, 0) (r1, 0)
    else A'_matrix hd (s1, 0) (r1, 1) := by
  dsimp [sheetDiffMatrix_block]
  have hz : (0 : ZMod 2) = 0 := rfl
  have ho : (1 : ZMod 2) = 1 := rfl
  have hno : ¬((0 : ZMod 2) = 1) := by decide
  have hnz : ¬((1 : ZMod 2) = 0) := by decide
  fin_cases s2 <;> fin_cases r2
  · simp [hz, ho, hno, hnz]
  · simp [hz, ho, hno, hnz]
  · simp [hz, ho, hno, hnz]
    exact A'_tau_sym_01_10 hd s1 r1
  · simp [hz, ho, hno, hnz]
    exact A'_tau_sym_11_00 hd s1 r1

-- 3. State and prove `chiral_anticommute`: `chiralOp d * sheetDiffMatrix_block hd + sheetDiffMatrix_block hd * chiralOp d = 0`.
lemma chiral_anticommute {d : ℕ} (hd : d ≥ 3) :
  chiralOp hd * sheetDiffMatrix_block hd + sheetDiffMatrix_block hd * chiralOp hd = 0 := by
  ext ⟨s1, s2⟩ ⟨r1, r2⟩
  simp only [Matrix.add_apply, Matrix.mul_apply, Matrix.zero_apply, Fintype.sum_prod_type]
  dsimp [chiralOp, sheetDiffMatrix_block]
  have h_sum1 : (∑ x : ZMod (2 ^ (d - 2)), ∑ x_1 : ZMod 2, (if s1 = x then if s2 = 0 ∧ x_1 = 1 then (-1 : ℚ) else if s2 = 1 ∧ x_1 = 0 then (1 : ℚ) else 0 else 0) * if x_1 = r2 then if x_1 = 0 then A'_matrix hd (x, 0) (r1, 0) else -A'_matrix hd (x, 1) (r1, 1) else A'_matrix hd (x, x_1) (r1, r2)) = 
                ∑ x_1 : ZMod 2, (if s2 = 0 ∧ x_1 = 1 then (-1 : ℚ) else if s2 = 1 ∧ x_1 = 0 then (1 : ℚ) else 0) * (if x_1 = r2 then if x_1 = 0 then A'_matrix hd (s1, 0) (r1, 0) else -A'_matrix hd (s1, 1) (r1, 1) else A'_matrix hd (s1, x_1) (r1, r2)) := by
    have h_swap1 : (∑ x : ZMod (2 ^ (d - 2)), ∑ x_1 : ZMod 2, (if s1 = x then if s2 = 0 ∧ x_1 = 1 then (-1 : ℚ) else if s2 = 1 ∧ x_1 = 0 then (1 : ℚ) else 0 else 0) * if x_1 = r2 then if x_1 = 0 then A'_matrix hd (x, 0) (r1, 0) else -A'_matrix hd (x, 1) (r1, 1) else A'_matrix hd (x, x_1) (r1, r2)) = 
                   ∑ x_1 : ZMod 2, ∑ x : ZMod (2 ^ (d - 2)), (if s1 = x then if s2 = 0 ∧ x_1 = 1 then (-1 : ℚ) else if s2 = 1 ∧ x_1 = 0 then (1 : ℚ) else 0 else 0) * if x_1 = r2 then if x_1 = 0 then A'_matrix hd (x, 0) (r1, 0) else -A'_matrix hd (x, 1) (r1, 1) else A'_matrix hd (x, x_1) (r1, r2) := Finset.sum_comm
    rw [h_swap1]
    apply Finset.sum_congr rfl
    intro x_1 _
    simp_rw [ite_mul, zero_mul]
    rw [Finset.sum_ite_eq, if_pos (Finset.mem_univ s1)]
  
  have h_sum2 : (∑ x : ZMod (2 ^ (d - 2)), ∑ x_1 : ZMod 2, (if s2 = x_1 then if s2 = 0 then A'_matrix hd (s1, 0) (x, 0) else -A'_matrix hd (s1, 1) (x, 1) else A'_matrix hd (s1, s2) (x, x_1)) * if x = r1 then if x_1 = 0 ∧ r2 = 1 then (-1 : ℚ) else if x_1 = 1 ∧ r2 = 0 then (1 : ℚ) else 0 else 0) =
                ∑ x_1 : ZMod 2, (if s2 = x_1 then if s2 = 0 then A'_matrix hd (s1, 0) (r1, 0) else -A'_matrix hd (s1, 1) (r1, 1) else A'_matrix hd (s1, s2) (r1, x_1)) * (if x_1 = 0 ∧ r2 = 1 then (-1 : ℚ) else if x_1 = 1 ∧ r2 = 0 then (1 : ℚ) else 0) := by
    have h_swap : (∑ x : ZMod (2 ^ (d - 2)), ∑ x_1 : ZMod 2, (if s2 = x_1 then if s2 = 0 then A'_matrix hd (s1, 0) (x, 0) else -A'_matrix hd (s1, 1) (x, 1) else A'_matrix hd (s1, s2) (x, x_1)) * if x = r1 then if x_1 = 0 ∧ r2 = 1 then (-1 : ℚ) else if x_1 = 1 ∧ r2 = 0 then (1 : ℚ) else 0 else 0) =
                  ∑ x_1 : ZMod 2, ∑ x : ZMod (2 ^ (d - 2)), (if s2 = x_1 then if s2 = 0 then A'_matrix hd (s1, 0) (x, 0) else -A'_matrix hd (s1, 1) (x, 1) else A'_matrix hd (s1, s2) (x, x_1)) * if x = r1 then if x_1 = 0 ∧ r2 = 1 then (-1 : ℚ) else if x_1 = 1 ∧ r2 = 0 then (1 : ℚ) else 0 else 0 := by
      exact Finset.sum_comm
    rw [h_swap]
    apply Finset.sum_congr rfl
    intro x_1 _
    simp_rw [mul_ite, mul_zero]
    rw [Finset.sum_ite_eq', if_pos (Finset.mem_univ r1)]

  rw [h_sum1, h_sum2]
  simp_rw [sum_zmod_two]
  have hz : (0 : ZMod 2) = 0 := rfl
  have ho : (1 : ZMod 2) = 1 := rfl
  have hno : ¬((0 : ZMod 2) = 1) := by decide
  have hnz : ¬((1 : ZMod 2) = 0) := by decide
  fin_cases s2 <;> fin_cases r2
  · simp [hz, ho, hno, hnz]
    have h1 := A'_tau_sym_11_00 hd s1 r1
    have h2 := A'_tau_sym_01_10 hd s1 r1
    linarith
  · simp [hz, ho, hno, hnz]
    have h1 := A'_tau_sym_11_00 hd s1 r1
    have h2 := A'_tau_sym_01_10 hd s1 r1
    linarith
  · simp [hz, ho, hno, hnz]
    have h1 := A'_tau_sym_11_00 hd s1 r1
    have h2 := A'_tau_sym_01_10 hd s1 r1
    linarith
  · simp [hz, ho, hno, hnz]
    have h1 := A'_tau_sym_11_00 hd s1 r1
    have h2 := A'_tau_sym_01_10 hd s1 r1
    linarith

-- 4. State the corollary that eigenvalues of `sheetDiffMatrix_block` come in `±μ` pairs.
lemma eigenvalues_pairs {d : ℕ} (hd : d ≥ 3) (μ : ℚ) (v : ZMod (2^(d-2)) × ZMod 2 → ℚ) 
    (hv : sheetDiffMatrix_block hd *ᵥ v = μ • v) : 
  sheetDiffMatrix_block hd *ᵥ (chiralOp hd *ᵥ v) = (-μ) • (chiralOp hd *ᵥ v) := by
  -- M (J v) = (M J) v = (-J M) v = -J (M v) = -J (μ v) = -μ (J v)
  have h1 : sheetDiffMatrix_block hd *ᵥ (chiralOp hd *ᵥ v) = (sheetDiffMatrix_block hd * chiralOp hd) *ᵥ v := by
    rw [← Matrix.mulVec_mulVec]
  have h2 : sheetDiffMatrix_block hd * chiralOp hd = - (chiralOp hd * sheetDiffMatrix_block hd) := by
    have h_anti := chiral_anticommute hd
    ext i j
    have h := congr_fun (congr_fun h_anti i) j
    simp only [Matrix.add_apply, Matrix.zero_apply] at h
    exact eq_neg_iff_add_eq_zero.mpr (by rw [add_comm, h])
  rw [h1, h2, Matrix.neg_mulVec, ← Matrix.mulVec_mulVec, hv]
  -- Now we have -(chiralOp hd *ᵥ (μ • v))
  -- chiralOp hd is linear
  have h3 : chiralOp hd *ᵥ (μ • v) = μ • (chiralOp hd *ᵥ v) := by
    ext i
    simp only [Matrix.mulVec, Matrix.dotProduct, Pi.smul_apply, smul_eq_mul]
    rw [Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro j _
    ring
  rw [h3]
  -- Now we have -(μ • (chiralOp hd *ᵥ v)) = (-μ) • (chiralOp hd *ᵥ v)
  ext i
  simp only [Pi.neg_apply, Pi.smul_apply, smul_eq_mul]
  ring
