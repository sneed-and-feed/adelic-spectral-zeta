import Mathlib
import Mathlib.Analysis.NormedSpace.Star.Matrix
import Mathlib.Analysis.NormedSpace.Star.Basic

open scoped Kronecker

namespace AFAlgebra

variable (n k : ℕ)

def embedMatrixAlgHom : Matrix (Fin n) (Fin n) ℂ →ₐ[ℂ] Matrix (Fin n × Fin k) (Fin n × Fin k) ℂ where
  toFun A := A ⊗ₖ (1 : Matrix (Fin k) (Fin k) ℂ)
  map_one' := by
    dsimp
    exact Matrix.one_kronecker_one
  map_mul' A B := by
    dsimp
    have h : (A * B) ⊗ₖ ((1 : Matrix (Fin k) (Fin k) ℂ) * (1 : Matrix (Fin k) (Fin k) ℂ)) = A ⊗ₖ (1 : Matrix (Fin k) (Fin k) ℂ) * B ⊗ₖ (1 : Matrix (Fin k) (Fin k) ℂ) :=
      Matrix.mul_kronecker_mul _ _ _ _
    rw [mul_one] at h
    exact h
  map_zero' := by
    dsimp
    ext ⟨i1, i2⟩ ⟨j1, j2⟩
    simp [Matrix.kroneckerMap]
  map_add' A B := by
    dsimp
    exact Matrix.add_kronecker A B (1 : Matrix (Fin k) (Fin k) ℂ)
  commutes' r := by
    ext ⟨i1, i2⟩ ⟨j1, j2⟩
    dsimp [Matrix.kroneckerMap]
    simp only [Algebra.algebraMap_eq_smul_one, smul_eq_mul, mul_one, Matrix.smul_apply, Matrix.one_apply]
    by_cases h1 : i1 = j1 <;> by_cases h2 : i2 = j2
    · subst h1; subst h2; simp
    · simp [h1, h2, Matrix.one_apply_ne]
    · simp [h1, h2, Matrix.one_apply_ne]
    · simp [h1, h2, Matrix.one_apply_ne]

def embedMatrixStarAlgHom : Matrix (Fin n) (Fin n) ℂ →⋆ₐ[ℂ] Matrix (Fin n × Fin k) (Fin n × Fin k) ℂ where
  toAlgHom := embedMatrixAlgHom n k
  map_star' A := by
    ext ⟨i1, i2⟩ ⟨j1, j2⟩
    dsimp [embedMatrixAlgHom, Matrix.kroneckerMap]
    simp only [star, Matrix.conjTranspose_apply, RCLike.star_def, RingHom.id_apply, map_mul]
    congr 2
    by_cases h2 : i2 = j2
    · subst h2; simp
    · simp [h2, Matrix.one_apply_ne, eq_comm]

-- Given a sequence of dimensions `n : ℕ → ℕ` where `n_i` divides `n_{i+1}`
-- and multiplicities `k i = n (i + 1) / n i`.
-- To form a direct limit of `Matrix (Fin (n i)) (Fin (n i)) ℂ`, one needs
-- StarAlgHom embeddings between them.
--
-- We can re-index `Fin (n × k)` to `Fin (n * k)` to get the sequence.
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
  toFun A := Matrix.reindex e e A
  map_one' := Matrix.reindex_one e
  map_mul' A B := Matrix.reindex_mul e e e A B
  map_zero' := by ext; simp [Matrix.reindex]
  map_add' A B := by ext; simp [Matrix.reindex]
  commutes' r := by ext; simp [Matrix.reindex, Algebra.algebraMap_eq_smul_one]
  map_star' A := by ext; simp [Matrix.reindex, star, Matrix.conjTranspose_apply]

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
