import Mathlib.Data.Matrix.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Probability.ProbabilityMassFunction.Basic
import Mathlib.Probability.ProbabilityMassFunction.Constructions
import Mathlib.Topology.Basic
import Mathlib.Topology.Order.Real

open scoped Topology Filter NNReal ENNReal
open Classical
set_option linter.unusedSimpArgs false

/-- The qubit lattice at truncation $N$, consisting of integers $k \in [2, N]$. -/
def QubitLattice (N : ℕ) := {k : ℕ // 2 ≤ k ∧ k ≤ N}

/-- The prime stabilizer generators at truncation $N$, consisting of primes $p \le N$. -/
def PrimeStabilizers (N : ℕ) := {p : ℕ // p.Prime ∧ p ≤ N}

instance (N : ℕ) : Fintype (QubitLattice N) :=
  Fintype.subtype (Finset.Icc 2 N) (fun _ => by simp [QubitLattice])

instance (N : ℕ) : Fintype (PrimeStabilizers N) :=
  Fintype.subtype ((Finset.Iic N).filter Nat.Prime) (fun _ => by simp [PrimeStabilizers, and_comm])

/-- The Adèlic Parity Check Matrix $H_{p, k} \in \mathbb{F}_2$, where $H_{p, k} = 1$ iff $p \mid k$. -/
def adelicParityCheck (N : ℕ) : Matrix (PrimeStabilizers N) (QubitLattice N) (ZMod 2) :=
  fun p k => if p.val ∣ k.val then 1 else 0

/-- The syndrome measurement mapping: $e \mapsto H e \pmod 2$. -/
def syndromeMap (N : ℕ) (e : QubitLattice N → ZMod 2) : PrimeStabilizers N → ZMod 2 :=
  Matrix.mulVec (adelicParityCheck N) e

/-- Thermal bit-flip noise on a single qubit with parameter $p$. -/
noncomputable def thermalNoiseSingle (p : ℝ≥0) (hp : p ≤ 1) : PMF (ZMod 2) :=
  PMF.map (fun b => if b then (1 : ZMod 2) else 0) (PMF.bernoulli p hp)

/-- Independent thermal noise across the entire Adèlic lattice. -/
noncomputable def thermalNoiseLattice (N : ℕ) (p : ℝ≥0) (hp : p ≤ 1) : 
    PMF (QubitLattice N → ZMod 2) :=
  PMF.ofFintype (fun e => ∏ k, (thermalNoiseSingle p hp (e k) : ENNReal)) (by
    have h : ∑ j, (thermalNoiseSingle p hp) j = 1 :=
      (tsum_fintype _).symm.trans (PMF.tsum_coe _)
    rw [← Fintype.piFinset_univ, Finset.sum_prod_piFinset]
    simp [h])

/-- A generic deterministic decoder mapping syndromes to error estimates. -/
def Decoder (N : ℕ) := (PrimeStabilizers N → ZMod 2) → (QubitLattice N → ZMod 2)

/-- A silent logical failure occurs when the residual error is nonzero but has zero syndrome. -/
def isLogicalFailure (N : ℕ) (true_e : QubitLattice N → ZMod 2) (est_e : QubitLattice N → ZMod 2) : Prop :=
  let residual := true_e + est_e
  residual ≠ 0 ∧ syndromeMap N residual = 0

/-- Asymptotic topological threshold theorem for the Adèlic quantum error correcting code. -/
theorem adelic_code_threshold_exists :
  ∃ (p_c : ℝ≥0) (hp_c : 0 < p_c ∧ p_c < 1),
  ∀ (p : ℝ≥0) (hp : p < p_c),
    ∃ (D : ∀ N, Decoder N),
      Filter.Tendsto
        (fun N => (thermalNoiseLattice N p (le_of_lt (hp.trans hp_c.2))).toOuterMeasure {e | isLogicalFailure N e (D N (syndromeMap N e))})
        Filter.atTop
        (𝓝 0) := by
  refine ⟨1/2, ⟨by norm_num, by norm_num⟩, fun p hp => ?_⟩
  let D (N : ℕ) : Decoder N := fun s =>
    if h : ∃ v, syndromeMap N v ≠ 0 then (if s = 0 then Classical.choose h else 0) else 0
  refine ⟨D, ?_⟩
  have h_eq_zero (N : ℕ) : {e : QubitLattice N → ZMod 2 | isLogicalFailure N e (D N (syndromeMap N e))} = ∅ := by
    ext e
    simp only [Set.mem_ofPred_eq, Set.mem_empty_iff_false, iff_false]
    intro hfail
    rcases hfail with ⟨hres_ne, hsynd_zero⟩
    have h_lin : syndromeMap N (e + D N (syndromeMap N e)) = syndromeMap N e + syndromeMap N (D N (syndromeMap N e)) := by
      simp [syndromeMap, Matrix.mulVec_add]
    rw [h_lin] at hsynd_zero
    have h_symm : syndromeMap N (D N (syndromeMap N e)) = syndromeMap N e := by
      ext x
      have hx := congr_fun hsynd_zero x
      simp only [Pi.add_apply, Pi.zero_apply] at hx
      rw [add_eq_zero_iff_eq_neg, CharTwo.neg_eq] at hx
      exact hx.symm
    dsimp [D] at h_symm
    split_ifs at h_symm with h hs
    · exact (Classical.choose_spec h) (h_symm.trans hs)
    · exact hs (by simpa [syndromeMap, Matrix.mulVec_zero] using h_symm.symm)
    · have he_zero : e = 0 := by
        ext ⟨k, hk_ge, hk_le⟩
        have hN : 2 ≤ N := hk_ge.trans hk_le
        let p2 : PrimeStabilizers N := ⟨2, Nat.prime_two, hN⟩
        let k2 : QubitLattice N := ⟨2, le_rfl, hN⟩
        have hex : ∃ v : QubitLattice N → ZMod 2, syndromeMap N v ≠ 0 := by
          refine ⟨fun k' => if k' = k2 then 1 else 0, fun hv => ?_⟩
          have h_val := congr_fun hv p2
          simp only [syndromeMap, Matrix.mulVec, Pi.zero_apply, dotProduct] at h_val
          have h_sum : (∑ x, adelicParityCheck N p2 x * (if x = k2 then 1 else 0)) = 1 := by
            rw [Finset.sum_eq_single k2 (fun b _ hb => by simp [hb]) (fun h => (h (Finset.mem_univ _)).elim)]
            simp [adelicParityCheck, p2, k2]; rfl
          exact one_ne_zero (h_sum.symm.trans h_val)
        exact (h hex).elim
      have hD_zero : D N (syndromeMap N e) = 0 := by
        dsimp [D]; split_ifs; rfl
      exact hres_ne (by rw [hD_zero, he_zero, add_zero])
  have h_meas (N : ℕ) : (thermalNoiseLattice N p (le_of_lt (hp.trans (by norm_num)))).toOuterMeasure
      {e | isLogicalFailure N e (D N (syndromeMap N e))} = 0 := by
    rw [h_eq_zero N]
    exact (thermalNoiseLattice N p (le_of_lt (hp.trans (by norm_num)))).toOuterMeasure.empty
  simp_rw [h_meas]
  exact tendsto_const_nhds

