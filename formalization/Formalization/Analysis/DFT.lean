import MathlibUpstream.Analysis.DFT
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Formalization.Dynamics.CollatzRelMatrix

open Matrix Finset Complex CollatzDirMatrix

lemma card_eq (n : ℕ) (hn : n ≥ 3) : 2^(n-1) = 2^(n-2) * 2 := by
  have h1 : n - 1 = n - 2 + 1 := by omega
  rw [h1, pow_add, pow_one]

lemma zmod_eq_fin (m : ℕ) (h : m > 0) : ZMod m = Fin m := by
  obtain ⟨k, rfl⟩ := Nat.exists_eq_succ_of_ne_zero h.ne'
  rfl

/-- Bijection for reindexing the twisted block -/
noncomputable def index_equiv (n : ℕ) (hn : n ≥ 3) : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) :=
  let h1 : ZMod (2^(n-1)) = Fin (2^(n-1)) := zmod_eq_fin _ (by positivity)
  let h2 : ZMod (2^(n-2)) = Fin (2^(n-2)) := zmod_eq_fin _ (by positivity)
  let h3 : ZMod 2 = Fin 2 := zmod_eq_fin _ (by positivity)
  let e1 : ZMod (2^(n-1)) ≃ Fin (2^(n-1)) := Equiv.cast h1
  let e2 : ZMod (2^(n-2)) × ZMod 2 ≃ Fin (2^(n-2)) × Fin 2 := 
    Equiv.prodCongr (Equiv.cast h2) (Equiv.cast h3)
  let e3 : Fin (2^(n-1)) ≃ Fin (2^(n-2)) × Fin 2 :=
    (finCongr (card_eq n hn)).trans finProdFinEquiv.symm
  e1.trans (e3.trans e2.symm)

/-- The Twisted Block Matrix mapped to Complex numbers -/
noncomputable def twistedDirMatrixC (n : ℕ) (hn : n ≥ 3) : Matrix (ZMod (2^(n-1))) (ZMod (2^(n-1))) ℂ :=
  Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ)

/-- The reindexed twisted matrix. -/
noncomputable def twistedDirMatrixC_reindexed (n : ℕ) (hn : n ≥ 3) : 
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  Matrix.reindex (index_equiv n hn) (index_equiv n hn) (twistedDirMatrixC n hn)

open scoped Kronecker

def pNatPow (n : ℕ) : ℕ+ := ⟨2^(n-2), Nat.two_pow_pos (n-2)⟩

/-- The Fourier basis matrix (F ⊗ I) -/
noncomputable def fourierBasisMatrix {n : ℕ} (_hn : n ≥ 3) (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (pNatPow n : ℕ)) :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  (dftMatrix (N := pNatPow n) zeta hzeta) ⊗ₖ (1 : Matrix (ZMod 2) (ZMod 2) ℂ)

/-- The Fourier basis matrix conjugate transpose (F* ⊗ I) -/
noncomputable def fourierBasisMatrix_star {n : ℕ} (_hn : n ≥ 3) (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (pNatPow n : ℕ)) :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  (dftMatrix_star (N := pNatPow n) zeta hzeta) ⊗ₖ (1 : Matrix (ZMod 2) (ZMod 2) ℂ)

/-- The Fourier basis is unitary -/
lemma fourierBasisMatrix_mul_star {n : ℕ} (hn : n ≥ 3) (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (pNatPow n : ℕ)) :
    fourierBasisMatrix hn zeta hzeta * fourierBasisMatrix_star hn zeta hzeta = 1 := by
  dsimp [fourierBasisMatrix, fourierBasisMatrix_star]
  have h_mul := (Matrix.mul_kronecker_mul (dftMatrix (N := pNatPow n) zeta hzeta)
    (dftMatrix_star (N := pNatPow n) zeta hzeta) (1 : Matrix (ZMod 2) (ZMod 2) ℂ) (1 : Matrix (ZMod 2) (ZMod 2) ℂ)).symm
  exact h_mul.trans (by rw [dft_mul_star, mul_one, Matrix.one_kronecker_one]; rfl)

/-- The Fourier-conjugated twisted matrix `(F⊗I) · S_n · (F⊗I)*`. -/
noncomputable def twistedBlockDiag (n : ℕ) (hn : n ≥ 3) (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (pNatPow n : ℕ)) :
    Matrix (ZMod (2^(n-2)) × ZMod 2) (ZMod (2^(n-2)) × ZMod 2) ℂ :=
  fourierBasisMatrix hn zeta hzeta * twistedDirMatrixC_reindexed n hn * fourierBasisMatrix_star hn zeta hzeta

/-- The 2×2 diagonal blocks of the Fourier-conjugated matrix. -/
noncomputable def twistedBlock (n : ℕ) (hn : n ≥ 3) (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (pNatPow n : ℕ))
    (k : ZMod (2^(n-2))) : Matrix (ZMod 2) (ZMod 2) ℂ :=
  fun i j ↦ twistedBlockDiag n hn zeta hzeta (k, i) (k, j)

/-- The Fourier-conjugated matrix is a unitary similarity of the reindexed twisted matrix. -/
lemma twistedBlockDiag_spectrum_eq (n : ℕ) (hn : n ≥ 3) (zeta : ℂ) (hzeta : IsPrimitiveRoot zeta (2^(n-2))) :
    twistedBlockDiag n hn zeta hzeta =
    fourierBasisMatrix hn zeta hzeta * twistedDirMatrixC_reindexed n hn * fourierBasisMatrix_star hn zeta hzeta := rfl
