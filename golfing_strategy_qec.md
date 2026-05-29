# Formalization Blueprint: Adèlic Topological Quantum Error Correction

## 1. Overview
This document defines the strategy for formalizing the error-correction threshold of the Adèlic Stabilizer Code under thermal noise in Lean 4. The code encodes logical qubits within a physical lattice indexed by integers $k \in \{2, \ldots, N\}$, with parity checks defined by prime divisibility $p \mid k$. The objective is to translate the structures found in `experiments/topological_qec.py` and `src/adelic_spectral_zeta/error_correction.py` into a rigorous Mathlib framework, ultimately stating the threshold existence theorem.

## 2. Lean 4 Mathlib Imports
To model the graph structure, finite fields, probability spaces, and number-theoretic boundaries, we require the following core Mathlib imports:
```lean
import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime
import Mathlib.Probability.ProbabilityMassFunction.Basic
import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.NumberTheory.ArithmeticFunction
```

## 3. Physical Lattice and Parity Check Matrix
The parity check matrix $`H_{p,k}`$ connects a qubit $k$ to a stabilizer $p$ if and only if $p$ divides $k$. We formalize this over the finite field $`\mathbb{F}_2`$ (represented via `ZMod 2`).
```lean
-- Define the index sets for qubits and stabilizers
def QubitLattice (N : ℕ) := {k : ℕ // 2 ≤ k ∧ k ≤ N}
def PrimeStabilizers (N : ℕ) := {p : ℕ // p.Prime ∧ p ≤ N}

-- The Adèlic Parity Check Matrix H_{p, k} ∈ 𝔽_2
def adelicParityCheck (N : ℕ) : Matrix (PrimeStabilizers N) (QubitLattice N) (ZMod 2) :=
  fun p k => if (p : ℕ) ∣ (k : ℕ) then 1 else 0

-- The syndrome measurement mapping: e ↦ H e mod 2
def syndromeMap (N : ℕ) (e : QubitLattice N → ZMod 2) : PrimeStabilizers N → ZMod 2 :=
  Matrix.mulVec (adelicParityCheck N) e
```

## 4. Probability and Thermal Noise Model
The noise is independent, identically distributed thermal bit-flip error. We capture this utilizing Lean's `PMF` (Probability Mass Function) to model independent Bernoulli random variables.
```lean
-- Thermal bit-flip noise on a single qubit
noncomputable def thermalNoiseSingle (p : ℝ≥0) (hp : p ≤ 1) : PMF (ZMod 2) :=
  PMF.bernoulli p hp

-- Independent thermal noise across the entire Adèlic lattice
noncomputable def thermalNoiseLattice (N : ℕ) (p : ℝ≥0) (hp : p ≤ 1) : 
  PMF (QubitLattice N → ZMod 2) :=
  -- Constructs the product measure of independent Bernoulli variables
  PMF.pi (fun _ => thermalNoiseSingle p hp)
```

## 5. Decoding Function and Logical Failure
A generic decoder attempts to recover the error from a syndrome. A decoding failure occurs if the decoder's estimate `est_e` combined with the true error `true_e` results in a non-zero residual error that is completely invisible to the stabilizers (it falls perfectly into the null-space $\ker H$).
```lean
-- A generic deterministic decoder signature
def Decoder (N : ℕ) := (PrimeStabilizers N → ZMod 2) → (QubitLattice N → ZMod 2)

-- Defining a silent logical failure
def isLogicalFailure (N : ℕ) (true_e : QubitLattice N → ZMod 2) (est_e : QubitLattice N → ZMod 2) : Prop :=
  let residual := true_e + est_e
  residual ≠ 0 ∧ syndromeMap N residual = 0
```

## 6. Main Theorem Signature: Topological Error Threshold
The capstone of the formalization establishes the existence of a non-zero topological error threshold $p_c$. Below this physical error rate, the probability of a logical failure exponentially vanishes as the lattice size $N \to \infty$.

```lean
-- The asymptotic topological threshold theorem
theorem adelic_code_threshold_exists :
  ∃ (p_c : ℝ≥0), 0 < p_c ∧ p_c < 1 ∧
  ∀ (p : ℝ≥0) (hp : p < p_c),
    ∃ (D : ∀ N, Decoder N),
      Filter.Tendsto
        (fun N => (thermalNoiseLattice N p (le_of_lt hp)).toOuterMeasure {e | isLogicalFailure N e (D N (syndromeMap N e))})
        Filter.atTop
        (𝓝 0)
```

## 7. Key Intermediate Proof Strategies
To prove the main threshold theorem, the formalization will need to establish:
1. **Hardy-Ramanujan Regularity**: Using `ArithmeticFunction.omega` to bound the column weight of $H$ (the number of distinct prime factors of $k \le N$ scales as $\sim \ln \ln N$).
2. **Prime Number Theorem / Chebotarev Densities**: Bounding the row weight of $H$ (a prime $p$ divides $\sim N/p$ qubits).
3. **Graph Expansion / LDPC Bounds**: Mapping the prime divisibility graph to a Tanner Graph and utilizing expander codes minimum-distance theorems to bound the dimension of $\ker H$, proving it can suppress local independent noise.
4. **Greedy Decoder Convergence**: If attempting to formally verify the specific Gallager Bit-Flip decoder implemented in Python, one must construct a strictly decreasing Lyapunov function on the `unsatisfied_checks` sequence to guarantee algorithm termination and correction bounds.
