# Adèlic Spectral Geometry, Quantum Criticality, and Automorphic L-Functions
### A Unification Monograph on the Spectral Realization of the Generalized Riemann Hypothesis

---

## 2. The Adèlic Spectral Triple $`(\mathcal{A}, \mathcal{H}_{\text{glob}}, D_{\text{glob}, \Delta})`$

We define the global spectral triple associated to an automorphic representation $\pi (or$ a Dirichlet character/cusp form like the Ramanujan $\Delta-function)$ as follows.

### 2.1 The Algebra $\mathcal{A}$
The algebra $\mathcal{A}$ is the non-commutative algebra of smooth, rapidly decreasing functions on the adèle class space, which can be represented as:

$$
\mathcal{A} = \mathcal{C}^\infty(S^1 \rtimes \mathbb{R}_+^\times) \otimes \bigotimes_{p} \mathcal{C}_{\text{loc}}(\mathcal{T}_p)
$$

where $`S^1 \rtimes \mathbb{R}_+^\times represents`$ the Archimedean dilation group, and $`\mathcal{T}_p`$ is the Bruhat-Tits tree associated to $`PGL_2(\\mathbb{Q}_p)`$.

### 2.2 The Hilbert Space $\mathcal{H}_{\text{glob}}$
The global Hilbert space is the direct sum of the Archimedean and non-Archimedean components:

$$
\mathcal{H}_{\text{glob}} = \mathcal{H}_\infty \otimes \bigotimes_{p} \mathcal{H}_p
$$

We discretize the continuous Archimedean component by projecting onto a Fourier-like scale-invariant basis. The basis states $\vert n\rangle$ for $n \in \mathbb{Z} represent states on$ the 1D Archimedean wire, corresponding to logarithmic wavefunctions:

$$
\psi_n(x) = x^{-1/2 - i n \pi / \ln \lambda}
$$

### 2.3 Rigorous Operator-Theoretic Construction of $D_{\text{glob}}$
Formally, we define the Archimedean Hilbert space as $`\mathcal{H}_\infty = \ell^2(\mathbb{Z})`$ with the unperturbed Dirac operator $`D_0 acting diagonally`$ in the scale-invariant basis $`\{\vert n\rangle\}_{n \in \mathbb{Z}}:`$

$$
D_0 \vert n\rangle = \lambda_n \vert n\rangle, \quad \lambda_n = \frac{n \pi}{\ln \lambda}
$$

The natural domain of $D_0$ is the dense subspace:

$$
\text{Dom}(D_0) = \left\lbrace u \in \ell^2(\mathbb{Z}) : \sum_{n=-\infty}^\infty \lambda_n^2 \vert u_n\vert ^2 \lt \infty \right\rbrace
$$

Since $`\lambda_n \in \mathbb{R},`$D_0 is self-adjoint on $`\text{Dom}(D_0).`$

The global coupling vector $\xi$ is defined by:

$$
\xi_n = \sum_{p} A_p \frac{\log p}{\sqrt{p}} p^{-i n \pi / \ln \lambda} + \xi_{\text{arch}}(n)
$$

where $`A_p`$ are the Satake parameters and $`\xi_{\text{arch}}(n) = \frac{1}{2} \psi(1/4 + i \lambda_n / 2) - \frac{1}{2} \ln(\pi) represents`$ the Gamma-conductor factor. Since $\psi(1/4 +$ it) \sim \ln\vert t\vert  as $\vert t\vert \to \infty,$ the components $`\xi_n`$ grow logarithmically: $`\xi_n = \mathcal{O}(\ln\vert n\vert ). Thus,`$\xi \notin \ell^2(\mathbb{Z}), meaning the projection $`P_\xi cannot`$ be defined directly on $`\mathcal{H}_\infty.`$

To construct the global Dirac operator $D_{\text{glob}} rigorously,$ we use the theory of singular rank-1 perturbations:
1. The linear functional $`\langle \xi, \cdot \rangle : u \mapsto \sum_n \bar{\xi}_n u_n`$ is defined on the domain $`\text{Dom}(D_0).`$ It is continuous with respect to the graph norm $`\Vert u\Vert _{D_0} = \sqrt{\Vert u\Vert ^2 + \Vert D_0 u\Vert ^2} because`$ the sequence $`\left\lbrace \frac{\xi_n}{\lambda_n} \right\rbrace`$ is in $\ell^2(\mathbb{Z}) (since$\sum_{n \neq 0} \frac{\ln^2\vert n\vert }{n^2} \lt  \infty).
2. We define the symmetric restriction $`D_{\text{sym}} = D_0 \vert _{\text{Dom}(D_{\text{sym}})} on`$ the dense domain:

$$
\text{Dom}(D_{\text{sym}}) = \text{Dom}(D_0) \cap \text{Ker}(\langle \xi, \cdot \rangle) = \left\lbrace u \in \text{Dom}(D_0) : \sum_{n=-\infty}^\infty \bar{\xi}_n u_n = 0 \right\rbrace
$$

   Since $`\text{Dom}(D_{\text{sym}})`$ is a closed subspace of codimension 1 in $`\text{Dom}(D_0)`$ under the graph norm, $`D_{\text{sym}}`$ is a closed, densely defined symmetric operator.
3. The deficiency spaces $`\mathcal{K}_\pm = \text{Ker}(D_{\text{sym}}^* \mp i\mathbb{I})`$ are spanned by the deficiency vectors:

$$
g_\pm = (D_0 \mp i\mathbb{I})^{-1}\xi \implies g_{\pm, n} = \frac{\xi_n}{\lambda_n \mp i}
$$

   Since $`\xi_n = \mathcal{O}(\ln\vert n\vert )`$ and $`\lambda_n \sim n,`$ the sum $`\sum_n \vert g_{\pm, n}\vert ^2`$ converges, so $`g_\pm \in \ell^2(\mathbb{Z}).`$
   For any $u \in \text{Dom}(D_{\text{sym}}),$ we have:

$$
\langle g_\pm, (D_{\text{sym}} \mp i\mathbb{I})u \rangle = \langle (D_0 \mp i\mathbb{I})^{-1}\xi, (D_0 \mp i\mathbb{I})u \rangle = \langle \xi, u \rangle = 0
$$

   This proves that $`g_\pm`$ are orthogonal to the range of $`D_{\text{sym}} \mp i\mathbb{I},`$ meaning $`\mathcal{K}_\pm = \text{span}\{g_\pm\}. Thus,`$ the deficiency indices are exactly $(1, 1).$
4. By von Neumann's theorem, all self-adjoint extensions $`D_\theta`$ of $`D_{\text{sym}}`$ are parameterized by a phase $\theta \in [0, 2\pi),$ which maps the normalized deficiency space via the isometry $`U_\theta : g_+ \mapsto e^{i\theta} g_-.`$ The domain of the extension $`D_\theta`$ is given by:

$$
\text{Dom}(D_\theta) = \left\lbrace u + c \left( g_+ + e^{i\theta} \frac{\Vert g_+\Vert }{\Vert g_-\Vert } g_- \right) : u \in \text{Dom}(D_{\text{sym}}), c \in \mathbb{C} \right\rbrace
$$

   On this domain, $D_\theta acts$ as:

$$
D_\theta \left( u + c \left( g_+ + e^{i\theta} \frac{\Vert g_+\Vert }{\Vert g_-\Vert } g_- \right) \right) = D_{\text{sym}} u + i c \left( g_+ - e^{i\theta} \frac{\Vert g_+\Vert }{\Vert g_-\Vert } g_- \right)
$$

   The global compressed Dirac operator $`D_{\text{glob}} corresponds`$ to a specific choice of $`\theta_0`$ that matches the physical adèlic boundary conditions, and its resolvent is given exactly by the regularized Krein formula. This guarantees that $`D_{\text{glob}}`$ is a self-adjoint operator on its domain.

### 2.4 Gauge-Covariant 2-Adic Connection and Global Covariant Operator

To model boundary gauge fields acting on the local non-Archimedean sectors, we introduce a non-Archimedean connection. For the $2$-adic sector, the Hilbert space is finite-dimensional $`\mathcal{H}_2 \cong \mathbb{C}^{2^d} representing`$ the boundary states at depth $d$ of the Bruhat-Tits tree. We construct the $2$-adic connection matrix $`\omega_2`$ as:

$$
(\omega_2)_{x, y} = \begin{cases} \frac{1}{2^d} & \text{if } x \not\equiv y \pmod 2 \\ 0 & \text{otherwise} \end{cases}
$$

This operator acts as a parity-flipping connection on the boundary states. 

The global covariant Dirac operator $`D_{\text{cov}}(\sigma) acting on`$ the tensor product Hilbert space $`\mathcal{H}_\infty \otimes \mathcal{H}_2`$ is constructed as:

$$
D_{\text{cov}}(\sigma) = D_0(\sigma) \otimes \mathbb{I}_{2^d} + \mathbb{I}_\infty \otimes \omega_2
$$

where $`D_0(\sigma) = \text{diag}(n \pi / \ln \lambda) + \sigma \mathbb{I}`$ is the unperturbed Archimedean drift operator. The connection term $`\mathbb{I}_\infty \otimes \omega_2 couples`$ the Archimedean scale-invariant wire directly to the $2$-adic boundary states, serving as a model for adèlic gauge fields.

### 2.5 Chinese Remainder Theorem (CRT) Diagonal Descent

To map the high-dimensional tensor product states of the multi-adic Bruhat-Tits boundary trees back to a 1D physical lattice, we define a diagonal descent mapping using the Chinese Remainder Theorem (CRT). For the sectors corresponding to two coprime primes (e.g., $`p_1 = 2`$ and $`p_2 = 3),`$ the joint state space is $`\mathcal{H}_2 \otimes \mathcal{H}_3 \cong \mathbb{C}^{2^d} \otimes \mathbb{C}^{3^k}.`$

We define the diagonal embedding vectors $`\vert e_n\rangle \in \mathcal{H}_2 \otimes \mathcal{H}_3`$ for $n = 1, \dots, M (with$M \le 2^d \cdot 3^k) as:

$$
\vert e_n\rangle = \vert n \pmod{2^d}\rangle \otimes \vert n \pmod{3^k}\rangle
$$

Because the dimensions $2^d$ and $3^k$ are coprime, these vectors are strictly orthonormal:

$$
\langle e_n \vert e_{n'}\rangle = \delta_{n, n'}
$$

The projection operator onto the diagonal subspace of dimension $M$ is given by $`P_{\mathbb{Z}, M} = \sum_{n=1}^M \vert e_n\rangle \langle e_n\vert . Using`$ this projection, we restrict the joint multi-adic transfer operator $`B_2 \otimes B_3`$ to the diagonal. The restricted joint transfer operator $`B_{\text{diag}, M} = P_{\mathbb{Z}, M} (B_2 \otimes B_3) P_{\mathbb{Z}, M} acts on`$ the $M-dimensional$ subspace with matrix elements:

$$
(B_{\text{diag}, M})_{n, n'} = (B_2)_{n \pmod{2^d}, n' \pmod{2^d}} \cdot (B_3)_{n \pmod{3^k}, n' \pmod{3^k}}
$$

This formulation allows us to analyze how the Ramanujan spectral gaps of the local non-Archimedean transfer dynamics descend to regularize the 1D physical coordinates, bypassing the curse of dimensionality via a vectorized Hadamard product.

---

[← Back to Master Monograph Table of Contents](../unified_monograph.md)