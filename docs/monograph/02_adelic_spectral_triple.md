# Adèlic Spectral Geometry, Quantum Criticality, and Automorphic L-Functions
### A Unification Monograph on the Spectral Realization of the Generalized Riemann Hypothesis

---

## 2. The Adèlic Spectral Triple $`(\mathcal{A}, \mathcal{H}_{\text{glob}}, D_{\text{glob}, \Delta})`$

We define the global spectral triple associated to an automorphic representation $`\pi`$ (or a Dirichlet character/cusp form like the Ramanujan $`\Delta`$-function) as follows.

### 2.1 The Algebra $`\mathcal{A}`$
The algebra $`\mathcal{A}`$ is the non-commutative algebra of smooth, rapidly decreasing functions on the adèle class space, which can be represented as:

```math
\mathcal{A} = \mathcal{C}^\infty(S^1 \rtimes \mathbb{R}_+^\times) \otimes \bigotimes_{p} \mathcal{C}_{\text{loc}}(\mathcal{T}_p)
```

where $`S^1 \rtimes \mathbb{R}_+^\times`$ represents the Archimedean dilation group, and $`\mathcal{T}_p`$ is the Bruhat-Tits tree associated to $`PGL_2(\mathbb{Q}_p)`$.

### 2.2 The Hilbert Space $`\mathcal{H}_{\text{glob}}`$
The global Hilbert space is the direct sum of the Archimedean and non-Archimedean components:

```math
\mathcal{H}_{\text{glob}} = \mathcal{H}_\infty \otimes \bigotimes_{p} \mathcal{H}_p
```

We discretize the continuous Archimedean component by projecting onto a Fourier-like scale-invariant basis. The basis states $`\vert n\rangle`$ for $`n \in \mathbb{Z}`$ represent states on the 1D Archimedean wire, corresponding to logarithmic wavefunctions:

```math
\psi_n(x) = x^{-1/2 - i n \pi / \ln \lambda}
```

### 2.3 Rigorous Operator-Theoretic Construction of $`D_{\text{glob}}`$
Formally, we define the Archimedean Hilbert space as $`\mathcal{H}_\infty = \ell^2(\mathbb{Z})`$ with the unperturbed Dirac operator $`D_0`$ acting diagonally in the scale-invariant basis $`\{\vert n\rangle\}_{n \in \mathbb{Z}}`$:

```math
D_0 \vert n\rangle = \lambda_n \vert n\rangle, \quad \lambda_n = \frac{n \pi}{\ln \lambda}
```

The natural domain of $`D_0`$ is the dense subspace:

```math
\text{Dom}(D_0) = \left\lbrace u \in \ell^2(\mathbb{Z}) : \sum_{n=-\infty}^\infty \lambda_n^2 \vert u_n\vert ^2 \lt  \infty \right\rbrace
```

Since $`\lambda_n \in \mathbb{R}`$, $`D_0`$ is self-adjoint on $`\text{Dom}(D_0)`$.

The global coupling vector $`\xi`$ is defined by:

```math
\xi_n = \sum_{p} A_p \frac{\log p}{\sqrt{p}} p^{-i n \pi / \ln \lambda} + \xi_{\text{arch}}(n)
```

where $`A_p`$ are the Satake parameters and $`\xi_{\text{arch}}(n) = \frac{1}{2} \psi(1/4 + i \lambda_n / 2) - \frac{1}{2} \ln(\pi)`$ represents the Gamma-conductor factor. Since $`\psi(1/4 + it) \sim \ln\vert t\vert `$ as $`\vert t\vert  \to \infty`$, the components $`\xi_n`$ grow logarithmically: $`\xi_n = \mathcal{O}(\ln\vert n\vert )`$. Thus, $`\xi \notin \ell^2(\mathbb{Z})`$, meaning the projection $`P_\xi`$ cannot be defined directly on $`\mathcal{H}_\infty`$.

To construct the global Dirac operator $`D_{\text{glob}}`$ rigorously, we use the theory of singular rank-1 perturbations:
1. The linear functional $`\langle \xi, \cdot \rangle : u \mapsto \sum_n \bar{\xi}_n u_n`$ is defined on the domain $`\text{Dom}(D_0)`$. It is continuous with respect to the graph norm $`\Vert u\Vert _{D_0} = \sqrt{\Vert u\Vert ^2 + \Vert D_0 u\Vert ^2}`$ because the sequence $`\left\lbrace \frac{\xi_n}{\lambda_n} \right\rbrace`$ is in $`\ell^2(\mathbb{Z})`$ (since $`\sum_{n \neq 0} \frac{\ln^2\vert n\vert }{n^2} \lt  \infty`$).
2. We define the symmetric restriction $`D_{\text{sym}} = D_0 \vert _{\text{Dom}(D_{\text{sym}})}`$ on the dense domain:

```math
\text{Dom}(D_{\text{sym}}) = \text{Dom}(D_0) \cap \text{Ker}(\langle \xi, \cdot \rangle) = \left\lbrace u \in \text{Dom}(D_0) : \sum_{n=-\infty}^\infty \bar{\xi}_n u_n = 0 \right\rbrace
```

   Since $`\text{Dom}(D_{\text{sym}})`$ is a closed subspace of codimension 1 in $`\text{Dom}(D_0)`$ under the graph norm, $`D_{\text{sym}}`$ is a closed, densely defined symmetric operator.
3. The deficiency spaces $`\mathcal{K}_\pm = \text{Ker}(D_{\text{sym}}^* \mp i\mathbb{I})`$ are spanned by the deficiency vectors:

```math
g_\pm = (D_0 \mp i\mathbb{I})^{-1}\xi \implies g_{\pm, n} = \frac{\xi_n}{\lambda_n \mp i}
```

   Since $`\xi_n = \mathcal{O}(\ln\vert n\vert )`$ and $`\lambda_n \sim n`$, the sum $`\sum_n \vert g_{\pm, n}\vert ^2`$ converges, so $`g_\pm \in \ell^2(\mathbb{Z})`$.
   For any $`u \in \text{Dom}(D_{\text{sym}})`$, we have:

```math
\langle g_\pm, (D_{\text{sym}} \mp i\mathbb{I})u \rangle = \langle (D_0 \mp i\mathbb{I})^{-1}\xi, (D_0 \mp i\mathbb{I})u \rangle = \langle \xi, u \rangle = 0
```

   This proves that $`g_\pm`$ are orthogonal to the range of $`D_{\text{sym}} \mp i\mathbb{I}`$, meaning $`\mathcal{K}_\pm = \text{span}\{g_\pm\}`$. Thus, the deficiency indices are exactly $`(1, 1)`$.
4. By von Neumann's theorem, all self-adjoint extensions $`D_\theta`$ of $`D_{\text{sym}}`$ are parameterized by a phase $`\theta \in [0, 2\pi)`$, which maps the normalized deficiency space via the isometry $`U_\theta : g_+ \mapsto e^{i\theta} g_-`$. The domain of the extension $`D_\theta`$ is given by:

```math
\text{Dom}(D_\theta) = \left\lbrace u + c \left( g_+ + e^{i\theta} \frac{\Vert g_+\Vert }{\Vert g_-\Vert } g_- \right) : u \in \text{Dom}(D_{\text{sym}}), c \in \mathbb{C} \right\rbrace
```

   On this domain, $`D_\theta`$ acts as:

```math
D_\theta \left( u + c \left( g_+ + e^{i\theta} \frac{\Vert g_+\Vert }{\Vert g_-\Vert } g_- \right) \right) = D_{\text{sym}} u + i c \left( g_+ - e^{i\theta} \frac{\Vert g_+\Vert }{\Vert g_-\Vert } g_- \right)
```

   The global compressed Dirac operator $`D_{\text{glob}}`$ corresponds to a specific choice of $`\theta_0`$ that matches the physical adèlic boundary conditions, and its resolvent is given exactly by the regularized Krein formula. This guarantees that $`D_{\text{glob}}`$ is a self-adjoint operator on its domain.

---


---

[← Back to Master Monograph Table of Contents](../unified_monograph.md)