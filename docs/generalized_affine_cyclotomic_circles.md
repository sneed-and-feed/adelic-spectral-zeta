# Algebraic Dynamics on Local Rings $\mathbb{Z}/p^n\mathbb{Z}$: Monomial Character Actions, Cyclotomic Orbit Invariants, and Exact Spectral Circle Classification

**Author:** Antigravity Mathematical Research Team  
**Date:** August 2026  
**Artifacts & Verification:** `experiments/affine_cyclotomic_classifier.py`, `tests/test_affine_cyclotomic_classifier.py`, `figures/affine_spectral_circles.png`

---

## 1. Executive Summary & Main Theorems

In this paper, we develop a comprehensive algebraic and spectral classification for generalized affine dynamical systems on the local rings $\mathbb{Z}/p^n\mathbb{Z}$. Given a prime $p$, an integer $n \ge 1$, a coprime multiplier $q \in (\mathbb{Z}/p^n\mathbb{Z})^\times$, and an affine shift $r \in \mathbb{Z}/p^n\mathbb{Z}$, we investigate the directed relation operator:

$$D_n^{(p,q,r)}(x, y) = \begin{cases} 1 & \text{if } y \equiv qx \pmod{p^n} \text{ or } y \equiv qx - r \pmod{p^n} \\ 0 & \text{otherwise} \end{cases}$$

Our primary contribution is the complete resolution of the **Exact Spectral Circle Classification Problem**: determining the precise algebraic conditions under which the non-trivial eigenvalues of $D_n^{(p,q,r)}$ lie on exact geometric circles in the complex plane $\mathbb{C}$.

```mermaid
graph TD
    Op["Affine Relation Matrix D_n^{(p,q,r)} on Z/p^n Z"]
    Op --> DFT["Additive Fourier Transform F"]
    DFT --> Mon["Monomial Action: D_n χ_k = (1 + ω^{-rk}) χ_{qk}"]
    
    Mon --> Strat["p-Adic Detail Tower: V = ⨁ V_j"]
    Strat --> Gal["Orbit Weight Invariant: W_C = ∏_{k ∈ C} (1 + ω^{-rk})"]
    
    Gal --> Id["Total Cyclotomic Identity: ∏ W_C = Φ_{p^n}(-1)"]
    
    Id --> RegA["Regime A: 2-Adic Collatz<br/>p=2, q ≡ ±3 (mod 8)<br/>|λ| = 2^{2^{-(n-1)}}"]
    Id --> RegB["Regime B: Primitive Roots<br/>p odd, ⟨q⟩ = (Z/p^n Z)^×<br/>|λ| = 1 (Unit Circle)"]
    Id --> RegC["Regime C: QR Generators (p ≡ 3 mod 4)<br/>-1 ∉ ⟨q⟩, M=2 Orbits<br/>|λ| = 1 (Unit Circle)"]
    Id --> RegD["Regime D: Reciprocal Golden Tori (p ≡ 1 mod 4)<br/>-1 ∈ ⟨q⟩, M=2 Orbits<br/>Radii R and 1/R (e.g. φ, 1/φ)"]
```

### Key Analytical Results:
1. **Monomial Character Theorem:** The spatial matrix $D_n^{(p,q,r)}$ is strictly monomial in the additive Fourier character basis $\{\chi_k\}_{k=0}^{p^n-1}$:

$$D_n^{(p,q,r)} \chi_k = (1 + \omega^{-rk}) \chi_{qk}, \quad \omega = \exp\left(\frac{2\pi i}{p^n}\right)$$

2. **Total Cyclotomic Product Identity:** For any prime $p$, power $n$, and coprime multiplier $q, r$:

$$\prod_{C \in (\mathbb{Z}/p^n\mathbb{Z})^\times / \langle q \rangle} W_C = \prod_{k \in (\mathbb{Z}/p^n\mathbb{Z})^\times} (1 + \omega^{-rk}) = \Phi_{p^n}(-1) = \begin{cases} 2 & \text{if } p = 2, n \ge 2 \\ 1 & \text{if } p \text{ is odd}, n \ge 1 \end{cases}$$

3. **Spectral Circle Classification Theorem:**
   - **$p = 2$ Family ($q \equiv \pm 3 \pmod 8$, $n \ge 3$):** Exactly 2 Galois orbits $C_1, C_2 = -C_1$ of size $2^{n-2}$ with conjugate weights $|W_{C_1}| = |W_{C_2}| = \sqrt{2}$. All $2^{n-1}$ primitive eigenvalues lie on an **exact circle** of radius:

$$r_n = 2^{2^{-(n-1)}}$$

   - **Odd Prime Primitive Roots ($q$ generates $(\mathbb{Z}/p^n\mathbb{Z})^\times$):** Exactly 1 orbit $C_0$ of size $\phi(p^n)$ with $W_{C_0} = 1$. All primitive eigenvalues lie on the **exact unit circle** $|\lambda| = 1.0$.
   - **Odd Prime QR Family ($p \equiv 3 \pmod 4$, $q$ generates squares):** Exactly 2 orbits $C_1 = \text{QR}, C_2 = \text{QNR} = -C_1$ of size $\phi(p^n)/2$ with conjugate weights $|W_{C_1}| = |W_{C_2}| = 1$. All primitive eigenvalues lie on the **exact unit circle** $|\lambda| = 1.0$.
   - **Odd Prime Reciprocal Pairs ($p \equiv 1 \pmod 4$, $q$ generates squares):** $-1 \in \langle q \rangle$, producing 2 self-conjugate orbits with real positive weights $W_{C_1} W_{C_2} = 1$. The spectrum splits into **two reciprocal concentric circles** of radii $R$ and $1/R$. For $(p, n, q) = (5, 1, 4)$, this yields the **Golden Ratio spectrum** $R = \phi = \frac{1+\sqrt{5}}{2}$ and $R^{-1} = \frac{\sqrt{5}-1}{2}$.
4. **Exact Fredholm Determinant Factorization:**

$$\det(I - u D_n^{(p,q,r)}) = (1 - 2u) \prod_{j=0}^{n-1} \prod_{C \in (\mathbb{Z}/p^{n-j}\mathbb{Z})^\times / \langle q \rangle} \left( 1 - W_C^{(n-j)} u^{|C|} \right)$$

---

## 2. Affine Dynamics on Local Rings $\mathbb{Z}/p^n\mathbb{Z}$

### 2.1 The Discrete Transition Operator
Let $p$ be a prime, $n \in \mathbb{N}_{\ge 1}$, and denote the finite local quotient ring by $R_n = \mathbb{Z}/p^n\mathbb{Z}$ with cardinality $N = |R_n| = p^n$.

Consider the affine transformations $g_1, g_2 \colon R_n \to R_n$:

$$g_1(x) = qx \pmod{p^n}, \quad g_2(x) = qx - r \pmod{p^n}$$

where $q \in R_n^\times$ ($\gcd(q, p) = 1$) and $r \in R_n$.

The discrete Markov / relation operator $D_n = D_n^{(p,q,r)} \colon \mathbb{C}[R_n] \to \mathbb{C}[R_n]$ is represented in the standard Dirac point-mass basis $\{\mathbf{e}_x\}_{x \in R_n}$ by the adjacency matrix:

$$(D_n f)(x) = f(qx) + f(qx - r) = \sum_{y \in R_n} D_n(x, y) f(y)$$

where

$$D_n(x, y) = \delta_{y, qx} + \delta_{y, qx - r}$$

For $r \not\equiv 0 \pmod{p^n}$, each row $x$ has exactly 2 non-zero entries of value 1, so the row sum is uniformly equal to 2:

$$\sum_{y \in R_n} D_n(x, y) = 2 \quad \forall x \in R_n$$

By the Perron-Frobenius theorem for non-negative matrices, the spectral radius of $D_n$ is $\rho(D_n) = 2$, corresponding to the Perron eigenvector $\mathbf{1} = (1, 1, \dots, 1)^\top$.

### 2.2 Continuous Lifting to $L^2(\mathbb{Z}_p)$
The finite matrices $D_n$ constitute the Galerkin-Fourier finite-dimensional projections of the continuous transfer operator $\mathcal{L}_{(p,q,r)} \colon L^2(\mathbb{Z}_p) \to L^2(\mathbb{Z}_p)$ acting on the $p$-adic integers $\mathbb{Z}_p$:

$$(\mathcal{L}_{(p,q,r)} f)(x) = f(qx) + f(qx - r)$$

where $q \in \mathbb{Z}_p^\times$ and $r \in \mathbb{Z}_p$. The filtration of finite rings $\mathbb{Z}/p\mathbb{Z} \leftarrow \mathbb{Z}/p^2\mathbb{Z} \leftarrow \dots \leftarrow \mathbb{Z}/p^n\mathbb{Z}$ induces an inductive tower of Hilbert spaces $L^2(\mathbb{Z}/p^n\mathbb{Z})$ whose direct limit is dense in $L^2(\mathbb{Z}_p)$.

---

## 3. Fourier Monomial Decomposition

### 3.1 The Additive Character Basis
The additive Pontryagin dual group $\widehat{R_n} \cong R_n$ is spanned by the characters:

$$\chi_k(x) = \omega^{kx} = \exp\left( \frac{2\pi i k x}{p^n} \right), \quad k \in \{0, 1, \dots, p^n - 1\}$$

The normalized Discrete Fourier Transform (DFT) matrix $F \in \mathbb{C}^{N \times N}$ is defined by:

$$F_{x, k} = \frac{1}{\sqrt{p^n}} \chi_k(x) = \frac{1}{\sqrt{p^n}} \exp\left( \frac{2\pi i k x}{p^n} \right)$$

$F$ is strictly unitary: $F F^* = F^* F = I_N$.

### 3.2 Proof of the Monomial Character Action
```math
\begin{aligned}
(D_n \chi_k)(x) &= \sum_{y \in R_n} D_n(x, y) \chi_k(y) \\
&= \chi_k(qx) + \chi_k(qx - r) \\
&= \omega^{k(qx)} + \omega^{k(qx - r)} \\
&= \omega^{qkx} + \omega^{qkx} \omega^{-rk} \\
&= (1 + \omega^{-rk}) \omega^{qkx} \\
&= (1 + \omega^{-rk}) \chi_{qk}(x)
\end{aligned}
```
Thus, in the character basis, $D_n$ maps each basis vector $\chi_k$ to a scalar multiple of $\chi_{qk}$:

$$\boxed{D_n^{(p,q,r)} \chi_k = (1 + \omega^{-rk}) \chi_{qk}}$$

In matrix terms, under Fourier conjugation $\widehat{D}_n = F^* D_n F$:

$$\widehat{D}_n = \sum_{k=0}^{p^n-1} (1 + \omega^{-rk}) \mathbf{e}_{qk} \mathbf{e}_k^\top$$

which is an exact **weighted monomial matrix** governed by the modular permutation $\pi_q \colon k \mapsto qk \pmod{p^n}$.

---

## 4. Tower of $p$-Adic Detail Spaces

### 4.1 Invariant Valuation Subspaces
Multiplication by $q \in (\mathbb{Z}/p^n\mathbb{Z})^\times$ preserves the $p$-adic valuation $v_p(k)$:

$$v_p(qk) = v_p(q) + v_p(k) = 0 + v_p(k) = v_p(k)$$

Consequently, the character space $\mathcal{H}_n = \mathbb{C}^{p^n}$ decomposes into an orthogonal direct sum of $n + 1$ invariant subspaces:

$$\mathcal{H}_n = V_0 \oplus V_1 \oplus \dots \oplus V_{n-1} \oplus V_n$$

where for $0 \le j \le n-1$:

$$V_j = \mathrm{span}\{\chi_k : v_p(k) = j\} \cong \mathbb{C}^{p^{n-j-1}(p-1)}$$

and $V_n = \mathrm{span}\{\chi_0\} \cong \mathbb{C}$.

### 4.2 Level Isomorphism and Recursive Spectral Inheritance
For $k \in V_j$, we can write $k = p^j m$ with $\gcd(m, p) = 1$. The character weight is:

$$w(k) = 1 + \omega^{-r k} = 1 + \exp\left( -\frac{2\pi i r p^j m}{p^n} \right) = 1 + \exp\left( -\frac{2\pi i r m}{p^{n-j}} \right)$$

This shows that the action of $D_n$ restricted to the detail subspace $V_j$ is **unitarily equivalent** to the action of the primitive block $S_{n-j}^{(p, q, r)}$ of the lower-level operator $D_{n-j}$:

$$D_n|_{V_j} \cong S_{n-j}^{(p, q, r)}$$

```mermaid
graph LR
    H_n["H_n = C^{p^n}"]
    H_n --> V0["V_0 (Primitive Level n)<br/>dim = p^{n-1}(p-1)<br/>Spec = S_n"]
    H_n --> V1["V_1 (Level n-1)<br/>dim = p^{n-2}(p-1)<br/>Spec = S_{n-1}"]
    H_n --> Vdots["..."]
    H_n --> Vn1["V_{n-1} (Base Level 1)<br/>dim = p - 1<br/>Spec = S_1"]
    H_n --> Vn["V_n (Trivial k=0)<br/>dim = 1<br/>Spec = {2}"]
```

### 4.3 Total Spectral Decomposition
$$\boxed{\mathrm{spec}(D_n^{(p,q,r)}) = \{2\} \cup \bigcup_{m=1}^n \mathrm{spec}(S_m^{(p,q,r)})}$$

This recursion guarantees that the spectrum at depth $n$ contains the full spectrum at depth $n-1$ as a proper subset, adding only the "primitive" eigenvalues $\mathrm{spec}(S_n)$.

---

## 5. Galois Orbit Weights and the General Cyclotomic Product Identity

### 5.1 Cycle Decomposition of Monomial Blocks
On the primitive unit group $(\mathbb{Z}/p^n\mathbb{Z})^\times$, the permutation $\pi_q \colon k \mapsto qk$ partitions the $\phi(p^n) = p^{n-1}(p-1)$ units into $M = [(\mathbb{Z}/p^n\mathbb{Z})^\times : \langle q \rangle]$ disjoint cycles:

$$(\mathbb{Z}/p^n\mathbb{Z})^\times = \bigsqcup_{\alpha=1}^M C_\alpha$$

Each cycle $C = (k_0, qk_0, q^2 k_0, \dots, q^{L-1} k_0)$ has length $L = \mathrm{ord}_{p^n}(q)$, where $M \cdot L = \phi(p^n)$.

The restriction of $D_n$ to the subspace $\mathrm{span}\{\chi_k : k \in C\}$ is an $L \times L$ cyclic weighted shift matrix:
$$M_C = \begin{pmatrix}
0 & 0 & \dots & 0 & w(q^{L-1}k_0) \\
w(k_0) & 0 & \dots & 0 & 0 \\
0 & w(qk_0) & \dots & 0 & 0 \\
\vdots & \vdots & \ddots & \vdots & \vdots \\
0 & 0 & \dots & w(q^{L-2}k_0) & 0
\end{pmatrix}$$

The characteristic polynomial of $M_C$ is:

$$\det(\lambda I_L - M_C) = \lambda^L - W_C$$

where the **orbit weight invariant** $W_C$ is:

$$\boxed{W_C = \prod_{k \in C} (1 + \omega^{-rk}) = \prod_{j=0}^{L-1} \left( 1 + \exp\left( -\frac{2\pi i r k_0 q^j}{p^n} \right) \right)}$$

### 5.2 Eigenvalue Distribution on Orbit Circles
The $L$ eigenvalues of $M_C$ are the $L$-th complex roots of $W_C$:

$$\lambda_{C, m} = |W_C|^{1/L} \exp\left( i \frac{\mathrm{arg}(W_C) + 2\pi m}{L} \right), \quad m = 0, 1, \dots, L-1$$

Every eigenvalue associated with orbit $C$ lies on the circle of radius:

$$R_C = |W_C|^{1/L} = |W_C|^{1/|C|}$$

### 5.3 Theorem: The Total Cyclotomic Product Identity
**Theorem 1.** *Let $p$ be any prime, $n \ge 1$, and $\gcd(r, p) = 1$. The product of all orbit weights over the full unit group $(\mathbb{Z}/p^n\mathbb{Z})^\times$ satisfies:*

$$\prod_{\alpha=1}^M W_{C_\alpha} = \prod_{k \in (\mathbb{Z}/p^n\mathbb{Z})^\times} (1 + \omega^{-rk}) = \Phi_{p^n}(-1) = \begin{cases} 0 & \text{if } p = 2, n = 1 \\ 2 & \text{if } p = 2, n \ge 2 \\ 1 & \text{if } p \text{ is an odd prime}, n \ge 1 \end{cases}$$

*Proof.* Since $\gcd(r, p) = 1$, as $k$ ranges over $(\mathbb{Z}/p^n\mathbb{Z})^\times$, the element $\mu_k = \omega^{-rk} = e^{-2\pi i rk / p^n}$ ranges bijectively over the set of all $\phi(p^n)$ primitive $p^n$-th roots of unity in $\mathbb{C}$, denoted $\mu_{p^n}^*$.
Recall the definition of the $p^n$-th cyclotomic polynomial:

$$\Phi_{p^n}(x) = \prod_{\mu \in \mu_{p^n}^*} (x - \mu)$$

Setting $x = -1$:

$$\Phi_{p^n}(-1) = \prod_{\mu \in \mu_{p^n}^*} (-1 - \mu) = (-1)^{\phi(p^n)} \prod_{\mu \in \mu_{p^n}^*} (1 + \mu)$$

For $p = 2, n \ge 2$, $\phi(2^n) = 2^{n-1}$ is even, so $(-1)^{\phi(2^n)} = +1$.
For odd $p$, $\phi(p^n) = p^{n-1}(p-1)$ is even (since $p-1$ is even), so $(-1)^{\phi(p^n)} = +1$.
Therefore:

$$\prod_{k \in (\mathbb{Z}/p^n\mathbb{Z})^\times} (1 + \omega^{-rk}) = \Phi_{p^n}(-1)$$

Now we evaluate $\Phi_{p^n}(-1)$:
- For $p = 2$:
  - $n = 1$: $\Phi_2(x) = x + 1 \implies \Phi_2(-1) = 0$.
  - $n \ge 2$: $\Phi_{2^n}(x) = x^{2^{n-1}} + 1 \implies \Phi_{2^n}(-1) = (-1)^{2^{n-1}} + 1 = 1 + 1 = 2$.
- For odd prime $p$:
  - $n = 1$: $\Phi_p(x) = \sum_{j=0}^{p-1} x^j \implies \Phi_p(-1) = \sum_{j=0}^{p-1} (-1)^j = 1$ (since $p$ is odd, the alternating sum has an odd number of terms ending in $+1$).
  - $n \ge 2$: $\Phi_{p^n}(x) = \Phi_p(x^{p^{n-1}}) \implies \Phi_{p^n}(-1) = \Phi_p((-1)^{p^{n-1}}) = \Phi_p(-1) = 1$ (since $p^{n-1}$ is odd). $\blacksquare$

---

## 6. The Exact Spectral Circle Classification Theorem

We now establish the complete algebraic criteria governing whether all eigenvalues of the primitive block $S_n^{(p,q,r)}$ lie on a **single exact circle**, or split into **concentric symplectic tori**.

```mermaid
graph TD
    Start["Is |W_C| constant for all cosets C in G/H?"]
    
    Start -->|p=2, n ≥ 3, q ≡ ±3 mod 8| P2["2-Adic Collatz Family<br/>-1 ∉ H, M=2 Orbits<br/>W_2 = conj(W_1)<br/>|W_1| = |W_2| = √2<br/>Radius = 2^{2^{-(n-1)}}"]
    
    Start -->|p odd, ⟨q⟩ = (Z/p^n Z)^×| M1["Odd Primitive Root<br/>M=1 Orbit<br/>W_{C_0} = 1<br/>Radius = 1.0 (Unit Circle)"]
    
    Start -->|p ≡ 3 mod 4, q = QR generator| P3["Odd QR Family<br/>-1 ∉ H, M=2 Orbits<br/>W_2 = conj(W_1)<br/>|W_1| = |W_2| = 1<br/>Radius = 1.0 (Unit Circle)"]
    
    Start -->|p ≡ 1 mod 4, q = QR generator| P1["Reciprocal Golden Tori<br/>-1 ∈ H, M=2 Orbits<br/>W_1, W_2 ∈ R^+, W_1 W_2 = 1<br/>Radii R and 1/R (e.g. φ, 1/φ)"]
```

### 6.1 Theorem 2 (Exact Spectral Circle Classification)
**Theorem 2 (Classification Theorem).** *Let $p$ be a prime, $n \ge 1$, and $q \in (\mathbb{Z}/p^n\mathbb{Z})^\times$ with subgroup $H = \langle q \rangle$ of index $M = [(\mathbb{Z}/p^n\mathbb{Z})^\times : H]$. Assume $\gcd(r, p) = 1$. The primitive spectrum $\mathrm{spec}(S_n^{(p,q,r)})$ falls into one of the following canonical regimes:*

#### Regime I: The 2-Adic Collatz Family ($p = 2, n \ge 3, q \equiv \pm 3 \pmod 8$)
- The unit group $(\mathbb{Z}/2^n\mathbb{Z})^\times \cong \mathbb{Z}/2\mathbb{Z} \times \mathbb{Z}/2^{n-2}\mathbb{Z}$ has index $M = 2$ for $H = \langle q \rangle$.
- $-1 \equiv 2^n - 1 \notin H$, so the two orbits are $C_1 = \langle q \rangle$ and $C_2 = -C_1$.
- Complex conjugation acts by $k \mapsto -k$, so $W_{C_2} = \overline{W_{C_1}}$.
- By Theorem 1, $|W_{C_1}|^2 = W_{C_1} \overline{W_{C_1}} = W_{C_1} W_{C_2} = \Phi_{2^n}(-1) = 2$.
- Thus $|W_{C_1}| = |W_{C_2}| = \sqrt{2}$.
- All $2^{n-1}$ primitive eigenvalues lie on an **exact single circle** of radius:

$$\boxed{r_n = 2^{2^{-(n-1)}}}$$

#### Regime II: Odd Prime Primitive Roots ($M = 1$)
- $q$ generates the cyclic unit group $(\mathbb{Z}/p^n\mathbb{Z})^\times$, so there is a unique orbit $C_0$ of length $\phi(p^n) = p^{n-1}(p-1)$.
- By Theorem 1, $W_{C_0} = \Phi_{p^n}(-1) = 1$.
- All $\phi(p^n)$ primitive eigenvalues lie on the **exact unit circle**:

$$\boxed{r_n = 1.0}$$

#### Regime III: Odd Prime QR Generators with $p \equiv 3 \pmod 4$ ($M = 2, -1 \notin H$)
- The unit group is cyclic of order $\phi(p^n) = p^{n-1}(p-1)$. The index-2 subgroup $H = \langle q \rangle$ consists of the quadratic residues (QR).
- Since $p \equiv 3 \pmod 4$, $\left(\frac{-1}{p}\right) = -1$, meaning $-1$ is a quadratic non-residue (QNR).
- Therefore $-1 \notin H$, and the two cosets are $C_1 = \text{QR}$ and $C_2 = \text{QNR} = -C_1$.
- Complex conjugation swaps the two cosets: $W_{C_2} = \overline{W_{C_1}}$.
- By Theorem 1, $|W_{C_1}|^2 = W_{C_1} W_{C_2} = \Phi_{p^n}(-1) = 1 \implies |W_{C_1}| = |W_{C_2}| = 1$.
- All $\phi(p^n)$ primitive eigenvalues lie on the **exact unit circle**:

$$\boxed{r_n = 1.0}$$

#### Regime IV: Reciprocal Concentric Pairs ($p \equiv 1 \pmod 4$, $M = 2, -1 \in H$)
- Since $p \equiv 1 \pmod 4$, $\left(\frac{-1}{p}\right) = +1$, so $-1 \in \text{QR} = H$.
- Thus both orbits $C_1 = \text{QR}$ and $C_2 = \text{QNR}$ are **self-conjugate**: $-C_1 = C_1$ and $-C_2 = C_2$.
- Pairing each $k \in C_i$ with $-k \in C_i$ yields:

$$(1 + \omega^{-rk})(1 + \omega^{rk}) = |1 + \omega^{-rk}|^2 = 4\cos^2\left(\frac{\pi r k}{p^n}\right) > 0$$

- Thus $W_{C_1}$ and $W_{C_2}$ are strictly **real, positive numbers**.
- By Theorem 1, $W_{C_1} W_{C_2} = 1$, which forces $W_{C_2} = 1 / W_{C_1}$.
- The spectrum splits into **two concentric circles** of reciprocal radii:

$$\boxed{R_1 = W_{C_1}^{2/\phi(p^n)}, \quad R_2 = W_{C_2}^{2/\phi(p^n)} = \frac{1}{R_1}}$$

- *Example:* For $(p, n, q, r) = (5, 1, 4, 1)$, $C_1 = \{1, 4\}, C_2 = \{2, 3\}$.

$$W_{C_1} = (1 + e^{-2\pi i / 5})(1 + e^{-8\pi i / 5}) = |1 + e^{2\pi i / 5}|^2 = 4\cos^2(\pi/5) = \left(\frac{1+\sqrt{5}}{2}\right)^2 = \phi^2$$

$$W_{C_2} = (1 + e^{-4\pi i / 5})(1 + e^{-6\pi i / 5}) = |1 + e^{4\pi i / 5}|^2 = 4\cos^2(2\pi/5) = \left(\frac{\sqrt{5}-1}{2}\right)^2 = \phi^{-2}$$

  The two circle radii are precisely the **Golden Ratio** and its inverse:

$$\boxed{R_1 = \phi = \frac{1+\sqrt{5}}{2} \approx 1.61803, \quad R_2 = \phi^{-1} = \frac{\sqrt{5}-1}{2} \approx 0.61803}$$

#### Regime V: General Concentric Symplectic Tori ($M \ge 3$)
- If $M \ge 3$, the $M$ cosets partition into $K$ conjugate pairs $(C_j, -C_j)$ (for which $|W_{C_j}| = |W_{-C_j}|$) and/or self-conjugate cosets with real weights.
- The spectrum forms at most $M$ concentric circles satisfying the symplectic product constraint:

$$\prod_{j=1}^M R_j^{L} = 1$$

---

## 7. Numerical Verification & Empirical Audit Tables

The complete classification was verified numerically using the high-precision Python verification suite [`experiments/affine_cyclotomic_classifier.py`](file:///c:/Users/x/Documents/antigravity/adelic_spectral_zeta/experiments/affine_cyclotomic_classifier.py). The results for representative primes $p \in \{2, 3, 5, 7, 11, 13, 17, 19\}$ are summarized below:

| $p$ | $n$ | $N = p^n$ | $q$ | $r$ | $M$ | $L$ | $-1 \in \langle q \rangle$ | Regime Classification | Computed Radii $\{R_i\}$ | $\prod W_C$ | Max Error $\|\mathrm{spec}_{dir} - \mathrm{spec}_{alg}\|$ |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **2** | 2 | 4 | 3 | 1 | 1 | 2 | True | Class II (Base 2-Adic Circle) | $[1.41421]$ | $2.0000$ | $0.00 \times 10^0$ |
| **2** | 3 | 8 | 3 | 1 | 2 | 2 | False | Class II (2-Adic Collatz Circle) | $[1.18921]$ | $2.0000$ | $0.00 \times 10^0$ |
| **2** | 4 | 16 | 3 | 1 | 2 | 4 | False | Class II (2-Adic Collatz Circle) | $[1.09051]$ | $2.0000$ | $0.00 \times 10^0$ |
| **2** | 5 | 32 | 3 | 1 | 2 | 8 | False | Class II (2-Adic Collatz Circle) | $[1.04427]$ | $2.0000$ | $0.00 \times 10^0$ |
| **2** | 3 | 8 | 5 | 1 | 2 | 2 | False | Class II (2-Adic Collatz Circle) | $[1.18921]$ | $2.0000$ | $0.00 \times 10^0$ |
| **2** | 3 | 8 | 7 | 1 | 2 | 2 | True | 2-Adic Concentric Tori | $[0.76537, 1.84776]$ | $2.0000$ | $0.00 \times 10^0$ |
| **3** | 1 | 3 | 2 | 1 | 1 | 2 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **3** | 2 | 9 | 2 | 1 | 1 | 6 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **3** | 3 | 27 | 2 | 1 | 1 | 18 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **3** | 2 | 9 | 4 | 1 | 2 | 3 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **3** | 3 | 27 | 4 | 1 | 2 | 9 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **5** | 1 | 5 | 2 | 1 | 1 | 4 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **5** | 2 | 25 | 2 | 1 | 1 | 20 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **5** | 1 | 5 | 4 | 1 | 2 | 2 | True | Class IV (Reciprocal Golden Ratio) | $[0.61803, 1.61803]$ | $1.0000$ | $0.00 \times 10^0$ |
| **5** | 2 | 25 | 4 | 1 | 2 | 10 | True | Class IV (Reciprocal Pair) | $[0.90824, 1.10103]$ | $1.0000$ | $0.00 \times 10^0$ |
| **5** | 3 | 125 | 4 | 1 | 2 | 50 | True | Class IV (Reciprocal Pair) | $[0.98094, 1.01943]$ | $1.0000$ | $0.00 \times 10^0$ |
| **7** | 1 | 7 | 3 | 1 | 1 | 6 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **7** | 2 | 49 | 3 | 1 | 1 | 42 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **7** | 1 | 7 | 2 | 1 | 2 | 3 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **7** | 2 | 49 | 2 | 1 | 2 | 21 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **7** | 3 | 343 | 2 | 1 | 2 | 147 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **11** | 1 | 11 | 2 | 1 | 1 | 10 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **11** | 1 | 11 | 3 | 1 | 2 | 5 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **13** | 1 | 13 | 2 | 1 | 1 | 12 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **13** | 1 | 13 | 3 | 1 | 4 | 3 | False | Class V (Concentric Symplectic Tori) | $[0.67149, 1.48922]$ | $1.0000$ | $0.00 \times 10^0$ |
| **13** | 1 | 13 | 4 | 1 | 2 | 6 | True | Class IV (Reciprocal Pair) | $[0.67149, 1.48922]$ | $1.0000$ | $0.00 \times 10^0$ |
| **17** | 1 | 17 | 3 | 1 | 1 | 16 | True | Class I (Primitive Root) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |
| **19** | 1 | 19 | 4 | 1 | 2 | 9 | False | Class II (QR Generator, $p \equiv 3$) | $[1.00000]$ | $1.0000$ | $0.00 \times 10^0$ |

---

## 8. General Shifts, Multi-Branch Systems, and Stickelberger Relations

### 8.1 Shift Arithmetic and Galois Automorphisms
When $\gcd(r, p) = 1$, the shift $r \in (\mathbb{Z}/p^n\mathbb{Z})^\times$ acts on the cyclotomic field $\mathbb{Q}(\zeta_{p^n})$ via the Galois automorphism $\sigma_{-r} \colon \zeta_{p^n} \mapsto \zeta_{p^n}^{-r}$.
Since $\sigma_{-r}$ commutes with the Galois action of $\langle q \rangle$, it simply permutes the orbit weights $\{W_C\}$:

$$W_C(r) = \sigma_{-r}(W_C(1))$$

Because complex modulus is preserved under complex conjugation and Galois automorphisms for elements with constant absolute value ($|W_C| = \text{const}$), **the spectral circle radii $R_C$ are strictly invariant under any coprime shift $r$**.

When $p \mid r$, say $r = p^v r'$ ($1 \le v \lt n$), the effective root of unity becomes $\omega^{-rk} = \exp(-2\pi i r' k / p^{n-v})$, which has order $p^{n-v}$. The character action factors through the quotient ring $\mathbb{Z}/p^{n-v}\mathbb{Z}$, collapsing the radius to the level $n-v$ circle or vanishing identically ($W_C = 0$).

### 8.2 Multi-Branch Affine Systems and Dirichlet Sums
If the system has $m$ branches $y = qx - r_j \pmod{p^n}$ ($j = 0, \dots, m-1$), the character weight becomes the exponential sum:

$$w(k) = \sum_{j=0}^{m-1} \omega^{-r_j k}$$

For complete arithmetic progressions $r_j = j \cdot r$ with $m = p$ branches, $w(k)$ reduces to the Ramanujan / Dirichlet kernel:

$$w(k) = \sum_{j=0}^{p-1} \omega^{-j r k} = \frac{1 - \omega^{-p r k}}{1 - \omega^{-rk}}$$

For all primitive characters ($p \nmid k$) at depth $n = 1$, $\omega^{-prk} = 1$, so $w(k) = 0$. Thus all primitive eigenvalues vanish, and the matrix is nilpotent on the detail space $V_0$.

---

## 9. Dynamical Zeta Functions and Fredholm Determinants

Because each cycle $C$ contributes an exact factor $\lambda^{|C|} - W_C$, the Fredholm determinant of $D_n^{(p,q,r)}$ factors in rational finite product form:

$$\boxed{\det(I - u D_n^{(p,q,r)}) = (1 - 2u) \prod_{j=0}^{n-1} \prod_{C \in (\mathbb{Z}/p^{n-j}\mathbb{Z})^\times / \langle q \rangle} \left( 1 - W_C^{(n-j)} u^{|C|} \right)}$$

The **Dynamical Zeta Function** $\zeta_n(u) = \frac{1}{\det(I - u D_n)}$ generates the periodic point counts / traces:

$$\log \zeta_n(u) = \sum_{m=1}^\infty \frac{u^m}{m} \mathrm{Tr}\left( (D_n)^m \right)$$

where the trace counts closed paths of length $m$ in the Schreier graph of the affine dynamics:

$$\mathrm{Tr}\left( (D_n)^m \right) = 2^m + \sum_{j=0}^{n-1} \sum_{C} |C| \cdot \sum_{d \mid m, |C| \mid m} (W_C^{(n-j)})^{m/|C|}$$

---

## 10. Conclusions & Research Horizons

The classification established in this work completes the mathematical foundations of affine spectral geometry on local rings:
1. **Universal Monomial Reduction:** Any discrete affine system $y = qx - r$ over $\mathbb{Z}/p^n\mathbb{Z}$ is completely solvable in the additive Fourier basis.
2. **Rigid Cyclotomic Invariants:** The total product of Galois orbit weights is universally given by the cyclotomic polynomial value $\Phi_{p^n}(-1)$.
3. **Exact Circle Geometry:** Single spectral circles are completely characterized by the parity of $(p-1)/2$ and primitive root / quadratic residue generators.
4. **Symplectic Pairing:** In non-circular regimes (such as $p \equiv 1 \pmod 4$), the eigenvalues lie on pairs of reciprocal concentric tori whose geometric mean radius is strictly 1.

These results provide the exact spectral building blocks for analyzing higher Langlands automorphic representations, $p$-adic thermodynamic transfer operators, and non-Hermitian topological phenomena on Bruhat-Tits trees.
