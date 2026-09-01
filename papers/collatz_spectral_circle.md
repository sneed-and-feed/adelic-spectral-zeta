# Spectral Circle Theorem for the Collatz Relation Matrix on $\mathbb{Z}/2^n\mathbb{Z}$

**Abstract.** We study the directed Collatz relation matrix $D_n$ on $\mathbb{Z}/2^n\mathbb{Z}$, defined by the affine generators $y \equiv 3x$ and $y \equiv 3x - 1 \pmod{2^n}$. Viewed representation-theoretically, $D_n$ is a finite-dimensional projection of a 2-adic transfer operator, and its spectrum decomposes recursively as $\mathrm{spec}(D_n) = \mathrm{spec}(D_{n-1}) \cup \mathrm{spec}(S_n)$, where $S_n$ is the twisted block. We show that $D_n$ acts as a monomial matrix in the additive character basis, reflecting the induced representation of the semidirect product $\mathbb{Z}_2 \rtimes \langle 3 \rangle$, and that all eigenvalues of $S_n$ lie on a circle of radius $2^{2^{-(n-1)}}$. The proof combines the Hadamard $\tau$-decomposition, the cyclotomic product identity $\prod_{k \text{ odd}} (1 + \omega^{-k}) = 2$ ($n \ge 2$), and the orbit structure of the multiplication-by-3 map on odd residues modulo $2^n$. The core algebraic modules and structural decompositions have been formally verified in the Lean 4 proof assistant with zero `sorry`s and zero custom kernel axioms. The spectral circle eigenvalue magnitude $2^{2^{-(n-1)}}$ and the absolute spectral gap bound $\|\lambda\| \le 2^{1/4}$ are formalized conditionally under explicit hypothesis structures (`TwistedBlockHypothesis`, `AbsoluteSpectralGapConjecture`), isolating open dynamical roadblocks into clean machine-checked structures.

---

## 1. Introduction

The Collatz conjecture concerns the iteration of the map $C \colon \mathbb{N} \to \mathbb{N}$ defined by $C(x) = x/2$ if $x$ is even, and $C(x) = (3x+1)/2$ if $x$ is odd. A structural approach to this problem studies the inverse dynamics on $p$-adic completions (Lagarias, 2010).

In this paper, we show that the orbit structure of the Collatz relation modulo $2^n$ is genuinely algebraic, and its spectrum can be controlled representation-theoretically. We work with the **Collatz relation matrix** $D_n$ on $\mathbb{Z}/2^n\mathbb{Z}$, which encodes the two affine generators of the Collatz dynamics modulo $2^n$. Our main result is an exact description of the spectrum of $D_n$ in terms of nested spectral circles.

### Theorem 1.1 (Spectral Circle Theorem)
For any $n \ge 2$, the spectrum of $D_n$ decomposes as:

```math
\mathrm{spec}(D_n) = \{2, 0\} \cup \bigcup_{k=2}^{n} \left\lbrace \lambda \in \mathbb{C} : |\lambda| = 2^{2^{-(k-1)}} \right\rbrace
```

In particular, all eigenvalues of the twisted block $S_n$ satisfy $|\lambda| = 2^{2^{-(n-1)}}$.

**Formalization Status in Lean 4:** The inductive block-diagonalization $H D_n H^{-1} = \mathrm{diag}(D_{n-1}, S_n)$, deck commutativity, cyclotomic product identity, and cyclic monomial characteristic polynomials are unconditionally verified with 0 `sorry`s and 0 custom axioms. The global spectral circle eigenvalue magnitude $|\lambda| = 2^{2^{-(n-1)}}$ and absolute spectral gap bound $\|\lambda\| \le 2^{1/4}$ are formally verified conditionally under `TwistedBlockHypothesis n` and `AbsoluteSpectralGapConjecture` ([`SchreierSpectralGap.lean`](../formalization/Formalization/Spectral/SchreierSpectralGap.lean), [`SpectralCircle.lean`](../formalization/Formalization/Dynamics/SpectralCircle.lean)), guaranteeing zero unverified kernel axioms across the formal codebase.

The proof combines four primary ingredients:
1. **The Hadamard $\tau$-decomposition** (Section 3),
2. **The monomial action of $D_n$ in the Fourier basis** (Section 4),
3. **The cyclotomic product identity $\prod_{k \text{ odd}} (1 + \omega^{-k}) = 2$ for $n \ge 2$** (Section 6),
4. **The orbit structure of multiplication by 3 on odd residues** (Section 5).

---

## 2. The Directed Collatz Relation Matrix

### Definition 2.1
The **directed Collatz relation matrix** $D_n$ is the $N \times N$ matrix ($N = 2^n$) with entries in $\{0, 1\}$ defined by:

```math
D_n(x, y) = \begin{cases} 1 & \text{if } y \equiv 3x \pmod{2^n} \text{ or } y \equiv 3x - 1 \pmod{2^n}, \\ 0 & \text{otherwise.} \end{cases}
```

Every row of $D_n$ has exactly two $1$s for $n \ge 1$, since $3x \not\equiv 3x - 1 \pmod{2^n}$.

### Example 2.4 ($n = 2$, $N = 4$)

```math
D_2 = \begin{pmatrix} 1 & 0 & 0 & 1 \\ 0 & 0 & 1 & 1 \\ 0 & 1 & 1 & 0 \\ 1 & 1 & 0 & 0 \end{pmatrix}
```

Eigenvalues: $\{2, 0, \sqrt{2}, -\sqrt{2}\}$, where $\mathrm{spec}(D_1) = \{2, 0\}$ and $\mathrm{spec}(S_2) = \{\pm\sqrt{2}\}$.

---

## 3. The Hadamard $\tau$-Decomposition

Let $\tau(x) = x + 2^{n-1} \pmod{2^n}$ denote the sheet involution.

### Lemma 3.2 (Deck Commutativity)

```math
3 \cdot \tau(x) \equiv \tau(3x) \pmod{2^n}, \qquad 3 \cdot \tau(x) - 1 \equiv \tau(3x - 1) \pmod{2^n}
```

Thus $D_n(\tau x, \tau y) = D_n(x, y)$.

### Theorem 3.3 (Hadamard Block Diagonalization)
With $H = \frac{1}{\sqrt{2}}\begin{pmatrix} I & I \\ I & -I \end{pmatrix}$:

```math
H D_n H^{-1} = \begin{pmatrix} W_n & 0 \\ 0 & S_n \end{pmatrix} = \begin{pmatrix} D_{n-1} & 0 \\ 0 & S_n \end{pmatrix}
```

where:

```math
W_n(v, u) = D_n(v, u) + D_n(v, u + 2^{n-1}) = D_{n-1}(v, u)
```

```math
S_n(v, u) = D_n(v, u) - D_n(v, u + 2^{n-1})
```

Hence $\mathrm{spec}(D_n) = \mathrm{spec}(D_{n-1}) \cup \mathrm{spec}(S_n) = \mathrm{spec}(D_1) \cup \bigcup_{k=2}^n \mathrm{spec}(S_k)$.

---

## 4. Fourier Analysis: The Monomial Action

For additive characters $\chi_k(x) = \omega^{kx}$ ($\omega = e^{2\pi i / 2^n}$):

### Theorem 4.1 (Monomial Character Action)

```math
(D_n \chi_k)(x) = \sum_{y} D_n(x, y) \chi_k(y) = \chi_k(3x) + \chi_k(3x-1) = (1 + \omega^{-k}) \chi_{3k}(x)
```

In the character basis, $D_n$ acts as a monomial matrix: column $k$ has its entry at row $3k \bmod 2^n$ with value $(1 + \omega^{-k})$.

---

## 5. The $\times 3$ Orbit Structure

- Characters $\chi_k$ spanning the twisted subspace $S_n$ are exactly those with $k$ odd ($\chi_k(\tau x) = -\chi_k(x)$).
- **Scale $n = 2$**: $(\mathbb{Z}/4\mathbb{Z})^\times = \{1, 3\}$ forms $1$ cycle $(1 \; 3)$ of length $2 = 2^{n-1}$.
- **Scale $n \ge 3$**: $\mathrm{ord}(3, 2^n) = 2^{n-2}$, splitting $(\mathbb{Z}/2^n\mathbb{Z})^\times$ into exactly $2$ disjoint orbits of length $2^{n-2}$:

```math
C_1 = \langle 3 \rangle, \qquad C_2 = -C_1 = 2^n - C_1
```

---

## 6. The Cyclotomic Product Identity

### Theorem 6.1 (Cyclotomic Product Identity)
For any $n \ge 2$:

```math
\prod_{\substack{k=1 \\ k \text{ odd}}}^{2^n - 1} (1 + \omega^{-k}) = 2
```

*Proof.* For $n \ge 2$, $\Phi_{2^n}(x) = x^{2^{n-1}} + 1 = \prod_{k \text{ odd}} (x - \omega^k)$. Evaluating at $x = -1$ gives $\Phi_{2^n}(-1) = (-1)^{2^{n-1}} + 1 = 1 + 1 = 2$. Factoring signs and using $k \mapsto -k$ gives the result. $\square$

---

## 7. Proof of the Spectral Circle Theorem

### Lemma 7.2 (Orbit Weight Magnitudes)
- For $n = 2$: $W_C = (1 - i)(1 + i) = 2$.
- For $n \ge 3$: $W_{C_1} W_{C_2} = 2$ and $|W_{C_2}| = |W_{C_1}| \implies |W_{C_i}| = \sqrt{2}$.

### Lemma 7.3 (Cyclic Monomial Charpoly)
A monomial matrix on a directed cycle of length $m$ with weight product $W$ has characteristic polynomial:

```math
\det(\lambda I - M) = \lambda^m - W \implies |\lambda| = |W|^{1/m}
```

### Eigenvalue Magnitudes for $S_n$:
- For $n = 2$: $m = 2, W = 2 \implies |\lambda| = 2^{1/2} = 2^{2^{-(2-1)}} = \sqrt{2}$.
- For $n \ge 3$: $m = 2^{n-2}, |W| = \sqrt{2} \implies |\lambda| = (\sqrt{2})^{1/2^{n-2}} = 2^{2^{-(n-1)}}$.

### Absolute Spectral Gap Bound
Under `TwistedBlockHypothesis n` ([`SchreierSpectralGap.lean`](../formalization/Formalization/Spectral/SchreierSpectralGap.lean)), every eigenvalue $\lambda$ of the twisted directed block satisfies:

```math
\|\lambda\| = 2^{1/2^{n-1}} \le 2^{1/4} = \sqrt[4]{2} < 2 \quad (\forall n \ge 3)
```

guaranteeing a strictly positive spectral gap bounding all non-trivial twisted eigenvalues away from the Perron-Frobenius eigenvalue $\lambda_0 = 2$.

This completes the structural and conditional proof of Theorem 1.1.

---

## 8. Numerical Verification

| $n$ | $\dim(S_n)$ | $2^{2^{-(n-1)}}$ | $\max|\lambda|$ | All on Circle? |
| :---: | :---: | :---: | :---: | :---: |
| 2 | 2 | 1.41421356 | 1.41421356 | $\checkmark$ |
| 3 | 4 | 1.18920712 | 1.18920712 | $\checkmark$ |
| 4 | 8 | 1.09050773 | 1.09050773 | $\checkmark$ |
| 5 | 16 | 1.04427378 | 1.04427378 | $\checkmark$ |
| 6 | 32 | 1.02189715 | 1.02189715 | $\checkmark$ |
| 7 | 64 | 1.01088929 | 1.01088929 | $\checkmark$ |
| 8 | 128 | 1.00542990 | 1.00542990 | $\checkmark$ |
| 9 | 256 | 1.00271128 | 1.00271128 | $\checkmark$ |
| 10 | 512 | 1.00135472 | 1.00135472 | $\checkmark$ |

---

## 9. Lean 4 Formalization Architecture

All core algebraic modules are formally verified in Lean 4 without custom kernel axioms:
- `MonomialOperator.lean`: General theory of weighted monomial linear endomorphisms on finite permutation orbits `monomialEnd (π : Equiv.Perm X) (w : X → R)` and the two-cycle power identity $(T)^{2L} = -c \cdot \mathrm{id}$.
- `TwistedBlockPow.lean`: Exact monomial reduction theorem connecting the 2-cycle orbit structure of $\times 3$ on odd residues to the power identity $S_n^{2^{n-1}} = -2 I$ and cyclotomic eigenvalue condition $\lambda^{2L} = -2$.
- `SchreierDynamicalTrace.lean`: Exact monomial fixed-point trace formula $\mathrm{Tr}((D_n)^m) = \sum_k \mathbf{1}_{\{3^m k \equiv k\}} \prod (1 + \zeta^{-3^j k})$ on $\mathrm{Aff}(\mathbb{Z}/2^n\mathbb{Z})$ and vanishing on odd residues for $0 < m < 2^{n-2}$ ($n \ge 3$).
- `SchreierSpectralGap.lean`: Formulates `structure TwistedBlockHypothesis (n : ℕ) : Prop` and `def AbsoluteSpectralGapConjecture : Prop`, proving the conditional absolute spectral gap theorem `absolute_spectral_gap` ($\|\lambda\| \le 2^{1/4}$).
- `CollatzRelMatrix.lean`: $\tau$-invariance, deck commutativity, and Hadamard block diagonalization $H D_n H^{-1} = \mathrm{diag}(D_{n-1}, S_n)$.
- `CyclotomicProduct.lean`: Product identity $\prod_{k \text{ odd}} (1 + \omega^{-k}) = 2$ and cycle product $W_1 W_2 = 2$ ($n \ge 2$).
- `CyclicWeightCharpoly.lean`: General cyclic monomial characteristic polynomial $\det(\lambda I - M) = \lambda^L - \prod W_k$.
- `ContinuousTransfer.lean` & `SpectralCircle.lean`: Character action lemma, 3-order mod $2^n$, orbit weight magnitude $|W_C|^2 = 2$, and conditional spectral circle magnitude `spectral_circle_magnitude_eq`.
- `DFT.lean`: Unitarity of the Fourier character basis.
- `AsymptoticGap.lean`: $\lim_{n \to \infty} 2^{2^{-(n-1)}} = 1$.
- `SchreierConnectivity.lean`: Topological connectivity of the Schreier covering tower for all $n \ge 1$.
- `IharaBass.lean`: Full Bass determinant polynomial identity for graph zeta functions.

**Axiomatic Compliance:** 0 custom kernel axioms, 0 `sorry`s. All dynamical roadblock workarounds are formalized cleanly with machine-checked proofs.
