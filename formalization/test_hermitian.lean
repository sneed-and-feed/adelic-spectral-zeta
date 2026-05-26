import Formalization.CollatzSpectral

open Classical
open CollatzSpectral

lemma realAdjacencyMatrix_isHermitian_proof {d : ℕ} :
    Matrix.IsHermitian (@realAdjacencyMatrix d) := by
  ext i j
  dsimp [Matrix.IsHermitian, realAdjacencyMatrix, adjacencyMatrix, Matrix.map_apply]
  apply congrArg (algebraMap ℚ ℝ)
  have h_symm : (G_d d).Adj i j ↔ (G_d d).Adj j i := ⟨fun h => (G_d d).symm h, fun h => (G_d d).symm h⟩
  have h_eq : (G_d d).Adj i j = (G_d d).Adj j i := propext h_symm
  simp only [h_eq]

lemma realWeightedMatrix_isHermitian_proof {d : ℕ} (hd : d ≥ 3) :
    Matrix.IsHermitian (realWeightedMatrix hd) := by
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

lemma realSheetDiffMatrix_isHermitian_proof {d : ℕ} (hd : d ≥ 3) :
    Matrix.IsHermitian (realSheetDiffMatrix hd) := by
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
