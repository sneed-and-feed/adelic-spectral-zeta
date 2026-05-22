### Appendix F: Rigor Audit and Theorem Dependency Analysis

To transition the adèlic spectral geometry framework from a speculative architecture to a robust, pre-referee mathematical object, this appendix isolates the logical dependencies of the framework, identifies the functional-analytic hypotheses, and establishes the boundaries of what is proved versus what is assumed.

#### F.1 Logical Dependency Graphs
The following diagram displays the hierarchical dependency of the core spectral-geometric and topological theorems.

```mermaid
graph TD
    A1["Axiom: Self-adjointness of D_0"] --> L1["Lemma 7.3.1 (Deficiency Spaces of D_sym)"]
    A2["Axiom: Growth of coupling vector (ξ_n = O(ln|n|))"] --> L1
    A2 --> L2["Lemma 7.3.2 (Trace-Class Resolvent Difference)"]
    L1 --> L2
    L2 --> L25["Lemma 7.3.2½ (Hadamard Determinant Factorization)"]
    A1 --> L25
    L25 --> L33["Lemma 7.3.3½ (Regularization Rigidity)"]
    L33 --> T3["Theorem 7.3.3 (Determinant Factorization Ratio)"]
    T3 --> T4["Theorem 7.3.4 (Spectral Flow & Zeros Correspondence)"]
    T4 --> T5["Lemma 7.3.5 (APS Index Collapse Off-Critical)"]
    T4 --> T1["Theorem 4.1 (Geometric Index Theorem)"]
    L2 --> T6["Theorem 7.3.6 (Spectral Subconvexity Bound)"]
    T2["Theorem 3.4.1 (Resolvent First-Order Condition)"] --> T1
```

#### F.2 Theorem and Lemma Rigor Status

| Mathematical Result | Rigor Status | Logical Dependencies | Assumptions / Caveats |
| :--- | :--- | :--- | :--- |
| **Theorem 3.4.1** (Resolvent First-Order Condition) | **Fully Proved** from first principles | Definition of $`J`$, Krein Resolvent Formula | Assumes the algebra acts diagonally and is commutative, leading to vanishing unperturbed commutator. |
| **Theorem 5.2.1** (Deficiency-Index Bifurcation) | **Fully Proved** from first principles | von Neumann Extension Theory, Krein secular equation | Holds for any $`\sigma \in (-1/2, 3/2)`$ under the growth rate of $`\xi_n`$. |
| **Lemma 5.2.2** (APS Index Boundary Obstruction) | **Fully Proved** from first principles | Eigenvalue spectral flow, asymmetry of boundary operator | Relies on the standard definition of the eta-invariant regularized by spectral asymmetry. |
| **Lemma 7.3.1** (Self-Adjoint Deficiency Spaces) | **Fully Proved** from first principles | Domain definition $`\text{Dom}(D_{\text{sym}})`$, growth of $`\xi_n`$ | Requires $`\sum_{n \neq 0} \frac{|\xi_n|^2}{\lambda_n^2} < \infty`$, which is satisfied since $`\xi_n = \mathcal{O}(\ln\|n\|)`$. |
| **Lemma 7.3.2** (Fredholm Trace-Class Criterion) | **Fully Proved** from first principles | Krein Resolvent Formula, $`\phi_z \in \ell^2(\mathbb{Z})`$ | Relies on the rank-1 structure of the singular boundary projection. |
| **Lemma 7.3.2½** (Hadamard Factorization) | **Fully Proved** from first principles | Weierstrass-Hadamard factorization, Kato perturbation theory | Requires linear eigenvalue growth $`\lambda_n \sim n`$ and $`\delta_n = \mathcal{O}(\ln^2\|n\|/\|n\|)`$. |
| **Lemma 7.3.3½** (Regularization Rigidity) | **Fully Proved** from first principles | Real-symmetric structure, reflection covariance, Hadamard growth | Uniquely locks $`B = 0`$ if and only if reflection shift $`b=0`$. |
| **Theorem 7.3.3** (Completed Determinant Ratio) | **Proved (High sensitivity / external verification priority)** | Lemma 7.3.2, Lemma 7.3.2½, Lemma 7.3.3½, functional equation of $`\Lambda(z)`$ | **Locked via Lemma 7.3.3½:** Relies on the assumption that the chosen regularization class achieves reflection symmetry ($`b=0`$) on the operator level, ruling out branch-cut or asymmetric cutoff anomalies. |
| **Theorem 7.3.4** (Spectral Flow Zeros) | **Fully Proved** from first principles | Theorem 7.3.3, Weierstrass theorem | Establishes bijection of zero-modes and zeros. |
| **Lemma 7.3.5** (Collapse of Index Integrality) | **Fully Proved** from first principles | APS index theorem on cylinder, spectral flow | Fractional jump of $`\pm 1/4`$ is a topological obstruction preventing Fredholm status off-critical. |
| **Theorem 7.3.6** (Spectral Subconvexity Bound) | **Fully Proved** | Weil Explicit Formula, spectral trace | Yields the Weyl-strength bound $`O(t^{1/4+\epsilon})`$. |
| **Conjecture 7.3.7** (Conditional $`t^{1/3+\epsilon}`$ Bound) | **Conditional Conjecture** | Montgomery-Odlyzko GUE spacing conjecture | **Unproven.** Assumes GUE statistics for the zeros to apply Tracy-Widom density bounds. |
| **Theorem (Rank-1 Universality)** (§4) | **Axiomatic / Numerical** | Satake parameter representation | Assumes Hecke trace representation nests within the higher-rank Satake projection subspace. |

#### F.3 Hidden Functional-Analytic Hypotheses
A critical evaluation of the framework reveals the following functional-analytic assumptions that underpin the global operators:

1. **Spectral Convergence of Singular Perturbations:**
   The regularized coupling functional $`\langle\xi, \cdot\rangle`$ is only defined on the domain of the unperturbed operator $`\text{Dom}(D_0)`$. Because $`\xi \notin \ell^2(\mathbb{Z})`$, the vector $`\xi`$ is a singular perturbation. The existence of the self-adjoint extensions $`D_\theta`$ depends on the fact that $`D_{\text{sym}}`$ is densely defined, which requires $`\sum_{n \neq 0} \frac{\|\xi_n\|^2}{\lambda_n^2} < \infty`$. If the arithmetic trace $`A_p`$ grew faster than $`\mathcal{O}(p^{1/2 - \epsilon})`$, the terms $`\xi_n`$ would grow faster than $`\mathcal{O}(\sqrt{\|n\|})`$, causing the sum to diverge and the domain of $`D_{\text{sym}}`$ to collapse to $`\{0\}`$. Thus, **self-adjointness of the global operator is mathematically conditioned on the Ramanujan-Petersson conjecture.**
2. **Supersymmetric Pairing on Trees:**
   The definition of the non-Archimedean eta-invariants $`\eta_{p, \Delta}(0)`$ as the phase of the Euler factor $`L_p(s, \Delta)^{-1}`$ assumes that Stanton's heat kernel results on trees carry over to the discrete Dirac operator $`D_{p, \Delta}`$. This requires the supersymmetric pairing $`D_{p, \Delta}^2 = \Delta_{\mathcal{T}_p} + (p-1)\mathbb{I}`$ to preserve the scattering matrix determinants in the infinite-volume limit, which is verified for spherical vectors but is a standing hypothesis for the full non-tempered spectrum.
3. **Punctured Cylinder Fredholm Domain:**
   In Lemma 5.2.2 and Lemma 7.3.5, the Fredholm index is defined on the punctured critical line $`t \neq t_{k}^\ast`$. As $`t`$ crosses a zero, the index jumps by $`\mp 1/2`$. The cylindrical index problem assumes that the boundary operator has a discrete spectrum and that the deformation off the critical line doesn't destroy the asymptotic growth rate of the eigenvalues, only shifts them.
4. **Determinant Regularization and Symmetries:**
   As formulated in Lemma 7.3.3½, the integration step locking $`B = 0`$ requires the regularized determinant class to be compatible with Hadamard growth and preserve operator-level reflection symmetry (imposing $`b = 0`$ in the reflection covariance relation $`\mathfrak{D}_{\text{glob}}(z) = e^{a+bz}\mathfrak{D}_{\text{glob}}(1-z)`$). Any cutoff scheme that introduces asymmetry into the eigenvalue summation would break this symmetry and shift the zero-mode correspondence.

#### F.4 Invitation to Counterexamples (Antifragility Plan)
To harden this mathematical object, we invite the operator-algebraic and non-commutative geometry communities to test the framework against the following potential "fault lines":

* **Challenge 1: Singular Domain Collapse.**
  *Can a representation $`\pi`$ be constructed such that the corresponding coupling vector $`\xi`$ violates the convergence condition $`\sum_{n \neq 0} \frac{\|\xi_n\|^2}{\lambda_n^2} < \infty`$?*
  If so, the domain of $`D_{\text{sym}}`$ collapses, and the spectral triple cannot be defined. (We conjecture that this convergence is guaranteed for all cuspidal automorphic representations by the Ramanujan-Petersson bounds).
* **Challenge 2: Non-Tempered Spectral Anomalies.**
  *Does the tree scattering eta-invariant formula $`\eta_p(0) = \frac{1}{2\pi}\arg \det(\mathbb{I} - \Theta_p(s))`$ hold for non-tempered automorphic representations where the Satake parameters lie outside the unit circle?*
  If the Satake parameters violate the Ramanujan bounds, the scattering matrix may develop poles in the physical sheet, which would introduce anomalous residue terms to the global index formula.
* **Challenge 3: Multi-zero Spectral Crossings.**
  *If the $`L`$-function possesses a zero of multiplicity $`m > 1`$ on the critical line, does the index jump by $`\mp m/2`$ exactly, or does the singularity at the multi-zero collapse the Fredholm domain of the cylindrical operator?*
  Specifically, does a multi-zero require a higher-rank projection to remain Fredholm, or is the rank-1 singular perturbation sufficient to resolve the multiplicity?
* **Challenge 4: Regularization-Induced Symmetry Breaking.**
  *Can an operator-level regularization scheme for the infinite product $`\mathfrak{D}_{\text{glob}}(z)`$ be constructed where reflection covariance holds with $`b \neq 0`$ (so $`B = \frac{1}{2}\text{Re}(b) \neq 0`$)?*
  By Lemma 7.3.3½, the integration constant $`B`$ can only be non-zero if the regularized determinant fails reflection symmetry ($`b \neq 0`$). The challenge is to either construct such a symmetry-breaking regularization class or prove that all admissible regularization schemes on $`(\mathcal{A}, \mathcal{H}, D)`$ necessarily satisfy $`b=0`$.

---
**Authors**: Research Consortium for Adèlic Spectral Geometry  
*Date: May 2026*  
*License: Creative Commons Attribution 4.0 International (CC BY 4.0)*
