import Formalization.SchreierSpectral

open Matrix
open scoped Matrix BigOperators
open SchreierSpectral

variable {d : ℕ} (hd : d ≥ 3)

noncomputable def symTransition : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2))) ℚ :=
  fun ⟨i1, j1⟩ i2 => if i1 = i2 then hadamardBlock j1 0 else 0

noncomputable def antisymTransition : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2))) ℚ :=
  fun ⟨i1, j1⟩ i2 => if i1 = i2 then hadamardBlock j1 1 else 0

noncomputable def symTransitionInv : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun i1 ⟨i2, j2⟩ => if i1 = i2 then hadamardInv 0 j2 else 0

noncomputable def antisymTransitionInv : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2)) × ZMod 2) ℚ :=
  fun i1 ⟨i2, j2⟩ => if i1 = i2 then hadamardInv 1 j2 else 0

lemma symTransition_inv_mul_symTransition :
    symTransitionInv * symTransition = (1 : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ) := by
  ext i j
  simp only [symTransitionInv, symTransition, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i = j
  · subst h
    have : ∀ k1, (∑ k2, (if i = k1 then hadamardInv 0 k2 else 0) * (if k1 = i then hadamardBlock k2 0 else 0))
        = if i = k1 then ∑ k2, hadamardInv 0 k2 * hadamardBlock k2 0 else 0 := by
      intro k1
      by_cases hk : i = k1 <;> simp [hk]
    simp_rw [this]
    have h_inv : (∑ k2 : ZMod 2, hadamardInv 0 k2 * hadamardBlock k2 0) = (1 : ℚ) := by
      calc (∑ k2 : ZMod 2, hadamardInv 0 k2 * hadamardBlock k2 0)
        _ = (hadamardInv * hadamardBlock) 0 0 := rfl
        _ = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) 0 0 := by rw [hadamard_inv_mul hd]
        _ = (1 : ℚ) := rfl
    simp_rw [h_inv]
    simp
  · have : ∀ k1 k2, (if i = k1 then hadamardInv 0 k2 else 0) * (if k1 = j then hadamardBlock k2 0 else 0) = (0 : ℚ) := by
      intro k1 k2
      by_cases hk1 : i = k1
      · subst hk1; simp [h]
      · simp [hk1]
    simp_rw [this]
    simp [h]

lemma antisymTransition_inv_mul_antisymTransition :
    antisymTransitionInv * antisymTransition = (1 : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ) := by
  ext i j
  simp only [antisymTransitionInv, antisymTransition, Matrix.mul_apply, Matrix.one_apply, Fintype.sum_prod_type]
  by_cases h : i = j
  · subst h
    have : ∀ k1, (∑ k2, (if i = k1 then hadamardInv 1 k2 else 0) * (if k1 = i then hadamardBlock k2 1 else 0))
        = if i = k1 then ∑ k2, hadamardInv 1 k2 * hadamardBlock k2 1 else 0 := by
      intro k1
      by_cases hk : i = k1 <;> simp [hk]
    simp_rw [this]
    have h_inv : (∑ k2 : ZMod 2, hadamardInv 1 k2 * hadamardBlock k2 1) = (1 : ℚ) := by
      calc (∑ k2 : ZMod 2, hadamardInv 1 k2 * hadamardBlock k2 1)
        _ = (hadamardInv * hadamardBlock) 1 1 := rfl
        _ = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) 1 1 := by rw [hadamard_inv_mul hd]
        _ = (1 : ℚ) := rfl
    simp_rw [h_inv]
    simp
  · have : ∀ k1 k2, (if i = k1 then hadamardInv 1 k2 else 0) * (if k1 = j then hadamardBlock k2 1 else 0) = (0 : ℚ) := by
      intro k1 k2
      by_cases hk1 : i = k1
      · subst hk1; simp [h]
      · simp [hk1]
    simp_rw [this]
    simp [h]

lemma symTransition_inv_mul_antisymTransition :
    symTransitionInv * antisymTransition = (0 : Matrix (ZMod (2^(d-2))) (ZMod (2^(d-2))) ℚ) := by
  ext i j
  simp only [symTransitionInv, antisymTransition, Matrix.mul_apply, Matrix.zero_apply, Fintype.sum_prod_type]
  by_cases h : i = j
  · subst h
    have : ∀ k1, (∑ k2, (if i = k1 then hadamardInv 0 k2 else 0) * (if k1 = i then hadamardBlock k2 1 else 0))
        = if i = k1 then ∑ k2, hadamardInv 0 k2 * hadamardBlock k2 1 else 0 := by
      intro k1
      by_cases hk : i = k1 <;> simp [hk]
    simp_rw [this]
    have h_inv : (∑ k2 : ZMod 2, hadamardInv 0 k2 * hadamardBlock k2 1) = (0 : ℚ) := by
      calc (∑ k2 : ZMod 2, hadamardInv 0 k2 * hadamardBlock k2 1)
        _ = (hadamardInv * hadamardBlock) 0 1 := rfl
        _ = (1 : Matrix (ZMod 2) (ZMod 2) ℚ) 0 1 := by rw [hadamard_inv_mul hd]
        _ = (0 : ℚ) := rfl
    simp_rw [h_inv]
    simp
  · have : ∀ k1 k2, (if i = k1 then hadamardInv 0 k2 else 0) * (if k1 = j then hadamardBlock k2 1 else 0) = (0 : ℚ) := by
      intro k1 k2
      by_cases hk1 : i = k1
      · subst hk1; simp [h]
      · simp [hk1]
    simp_rw [this]
    simp

lemma symTransition_mul_symTransition_inv_add_antisymTransition_mul_antisymTransition_inv :
    symTransition * symTransitionInv + antisymTransition * antisymTransitionInv = (1 : Matrix (ZMod (2^(d-2)) × ZMod 2) (ZMod (2^(d-2)) × ZMod 2) ℚ) := by
  ext ⟨i1, j1⟩ ⟨i2, j2⟩
  simp only [symTransition, symTransitionInv, antisymTransition, antisymTransitionInv, Matrix.add_apply, Matrix.mul_apply, Matrix.one_apply, Prod.mk.injEq]
  by_cases h : i1 = i2
  · subst h
    have h_sym : (∑ k, (if i1 = k then hadamardBlock j1 0 else 0) * (if k = i1 then hadamardInv 0 j2 else 0)) = hadamardBlock j1 0 * hadamardInv 0 j2 := by
      have : ∀ k, (if i1 = k then hadamardBlock j1 0 else 0) * (if k = i1 then hadamardInv 0 j2 else 0) = if i1 = k then hadamardBlock j1 0 * hadamardInv 0 j2 else 0 := by
        intro k
        by_cases hk : i1 = k <;> simp [hk]
      simp_rw [this]
      simp
    have h_anti : (∑ k, (if i1 = k then hadamardBlock j1 1 else 0) * (if k = i1 then hadamardInv 1 j2 else 0)) = hadamardBlock j1 1 * hadamardInv 1 j2 := by
      have : ∀ k, (if i1 = k then hadamardBlock j1 1 else 0) * (if k = i1 then hadamardInv 1 j2 else 0) = if i1 = k then hadamardBlock j1 1 * hadamardInv 1 j2 else 0 := by
        intro k
        by_cases hk : i1 = k <;> simp [hk]
      simp_rw [this]
      simp
    rw [h_sym, h_anti]
    have h_sum : hadamardBlock j1 0 * hadamardInv 0 j2 + hadamardBlock j1 1 * hadamardInv 1 j2 = (hadamardBlock * hadamardInv) j1 j2 := by
      dsimp [Matrix.mul_apply]
      rw [sum_zmod_two]
    rw [h_sum, hadamard_mul_inv hd, Matrix.one_apply]
    simp
  · have h_sym : (∑ k, (if i1 = k then hadamardBlock j1 0 else 0) * (if k = i2 then hadamardInv 0 j2 else 0)) = (0 : ℚ) := by
      have : ∀ k, (if i1 = k then hadamardBlock j1 0 else 0) * (if k = i2 then hadamardInv 0 j2 else 0) = 0 := by
        intro k
        by_cases hk1 : i1 = k
        · subst hk1; simp [h]
        · simp [hk1]
      simp_rw [this]
      simp
    have h_anti : (∑ k, (if i1 = k then hadamardBlock j1 1 else 0) * (if k = i2 then hadamardInv 1 j2 else 0)) = (0 : ℚ) := by
      have : ∀ k, (if i1 = k then hadamardBlock j1 1 else 0) * (if k = i2 then hadamardInv 1 j2 else 0) = 0 := by
        intro k
        by_cases hk1 : i1 = k
        · subst hk1; simp [h]
        · simp [hk1]
      simp_rw [this]
      simp
    rw [h_sym, h_anti]
    simp [h]
