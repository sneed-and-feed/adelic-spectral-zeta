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
    have hN : (N : ℂ) ≠ 0 := by exact_mod_cast N.ne_zero
    rw [h_card, one_div, inv_mul_cancel hN]
  · simp [mul_zero]

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
  rw [fourierBasisMatrix, fourierBasisMatrix_star, ← Matrix.mul_kronecker_mul]
  rw [dft_mul_star, Matrix.mul_one]
  exact Matrix.one_kronecker_one

/-- The Fourier-conjugated twisted matrix `(F⊗I) · S_n · (F⊗I)*`.

    This is a unitary similarity transform, preserving the spectrum.

    ## Block Diagonalization Status

    The `F ⊗ I_2` conjugation does NOT produce 2×2 block diagonal form.
    However, the full DFT `F_{2^{n-1}}` applied directly to `S_n` DOES produce
    a **monomial** (generalized permutation) matrix, because:

    1. The generators `y = 3x` and `y = 3x-1` both respect the character
       decomposition: `χ_k(3x) = χ_{3k}(x)` and `χ_k(3x-1) = ω^{-k} · χ_{3k}(x)`.

    2. So `D_n` maps `χ_k ↦ (1 + ω^{-k}) · χ_{3k}`, a monomial action.

    3. The odd characters (where `χ_k(x + 2^{n-1}) = -χ_k(x)`) form the `S_n`
       eigenspace, and `×3` preserves parity, so `S_n` is monomial on odd `k`.

    4. The ×3 orbits on odd residues mod 2^n form exactly 2 cycles of length 2^{n-2}.

    5. The cyclotomic product identity `∏_{k odd} (1 + ω^{-k}) = 2` (proven in
       `CyclotomicProduct.lean`) gives each orbit weight product magnitude √2.

    6. Therefore ALL eigenvalues of `S_n` lie on a circle of radius `2^{1/2^{n-1}}`.

    The `F⊗I` infrastructure and definitions below remain valid as building blocks. -/
noncomputable def twistedBlockDiag :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  fourierBasisMatrix zeta hzeta * twistedDirMatrixC_reindexed hn * fourierBasisMatrix_star zeta hzeta

/-- The 2×2 diagonal blocks of the Fourier-conjugated matrix.
    Note: the full matrix is NOT block diagonal in these 2×2 blocks.
    The correct decomposition uses the full DFT into 2 orbit blocks. -/
noncomputable def twistedBlock (k : ZMod (2^(n-2))) : Matrix (ZMod 2) (ZMod 2) ℂ :=
  fun i j ↦ twistedBlockDiag hn zeta hzeta (k, i) (k, j)

/-- The Fourier-conjugated matrix is a unitary similarity of the reindexed twisted matrix.
    Therefore they share the same spectrum (eigenvalues with multiplicities). -/
lemma twistedBlockDiag_spectrum_eq :
    twistedBlockDiag hn zeta hzeta =
    fourierBasisMatrix zeta hzeta * twistedDirMatrixC_reindexed hn * fourierBasisMatrix_star zeta hzeta := by
  rfl


