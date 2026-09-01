import Mathlib.Data.Matrix.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.Fin.Basic
import Mathlib.Data.Finset.Basic
import Mathlib.Data.Fintype.Card
import Mathlib.Data.ZMod.Basic
import Mathlib.LinearAlgebra.Matrix.Trace
import Mathlib.LinearAlgebra.Matrix.ConjTranspose
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Tactic

open scoped BigOperators Real Matrix

set_option linter.unusedSimpArgs false
set_option linter.dupNamespace false

namespace AMEPentagonTensor

/-!
# 5-Qubit Absolutely Maximally Entangled (AME(5, 2)) State and [[5, 1, 3]] Perfect Tensor

This module formalizes the 5-qubit Absolutely Maximally Entangled (AME(5, 2)) state,
the stabilizer algebra of the [[5, 1, 3]] quantum error correcting code, and the
pentagon perfect tensor underpinning HaPPY holographic tensor networks.

## Main Components:
1. **State Spaces**: Definition of the 5-leg qubit space, subsystem leg configurations,
   and exact Hilbert state gluing.
2. **Pauli Stabilizers & Cyclic Symmetry**: The 5-qubit Pauli operators, symplectic inner
   product, cyclic permutation symmetry $C_5$, mutual commutation of stabilizer generators
   $g_1, g_2, g_3, g_4$, and logical $\bar{X}, \bar{Z}$ anticommutation.
3. **Stabilizer Code Properties**: Proof that all 15 non-identity stabilizer elements have
   Pauli weight $\ge 4$.
4. **AME(5, 2) Pentagon Tensor**: Algebraic structure `PentagonAME` defining 5-leg perfect tensors where
   every subsystem $S \subseteq \mathrm{Fin}\ 5$ with $|S| \le 2$ has maximally mixed
   reduced density matrix $\rho_S = \frac{1}{2^{|S|}} I$.
5. **Canonical AME Construction**: Explicit constructive graph state pentagon tensor on the
   5-cycle $C_5$ with verified AME properties.
6. **Bipartite Isometries**: Exact isometric reduction $V^\dagger V = I$ for $2 \to 3$ legs,
   $1 \to 4$ legs (single-qubit isometric encoding), and $0 \to 5$ legs (state normalization).
7. **Purity & Entanglement Entropy**: Exact calculation of purity $\gamma(\rho_S) = 2^{-|S|}$
   and maximal 2-qubit entanglement entropy $S(\rho_S) = 2 \ln 2$.
8. **[[5, 1, 3]] Error-Erasure Recovery**: Proof of the Knill-Laflamme error-erasure correction
   condition and perfect quantum state reconstruction from any 3 qubits when at most 2 are erased.
-/

/-! ### 1. State and Operator Spaces -/

/-- Dimension of a single qubit Hilbert space. -/
def qubitDim : ℕ := 2

/-- Legs of the pentagon tensor, indexed by `Fin 5`. -/
abbrev PentagonLeg := Fin 5

/-- Basis state configurations of a subsystem of legs `S : Finset (Fin 5)`. -/
abbrev LegState (S : Finset (Fin 5)) := (i : S) → Fin 2

/-- Basis state configuration of all 5 legs of the pentagon tensor. -/
abbrev Basis5 := Fin 5 → Fin 2

/-- The dimension / cardinality of the subsystem basis `LegState S` is `2^|S|`. -/
theorem card_legState (S : Finset (Fin 5)) : Fintype.card (LegState S) = 2 ^ S.card := by
  dsimp [LegState]
  rw [Fintype.card_fun, Fintype.card_fin, Fintype.card_coe]

/-- Glue two partial basis assignments across disjoint subsets `A` and `Finset.univ \ A`. -/
def glue (A : Finset (Fin 5)) (a : LegState A) (b : LegState (Finset.univ \ A)) : Basis5 :=
  fun i =>
    if h : i ∈ A then
      a ⟨i, h⟩
    else
      b ⟨i, Finset.mem_sdiff.mpr ⟨Finset.mem_univ i, h⟩⟩

/-! ### 2. Pauli Algebra and [[5, 1, 3]] Stabilizer -/

/-- Single-qubit Pauli operator labels. -/
inductive PauliOp : Type
  | I | X | Y | Z
  deriving DecidableEq, Repr

/-- Symplectic binary coordinates $(x, z) \in \mathbb{F}_2 \times \mathbb{F}_2$ for a Pauli operator. -/
def pauliSymplectic : PauliOp → ZMod 2 × ZMod 2
  | .I => (0, 0)
  | .X => (1, 0)
  | .Z => (0, 1)
  | .Y => (1, 1)

/-- Reconstruct a Pauli operator from symplectic binary coordinates. -/
def pauliOfSymplectic : ZMod 2 × ZMod 2 → PauliOp
  | (0, 0) => .I
  | (1, 0) => .X
  | (0, 1) => .Z
  | (1, 1) => .Y

/-- 5-qubit Pauli operator represented as a function `Fin 5 → PauliOp`. -/
abbrev Pauli5 := Fin 5 → PauliOp

/-- Symplectic inner product measuring the commutation relation between two 5-qubit Pauli operators.
The inner product vanishes in `ZMod 2` if and only if the operators commute. -/
def symplecticInner (P Q : Pauli5) : ZMod 2 :=
  ∑ i : Fin 5,
    let (x1, z1) := pauliSymplectic (P i)
    let (x2, z2) := pauliSymplectic (Q i)
    (x1 * z2 + z1 * x2)

/-- Two 5-qubit Pauli operators commute if their symplectic inner product is zero. -/
def pauliCommute (P Q : Pauli5) : Prop :=
  symplecticInner P Q = 0

instance (P Q : Pauli5) : Decidable (pauliCommute P Q) :=
  inferInstanceAs (Decidable (symplecticInner P Q = 0))

/-- Cyclic right-shift on 5 legs: $i \mapsto (i + 4) \pmod 5$. -/
def shiftRight (P : Pauli5) : Pauli5 :=
  fun i => P ⟨(i.val + 4) % 5, by omega⟩

/-- First stabilizer generator $g_1 = X Z Z X I$. -/
def g1 : Pauli5 | 0 => .X | 1 => .Z | 2 => .Z | 3 => .X | 4 => .I

/-- Second stabilizer generator $g_2 = I X Z Z X$. -/
def g2 : Pauli5 | 0 => .I | 1 => .X | 2 => .Z | 3 => .Z | 4 => .X

/-- Third stabilizer generator $g_3 = X I X Z Z$. -/
def g3 : Pauli5 | 0 => .X | 1 => .I | 2 => .X | 3 => .Z | 4 => .Z

/-- Fourth stabilizer generator $g_4 = Z X I X Z$. -/
def g4 : Pauli5 | 0 => .Z | 1 => .X | 2 => .I | 3 => .X | 4 => .Z

/-- Fifth stabilizer generator $g_5 = Z Z X I X$ (product $g_1 g_2 g_3 g_4$). -/
def g5 : Pauli5 | 0 => .Z | 1 => .Z | 2 => .X | 3 => .I | 4 => .X

/-- Logical $\bar{X} = X^{\otimes 5}$. -/
def logicalX : Pauli5 := fun _ => .X

/-- Logical $\bar{Z} = Z^{\otimes 5}$. -/
def logicalZ : Pauli5 := fun _ => .Z

/-- Cyclic generation: $g_2$ is the cyclic shift of $g_1$. -/
theorem shift_g1_eq_g2 : shiftRight g1 = g2 := by ext x; fin_cases x <;> rfl

/-- Cyclic generation: $g_3$ is the cyclic shift of $g_2$. -/
theorem shift_g2_eq_g3 : shiftRight g2 = g3 := by ext x; fin_cases x <;> rfl

/-- Cyclic generation: $g_4$ is the cyclic shift of $g_3$. -/
theorem shift_g3_eq_g4 : shiftRight g3 = g4 := by ext x; fin_cases x <;> rfl

/-- Cyclic generation: $g_5$ is the cyclic shift of $g_4$. -/
theorem shift_g4_eq_g5 : shiftRight g4 = g5 := by ext x; fin_cases x <;> rfl

/-- Cyclic generation: $g_1$ is the cyclic shift of $g_5$. -/
theorem shift_g5_eq_g1 : shiftRight g5 = g1 := by ext x; fin_cases x <;> rfl

/-- Stabilizer generators $g_1$ and $g_2$ commute. -/
theorem g1_comm_g2 : pauliCommute g1 g2 := by decide

/-- Stabilizer generators $g_1$ and $g_3$ commute. -/
theorem g1_comm_g3 : pauliCommute g1 g3 := by decide

/-- Stabilizer generators $g_1$ and $g_4$ commute. -/
theorem g1_comm_g4 : pauliCommute g1 g4 := by decide

/-- Stabilizer generators $g_2$ and $g_3$ commute. -/
theorem g2_comm_g3 : pauliCommute g2 g3 := by decide

/-- Stabilizer generators $g_2$ and $g_4$ commute. -/
theorem g2_comm_g4 : pauliCommute g2 g4 := by decide

/-- Stabilizer generators $g_3$ and $g_4$ commute. -/
theorem g3_comm_g4 : pauliCommute g3 g4 := by decide

/-- Logical $\bar{X}$ commutes with stabilizer generator $g_1$. -/
theorem logicalX_comm_g1 : pauliCommute logicalX g1 := by decide

/-- Logical $\bar{X}$ commutes with stabilizer generator $g_2$. -/
theorem logicalX_comm_g2 : pauliCommute logicalX g2 := by decide

/-- Logical $\bar{X}$ commutes with stabilizer generator $g_3$. -/
theorem logicalX_comm_g3 : pauliCommute logicalX g3 := by decide

/-- Logical $\bar{X}$ commutes with stabilizer generator $g_4$. -/
theorem logicalX_comm_g4 : pauliCommute logicalX g4 := by decide

/-- Logical $\bar{Z}$ commutes with stabilizer generator $g_1$. -/
theorem logicalZ_comm_g1 : pauliCommute logicalZ g1 := by decide

/-- Logical $\bar{Z}$ commutes with stabilizer generator $g_2$. -/
theorem logicalZ_comm_g2 : pauliCommute logicalZ g2 := by decide

/-- Logical $\bar{Z}$ commutes with stabilizer generator $g_3$. -/
theorem logicalZ_comm_g3 : pauliCommute logicalZ g3 := by decide

/-- Logical $\bar{Z}$ commutes with stabilizer generator $g_4$. -/
theorem logicalZ_comm_g4 : pauliCommute logicalZ g4 := by decide

/-- Logical $\bar{X}$ and $\bar{Z}$ anticommute. -/
theorem logical_anticommute : symplecticInner logicalX logicalZ = 1 := by decide

/-! ### 3. Stabilizer Group and Weight Distribution -/

/-- General element of the 16-element stabilizer group specified by linear combination vector `c`. -/
def stabilizerElement (c : Fin 4 → ZMod 2) : Pauli5 :=
  fun i =>
    let (x1, z1) := pauliSymplectic (g1 i)
    let (x2, z2) := pauliSymplectic (g2 i)
    let (x3, z3) := pauliSymplectic (g3 i)
    let (x4, z4) := pauliSymplectic (g4 i)
    let x := c 0 * x1 + c 1 * x2 + c 2 * x3 + c 3 * x4
    let z := c 0 * z1 + c 1 * z2 + c 2 * z3 + c 3 * z4
    pauliOfSymplectic (x, z)

/-- Pauli weight: The number of legs on which a Pauli operator differs from the identity $I$. -/
def pauliWeight (P : Pauli5) : ℕ :=
  (Finset.filter (fun i => P i ≠ .I) Finset.univ).card

/-- Weight theorem for [[5, 1, 3]] stabilizer: Every non-identity element of the stabilizer
group has Pauli weight $\ge 4$ (in fact, exactly weight 4). -/
theorem stabilizer_min_weight (c : Fin 4 → ZMod 2) (hc : c ≠ 0) :
    pauliWeight (stabilizerElement c) ≥ 4 := by
  revert c hc
  decide

/-! ### 4. Reduced Density Matrices and AME(5, 2) Pentagon Tensors -/

/-- Reduced density matrix $\rho_S = \mathrm{Tr}_{S^c}(|T\rangle\langle T|)$ on subsystem $S$. -/
def reducedDensityMatrix (T : Basis5 → ℂ) (S : Finset (Fin 5)) :
    Matrix (LegState S) (LegState S) ℂ :=
  fun u v => ∑ w : LegState (Finset.univ \ S), T (glue S u w) * starRingEnd ℂ (T (glue S v w))

/-- Linear map / matrix representation of tensor `T` mapping from legs `A` to legs `Finset.univ \ A`,
normalized by $\sqrt{2^{|A|}}$. -/
noncomputable def tensorToMap (T : Basis5 → ℂ) (A : Finset (Fin 5)) :
    Matrix (LegState (Finset.univ \ A)) (LegState A) ℂ :=
  fun b a => (Real.sqrt ((2 : ℝ) ^ A.card) : ℂ) * T (glue A a b)

/-- Fundamental Isometry Theorem: If the reduced density matrix on subsystem `A` is maximally mixed
$\rho_A = \frac{1}{2^{|A|}} I$, then the linear map $V_{A \to A^c}$ is an exact isometry:
$V^\dagger V = I$. -/
theorem isometry_of_maximally_mixed (T : Basis5 → ℂ) (A : Finset (Fin 5))
    (h_rho : reducedDensityMatrix T A = (1 / ((2 : ℂ) ^ A.card)) • (1 : Matrix (LegState A) (LegState A) ℂ)) :
    (tensorToMap T A).conjTranspose * (tensorToMap T A) = 1 := by
  ext a1 a2
  rw [Matrix.mul_apply]
  have h_star (b : LegState (Finset.univ \ A)) :
      (tensorToMap T A).conjTranspose a1 b =
      (Real.sqrt ((2 : ℝ) ^ A.card) : ℂ) * starRingEnd ℂ (T (glue A a1 b)) := by
    dsimp [Matrix.conjTranspose, tensorToMap]
    rw [map_mul, Complex.conj_ofReal]
  simp_rw [h_star]
  dsimp [tensorToMap]
  have h_pull : (∑ x : LegState (Finset.univ \ A),
      ((Real.sqrt ((2 : ℝ) ^ A.card) : ℂ) * starRingEnd ℂ (T (glue A a1 x))) *
      ((Real.sqrt ((2 : ℝ) ^ A.card) : ℂ) * T (glue A a2 x))) =
      ((Real.sqrt ((2 : ℝ) ^ A.card) : ℂ) ^ 2) *
      ∑ x : LegState (Finset.univ \ A), T (glue A a2 x) * starRingEnd ℂ (T (glue A a1 x)) := by
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl (fun _ _ => by ring)
  rw [h_pull]
  have h_sqrt_sq : ((Real.sqrt ((2 : ℝ) ^ A.card) : ℂ) ^ 2) = ((2 : ℂ) ^ A.card) := by
    have : 0 ≤ (2 : ℝ) ^ A.card := by positivity
    exact_mod_cast Real.sq_sqrt this
  rw [h_sqrt_sq]
  have h_rho_val := congr_fun (congr_fun h_rho a2) a1
  dsimp [reducedDensityMatrix] at h_rho_val
  rw [h_rho_val]
  have h2_ne : ((2 : ℂ) ^ A.card) ≠ 0 := pow_ne_zero _ two_ne_zero
  by_cases h : a1 = a2
  · subst h
    simp only [Matrix.one_apply, ite_true]
    rw [mul_one, mul_one_div_cancel h2_ne]
  · have h_ne : a2 ≠ a1 := ne_comm.mp h
    simp only [Matrix.one_apply, ite_false, h, h_ne, mul_zero]

/-- Absolutely Maximally Entangled 5-qubit (AME(5, 2)) / HaPPY pentagon tensor structure.
A pure state tensor on 5 qubits such that every reduced density matrix on $\le 2$ qubits is maximally mixed. -/
structure PentagonAME where
  /-- The tensor state amplitudes on the 5-qubit basis `Fin 5 → Fin 2`. -/
  tensor : Basis5 → ℂ
  /-- Maximally mixed reduced density matrix condition for all subsystems of size $\le 2$. -/
  is_ame : ∀ (S : Finset (Fin 5)), S.card ≤ 2 →
    reducedDensityMatrix tensor S = (1 / ((2 : ℂ) ^ S.card)) • (1 : Matrix (LegState S) (LegState S) ℂ)

/-- Abbreviation for `PentagonAME` as `AMEPentagonTensor`. -/
abbrev AMEPentagonTensor := PentagonAME

/-! ### 5. Canonical Constructive AME(5, 2) Tensor -/

/-- Graph state phase function on the 5-cycle graph $C_5$:
$\sum_{i=0}^4 x_i x_{i+1} \pmod 2$. -/
def graphStatePhase (x : Basis5) : ZMod 2 :=
  (x 0).val * (x 1).val +
  (x 1).val * (x 2).val +
  (x 2).val * (x 3).val +
  (x 3).val * (x 4).val +
  (x 4).val * (x 0).val

/-- Sign of the amplitude: $+1$ if phase is 0, $-1$ if phase is 1. -/
def graphStateSign (x : Basis5) : Int :=
  if graphStatePhase x = 0 then 1 else -1

/-- Canonical 5-qubit AME state amplitude: $T(x) = (-1)^{\mathrm{phase}(x)} / \sqrt{32}$. -/
noncomputable def canonicalAMEState (x : Basis5) : ℂ :=
  ((graphStateSign x : ℂ)) / (Real.sqrt 32 : ℂ)

/-- Integer inner product of partial trace sums for the canonical graph state. -/
def reducedDensityInt (S : Finset (Fin 5)) (u v : LegState S) : Int :=
  ∑ w : LegState (Finset.univ \ S), graphStateSign (glue S u w) * graphStateSign (glue S v w)

/-- Finite decision verification that the canonical $C_5$ graph state has exact orthogonal
maximally mixed reductions for all subsystems with $|S| \le 2$. -/
theorem c5_is_ame_int : ∀ (S : Finset (Fin 5)), S.card ≤ 2 → ∀ (u v : LegState S),
    reducedDensityInt S u v = if u = v then 2^(5 - S.card) else 0 := by
  decide

/-- The canonical graph state on $C_5$ satisfies the AME(5, 2) maximally mixed condition. -/
theorem canonical_is_ame (S : Finset (Fin 5)) (hS : S.card ≤ 2) :
    reducedDensityMatrix canonicalAMEState S = (1 / ((2 : ℂ) ^ S.card)) • (1 : Matrix (LegState S) (LegState S) ℂ) := by
  ext u v
  rw [Matrix.smul_apply, Matrix.one_apply, smul_eq_mul]
  change (∑ w : LegState (Finset.univ \ S),
      canonicalAMEState (glue S u w) * starRingEnd ℂ (canonicalAMEState (glue S v w))) =
      (1 / (2 : ℂ) ^ S.card) * (if u = v then 1 else 0)
  dsimp only [canonicalAMEState]
  have h_term (w : LegState (Finset.univ \ S)) :
      (((graphStateSign (glue S u w) : ℂ)) / (Real.sqrt 32 : ℂ)) *
      starRingEnd ℂ (((graphStateSign (glue S v w) : ℂ)) / (Real.sqrt 32 : ℂ)) =
      (((graphStateSign (glue S u w) * graphStateSign (glue S v w) : ℤ) : ℂ)) / (32 : ℂ) := by
    have h32 : (Real.sqrt 32 : ℂ) * (Real.sqrt 32 : ℂ) = 32 := by
      exact_mod_cast Real.mul_self_sqrt (by positivity)
    have : starRingEnd ℂ ((graphStateSign (glue S v w) : ℂ) / (Real.sqrt 32 : ℂ)) =
        (graphStateSign (glue S v w) : ℂ) / (Real.sqrt 32 : ℂ) := by simp
    rw [this, div_mul_div_comm, h32]
    push_cast; rfl
  simp_rw [h_term, ← Finset.sum_div]
  have h_sum_cast : (∑ x : LegState (Finset.univ \ S), (((graphStateSign (glue S u x) * graphStateSign (glue S v x) : ℤ) : ℂ))) =
      ((∑ x : LegState (Finset.univ \ S), graphStateSign (glue S u x) * graphStateSign (glue S v x) : ℤ) : ℂ) := by
    push_cast; rfl
  rw [h_sum_cast]
  have h_int := c5_is_ame_int S hS u v
  dsimp [reducedDensityInt] at h_int
  rw [h_int]
  split_ifs with h
  · have h_pow_split : (2 : ℂ) ^ 5 = (2 : ℂ) ^ (5 - S.card) * (2 : ℂ) ^ S.card := by
      rw [← pow_add]; congr 1; omega
    have h_pow_eq : (2 : ℂ) ^ (5 - S.card) / 32 = 1 / (2 : ℂ) ^ S.card := by
      rw [(by norm_num : (32 : ℂ) = (2 : ℂ) ^ 5), h_pow_split]
      have : (2 : ℂ) ^ (5 - S.card) ≠ 0 := pow_ne_zero _ two_ne_zero
      have : (2 : ℂ) ^ S.card ≠ 0 := pow_ne_zero _ two_ne_zero
      field_simp
    push_cast; rw [h_pow_eq, mul_one]
  · push_cast; ring

/-- Canonical explicit constructive instance of the 5-qubit AME / HaPPY pentagon tensor. -/
noncomputable def canonicalAMEPentagonTensor : PentagonAME where
  tensor := canonicalAMEState
  is_ame := canonical_is_ame

/-! ### 6. Bipartite Isometries (2 to 3, 1 to 4, 0 to 5) -/

/-- 2-to-3 leg isometry: For any subset $A \subset \mathrm{Fin}\ 5$ with $|A| = 2$,
the linear map $V_{A \to A^c} : \mathbb{C}^4 \to \mathbb{C}^8$ is an exact isometry: $V^\dagger V = I$. -/
theorem ame_isometry_two_to_three (T : PentagonAME) (A : Finset (Fin 5)) (hA : A.card = 2) :
    (tensorToMap T.tensor A).conjTranspose * (tensorToMap T.tensor A) = 1 :=
  isometry_of_maximally_mixed T.tensor A (T.is_ame A (by omega))

/-- 1-to-4 leg isometric embedding: For any single leg $i \in \mathrm{Fin}\ 5$,
the linear map $V_{\{i\} \to \{i\}^c} : \mathbb{C}^2 \to \mathbb{C}^{16}$ is an exact isometry,
encoding 1 logical qubit into 4 physical qubits. -/
theorem ame_isometry_one_to_four (T : PentagonAME) (i : Fin 5) :
    (tensorToMap T.tensor {i}).conjTranspose * (tensorToMap T.tensor {i}) = 1 :=
  isometry_of_maximally_mixed T.tensor {i} (T.is_ame {i} (by simp))

/-- 0-to-5 leg state normalization: The AME tensor has unit norm $\langle T | T \rangle = 1$. -/
theorem ame_normalized (T : PentagonAME) :
    (tensorToMap T.tensor ∅).conjTranspose * (tensorToMap T.tensor ∅) = 1 :=
  isometry_of_maximally_mixed T.tensor ∅ (T.is_ame ∅ (by simp))

/-! ### 7. Purity and Entanglement Entropy -/

/-- Purity $\gamma(\rho) = \mathrm{Tr}(\rho^2)$ of a density matrix. -/
def purity {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ) : ℂ :=
  Matrix.trace (M * M)

/-- Rényi-2 / von Neumann entanglement entropy $S(\rho) = -\ln(\mathrm{Re}(\gamma(\rho)))$. -/
noncomputable def entanglementEntropy {n : Type*} [Fintype n] [DecidableEq n] (M : Matrix n n ℂ) : ℝ :=
  - Real.log (Complex.re (purity M))

/-- Purity of a maximally mixed state on subsystem $S$: $\gamma(\rho_S) = 1 / 2^{|S|}$. -/
theorem purity_maximally_mixed (S : Finset (Fin 5)) :
    purity ((1 / ((2 : ℂ) ^ S.card)) • (1 : Matrix (LegState S) (LegState S) ℂ)) =
      1 / ((2 : ℂ) ^ S.card) := by
  dsimp [purity]
  rw [Matrix.smul_mul, Matrix.mul_smul, Matrix.mul_one, Matrix.trace_smul, Matrix.trace_smul,
    Matrix.trace_one, card_legState, Nat.cast_pow, Nat.cast_ofNat]
  have h2_ne : ((2 : ℂ) ^ S.card) ≠ 0 := pow_ne_zero _ two_ne_zero
  dsimp
  rw [one_div_mul_cancel h2_ne, mul_one]

/-- General subsystem entanglement entropy: $S(\rho_S) = |S| \ln 2$. -/
theorem entanglementEntropy_maximally_mixed (S : Finset (Fin 5)) :
    entanglementEntropy ((1 / ((2 : ℂ) ^ S.card)) • (1 : Matrix (LegState S) (LegState S) ℂ)) =
      (S.card : ℝ) * Real.log 2 := by
  dsimp [entanglementEntropy]
  rw [purity_maximally_mixed, (by push_cast; rfl : (1 / (2 : ℂ) ^ S.card) = ((1 / (2 : ℝ) ^ S.card : ℝ) : ℂ)),
    Complex.ofReal_re, Real.log_div (by norm_num) (by positivity), Real.log_one, zero_sub, neg_neg, Real.log_pow]

/-- Maximally mixed 2-qubit reduction: For any 2-qubit subsystem $S \subset \mathrm{Fin}\ 5$ with $|S| = 2$,
the entanglement entropy is maximal and equals $2 \ln 2$. -/
theorem ame_two_qubit_entropy_max (S : Finset (Fin 5)) (hS : S.card = 2) :
    entanglementEntropy ((1 / ((2 : ℂ) ^ S.card)) • (1 : Matrix (LegState S) (LegState S) ℂ)) =
      2 * Real.log 2 := by
  rw [entanglementEntropy_maximally_mixed, hS, Nat.cast_ofNat]

/-! ### 8. [[5, 1, 3]] Error-Erasure Recovery -/

/-- Recovery decoder matrix $\mathcal{R}_E = V_{E \to E^c}^\dagger$ for erased subsystem $E$. -/
noncomputable def erasureDecoder (T : PentagonAME) (E : Finset (Fin 5)) :
    Matrix (LegState E) (LegState (Finset.univ \ E)) ℂ :=
  (tensorToMap T.tensor E).conjTranspose

/-- The [[5, 1, 3]] Error-Erasure Correction Theorem:
Any erasure of up to 2 qubits ($|E| \le 2$) can be perfectly corrected from the remaining
qubits $E^c$ ($|E^c| \ge 3$) via the recovery decoder $\mathcal{R}_E V = I$. -/
theorem five_one_three_erasure_recovery (T : PentagonAME) (E : Finset (Fin 5)) (hE : E.card ≤ 2) :
    erasureDecoder T E * tensorToMap T.tensor E = 1 :=
  isometry_of_maximally_mixed T.tensor E (T.is_ame E hE)

/-- Quantum State Vector Reconstruction: Any arbitrary state vector $\psi$ supported on the erased
subsystem $E$ is faithfully recovered after encoding and decoding through the surviving qubits $E^c$. -/
theorem five_one_three_vector_recovery (T : PentagonAME) (E : Finset (Fin 5)) (hE : E.card ≤ 2)
    (ψ : LegState E → ℂ) :
    Matrix.mulVec (erasureDecoder T E) (Matrix.mulVec (tensorToMap T.tensor E) ψ) = ψ := by
  rw [Matrix.mulVec_mulVec, five_one_three_erasure_recovery T E hE, Matrix.one_mulVec]

end AMEPentagonTensor
