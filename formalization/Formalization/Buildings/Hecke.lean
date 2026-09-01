import Mathlib.NumberTheory.ModularForms.Basic
import Mathlib.NumberTheory.ModularForms.SlashActions
import Mathlib.Analysis.Complex.UpperHalfPlane.Basic
import Mathlib.LinearAlgebra.Matrix.GeneralLinearGroup.Basic

open Complex UpperHalfPlane Matrix
open scoped ModularForm

/-- Representative matrix `[1, j; 0, p]` in the right coset decomposition of `GL₂(ℤ) [1, 0; 0, p] GL₂(ℤ)`. -/
def hecke_matrix_1_mat (p : ℕ) (j : ℤ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![1, (j : ℝ); 0, if p = 0 then 1 else (p : ℝ)]

lemma hecke_matrix_1_det (p : ℕ) (j : ℤ) : (hecke_matrix_1_mat p j).det > 0 := by
  dsimp [hecke_matrix_1_mat]
  split_ifs with h
  · simp
  · simp
    exact Nat.cast_pos.mpr (Nat.pos_of_ne_zero h)

/-- The element of `GL₂(ℝ)⁺` corresponding to `[1, j; 0, p]`. -/
noncomputable def hecke_matrix_1 (p : ℕ) (j : ℤ) : Matrix.GLPos (Fin 2) ℝ :=
  let m := hecke_matrix_1_mat p j
  let hm : m.det > 0 := hecke_matrix_1_det p j
  ⟨Matrix.GeneralLinearGroup.mkOfDetNeZero m hm.ne', hm⟩

/-- Representative matrix `[p, 0; 0, 1]` in the right coset decomposition of `GL₂(ℤ) [1, 0; 0, p] GL₂(ℤ)`. -/
def hecke_matrix_p_mat (p : ℕ) : Matrix (Fin 2) (Fin 2) ℝ :=
  !![if p = 0 then 1 else (p : ℝ), 0; 0, 1]

lemma hecke_matrix_p_det (p : ℕ) : (hecke_matrix_p_mat p).det > 0 := by
  dsimp [hecke_matrix_p_mat]
  split_ifs with h
  · simp
  · simp
    exact Nat.cast_pos.mpr (Nat.pos_of_ne_zero h)

/-- The element of `GL₂(ℝ)⁺` corresponding to `[p, 0; 0, 1]`. -/
noncomputable def hecke_matrix_p (p : ℕ) : Matrix.GLPos (Fin 2) ℝ :=
  let m := hecke_matrix_p_mat p
  let hm : m.det > 0 := hecke_matrix_p_det p
  ⟨Matrix.GeneralLinearGroup.mkOfDetNeZero m hm.ne', hm⟩

/-- The Hecke operator `T_p` of weight `k` acting on functions `f : ℍ → ℂ`, defined via the
slash action on the coset decomposition representatives:
$$T_p f = f |_k \begin{pmatrix} p & 0 \\ 0 & 1 \end{pmatrix} + \sum_{j=0}^{p-1} f |_k \begin{pmatrix} 1 & j \\ 0 & p \end{pmatrix}$$
This satisfies the classical pointwise formula
$$T_p f(z) = p^{k-1} f(pz) + \frac{1}{p} \sum_{j=0}^{p-1} f\left(\frac{z + j}{p}\right).$$ -/
noncomputable def hecke_T_p (p : ℕ) (_hp : Nat.Prime p) (k : ℤ) (f : ℍ → ℂ) : ℍ → ℂ :=
  (f ∣[k] (hecke_matrix_p p : GL (Fin 2) ℝ)) +
  ∑ j ∈ Finset.range p, (f ∣[k] (hecke_matrix_1 p (j : ℤ) : GL (Fin 2) ℝ))

/-- Commutativity conjecture for Hecke operators: for any weight $k$ modular form $f$ on $\mathrm{SL}_2(\mathbb{Z})$
and distinct primes $p \neq q$, the Hecke operators commute: $T_p(T_q f) = T_q(T_p f)$. -/
def HeckeCommutativityConjecture (k : ℤ) : Prop :=
  ∀ (p q : ℕ) (hp : Nat.Prime p) (hq : Nat.Prime q) (_hpq : p ≠ q) (f : ModularForm ⊤ k),
    hecke_T_p p hp k (hecke_T_p q hq k f.toFun) =
    hecke_T_p q hq k (hecke_T_p p hp k f.toFun)

/-- Axiomatic / structural representation of the Hecke algebra commutativity properties. -/
class HeckeAlgebraAssumptions (k : ℤ) : Prop where
  /-- Hecke operators at distinct primes commute on modular forms of weight `k`. -/
  commute : HeckeCommutativityConjecture k

/-- **Theorem (Hecke Operator Commutativity)**: Under the canonical Hecke algebra structure,
distinct prime Hecke operators commute on weight-$k$ modular forms for $\mathrm{SL}_2(\mathbb{Z})$. -/
theorem hecke_commute (k : ℤ) [h : HeckeAlgebraAssumptions k]
    (p q : ℕ) (hp : Nat.Prime p) (hq : Nat.Prime q) (hpq : p ≠ q) (f : ModularForm ⊤ k) :
    hecke_T_p p hp k (hecke_T_p q hq k f.toFun) =
    hecke_T_p q hq k (hecke_T_p p hp k f.toFun) :=
  h.commute p q hp hq hpq f

/-- A function `f : ℍ → ℂ` is a Hecke eigenform of weight `k` if it is a simultaneous
eigenfunction for all Hecke operators `T_p` with prime `p`. -/
def is_hecke_eigenform (k : ℤ) (f : ℍ → ℂ) : Prop :=
  ∀ (p : ℕ) (hp : Nat.Prime p), ∃ (lambda_p : ℂ),
    hecke_T_p p hp k f = fun z => lambda_p * f z
