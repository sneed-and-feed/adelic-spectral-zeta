import Mathlib
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Matrix.Kronecker
import Mathlib.NumberTheory.LegendreSymbol.AddCharacter
import Formalization.CollatzRelMatrix

open Matrix Finset Complex CollatzDirMatrix

variable {N : ℕ+} (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta N)

noncomputable def zmodChar_C : AddChar (ZMod N) ℂ := 
  AddChar.zmodChar N hzeta.pow_eq_one

lemma char_neg (x : ZMod N) : (zmodChar_C zeta hzeta) (-x) = ((zmodChar_C zeta hzeta) x)⁻¹ := 
  eq_inv_of_mul_eq_one_left <| by rw [← AddChar.map_add_mul, add_left_neg, AddChar.map_zero_one]

lemma char_star (x : ZMod N) : star (zmodChar_C zeta hzeta x) = zmodChar_C zeta hzeta (-x) := by
  have h_norm : ‖zmodChar_C zeta hzeta x‖ = 1 := by
    change ‖AddChar.zmodChar N _ x‖ = 1
    rw [AddChar.zmodChar_apply, norm_pow, Complex.norm_eq_one_of_pow_eq_one hzeta.pow_eq_one N.ne_zero, one_pow]
  rw [char_neg]
  apply eq_inv_of_mul_eq_one_left
  have hz2 := RCLike.conj_mul (zmodChar_C zeta hzeta x)
  rw [← RCLike.star_def] at hz2
  exact hz2.trans (by simp [h_norm])

noncomputable def dftMatrix : Matrix (ZMod N) (ZMod N) ℂ :=
  fun i j ↦ (1 / Real.sqrt N) * zmodChar_C zeta hzeta (i * j)

noncomputable def dftMatrix_star : Matrix (ZMod N) (ZMod N) ℂ :=
  fun i j ↦ star (dftMatrix zeta hzeta j i)

lemma dft_mul_star :
    dftMatrix zeta hzeta * dftMatrix_star zeta hzeta = 1 := by
  ext i j
  simp only [mul_apply, one_apply, dftMatrix, dftMatrix_star]
  have hs : star (1 / (Real.sqrt N : ℂ)) = 1 / (Real.sqrt N : ℂ) := by
    simp only [star_div', star_one, RCLike.star_def, conj_ofReal]
  have hs2 : (Real.sqrt N : ℂ) ^ 2 = (N : ℂ) := by norm_cast; exact Real.sq_sqrt (by positivity)
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr N.ne_zero
  have h_sum_congr : (∑ k : ZMod N, (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (i * k)) * star (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (j * k))) =
    ∑ k : ZMod N, (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((i - j) * k) := by
    apply sum_congr rfl
    intro k _
    rw [star_mul', char_star, hs]
    calc
      _ = (1 / (Real.sqrt N : ℂ) ^ 2) * (zmodChar_C zeta hzeta (i * k) * zmodChar_C zeta hzeta (-(j * k))) := by ring
      _ = (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((i - j) * k) := by rw [hs2, ← AddChar.map_add_mul]; congr 2; ring
  rw [h_sum_congr, ← Finset.mul_sum]
  have h_sum_comm : (∑ i_1 : ZMod N, (zmodChar_C zeta hzeta) ((i - j) * i_1)) = ∑ i_1 : ZMod N, (AddChar.zmodChar N hzeta.pow_eq_one) (i_1 * (i - j)) := by
    apply sum_congr rfl; intro k _; exact congrArg _ (mul_comm _ _)
  rw [h_sum_comm, AddChar.sum_mulShift _ (AddChar.zmodChar_primitive_of_primitive_root N hzeta)]
  simp_rw [sub_eq_zero]
  split_ifs with h_eq
  · rw [ZMod.card, one_div, inv_mul_cancel hN]
  · simp

lemma dft_star_mul :
    dftMatrix_star zeta hzeta * dftMatrix zeta hzeta = 1 := by
  ext i j
  simp only [mul_apply, one_apply, dftMatrix, dftMatrix_star]
  have hs : star (1 / (Real.sqrt N : ℂ)) = 1 / (Real.sqrt N : ℂ) := by
    simp only [star_div', star_one, RCLike.star_def, conj_ofReal]
  have hs2 : (Real.sqrt N : ℂ) ^ 2 = (N : ℂ) := by norm_cast; exact Real.sq_sqrt (by positivity)
  have hN : (N : ℂ) ≠ 0 := Nat.cast_ne_zero.mpr N.ne_zero
  have h_sum_congr : (∑ k : ZMod N, star (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (k * i)) * (1 / (Real.sqrt N : ℂ) * zmodChar_C zeta hzeta (k * j))) =
    ∑ k : ZMod N, (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((j - i) * k) := by
    apply sum_congr rfl
    intro k _
    rw [star_mul', char_star, hs]
    calc
      _ = (1 / (Real.sqrt N : ℂ) ^ 2) * (zmodChar_C zeta hzeta (-(k * i)) * zmodChar_C zeta hzeta (k * j)) := by ring
      _ = (1 / (N : ℂ)) * zmodChar_C zeta hzeta ((j - i) * k) := by rw [hs2, ← AddChar.map_add_mul]; congr 2; ring
  rw [h_sum_congr, ← Finset.mul_sum]
  have h_sum_comm : (∑ i_1 : ZMod N, (zmodChar_C zeta hzeta) ((j - i) * i_1)) = ∑ i_1 : ZMod N, (AddChar.zmodChar N hzeta.pow_eq_one) (i_1 * (j - i)) := by
    apply sum_congr rfl; intro k _; exact congrArg _ (mul_comm _ _)
  rw [h_sum_comm, AddChar.sum_mulShift _ (AddChar.zmodChar_primitive_of_primitive_root N hzeta)]
  have h_iff : j - i = 0 ↔ i = j := by constructor <;> intro h <;> [exact sub_eq_zero.mp h |>.symm; rw [h, sub_self]]
  simp_rw [h_iff]
  split_ifs with h_eq
  · rw [ZMod.card, one_div, inv_mul_cancel hN]
  · simp

variable {n : ℕ} (hn : n ≥ 3)

lemma hn_ge_2 : n ≥ 2 := by omega

lemma card_eq : 2^(n-1) = 2^(n-2) * 2 := by
  have h1 : n - 1 = n - 2 + 1 := by omega
  rw [h1, pow_add, pow_one]

lemma zmod_eq_fin (m : ℕ) (h : m > 0) : ZMod m = Fin m := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_succ_of_ne_zero h.ne'
  rfl

/-- Bijection for reindexing the twisted block -/
noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) :=
  let h1 : ZMod (2^(n-1)) = Fin (2^(n-1)) := zmod_eq_fin _ (by positivity)
  let h2 : ZMod (2^(n-2)) = Fin (2^(n-2)) := zmod_eq_fin _ (by positivity)
  let h3 : ZMod 2 = Fin 2 := zmod_eq_fin _ (by positivity)
  let e1 : ZMod (2^(n-1)) ≃ Fin (2^(n-1)) := Equiv.cast h1
  let e2 : ZMod (2^(n-2)) × ZMod 2 ≃ Fin (2^(n-2)) × Fin 2 := 
    Equiv.prodCongr (Equiv.cast h2) (Equiv.cast h3)
  let e3 : Fin (2^(n-1)) ≃ Fin (2^(n-2)) × Fin 2 :=
    (finCongr (card_eq hn)).trans finProdFinEquiv.symm
  e1.trans (e3.trans e2.symm)

/-- The Twisted Block Matrix mapped to Complex numbers -/
noncomputable def twistedDirMatrixC : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ :=
  Matrix.map (twistedDirMatrix (hn_ge_2 hn)) (algebraMap ℚ ℂ)

/-- The reindexed twisted matrix. -/
noncomputable def twistedDirMatrixC_reindexed : 
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  Matrix.reindex (index_equiv hn) (index_equiv hn) (twistedDirMatrixC hn)

set_option linter.unreachableTactic false
variable (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (⟨2^(n-2), by positivity⟩ : ℕ+))

open scoped Kronecker

/-- The Fourier basis matrix (F ⊗ I) -/
noncomputable def fourierBasisMatrix :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  (dftMatrix zeta hzeta) ⊗ₖ (1 : Matrix (ZMod 2) (ZMod 2) ℂ)

/-- The Fourier basis matrix conjugate transpose (F* ⊗ I) -/
noncomputable def fourierBasisMatrix_star :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  (dftMatrix_star zeta hzeta) ⊗ₖ (1 : Matrix (ZMod 2) (ZMod 2) ℂ)

/-- The Fourier basis is unitary -/
lemma fourierBasisMatrix_mul_star :
    fourierBasisMatrix zeta hzeta * fourierBasisMatrix_star zeta hzeta = 1 := by
  rw [fourierBasisMatrix, fourierBasisMatrix_star, ← Matrix.mul_kronecker_mul, dft_mul_star, Matrix.mul_one, Matrix.one_kronecker_one]

noncomputable def twistedBlockDiag :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  fourierBasisMatrix zeta hzeta * twistedDirMatrixC_reindexed hn * fourierBasisMatrix_star zeta hzeta

noncomputable def twistedBlock (k : ZMod (2^(n-2))) : Matrix (ZMod 2) (ZMod 2) ℂ :=
  fun i j ↦ twistedBlockDiag hn zeta hzeta (k, i) (k, j)

lemma twistedBlockDiag_spectrum_eq :
    twistedBlockDiag hn zeta hzeta =
    fourierBasisMatrix zeta hzeta * twistedDirMatrixC_reindexed hn * fourierBasisMatrix_star zeta hzeta := rfl
