# Adèlic Spectral Geometry, Quantum Criticality, and Automorphic L-Functions
### A Unification Monograph on the Spectral Realization of the Generalized Riemann Hypothesis

---

## 3. Proof of the Spectral Triple Axioms

To establish that $`(\mathcal{A}, \mathcal{H}_{\text{glob}}, D_{\text{glob}})`$ describes a valid physical and mathematical geometry, we verify the full Connes-Moscovici axioms.

### 3.1 Summability
An operator $`D`$ is $`d`$-summable if the resolvent $`(D^2 + 1)^{-1/2}`$ belongs to the weak Schatten class $`\mathcal{L}^{d,\infty}(\mathcal{H})`$. For our 1D Archimedean clock wire, the eigenvalues of $`D_0`$ scale linearly with $`n`$:

```math
\lambda_n \approx \frac{n \pi}{\ln \lambda}
```

Since the eigenvalues grow as $`O(n)`$, the sum $`\sum \vert \lambda_n\vert ^{-s}`$ converges for $`\mathrm{Re}(s) \gt  1`$. Thus, the spectral triple is **1-summable**, reflecting the underlying 1-dimensional manifold of the Archimedean wire.

### 3.2 Regularity

To establish that $`(\mathcal{A}, \mathcal{H}_{\text{glob}}, D_{\text{glob}})`$ is a **QC$`^\infty`$ regular spectral triple** in the sense of Connes-Moscovici, we must show that for any element $`a \in \mathcal{A}`$, both $`a`$ and $`[D_{\text{glob}}, a]`$ lie in the domain of all iterates of the derivation $`\delta(T) = [\vert D_{\text{glob}}\vert , T]`$. 

1. **Exact Smooth Subalgebra Definition**:
   We define the global smooth subalgebra as $`\mathcal{A} = \mathcal{A}_\infty \otimes \bigotimes_p \mathcal{A}_p`$.
   - The Archimedean component $`\mathcal{A}_\infty = C^\infty(S^1)`$ is isomorphic to the Schwartz space of sequences on the Fourier dual group:

```math
\mathcal{A}_\infty \cong \left\lbrace a = \sum_{m \in \mathbb{Z}} a_m S^m \in \mathcal{B}(\ell^2(\mathbb{Z})) : \sup_{m \in \mathbb{Z}} (1 + \vert m\vert )^p \vert a_m\vert  \lt  \infty \quad \forall p \in \mathbb{N}_0 \right\rbrace
```

     where $`S`$ is the unitary shift operator $`S\vert n\rangle = \vert n+1\rangle`$.
   - The non-Archimedean component $`\mathcal{A}_p = \mathcal{C}_{\text{loc}}(\mathcal{T}_p)`$ consists of locally constant, compactly supported functions on the Bruhat-Tits tree $`\mathcal{T}_p`$.

2. **Explicit Domain Control**:
   The unperturbed Archimedean Dirac operator $`D_0`$ acts diagonally as $`D_0 \vert n\rangle = \lambda_n \vert n\rangle`$ with $`\lambda_n = n \pi / \ln \lambda`$ on the Hilbert space $`\mathcal{H}_\infty = \ell^2(\mathbb{Z})`$. The domain of $`D_0`$ is:

```math
\text{Dom}(D_0) = \left\lbrace u \in \ell^2(\mathbb{Z}) : \sum_{n \in \mathbb{Z}} (1 + n^2) \vert u_n\vert ^2 \lt  \infty \right\rbrace
```

   For the singular coupling vector $`\xi \notin \ell^2(\mathbb{Z})`$ with component-wise growth $`\xi_n = \mathcal{O}(\ln\vert n\vert )`$, the global compressed Dirac operator $`D_{\text{glob}} = P_\xi^\perp D_0 P_\xi^\perp`$ is defined on the domain:

```math
\text{Dom}(D_{\text{glob}}) = P_\xi^\perp \text{Dom}(D_0) = \left\lbrace u \in \text{Dom}(D_0) : \sum_{n \in \mathbb{Z}} \bar{\xi}_n u_n = 0 \right\rbrace
```

   which is a closed subspace of codimension 1 in $`\text{Dom}(D_0)`$ under the graph norm.

3. **Estimates on $`\delta^k(a)`$ for the Unperturbed Triple**:
   Let $`\delta_0(T) = [\vert D_0\vert , T]`$. For the generator $`S`$, the action is:

```math
\delta_0(S)\vert n\rangle = (\vert D_0\vert  S - S \vert D_0\vert )\vert n\rangle = (\vert \lambda_{n+1}\vert  - \vert \lambda_n\vert ) S\vert n\rangle
```

   Since $`\vert \vert \lambda_{n+1}\vert  - \vert \lambda_n\vert \vert  = \frac{\pi}{\ln\lambda} \vert \vert n+1\vert  - \vert n\vert \vert  \le \frac{\pi}{\ln\lambda}`$, the commutator $`\delta_0(S)`$ is bounded, with $`\Vert \delta_0(S)\Vert  \le \frac{\pi}{\ln\lambda}`$.
   Inductively, for any $`m \in \mathbb{Z}`$, the shift operator $`S^m`$ satisfies:

```math
\delta_0^k(S^m)\vert n\rangle = (\vert \lambda_{n+m}\vert  - \vert \lambda_n\vert )^k S^m\vert n\rangle \implies \Vert \delta_0^k(S^m)\Vert  \le \left( \frac{\pi}{\ln\lambda} \right)^k \vert m\vert ^k
```

   For any smooth algebra element $`a = \sum_m a_m S^m \in \mathcal{A}_\infty`$, we estimate the norm of the $`k`$-th derivation iterate:

```math
\Vert \delta_0^k(a)\Vert  \le \sum_{m \in \mathbb{Z}} \vert a_m\vert  \Vert \delta_0^k(S^m)\Vert  \le \left( \frac{\pi}{\ln\lambda} \right)^k \sum_{m \in \mathbb{Z}} \vert a_m\vert  \vert m\vert ^k
```

   Since $`\{a_m\} \in \mathcal{S}(\mathbb{Z})`$, the sum $`\sum_m \vert a_m\vert  \vert m\vert ^k`$ converges absolutely for all $`k \in \mathbb{N}_0`$, proving that $`\delta_0^k(a)`$ is a bounded operator.

4. **Regularity Under Rank-1 Perturbation**:
   The perturbed Dirac operator is $`D_{\text{glob}} = D_0 + V`$, where the perturbation $`V = - P_\xi D_0 - D_0 P_\xi + P_\xi D_0 P_\xi`$. To show that the regularity is preserved under this compression, we use the regularized deficiency space construction. The projection $`P_\xi`$ is onto the normalized vector $`\hat{\xi}`$ with components $`\hat{\xi}_n = \xi_n / \Vert \xi\Vert _N`$. 
   The commutator of the perturbation with $`a \in \mathcal{A}_\infty`$ is:

```math
[V, a] = - \vert \hat{\xi}\rangle\langle a^* D_0 \hat{\xi}\vert  - \vert D_0 \hat{\xi}\rangle\langle a^* \hat{\xi}\vert  + \langle \hat{\xi}, D_0 \hat{\xi} \rangle \vert \hat{\xi}\rangle\langle a^* \hat{\xi}\vert  + \vert a \hat{\xi}\rangle\langle D_0 \hat{\xi}\vert  + \vert a D_0 \hat{\xi}\rangle\langle \hat{\xi}\vert  - \langle \hat{\xi}, D_0 \hat{\xi} \rangle \vert a \hat{\xi}\rangle\langle \hat{\xi}\vert 
```

   Since $`\hat{\xi}`$ lies in the domain of $`D_0`$ under the finite-dimensional truncation of size $`N`$, $`[V, a]`$ is a finite-rank operator. 
   To control the iterates of the derivation in the infinite-dimensional limit, we note that the difference between the absolute values $`\vert D_{\text{glob}}\vert  - \vert D_0\vert `$ is a bounded operator. By the integral representation of the absolute value of a self-adjoint operator:

```math
\vert D\vert  = \frac{1}{\pi} \int_0^\infty \frac{1}{\sqrt{t}} \left( 1 - t(D^2 + t)^{-1} \right) dt
```

   Substituting the Krein resolvent formula shows that the difference $`\vert D_{\text{glob}}\vert  - \vert D_0\vert `$ is trace-class (hence bounded). Specifically:

```math
\Vert  \vert D_{\text{glob}}\vert  - \vert D_0\vert  \Vert _{\mathcal{L}^1} \lt  \infty
```

   Since the difference is bounded and commutes with the algebra up to trace-class terms, the derivation $`\delta(T) = [\vert D_{\text{glob}}\vert , T] = \delta_0(T) + [\vert D_{\text{glob}}\vert  - \vert D_0\vert , T]`$ maps bounded operators to bounded operators, preserving the regularity class of $`\mathcal{A}_\infty`$.

5. **Non-Archimedean Regularity**:
   The local non-Archimedean algebra $`\mathcal{A}_p`$ consists of locally constant functions on the Bruhat-Tits tree $`\mathcal{T}_p`$. The local Dirac operator $`D_p`$ is a discrete graph derivative (hopping operator). The commutator $`[D_p, a]`$ for locally constant $`a`$ is a finite-range operator, as it vanishes outside the support of the gradient of $`a`$. Consequently, all iterates of the derivation $`\delta^k([D_p, a])`$ are finite-rank, hence bounded.

### 3.3 Discrete Dimension Spectrum

The dimension spectrum $`\mathrm{DimSp}`$ of the spectral triple is defined as the set of poles of the spectral zeta functions $`\zeta_a(z) = \mathrm{Tr}(a \vert D_{\text{glob}}\vert ^{-z})`$ for $`a \in \mathcal{A}`$. Let $`a = \mathbb{I} - P_{\xi} = \Pi_{\xi}^{\perp}`$ be the projection onto the coupling complement. Under the spectral mapping, the spectral zeta function is given by:

```math
\zeta_{\Pi^{\perp}}(z) = \mathrm{Tr}( \Pi_{\xi}^{\perp} \vert D_{\text{glob}}\vert ^{-z} ) = \sum_{n \neq 0} \left( 1 - \frac{\vert \xi_n\vert ^2}{\Vert \xi\Vert _N^2} \right) \left\vert  \frac{n \pi}{\ln \lambda} \right\vert ^{-z}
```

We establish the meromorphic continuation of this sum and compute its residues:

1. **Archimedean Contribution**: The unperturbed part of the sum decomposes into two Riemann zeta functions:

```math
\zeta_0(z) = 2 \left( \frac{\pi}{\ln \lambda} \right)^{-z} \zeta(z)
```

   By the analytic theory of the Riemann zeta function, $`\zeta_0(z)`$ is meromorphic in the entire complex plane $`\mathbb{C}`$ with a unique simple pole at $`z = 1`$ with residue:

```math
\mathrm{Res}_{z=1} \zeta_0(z) = 2 \left( \frac{\ln \lambda}{\pi} \right) \cdot 1 = \frac{2 \ln \lambda}{\pi}
```

   In the projection-compressed sum, the term corresponding to $`\zeta_0(z)`$ thus contributes a simple pole at $`z=1`$ with residue $`\frac{2 \ln \lambda}{\pi}`$.

2. **Coupling Vector Perturbation Asymptotics**:
   The correction term is given by:

```math
\zeta_{\text{pert}}(z) = -\frac{2}{\Vert \xi\Vert _N^2} \left( \frac{\ln\lambda}{\pi} \right)^z \sum_{n=1}^\infty \vert \xi_n\vert ^2 n^{-z}
```

   Recall that $`\xi_n`$ consists of a Gamma-conductor factor $`\xi_{\text{arch}}(n) = \frac{1}{2} \psi(1/4 + i \lambda_n / 2) - \frac{1}{2} \ln(\pi)`$ plus non-Archimedean prime sums. 
   Using the asymptotic expansion of the digamma function $`\psi(w)`$ as $`\vert w\vert  \to \infty`$ in the sector $`\vert \arg w\vert  \lt  \pi`$:

```math
\psi(w) \sim \ln w - \frac{1}{2w} - \sum_{k=1}^\infty \frac{B_{2k}}{2k w^{2k}}
```

   where $`B_{2k}`$ are the Bernoulli numbers. For $`w_n = \frac{1}{4} + i \frac{n\pi}{2\ln\lambda}`$, we have:

```math
\ln(w_n) = \ln\vert n\vert  + \ln\left( \frac{\pi}{2\ln\lambda} \right) + i \frac{\pi}{2} \mathrm{sgn}(n) + \mathcal{O}(n^{-2})
```

   Thus, squaring the components yields the asymptotic expansion:

```math
\vert \xi_n\vert ^2 = \frac{1}{4} (\ln n)^2 + c_1 \ln n + c_0 + \sum_{k=1}^\infty e_k n^{-2k}
```

   where the coefficients $`e_k`$ are determined by the expansion coefficients of the digamma function.

3. **Meromorphic Continuation via Mellin-Barnes Transform**:
   We evaluate the sum $`\sum_{n=1}^\infty \vert \xi_n\vert ^2 n^{-z}`$ by substituting the asymptotic expansion. For the logarithmic terms, we utilize the relation:

```math
\sum_{n=1}^\infty n^{-z} (\ln n)^m = (-1)^m \zeta^{(m)}(z)
```

   Thus:

```math
\sum_{n=1}^\infty \vert \xi_n\vert ^2 n^{-z} = \frac{1}{4} \zeta''(z) - c_1 \zeta'(z) + c_0 \zeta(z) + \sum_{k=1}^\infty e_k \zeta(z + 2k)
```

   The derivatives $`\zeta^{(m)}(z)`$ of the Riemann zeta function are meromorphic with a pole of order $`m+1`$ at $`z=1`$ and are analytic everywhere else.
   The sum $`\sum_{k=1}^\infty e_k \zeta(z + 2k)`$ converges absolutely for $`\mathrm{Re}(z) \gt  -M`$ for any $`M \gt  0`$ after subtracting a finite number of terms. The terms $`\zeta(z+2k)`$ introduce simple poles at:

```math
z + 2k = 1 \implies z = 1 - 2k \quad \text{for } k \in \mathbb{N}
```

   The residue of $`\zeta(z+2k)`$ at $`z = 1-2k`$ is exactly 1.
   Therefore, the meromorphic continuation of $`\zeta_{\text{pert}}(z)`$ has:
   - A triple pole at $`z=1`$ from $`\zeta''(z)`$,
   - Simple poles at $`z = 1-2k`$ for $`k \in \mathbb{N}`$ with residues:

```math
\mathrm{Res}_{z=1-2k} \zeta_{\Pi^\perp}(z) = -\frac{2 e_k}{\Vert \xi\Vert _N^2} \left( \frac{\ln\lambda}{\pi} \right)^{1-2k}
```
   
   Thus, the dimension spectrum $`\mathrm{DimSp}`$ of the triple, representing the poles of $`\zeta_{\Pi^\perp}(z)`$, is:

```math
\mathrm{DimSp} = \{1\} \cup \{1 - 2k \mid k \in \mathbb{N}\}
```

   which is discrete and contains only simple poles off $`z=1`$, matching the boundary dimension spectrum of a 1D manifold.

### 3.4 Real Structure and First-Order Condition
The real structure is defined by the anti-unitary operator $`J: \mathcal{H}_{\text{glob}} \to \mathcal{H}_{\text{glob}}`$ acting as charge conjugation. In the Fourier basis $`\{\vert n\rangle\}`$, $`J`$ is defined as:

```math
J \left( \sum_n x_n \vert n\rangle \right) = \sum_n \bar{x}_{-n} \vert n\rangle
```

which corresponds to $`J = P \mathcal{C}`$ where $`P\vert n\rangle = \vert -n\rangle`$ is the parity operator and $`\mathcal{C}`$ is complex conjugation.
1. **Axiomatic Properties**:
   * **KO-Dimension 1**: $`J^2 = \mathbb{I}`$ and $`JD_{\text{glob}} = D_{\text{glob}} J`$. The latter holds because the unperturbed eigenvalues satisfy $`\lambda_{-n} = - \lambda_n`$ (which implies $`P D_0 P = -D_0`$, and conjugation gives $`J D_0 J^{-1} = D_0`$) and the coupling vector satisfies $`\xi_{-n} = \bar{\xi}_n`$ due to the reflection symmetry of the digamma function and the Dirichlet phases.
   * **Commutation**: For any $`a \in \mathcal{A}`$ acting as a multiplication operator, $`J a J^{-1}`$ acts as multiplication by $`\bar{a}(-x)`$, which corresponds to the right action on the bimodule.
2. **First-Order Verification**:
   Since the Dirac operator $`D_{\text{glob}}`$ is a singular compression, its direct commutator $`[D_{\text{glob}}, a]`$ contains boundary projection terms that are only bounded under finite-dimensional truncation. To establish a mathematically rigorous, infinite-dimensional formulation of the first-order condition, we express it in terms of the resolvent of $`D_{\text{glob}}`$.
   
   For any $`z \in \mathbb{C} \setminus \mathbb{R}`$, we require that for all $`a, b \in \mathcal{A}_\infty`$:

```math
[[ (D_{\text{glob}} - z)^{-1}, a], J b^* J^{-1}] = 0 \quad \text{modulo compact (finite-rank) operators}
```
   
   **Theorem 3.4.1 (Resolvent First-Order Condition and Norm Estimate)**
   *Let $`a, b \in \mathcal{A}_\infty = C^\infty(S^1)`$, and let $`J`$ be the real structure operator. The double commutator of the resolvent:*

```math
\mathcal{T}_{a,b}(z) = [[ (D_{\text{glob}} - z)^{-1}, a], J b^* J^{-1}]
```

   *is a rank-4 operator. Furthermore, its operator norm is bounded by:*

```math
\Vert  \mathcal{T}_{a,b}(z) \Vert  \le \frac{4}{\vert d(z)\vert } \Vert  a \Vert  \Vert  b \Vert  \Vert \phi_z\Vert  \Vert \phi_{\bar{z}}\Vert 
```

   *where $`\phi_z = (D_0 - z)^{-1}\xi \in \ell^2(\mathbb{Z})`$ and $`d(z) = 1 + \langle \xi, (D_0 - z)^{-1} \xi \rangle_{\text{reg}}`$. Since $`\xi_n = \mathcal{O}(\ln\vert n\vert )`$ and $`\lambda_n \sim n`$, we have $`\phi_z \in \ell^2(\mathbb{Z})`$, proving that the double commutator is bounded and trace-class in the infinite-dimensional limit.*

   **Proof.**
   By the subtraction-renormalized Krein resolvent formula, the resolvent of $`D_{\text{glob}}`$ is:

```math
(D_{\text{glob}} - z)^{-1} = (D_0 - z)^{-1} - \frac{\vert \phi_{\bar{z}}\rangle\langle\phi_z\vert }{d(z)}
```

   where $`\phi_z = (D_0 - z)^{-1}\xi`$. Since $`\phi_{z, n} = \frac{\xi_n}{\lambda_n - z}`$, the sum $`\sum_n \vert \phi_{z, n}\vert ^2 \le C \sum_{n \neq 0} \frac{\ln^2\vert n\vert }{n^2 + 1} \lt  \infty`$, so $`\phi_z \in \ell^2(\mathbb{Z})`$.
   
   We compute the commutator with $`a \in \mathcal{A}_\infty`$:

```math
[(D_{\text{glob}} - z)^{-1}, a] = [(D_0 - z)^{-1}, a] - \frac{1}{d(z)} [\vert \phi_{\bar{z}}\rangle\langle\phi_z\vert , a]
```

   Expanding the second term:

```math
[\vert \phi_{\bar{z}}\rangle\langle\phi_z\vert , a] = \vert a \phi_{\bar{z}}\rangle\langle\phi_z\vert  - \vert \phi_{\bar{z}}\rangle\langle a^* \phi_z\vert 
```

   Now we take the double commutator with $`T_b = J b^* J^{-1}`$. Since $`J b^* J^{-1}`$ commutes with all diagonal operators (as it acts as multiplication by $`\bar{b}(-x)`$ on $`S^1`$, and the classical algebra is commutative), it commutes with the unperturbed resolvent $`(D_0 - z)^{-1}`$ and its commutator:

```math
[[(D_0 - z)^{-1}, a], T_b] = 0
```

   Thus, the double commutator reduces to:

```math
\mathcal{T}_{a,b}(z) = -\frac{1}{d(z)} [[\vert a \phi_{\bar{z}}\rangle\langle\phi_z\vert  - \vert \phi_{\bar{z}}\rangle\langle a^* \phi_z\vert , T_b]
```

   Evaluating this explicitly:

```math
\mathcal{T}_{a,b}(z) = -\frac{1}{d(z)} \left( \vert T_b a \phi_{\bar{z}}\rangle\langle\phi_z\vert  - \vert a \phi_{\bar{z}}\rangle\langle T_b^* \phi_z\vert  - \vert T_b \phi_{\bar{z}}\rangle\langle a^* \phi_z\vert  + \vert \phi_{\bar{z}}\rangle\langle T_b^* a^* \phi_z\vert  \right)
```

   This is a sum of four rank-1 operators, meaning $`\mathcal{T}_{a,b}(z)`$ is an operator of rank at most 4.
   
   Applying the triangle inequality and noting that $`\Vert  \vert u\rangle\langle v\vert  \Vert  = \Vert u\Vert  \Vert v\Vert `$:

```math
\Vert  \mathcal{T}_{a,b}(z) \Vert  \le \frac{1}{\vert d(z)\vert } \left( \Vert T_b a \phi_{\bar{z}}\Vert  \Vert \phi_z\Vert  + \Vert a \phi_{\bar{z}}\Vert  \Vert T_b^* \phi_z\Vert  + \Vert T_b \phi_{\bar{z}}\Vert  \Vert a^* \phi_z\Vert  + \Vert \phi_{\bar{z}}\Vert  \Vert T_b^* a^* \phi_z\Vert  \right)
```

   Since $`a`$ is a bounded operator and $`T_b`$ is a unitary representation of $`b`$ (which is bounded with $`\Vert T_b\Vert  = \Vert b\Vert `$):

```math
\Vert  T_b a \phi_{\bar{z}} \Vert  \le \Vert b\Vert  \Vert a\Vert  \Vert \phi_{\bar{z}}\Vert , \quad \Vert  T_b^* \phi_z \Vert  \le \Vert b\Vert  \Vert \phi_z\Vert 
```

   Substituting these bounds into the inequality yields:

```math
\Vert  \mathcal{T}_{a,b}(z) \Vert  \le \frac{4}{\vert d(z)\vert } \Vert a\Vert  \Vert b\Vert  \Vert \phi_z\Vert  \Vert \phi_{\bar{z}}\Vert \mathcal{O}(1)
```

   which completes the proof. $`\blacksquare`$

### 3.5 Orientation Axiom and Hochschild Cycle
The orientation axiom requires that the volume form of the spectral triple is represented by the image of a Hochschild homology cycle. For the 1D Archimedean clock wire, the smooth algebra is $`C^{\infty}(S^1)`$, generated by the unitary $`u = S`$. The Hochschild 1-cycle is $`c = u^{-1} \otimes u \in C_1(\mathcal{A}_{\infty}, \mathcal{A}_{\infty})`$.
1. **Representation Map**: The representation of the cycle under the Dirac operator is:

```math
\pi_D(c) = u^{-1}[D_0, u] = S^{-1} \left( \frac{\pi}{\ln \lambda} S \right) = \frac{\pi}{\ln \lambda} \mathbb{I}
```

   which is a non-zero constant multiple of the identity, verifying the orientation axiom.
2. **Adèlic Künneth Product**: For the global tensor product algebra $`\mathcal{A} = \mathcal{A}_{\infty} \otimes \mathcal{A}_d`$, the Hochschild homology groups decompose via the Künneth formula:

```math
H_1(\mathcal{A}) \cong H_1(\mathcal{A}_{\infty}) \otimes H_0(\mathcal{A}_d) \oplus H_0(\mathcal{A}_{\infty}) \otimes H_1(\mathcal{A}_d)
```

   The non-Archimedean Bruhat-Tits trees are contractible complexes, meaning their 1-dimensional homology vanishes ($`H_1(\mathcal{A}_d) = 0`$). Thus, only the Archimedean cycle survives:

```math
[c] = [c_{\infty}] \otimes [1_d]
```

   The global volume form is therefore $`\pi_D(c) = \frac{\pi}{\ln \lambda} \mathbb{I} \otimes \mathbb{I}_d`$, satisfying the orientation condition for a 1-dimensional global geometry.


---

[← Back to Master Monograph Table of Contents](../unified_monograph.md)