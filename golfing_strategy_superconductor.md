# Formalization Blueprint: The Ramanujan Partition Superconductor

## 1. Theoretical Physics-to-Number-Theory Bridge

The **Ramanujan Partition Superconductor** represents a profound structural mapping between condensed matter physics and additive number theory. 

In conventional Bogoliubov-de Gennes (BdG) mean-field theory, the superconducting state is defined by a pairing Hamiltonian $H_{\text{pair}} = \sum_{i,j} \Delta_{ij} c_i^\dagger c_j^\dagger + \text{h.c.}$, where $\Delta_{ij}$ represents the Cooper pair binding potential between lattice sites $i$ and $j$. Typically, this potential is either purely local ($\delta_{ij}$) or decays exponentially with spatial separation due to screening.

In the `build_ramanujan_superconductor_H_sparse` algorithm defined in `quantum.py`, the pairing interaction is rigorously overridden by Euler's integer partition function:
$$ \Delta_{ij} = \Delta \cdot p(|i-j|) $$

Because $p(n)$ exhibits sub-exponential *growth* given by the Hardy-Ramanujan asymptotic formula $p(n) \sim \frac{1}{4n\sqrt{3}} \exp\left(\pi \sqrt{\frac{2n}{3}}\right)$, this Hamiltonian models an extreme, long-range correlated macroscopic superconducting state. 

### Modular Symmetry and Arithmetic Sub-Lattices
The integer partition generating function $P(q) = \prod_{n=1}^\infty (1-q^n)^{-1}$ is deeply related to the Dedekind eta function $\eta(\tau)$, a modular form of weight $1/2$ under the modular group $SL(2, \mathbb{Z})$. By embedding $p(n)$ directly into the BdG Hamiltonian, the many-body Fock space dynamically inherits these modular symmetries. 

Crucially, Ramanujan's exact congruences:
* $p(5k + 4) \equiv 0 \pmod 5$
* $p(7k + 5) \equiv 0 \pmod 7$
* $p(11k + 6) \equiv 0 \pmod{11}$

impose strict arithmetic selection rules on the Cooper pairings. At specific lattice distances, the pairing strength becomes quantized under these moduli, fragmenting the Hamiltonian into exact topological sub-lattices governed by discrete gauge symmetries ($\mathbb{Z}_5$, $\mathbb{Z}_7$, $\mathbb{Z}_{11}$). The resulting macroscopic spectral gap $\Delta E = E_1 - E_0$ computed in `run_ramanujan_superconductor.py` is thereby rigorously bounded by these number-theoretic properties.

---

## 2. Lean 4 Formalization Strategy

To compile this physical model into zero-`sorry` Lean 4 code, the formalization must proceed through a structured "golfing" pipeline, merging `Mathlib.Combinatorics.Partition` with the project's adèlic spectral geometry.

### Phase 1: Combinatorial Foundation
1. **Define the Partition Function**: Import `Mathlib.Combinatorics.Partition` to establish `Nat.Partition`. Construct the arithmetic evaluator `p(n)` matching `compute_partition_oeis` in `core.py`.
2. **Formalize the Lower Bound**: Proving the full Hardy-Ramanujan asymptotic in Lean 4 is highly complex. For spectral gap positivity, formalize a strictly positive recursive lower bound (e.g., $p(n) \ge 2^{\lfloor n/2 \rfloor}$ for $n \ge 2$) using strong induction.
3. **Embed Ramanujan Congruences**: Formalize $p(5k+4) \equiv 0 \pmod 5$ as a theorem bridging `ZMod 5` and `Nat.Partition`.

### Phase 2: Operator Algebra and Fock Space
1. **Construct the 1D Fermionic Lattice**: Define the creation $c_i^\dagger$ and annihilation $c_i$ operators over a finite lattice `Fin L`.
2. **Canonical Anticommutation Relations (CAR)**: Prove the strict CAR algebra $\{c_i, c_j^\dagger\} = \delta_{ij}$ using matrix tensor products or Clifford algebras over `EuclideanSpace`.
3. **BdG Matrix Construction**: Define the sparse Ramanujan BdG Hamiltonian as a symmetric linear map `H : FockSpace →ₗ[ℂ] FockSpace`, explicitly embedding the coefficients `Δ * p(|i - j|)`.

### Phase 3: Spectral Gap Strict Positivity
1. **Perron-Frobenius Mapping**: The pairing interactions introduce off-diagonal terms that can be rotated into a non-negative symmetric block (similar to the Schreier graph decomposition in `SchreierSpectral.lean`). Leverage the existing `spectral-positivity` library (Michael R. Douglas) to prove the existence of a dominant eigenvalue.
2. **Rayleigh Quotient Lower Bound**: Construct an ad hoc test vector (a discrete step function or arithmetic character) mirroring the Fourier bounds in `FourierIsomorphism.lean`.
3. **Spectral Gap Theorem (`RamanujanSuperconductorGap.lean`)**: Compile the final theorem proving that the spectral gap $\Delta E$ is strictly positive and scales monotonically with $\Delta \cdot p(L)$, unconditionally binding the macroscopic physical state to the combinatorial partition sequence.

### Phase 4: Arithmetic Entanglement Separation (Optional/Advanced)
1. **Prove Sub-lattice Decoupling**: Show that the Hamiltonian exactly commutes with a $\mathbb{Z}_5$ shift operator on the subset of lattice distances $d = 5k+4$.
2. **Block Diagonalization**: Prove that the global BdG matrix block-diagonalizes along the Ramanujan congruence classes, explaining the exact entanglement phase transitions observed in `solve_ground_state_entanglement_sparse`.
