import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime
import Mathlib.Probability.ProbabilityMassFunction.Basic
import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Probability.Independence.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.NumberTheory.ArithmeticFunction

-- Define the index sets for qubits and stabilizers
def QubitLattice (N : ℕ) := {k : ℕ // 2 ≤ k ∧ k ≤ N}
def PrimeStabilizers (N : ℕ) := {p : ℕ // p.Prime ∧ p ≤ N}

-- The Adèlic Parity Check Matrix H_{p, k} ∈ 𝔽_2
def adelicParityCheck (N : ℕ) : Matrix (PrimeStabilizers N) (QubitLattice N) (ZMod 2) :=
  fun p k => if (p : ℕ) ∣ (k : ℕ) then 1 else 0

-- The syndrome measurement mapping: e ↦ H e mod 2
def syndromeMap (N : ℕ) (e : QubitLattice N → ZMod 2) : PrimeStabilizers N → ZMod 2 :=
  Matrix.mulVec (adelicParityCheck N) e

-- Thermal bit-flip noise on a single qubit
noncomputable def thermalNoiseSingle (p : ℝ≥0) (hp : p ≤ 1) : PMF (ZMod 2) :=
  PMF.bernoulli p hp

-- Independent thermal noise across the entire Adèlic lattice
noncomputable def thermalNoiseLattice (N : ℕ) (p : ℝ≥0) (hp : p ≤ 1) : 
  PMF (QubitLattice N → ZMod 2) :=
  -- Constructs the product measure of independent Bernoulli variables
  PMF.pi (fun _ => thermalNoiseSingle p hp)

-- A generic deterministic decoder signature
def Decoder (N : ℕ) := (PrimeStabilizers N → ZMod 2) → (QubitLattice N → ZMod 2)

-- Defining a silent logical failure
def isLogicalFailure (N : ℕ) (true_e : QubitLattice N → ZMod 2) (est_e : QubitLattice N → ZMod 2) : Prop :=
  let residual := true_e + est_e
  residual ≠ 0 ∧ syndromeMap N residual = 0

-- The asymptotic topological threshold theorem
theorem adelic_code_threshold_exists :
  ∃ (p_c : ℝ≥0), 0 < p_c ∧ p_c < 1 ∧
  ∀ (p : ℝ≥0) (hp : p < p_c),
    ∃ (D : ∀ N, Decoder N),
      Filter.Tendsto
        (fun N => (thermalNoiseLattice N p (le_of_lt hp)).toOuterMeasure {e | isLogicalFailure N e (D N (syndromeMap N e))})
        Filter.atTop
        (𝓝 0)
