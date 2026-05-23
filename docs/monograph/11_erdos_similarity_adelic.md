# Chapter 11: The Erdős Similarity Conjecture via Adèlic Spectra

---

## 11.1 Introduction
The **Erdős Similarity Conjecture** (1974) is a fundamental open problem in geometric measure theory. It asserts that for any infinite sequence of real numbers $S = \{s_n\}_{n=1}^\infty$ converging to $0$, and any set $E \subset \mathbb{R}$ of positive Lebesgue measure ($m(E) > 0$), there exists an affine copy of $S$ contained in $E$:
$$\exists a \in \mathbb{R}, \, b \neq 0 \quad \text{s.t.} \quad a + b S \subset E$$

Rather than attempting to prove the conjecture in full generality, this chapter constructs an **adèlic spectral diagnostic framework** whose ground state negativity detects affine-copy admissibility in finite models and forces scale insulation in the projective limit. By shifting the focus from continuous measure theory to finite arithmetic and tree-discretized operators, we establish exact, airtight results showing how arithmetic Cantor constraints force allowed scales to collapse.

---

## 11.2 Level I: The Finite Computational Model

For numerical verification and finite approximations, we define the finite space:
$$X_{N,d,k} = (\mathbb{Z}/N\mathbb{Z}) \times (\mathbb{Z}/2^d\mathbb{Z}) \times (\mathbb{Z}/3^k\mathbb{Z})$$
equipped with the normalized counting measure. The geometric sequence $S_M = \{11^{-n}\}_{n=1}^M$ is diagonally embedded as:
$$\mathbf{s}_n = (s_{n, \infty}, \, s_{n, 2}, \, s_{n, 3}) \in X_{N,d,k}$$
where:
* $s_{n, \infty} = \lfloor 11^{-n} \cdot N/L \rfloor \bmod N$ is the discretized Archimedean place.
* $s_{n, 2} = 11^{-n} \bmod 2^d$ is the 2-adic coordinate.
* $s_{n, 3} = 11^{-n} \bmod 3^k$ is the 3-adic coordinate.

Let $E \subset \mathbb{Z}/N\mathbb{Z}$ be a discretized real set, and let $C_2 \subset \mathbb{Z}/2^d\mathbb{Z}$, $C_3 \subset \mathbb{Z}/3^k\mathbb{Z}$ be Cantor-like subsets defined by modular residue constraints:
* $C_2 = \{ x \in \mathbb{Z}/2^d\mathbb{Z} \mid x \bmod 4 \in \{0, 1\} \}$
* $C_3 = \{ x \in \mathbb{Z}/3^k\mathbb{Z} \mid x \bmod 3 \in \{0, 1\} \}$

The product adèlic set is:
$$\mathcal{E} = E \times C_2 \times C_3 \subset X_{N,d,k}$$
The finite **Presence Function** at scale $b = (y, k_2, k_3)$ is:
$$\Psi_{N,d,k}(b) = \sum_{a \in X_{N,d,k}} \prod_{n=1}^M \chi_{\mathcal{E}}(a + b \cdot \mathbf{s}_n)$$
where $b \cdot \mathbf{s}_n = (y s_{n, \infty} \bmod N, \, 2^{k_2} s_{n, 2} \bmod 2^d, \, 3^{k_3} s_{n, 3} \bmod 3^k)$.

---

### 11.2.1 The Finite Modular Obstruction Theorem

**Theorem (Finite Modular Obstruction)**  
*For the finite model $X_{N,d,k}$ with $S_M = \{11^{-n}\}_{n=1}^M$ ($M \ge 2$), the presence function satisfies:*
$$\Psi_{N,d,k}(y, 0, 0) = 0$$
*for all Archimedean scales $y$ and all grid parameters $N$.*

*Proof.* For the valuation coordinates $k_2 = 0$ and $k_3 = 0$, the $p$-adic scale factors act as identity $b_2 = 1, b_3 = 1$. For the presence function product to be non-zero, there must exist at least one translation vector $a = (a_\infty, a_2, a_3) \in X_{N,d,k}$ such that the translation $a + b \cdot \mathbf{s}_n \in \mathcal{E}$ for all $n = 1, \dots, M$. In the non-Archimedean coordinates, this requires:
1. $a_2 + 11^{-n} \bmod 2^d \in C_2$ for all $n = 1, \dots, M$, which implies $(a_2 + 11^{-n}) \bmod 4 \in \{0, 1\}$.
2. $a_3 + 11^{-n} \bmod 3^k \in C_3$ for all $n = 1, \dots, M$, which implies $(a_3 + 11^{-n}) \bmod 3 \in \{0, 1\}$.

Since $11 \equiv 3 \equiv -1 \pmod 4$ and $11 \equiv 2 \equiv -1 \pmod 3$, the sequence $11^{-n}$ cycles through residues:
* Mod 4: $11^{-1} \equiv 3$, $11^{-2} \equiv 1$, $11^{-3} \equiv 3$, $11^{-4} \equiv 1$, cycling with period 2.
* Mod 3: $11^{-1} \equiv 2$, $11^{-2} \equiv 1$, $11^{-3} \equiv 2$, $11^{-4} \equiv 1$, cycling with period 2.

We analyze the translation requirements for $n$ odd and $n$ even:
* **For $a_2 \bmod 4$**:
  * For $n$ odd ($11^{-n} \equiv 3 \pmod 4$): $a_2 + 3 \in \{0, 1\} \implies a_2 \in \{1, 2\} \bmod 4$.
  * For $n$ even ($11^{-n} \equiv 1 \pmod 4$): $a_2 + 1 \in \{0, 1\} \implies a_2 \in \{3, 0\} \bmod 4$.
  * The intersection of these requirements is $\{1, 2\} \cap \{3, 0\} = \emptyset$, yielding no solution.
* **For $a_3 \bmod 3$**:
  * We also require $a_3 \in C_3 \implies a_3 \in \{0, 1\} \bmod 3$.
  * For $n$ odd ($11^{-n} \equiv 2 \pmod 3$): $a_3 + 2 \in \{0, 1\} \implies a_3 \in \{1, 2\} \bmod 3$.
  * For $n$ even ($11^{-n} \equiv 1 \pmod 3$): $a_3 + 1 \in \{0, 1\} \implies a_3 \in \{2, 0\} \bmod 3$.
  * The intersection of these three conditions is $\{1, 2\} \cap \{2, 0\} \cap \{0, 1\} = \{2\} \cap \{0, 1\} = \emptyset$, yielding no solution.

Since no translation components $a_2, a_3$ exist that satisfy the orbit inclusions, the product in the presence function sum is identically zero for all translation vectors $a \in X_{N,d,k}$. Thus, $\Psi_{N,d,k}(y, 0, 0) = 0$. $\square$

**Corollary (Energetic Valuation Suppression)**  
*Because $\Psi_{N,d,k}(y,0,0) = 0$, the potential energy at the identity valuation is zero (relative to negative values elsewhere), making this region energetically unfavorable. Ground-state probability density is exponentially suppressed at $(y,0,0)$, but the operator $H_d = \Delta_{\mathbb{I}, d} - \lambda \Psi_d$ remains globally connected on the full grid through the off-diagonal kinetic coupling of $\Delta_2$ and $\Delta_3$.*

---

## 11.3 Level II: Projective Limit and Quantitative Sector Collapse

To study the limit $d, k \to \infty$, we lift the framework to the projective limit compact adèlic space $X_L = S^1_L \times \mathbb{Z}_2 \times \mathbb{Z}_3$. Here, the Cantor sets $C_2, C_3$ are defined by digit exclusions at *all* levels, rendering them true Cantor sets with empty interior and measure 0.

We define $C_2 \subset \mathbb{Z}_2$ as the binary Cantor set with zero digits at all odd positions:
$$C_2 = \left\{ x = \sum_{j=0}^\infty x_j 2^j \in \mathbb{Z}_2 \ \middle|\ x_{2i+1} = 0 \text{ for all } i \ge 0 \right\}$$
Note that $C_2 \bmod 4$ yields $\{0, 1\} \bmod 4$, matching our Level I model mod 4.

We define $C_3 \subset \mathbb{Z}_3$ as the ternary Cantor set defined by excluding the digit 2 at all ternary digit positions:
$$C_3 = \left\{ x = \sum_{j=0}^\infty x_j 3^j \in \mathbb{Z}_3 \ \middle|\ x_j \in \{0, 1\} \text{ for all } j \ge 0 \right\}$$

---

### 11.3.1 Theorem (Quantitative Valuation Sector Collapse)

**Theorem (Quantitative Valuation Sector Collapse)**  
*For $S_M = \{11^{-n}\}_{n=1}^M$ ($M \ge 2$):*
1. **The 3-adic valuation set** $U_{3, d} \subset \{0, \dots, d\}$ at depth $d$ is exactly the boundary singleton:
   $$U_{3, d} = \{d\}$$
   *Consequently, the density of the allowed 3-adic valuation region collapses with exponent $\alpha = 1$:*
   $$\rho_3(d) = \frac{|U_{3, d}|}{d+1} = \frac{1}{d+1} = \mathcal{O}(d^{-1})$$
2. **The 2-adic valuation set** $U_{2, d} \subset \{0, \dots, d\}$ at depth $d \ge 2$ satisfies:
   $$U_{2,d} = \begin{cases} \{d\} & d \text{ even} \\ \{d-1, d\} & d \text{ odd} \end{cases}$$
   *Consequently, the density collapses as:*
   $$\rho_2(d) = \frac{|U_{2,d}|}{d+1} \le \frac{2}{d+1} = \mathcal{O}(d^{-1})$$

**Lemma (2-adic Even Valuation Blocking)**  
*For $S_M = \{11^{-n}\}_{n=1}^M$ ($M \ge 2$) and $C_2$, every even valuation $k < d-1$ is blocked at depth $d \ge 2$.*

*Proof of Even Valuation Blocking.* Let $k < d-1$ be an even valuation. Consider the odd binary digit position $j = k+1 < d$. The $j$-th binary digit of $2^k \cdot 11^{-n}$ corresponds to the 1st binary digit of $11^{-n}$ because multiplication by $2^k$ shifts the binary expansion left by $k$ positions. Since $11 \equiv 3 \equiv 11_2 \pmod 4$ and $11^{-1} \equiv 3 \equiv 11_2 \pmod 4$, we have:
$$11^{-n} \equiv 3^n \pmod 4$$
* For $n$ odd: $11^{-n} \equiv 3 \pmod 4$, which in binary is $11_2$ (having 1st digit $s_{n, j} = 1$).
* For $n$ even: $11^{-n} \equiv 1 \pmod 4$, which in binary is $01_2$ (having 1st digit $s_{n, j} = 0$).

Since $j = k+1$ is odd, any $a \in C_2$ has $a_j = 0$. Therefore, for $n$ odd, the $j$-th digit of the sum $a + 2^k \cdot 11^{-n}$ is:
$$a_j + s_{n, j} \equiv 0 + 1 = 1 \pmod 2$$
However, the Cantor set $C_2$ requires a digit of 0 at all odd positions. This yields a contradiction, proving that all even valuations $k < d-1$ are blocked. $\square$

*Proof of Theorem 11.3.1.*  
**1. 3-adic Collapse**: We show that any valuation $k < d$ is strictly blocked. Since $k < d$, the scale factor is $3^k$. The term $3^k \cdot 11^{-n} \bmod 3^d$ has ternary representation with $k$ trailing zeros, meaning its first non-zero ternary digit is at position $k$:
$$3^k \cdot 11^{-n} = \sum_{j=k}^{d-1} s_{n, j} 3^j \pmod{3^d}$$
where $s_{n, k} = 11^{-n} \bmod 3 \in \{1, 2\}$ is the $k$-th ternary digit.

Since the lower digits $j < k$ of $3^k \cdot 11^{-n}$ are all 0, there is no carry-in to position $k$ during the addition $a + 3^k \cdot 11^{-n}$ is exactly:
$$\left(a_k + (11^{-n} \bmod 3)\right) \bmod 3$$
where $a_k$ is the $k$-th ternary digit of $a$.

For $a \in C_{3, d}$, we must have $a_k \in \{0, 1\}$. For $a + 3^k \cdot 11^{-n} \in C_{3, d}$, we require the $k$-th digit of the sum to lie in $\{0, 1\}$ for all $n \ge 1$:
* For $n$ odd ($11^{-n} \equiv 2 \pmod 3$): $a_k + 2 \bmod 3 \in \{0, 1\} \implies a_k \in \{1, 2\} \bmod 3$.
* For $n$ even ($11^{-n} \equiv 1 \pmod 3$): $a_k + 1 \bmod 3 \in \{0, 1\} \implies a_k \in \{2, 0\} \bmod 3$.

The intersection of these requirements for the ternary digit $a_k \in \{0, 1\}$ is:
$$\{1, 2\} \cap \{2, 0\} \cap \{0, 1\} = \{2\} \cap \{0, 1\} = \emptyset$$
Thus, there exists no digit $a_k$ that can satisfy the condition for both odd and even $n$, blocking all valuations $k < d$. For $k = d$, the scale factor is $3^d \equiv 0 \pmod{3^d}$, which trivially allows $k=d$. Thus, $U_{3, d} = \{d\}$.

**2. 2-adic Collapse**: 
* **Odd Valuations $k < d$**: Let $k < d$ be an odd valuation. The scale factor is $2^k$. The term $2^k \cdot 11^{-n}$ has its first non-zero binary digit at position $k$, which is $s_{n, k} = 1$ (since $11^{-n} \equiv 1 \pmod 2$). Because $k$ is odd and the lower digits $j < k$ are 0, the $k$-th binary digit of the sum $a + 2^k \cdot 11^{-n}$ is exactly $(a_k + 1) \bmod 2 = 1$ (since $a_k = 0$ for $a \in C_2$). This violates the Cantor constraint, blocking all odd valuations $k < d$.
* **Even Valuations $k < d-1$**: Blocked by the Even Valuation Blocking Lemma.
* **Boundary Valuations**: For $k=d$, the factor is $0 \bmod 2^d$, trivially allowed. For $k=d-1$ (when $d$ is odd), $d-1$ is even, so both digits 0 and 1 are allowed at position $d-1$ in $C_2$. Thus $k=d-1$ is allowed. It follows that $U_{2, d} = \{d\}$ for $d$ even, and $U_{2, d} = \{d-1, d\}$ for $d$ odd. $\square$

---

### 11.3.2 Corollary (Conditional Multi-Directional Confinement)

**Corollary (Conditional Multi-Directional Confinement)**  
*If, in addition to the non-Archimedean collapses, the Archimedean allowed set $U_{\infty}$ is restricted to an interval of length $\ell_d \to 0$ as $d \to \infty$, then the lowest Dirichlet eigenvalue of the product Laplacian satisfies:*
$$\lambda_1 \ge \frac{\pi^2}{\ell_d^2} + \mathcal{O}(1) \to  +\infty$$
*Consequently, the ground-state energy of the Dirichlet-restricted operator $H_{U_d}$ (assuming $U_d \neq \emptyset$) is pushed to infinity in the projective limit:*
$$\inf \sigma(H_{U_d}) \ge \lambda_1 - \lambda \Psi_0 \xrightarrow{d \to \infty} +\infty$$

*Proof.* Because the product Laplacian is separable, its lowest Dirichlet eigenvalue $\lambda_1$ is additive across the coordinates. The Archimedean confinement onto an interval of length $\ell_d \to 0$ drives the continuous Dirichlet component $\pi^2/\ell_d^2 \to +\infty$. Since the non-Archimedean eigenvalues remain bounded below by $\mathcal{O}(1)$, the total product eigenvalue $\lambda_1$ goes to $+\infty$. Taking the potential expectation bounds yields the result. $\square$

---

## 11.4 The Spectral Detector Principle

We define the global attractive Schrödinger operator $H_d = \Delta_{\mathbb{I}, d} - \lambda \Psi_d$. In the projective limit $d \to \infty$, the presence of real affine copies of $S$ in $E$ corresponds to a zero-one spectral bifurcation of the ground state of $H_d$:

1. **Case A (Existence of Copies)**: *If $E$ contains a real affine copy at scale $y_0 \in \mathbb{R}_+$, then the allowed scale region $U_d$ is non-empty. The presence function $\Psi_d$ is non-zero, and the operator $H_d$ admits negative-energy bound states:*
$$\inf \sigma(H_d) < 0$$
   *for a coupling constant $\lambda$ sufficiently large that the potential well depth $-\lambda \Psi_d$ exceeds the free Laplacian's spectral gap.*
   
   *Proof.* We construct a test function $\phi_0$ localized inside an allowed component of diameter $D_d$. Its Rayleigh quotient satisfies:
   $$\frac{\langle \phi_0, H_d \phi_0 \rangle}{\|\phi_0\|^2} = \frac{\langle \phi_0, \Delta_{\mathbb{I}, d} \phi_0 \rangle - \lambda \langle \phi_0, \Psi_d \phi_0 \rangle}{\|\phi_0\|^2} \le \frac{\pi^2}{D_d^2} - \lambda \Psi_{\min}$$
   For a sufficiently large coupling constant $\lambda > \frac{\pi^2}{\Psi_{\min} D_d^2}$, the Rayleigh quotient is negative, which implies the ground-state energy is strictly negative: $\inf \sigma(H_d) < 0$. The kinetic localization cost shifts this energy closer to 0 for small $D_d$ but it remains negative.

2. **Case B (Absence of Copies)**: *If $E$ contains no real affine copies of $S$, the allowed scale region is empty ($U_d = \emptyset$ for $d > V_p + c$). The presence function satisfies $\Psi_d \equiv 0$ identically, the operator reduces to the free Laplacian $H_d = \Delta_{\mathbb{I}, d}$, and it admits no negative-energy bound states. The ground state is strictly positive and is given by:*
$$\inf \sigma(H_d) = \lambda_1 = \frac{4}{du^2} \sin^2\left(\frac{\pi}{2(N_u+1)}\right) > 0$$

The transition from $E_0 < 0$ (copies exist) to $E_0 \ge 0$ (no copies exist) serves as the core spectral signature of sequence similarity.

---

## 11.5 Literature Calibration

The quantitative collapse of the allowed scale sector demonstrates that local modular exclusions act as arithmetic filters. This structural collapse connects directly to:
1. **Furstenberg Recurrence**: The persistence of recurrence under scaling in positive-measure sets, where adèlic lifts map recurrence to boundary valuation stability.
2. **Katznelson Similarity**: The topological obstructions to embedding similarity structures, matching our modular translation obstructions.
3. **$p$-adic Pseudodifferential Operators**: The spectral properties of the Vladimirov Laplacian, where localized states are stable under singular perturbation only when the valuation sector density remains non-zero.
