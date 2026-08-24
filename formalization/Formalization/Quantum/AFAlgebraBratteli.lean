import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fin.VecNotation
import Mathlib.Data.Matrix.Basic
import Mathlib.LinearAlgebra.Matrix.Kronecker
import Mathlib.LinearAlgebra.Matrix.Reindex
import Mathlib.Analysis.CStarAlgebra.Matrix
import Mathlib.Analysis.CStarAlgebra.Classes
import Mathlib.Tactic

open scoped Kronecker

namespace AFAlgebra

variable (n k : ℕ)

def embedMatrixAlgHom : Matrix (Fin n) (Fin n) ℂ →ₐ[ℂ] Matrix (Fin n × Fin k) (Fin n × Fin k) ℂ where
  toFun A := A ⊗ₖ (1 : Matrix (Fin k) (Fin k) ℂ)
  map_one' := Matrix.one_kronecker_one
  map_mul' A B := by
    have h : (A * B) ⊗ₖ ((1 : Matrix (Fin k) (Fin k) ℂ) * (1 : Matrix (Fin k) (Fin k) ℂ)) = A ⊗ₖ (1 : Matrix (Fin k) (Fin k) ℂ) * B ⊗ₖ (1 : Matrix (Fin k) (Fin k) ℂ) :=
      Matrix.mul_kronecker_mul _ _ _ _
    rw [mul_one] at h
    exact h
  map_zero' := by
    ext ⟨i1, i2⟩ ⟨j1, j2⟩
    simp [Matrix.kroneckerMap]
  map_add' A B := Matrix.add_kronecker A B (1 : Matrix (Fin k) (Fin k) ℂ)
  commutes' r := by
    ext ⟨i1, i2⟩ ⟨j1, j2⟩
    simp only [Algebra.algebraMap_eq_smul_one, smul_eq_mul, Matrix.smul_apply, Matrix.one_apply,
      Matrix.kroneckerMap]
    by_cases h1 : i1 = j1 <;> by_cases h2 : i2 = j2
    · subst h1; subst h2; simp
    · simp [h2]
    · simp [h1]
    · simp [h1]

def embedMatrixStarAlgHom : Matrix (Fin n) (Fin n) ℂ →⋆ₐ[ℂ] Matrix (Fin n × Fin k) (Fin n × Fin k) ℂ where
  toAlgHom := embedMatrixAlgHom n k
  map_star' A := by
    ext ⟨i1, i2⟩ ⟨j1, j2⟩
    simp only [embedMatrixAlgHom, Matrix.kroneckerMap, star, Matrix.conjTranspose_apply]
    by_cases h2 : i2 = j2
    · subst h2; simp
    · have : (1 : Matrix (Fin k) (Fin k) ℂ) i2 j2 = 0 := Matrix.one_apply_ne h2
      have : (1 : Matrix (Fin k) (Fin k) ℂ) j2 i2 = 0 := Matrix.one_apply_ne (Ne.symm h2)
      simp [*]; rfl

def reindexAlgHom {m m' : ℕ} (h : m = m') :
    Matrix (Fin m) (Fin m) ℂ →⋆ₐ[ℂ] Matrix (Fin m') (Fin m') ℂ where
  toFun A := by subst h; exact A
  map_one' := by subst h; rfl
  map_mul' A B := by subst h; rfl
  map_zero' := by subst h; rfl
  map_add' A B := by subst h; rfl
  commutes' r := by subst h; rfl
  map_star' A := by subst h; rfl

def finProdEquiv {n k : ℕ} : Fin n × Fin k ≃ Fin (n * k) :=
  finProdFinEquiv

def equivAlgHom {m m' : Type*} [Fintype m] [Fintype m'] [DecidableEq m] [DecidableEq m']
    (e : m ≃ m') : Matrix m m ℂ →⋆ₐ[ℂ] Matrix m' m' ℂ where
  toAlgHom := (Matrix.reindexAlgEquiv ℂ ℂ e).toAlgHom
  map_star' A := by
    ext i j
    simp [Matrix.reindexAlgEquiv, Matrix.reindex, star, Matrix.conjTranspose_apply]

def stepStarAlgHom (n k : ℕ) : Matrix (Fin n) (Fin n) ℂ →⋆ₐ[ℂ] Matrix (Fin (n * k)) (Fin (n * k)) ℂ :=
  (equivAlgHom finProdEquiv).comp (embedMatrixStarAlgHom n k)

/-!
# Direct Limit of C*-algebras: Insurmountable Roadblock

Mathlib's `Algebra.DirectLimit` works for rings, modules, and `AlgHom`.
However, it does **not** preserve topological, metric, or normed structures out of the box,
meaning we cannot readily form the norm completion of the direct limit of C*-algebras.

Additionally, to formally define `UniformSpace.Completion` on the algebraic direct limit,
one must manually prove that the C* semi-norm defined on the direct limit satisfies the C*-identity,
quotient out by the kernel of this semi-norm, define a metric space, and then complete it.
This requires a massive amount of missing Mathlib infrastructure.

We explicitly fail here per the mandate.
-/

end AFAlgebra
