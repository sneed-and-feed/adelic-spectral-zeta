# Macroscopic Entanglement Phase Transition: Theoretical Blueprint

This blueprint outlines the formalization roadmap for bridging the single-particle L-function zero modes to the many-body entanglement phase transition in the thermodynamic limit. It extends the base finite-dimensional results in `ManyBodyPhaseTransition.lean` and theoretically underpins the numeric observations from `experiments/entanglement_phase_transition.py`.

## 1. Literature Context & Physical Motivation

A comprehensive literature search confirms the structural connection between fermionic zero modes and macroscopic entanglement entropy jumps:
* **Klich, Vaman, Wong (2015) [arXiv:1501.00482]**: Demonstrates how finite-rank perturbations and Riemann-Hilbert solutions explicitize the change in entanglement entropy due to chiral zero modes in free fermion systems. This fundamentally mirrors the Adèlic rank-1 perturbation used in our framework.
* **Southier et al. (2023) [arXiv:2303.10157]**: Examines the identification of primes from entanglement dynamics, establishing an explicit phenomenological connection between entanglement entropy singularities and the zeros of the Riemann zeta function.
* **Pouranvari & Yang (2014) [arXiv:1311.4108]** and **Larsson & Johannesson (2006) [arXiv:quant-ph/0602048]**: Establish that single-site or localized subsystem entanglement acts as a rigorous order parameter for quantum phase transitions in fermionic chains.

In `formalization/Formalization/ManyBodyPhaseTransition.lean`, we have unconditionally proven `degeneracy_from_zero_mode` for finite dimensions (`Fintype I`). The thermodynamic simulation (`experiments/entanglement_phase_transition.py`) explicitly constructs the single-particle Dirac operator $D_{\text{glob}}$ and lifts it to an interacting Fermionic Fock space via `build_many_body_H_sparse`. As the system size increases ($L \ge 14$), the exact diagonalization shows sharp, macroscopic von Neumann entropy spikes exactly at the Riemann/Buhler zeros ($t_k \approx 5.1015, 5.5613, \dots$). 

To rigorously lift this behavior to the thermodynamic limit in Lean 4 and prove the phase transition, we must formalize the infinite-dimensional Fermionic Fock space and the resulting discontinuity of the bipartite von Neumann entropy.

## 2. Sequence of Theorems for the Thermodynamic Limit

To achieve a 0-`sorry` formalization of the thermodynamic limit physics, the golfing strategy dictates four major milestones:

### Phase I: Infinite-Dimensional Fermionic Fock Space (CAR Algebra)
Currently, `ManyBodyPhaseTransition.lean` restricts the particle lattice to `[Fintype I]`. We must transition to a $C^*$-algebraic formalism to rigorously take $L \to \infty$.
1. **Theorem `CAR_Algebra_Existence`**: Define the Canonical Anticommutation Relation (CAR) algebra over $\ell^2(\mathbb{Z})$ and formalize the creation/annihilation operator anticommutator brackets $\{c_i^\dagger, c_j\} = \delta_{ij}$.
2. **Theorem `Fock_Space_GNS`**: Construct the unique continuous representation of the Fock space via the Gelfand-Naimark-Segal (GNS) construction with respect to the non-interacting vacuum state.

### Phase II: Bipartite Tracing and Reduced Density Matrices
The Python script computes `eigsh` for the interacting ground state and evaluates bipartite entanglement by tracing out $N_f$ degrees of freedom. This trace operation must be formalized.
3. **Theorem `Bipartite_Decomposition`**: Formalize the tensor product decomposition of the infinite Fock space $\mathcal{H} = \mathcal{H}_A \otimes \mathcal{H}_B$ across a spatial cut.
4. **Theorem `Reduced_Density_Matrix`**: Prove that for a normalized pure state $|\psi\rangle$, the partial trace $\rho_A = \text{Tr}_B(|\psi\rangle\langle\psi|)$ is a valid, trace-class, positive semi-definite operator.

### Phase III: von Neumann Entropy and Zero-Mode Perturbation
5. **Theorem `von_Neumann_Entropy_WellDefined`**: Define $S(\rho_A) = -\text{Tr}(\rho_A \ln \rho_A)$ using the functional calculus of trace-class operators and prove its analyticity away from ground-state level crossings.
6. **Theorem `RankOne_ZeroMode_Creation`**: Formalize the exact perturbation mechanism driving the Python script's `get_D_matrix(t_lam, L)`: Prove that the Adèlic rank-1 perturbation (the prime-weighted vector $\xi$) induces exactly one zero-eigenvalue mode in the single-particle Dirac spectrum if and only if the evaluation parameter $t$ coincides with a zero of the completed $L$-function.

### Phase IV: The Macroscopic Phase Transition
7. **Theorem `Thermodynamic_Entanglement_Jump`**: (The Capstone). Prove that in the limit $L \to \infty$, the presence of a single-particle zero mode (from Phase III) strictly forces a macroscopic ground-state degeneracy in the interacting many-body sector. 
8. **Theorem `Phase_Transition_Singularity`**: Prove that the degenerate ground states structurally restrict the reduced density matrix $\rho_A$, bounding the entanglement entropy from below by a finite step (e.g., $\ln(2)$). Conclude that $S_A(t)$ undergoes a non-analytic jump (a quantum phase transition) exactly at the $L$-function zeros.

---
**Status:** Theoretical framework complete. Ready for Golfer subagent execution. No code modifications were performed during this research pass.
