import Mathlib
import Formalization.SpectralCircle
import Formalization.SchreierSpectralGap

open CollatzDirMatrix

namespace Sorry3

theorem spectral_circle (n : ℕ) (hn : n ≥ 3)
    (μ : ℂ) (hμ : μ ∈ spectrum ℂ (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) :
    Complex.abs μ = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  have h_eig : Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) μ := by
    rw [Module.End.hasEigenvalue_iff_mem_spectrum]
    have h_eq : spectrum ℂ (Matrix.toLin' (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) = spectrum ℂ (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ)) := by
      exact AlgEquiv.spectrum_eq Matrix.toLinAlgEquiv' _
    rw [h_eq]
    exact hμ
  exact twisted_eigenvalue_magnitude n hn μ h_eig

end Sorry3
