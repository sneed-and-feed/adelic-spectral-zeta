import Mathlib
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Kronecker
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Formalization.CollatzRelMatrix

open Matrix
open Finset
open Complex
open CollatzDirMatrix

variable {N : ℕ+} (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta N)

-- Construct the zmodChar for ZMod N.
noncomputable def zmodChar_C : AddChar (ZMod N) ℂ := 
  AddChar.zmodChar N hzeta.pow_eq_one

/-- The Discrete Fourier Transform Matrix -/
noncomputable def dftMatrix : Matrix (ZMod N) (ZMod N) ℂ :=
  fun i j ↦ (1 / Real.sqrt N) * zmodChar_C zeta hzeta (i * j)

/-- Conjugate transpose of the DFT Matrix -/
noncomputable def dftMatrix_star : Matrix (ZMod N) (ZMod N) ℂ :=
  fun i j ↦ star (dftMatrix zeta hzeta j i)

lemma char_neg (x : ZMod N) : (zmodChar_C zeta hzeta) (-x) = ((zmodChar_C zeta hzeta) x)⁻¹ := by
  apply eq_inv_of_mul_eq_one_left
  rw [← AddChar.map_add_mul, add_left_neg, AddChar.map_zero_one]

lemma char_star (x : ZMod N) : star (zmodChar_C zeta hzeta x) = zmodChar_C zeta hzeta (-x) := by
  rw [char_neg]
  have h_norm : ‖zmodChar_C zeta hzeta x‖ = 1 := by
    change ‖AddChar.zmodChar N hzeta.pow_eq_one x‖ = 1
    rw [AddChar.zmodChar_apply, norm_pow]
    have hz : ‖zeta‖ = 1 := by exact Complex.norm_eq_one_of_pow_eq_one hzeta.pow_eq_one N.ne_zero
    rw [hz, one_pow]
  apply eq_inv_of_mul_eq_one_left
  have h_sq : (‖zmodChar_C zeta hzeta x‖ : ℂ) ^ 2 = 1 := by 
    rw [h_norm]
    simp
  rw [RCLike.star_def]
  have hz2 := RCLike.conj_mul (zmodChar_C zeta hzeta x)
  rw [hz2]
  exact h_sq

/-- The DFT matrix is unitary -/
lemma dft_mul_star :
    dftMatrix zeta hzeta * dftMatrix_star zeta hzeta = 1 := by
  ext i j
  simp only [mul_apply, one_apply]
  have h_sum_congr : (∑ k : ZMod N, dftMatrix zeta hzeta i k * dftMatrix_star zeta hzeta k j) =
    ∑ k : ZMod N, (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((i - j) * k) := by
    apply sum_congr rfl
    intro k _
    change (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (i * k)) * star (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (j * k)) = _
    rw [star_mul', char_star]
    have hs : star (1 / (Real.sqrt N : ℂ)) = 1 / (Real.sqrt N : ℂ) := by
      simp only [star_div', star_one, RCLike.star_def, conj_ofReal]
    rw [hs]
    calc
      _ = (1 / (Real.sqrt N : ℂ)) * (1 / (Real.sqrt N : ℂ)) * (zmodChar_C zeta hzeta (i * k) * zmodChar_C zeta hzeta (-(j * k))) := by ring
      _ = (1 / (Real.sqrt N : ℂ) ^ 2) * (zmodChar_C zeta hzeta (i * k) * zmodChar_C zeta hzeta (-(j * k))) := by ring
      _ = (1 / (N : ℂ)) * (zmodChar_C zeta hzeta (i * k) * zmodChar_C zeta hzeta (-(j * k))) := by
        congr 2
        have hs2 : (Real.sqrt N : ℂ) ^ 2 = (N : ℂ) := by
          norm_cast
          exact Real.sq_sqrt (by positivity)
        rw [hs2]
      _ = (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((i - j) * k) := by
        congr 1
        rw [← AddChar.map_add_mul]
        congr 1
        ring
  rw [h_sum_congr, ← Finset.mul_sum]
  have h_sum_comm : (∑ i_1 : ZMod N, (zmodChar_C zeta hzeta) ((i - j) * i_1)) = ∑ i_1 : ZMod N, (zmodChar_C zeta hzeta) (i_1 * (i - j)) := by
    apply sum_congr rfl
    intro k _
    congr 1
    ring
  rw [h_sum_comm]
  have h_prim := AddChar.zmodChar_primitive_of_primitive_root N hzeta
  have h_sum := AddChar.sum_mulShift (i - j) h_prim
  change 1 / (N : ℂ) * (∑ i_1 : ZMod N, (AddChar.zmodChar N hzeta.pow_eq_one) (i_1 * (i - j))) = _
  have h_iff : i - j = 0 ↔ i = j := sub_eq_zero
  simp_rw [h_iff] at h_sum
  rw [h_sum]
  split_ifs with h_eq
  · have h_card : (Fintype.card (ZMod N) : ℂ) = N := by
      rw [ZMod.card]
      norm_cast
    have hN : (N : ℂ) ≠ 0 := by exact_mod_cast N.ne_zero
    rw [h_card, one_div, inv_mul_cancel hN]
  · simp [mul_zero]

/-- The DFT matrix is unitary (star_mul version) -/
lemma dft_star_mul :
    dftMatrix_star zeta hzeta * dftMatrix zeta hzeta = 1 := by
  ext i j
  simp only [mul_apply, one_apply]
  have h_sum_congr : (∑ k : ZMod N, dftMatrix_star zeta hzeta i k * dftMatrix zeta hzeta k j) =
    ∑ k : ZMod N, (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((j - i) * k) := by
    apply sum_congr rfl
    intro k _
    change star (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (k * i)) * (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (k * j)) = _
    rw [star_mul', char_star]
    have hs : star (1 / (Real.sqrt N : ℂ)) = 1 / (Real.sqrt N : ℂ) := by
      simp only [star_div', star_one, RCLike.star_def, conj_ofReal]
    rw [hs]
    calc
      _ = (1 / (Real.sqrt N : ℂ)) * (1 / (Real.sqrt N : ℂ)) * (zmodChar_C zeta hzeta (-(k * i)) * zmodChar_C zeta hzeta (k * j)) := by ring
      _ = (1 / (Real.sqrt N : ℂ) ^ 2) * (zmodChar_C zeta hzeta (-(k * i)) * zmodChar_C zeta hzeta (k * j)) := by ring
      _ = (1 / (N : ℂ)) * (zmodChar_C zeta hzeta (-(k * i)) * zmodChar_C zeta hzeta (k * j)) := by
        congr 2
        have hs2 : (Real.sqrt N : ℂ) ^ 2 = (N : ℂ) := by
          norm_cast
          exact Real.sq_sqrt (by positivity)
        rw [hs2]
      _ = (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((j - i) * k) := by
        congr 1
        rw [← AddChar.map_add_mul]
        congr 1
        ring
  rw [h_sum_congr, ← Finset.mul_sum]
  have h_sum_comm : (∑ i_1 : ZMod N, (zmodChar_C zeta hzeta) ((j - i) * i_1)) = ∑ i_1 : ZMod N, (zmodChar_C zeta hzeta) (i_1 * (j - i)) := by
    apply sum_congr rfl
    intro k _
    congr 1
    ring
  rw [h_sum_comm]
  have h_prim := AddChar.zmodChar_primitive_of_primitive_root N hzeta
  have h_sum := AddChar.sum_mulShift (j - i) h_prim
  change 1 / (N : ℂ) * (∑ i_1 : ZMod N, (AddChar.zmodChar N hzeta.pow_eq_one) (i_1 * (j - i))) = _
  have h_iff : j - i = 0 ↔ i = j := by
    constructor
    · intro h
      exact sub_eq_zero.mp h |>.symm
    · intro h
      rw [h, sub_self]
  simp_rw [h_iff] at h_sum
  rw [h_sum]
  split_ifs with h_eq
  · have h_card : (Fintype.card (ZMod N) : ℂ) = N := by
      rw [ZMod.card]
      norm_cast
    have hN : (N : ℂ) ≠ 0 := by exact_mod_cast N.ne_zero
    rw [h_card, one_div, inv_mul_cancel hN]
  · simp [mul_zero]

variable {n : ℕ} (hn : n ≥ 3)

lemma hn_ge_2 : n ≥ 2 := by omega

/-- Bijection for reindexing the twisted block -/
noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) :=
  sorry

/-- The Twisted Block Matrix mapped to Complex numbers -/
noncomputable def twistedDirMatrixC : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ :=
  Matrix.map (twistedDirMatrix (hn_ge_2 hn)) (algebraMap ℚ ℂ)

/-- The Twisted Block Matrix reindexed to the Kronecker product space -/
noncomputable def twistedDirMatrixC_reindexed : 
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  Matrix.reindex index_equiv index_equiv (twistedDirMatrixC hn)

variable (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (⟨2^(n-2), by positivity⟩ : ℕ+))

/-- The Fourier basis matrix (F ⊗ I) -/
noncomputable def fourierBasisMatrix :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  Matrix.kronecker (dftMatrix zeta hzeta) (1 : Matrix (ZMod 2) (ZMod 2) ℂ)

/-- The Fourier basis matrix conjugate transpose (F* ⊗ I) -/
noncomputable def fourierBasisMatrix_star :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  Matrix.kronecker (dftMatrix_star zeta hzeta) (1 : Matrix (ZMod 2) (ZMod 2) ℂ)

/-- The Fourier basis is unitary -/
lemma fourierBasisMatrix_mul_star :
    fourierBasisMatrix zeta hzeta * fourierBasisMatrix_star zeta hzeta = 1 := by
  rw [fourierBasisMatrix, fourierBasisMatrix_star, ← Matrix.mul_kronecker_mul]
  rw [dft_mul_star, Matrix.mul_one]
  exact Matrix.one_kronecker_one

/-- The block diagonalized twisted matrix F T F* -/
noncomputable def twistedBlockDiag :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  fourierBasisMatrix zeta hzeta * twistedDirMatrixC_reindexed hn * fourierBasisMatrix_star zeta hzeta

/-- The 2x2 blocks of the block diagonalized matrix -/
noncomputable def twistedBlock (k : ZMod (2^(n-2))) : Matrix (ZMod 2) (ZMod 2) ℂ :=
  fun i j ↦ twistedBlockDiag hn zeta hzeta (k, i) (k, j)

/-- Proof that twistedBlockDiag is actually block diagonal -/
lemma twistedBlockDiag_is_block_diagonal (k1 k2 : ZMod (2^(n-2))) (h_neq : k1 ≠ k2) :
    twistedBlockDiag hn zeta hzeta (k1, 0) (k2, 0) = 0 ∧
    twistedBlockDiag hn zeta hzeta (k1, 0) (k2, 1) = 0 ∧
    twistedBlockDiag hn zeta hzeta (k1, 1) (k2, 0) = 0 ∧
    twistedBlockDiag hn zeta hzeta (k1, 1) (k2, 1) = 0 := by
  sorry
