# Parity-Twisted Operator Relations, Commutator Kernels, and Spectral Triples for the 2-Adic Collatz Map

### Abstract
We present a formal operator-theoretic framework representing the Collatz $3x+1$ map on the ring of 2-adic integers $\mathbb{Z}_2$ via a parity-twisted translation relation. By mapping the dynamics to the Hilbert space $L^2(\mathbb{Z}_2, \mu_2)$, we show that the carry propagation of the additive $+1$ step is absorbed exactly into a parity-conditioned translation operator, yielding an exact operator identity. We relate this structure to a piecewise representation of the Baumslag-Solitar relation twisted by a parity-conditioned connection. We establish a classification theorem proving that this relation uniquely characterizes the Collatz family of maps on $\mathbb{Z}_2$. By equipping $\mathbb{Z}_2$ with a Pearson-Bellissard spectral triple and a Taibleson-Vladimirov Dirac operator, we prove the self-adjointness, compact resolvent, and bounded commutator properties, and derive an exact rank-1 formula for the commutator with the parity-switching connection. We show that the resulting commutator curvature converges asymptotically in finite truncations to a universal, scale-invariant limit of $1.0$. Furthermore, we prove that the finite-dimensional commutator has a kernel of dimension exactly $2^{d-1}+1$, and analyze the constraints this imposes on joint eigenfunctions. Finally, we discuss the mathematical and number-theoretic obstructions that prevent this local 2-adic representation from descending to the diagonal embedding of the rational integers.

---

### Introduction
The Collatz conjecture remains one of the most famous open problems in mathematics, posing deep questions about the structure of arithmetic and dynamical orbits. In this paper, we study the operator-theoretic and spectral aspects of the Collatz map over the 2-adic integers $\mathbb{Z}_2$ through the lens of noncommutative geometry. The two main results of this work are Theorem 2, which provides a complete algebraic classification of continuous maps satisfying the Collatz parity-twisted intertwining relation, and Theorem 5, which determines the exact dimension ($2^{d-1}+1$) of the finite-dimensional commutator kernel of the transfer operator.

---

## §1. Mathematical Formulation & Classification

Let $\mathbb{Z}_2 = \varprojlim \mathbb{Z}/2^d\mathbb{Z}$ be the ring of 2-adic integers. The shortcut Collatz map $T: \mathbb{Z}_2 \to \mathbb{Z}_2$ is defined by:

```math
T(x) = \frac{x}{2} P_0(x) + \frac{3x+1}{2} P_1(x)
```

where $P_0, P_1$ are the characteristic projection functions of the even and odd subsets:
- $P_0(x) = 1$ if $x \equiv 0 \pmod 2$, and $0$ otherwise.
- $P_1(x) = 1$ if $x \equiv 1 \pmod 2$, and $0$ otherwise.

Let $A: \mathbb{Z}_2 \to \mathbb{Z}_2$ be the translation map $A(x) = x+1$. Since $A^2(x) = x+2$, translation by 2 preserves the parity of any $x \in \mathbb{Z}_2$.

### Lemma 1: Pointwise Parity-Twisted Identity
*For all $x \in \mathbb{Z}_2$, the Collatz map $T$ and translation $A$ satisfy:*

```math
T(A^2(x)) = A(T(x)) P_0(x) + A^3(T(x)) P_1(x)
```

*Proof.* Since $P_0$ and $P_1$ partition $\mathbb{Z}_2$, we evaluate the relation on each sector:
1. **Even Sector ($P_0(x) = 1, P_1(x) = 0$):**
   Since $x$ is even, $x+2$ is also even. The LHS evaluates to:
   
```math
T(A^2(x)) = T(x+2) = \frac{x+2}{2} = \frac{x}{2} + 1 = T(x) + 1 = A(T(x))
```

   The RHS evaluates to:
   
```math
A(T(x)) \cdot 1 + A^3(T(x)) \cdot 0 = A(T(x))
```

2. **Odd Sector ($P_0(x) = 0, P_1(x) = 1$):**
   Since $x$ is odd, $x+2$ is also odd. The LHS evaluates to:
   
```math
T(A^2(x)) = T(x+2) = \frac{3(x+2)+1}{2} = \frac{3x+1}{2} + 3 = T(x) + 3 = A^3(T(x))
```

   The RHS evaluates to:
   
```math
A(T(x)) \cdot 0 + A^3(T(x)) \cdot 1 = A^3(T(x))
```

   In both cases, the LHS matches the RHS identically. $\square$

### Theorem 2: Classification of Parity-Intertwining Maps
*Let $T: \mathbb{Z}_2 \to \mathbb{Z}_2$ be a continuous map. Then $T$ satisfies the pointwise identity:*

```math
T(x+2) = T(x) + 1 \quad \text{if } x \equiv 0 \pmod 2
```

```math
T(x+2) = T(x) + 3 \quad \text{if } x \equiv 1 \pmod 2
```

*if and only if there exist constants $c_0, c_1 \in \mathbb{Z}_2$ such that:*

```math
T(x) = \frac{x}{2} + c_0 \quad \text{for even } x
```

```math
T(x) = \frac{3x + (2c_1 - 3)}{2} \quad \text{for odd } x
```

*In particular, the shortcut Collatz map is the unique such map satisfying the boundary conditions $T(0) = 0$ and $T(1) = 2$ (which correspond to $c_0 = 0$ and $c_1 = 2$).*

*Proof.* Let $T: \mathbb{Z}_2 \to \mathbb{Z}_2$ be a continuous map. We decompose $T$ into its even and odd components by defining $T_0, T_1: \mathbb{Z}_2 \to \mathbb{Z}_2$ via:

```math
T_0(y) = T(2y), \quad T_1(y) = T(2y+1) \quad \text{for } y \in \mathbb{Z}_2
```

If $x = 2y$ is even, the relation $T(x+2) = T(x) + 1$ implies:

```math
T(2y+2) = T(2y) + 1 \implies T_0(y+1) = T_0(y) + 1
```

Since $T$ is continuous, $T_0$ is continuous. The equation $T_0(y+1) = T_0(y) + 1$ holds for all $y \in \mathbb{Z}_2$. By induction, this holds for all $y \in \mathbb{N}$. Because the natural numbers $\mathbb{N}$ are dense in the 2-adic integers $\mathbb{Z}_2$ under the 2-adic metric, this recurrence extends uniquely to:

```math
T_0(y) = y + c_0
```

for some constant $c_0 \in \mathbb{Z}_2$. Thus, for even $x = 2y$, we have:

```math
T(x) = T_0(x/2) = \frac{x}{2} + c_0
```

If $x = 2y+1$ is odd, the relation $T(x+2) = T(x) + 3$ implies:

```math
T(2y+3) = T(2y+1) + 3 \implies T_1(y+1) = T_1(y) + 3
```

Again, by continuity and the density of $\mathbb{N}$ in $\mathbb{Z}_2$, this recurrence has the unique solution:

```math
T_1(y) = 3y + c_1
```

for some constant $c_1 \in \mathbb{Z}_2$. Thus, for odd $x = 2y+1$, we have:

```math
T(x) = T_1\left(\frac{x-1}{2}\right) = 3\left(\frac{x-1}{2}\right) + c_1 = \frac{3x - 3 + 2c_1}{2}
```

Comparing this to the shortcut Collatz map $T(x) = (3x+1)/2$ for odd $x$, we require $2c_1 - 3 = 1 \implies 2c_1 = 4 \implies c_1 = 2$. For even $x$, we require $T(x) = x/2 \implies c_0 = 0$. $\square$

---

## §2. Operator Representation & Group Relations

Let $\mathcal{H} = L^2(\mathbb{Z}_2, \mu_2)$ be the Hilbert space of square-integrable functions on $\mathbb{Z}_2$ with respect to the Haar measure $\mu_2$. The Ruelle-Perron-Frobenius transfer operator $B: \mathcal{H} \to \mathcal{H}$ associated to $T$ is the adjoint of the Koopman operator $U_T g = g \circ T$, defined by:

```math
(B f)(x) = \frac{1}{2} f(2x) + \frac{1}{2} f\left(3^{-1}(2x-1)\right)
```

Note that since $3$ is invertible in $\mathbb{Z}_2$, the term $3^{-1}(2x-1)$ is always a well-defined 2-adic integer. Furthermore, because $2x$ is even, $2x-1$ is odd, and the product of two odd 2-adic integers ($3^{-1}$ and $2x-1$) is always odd. Thus, the two preimage branches $T_0^{-1}(x) = 2x$ (even) and $T_1^{-1}(x) = 3^{-1}(2x-1)$ (odd) are always well-defined, and no extra indicator function is required.

Let $\mathbf{A}$ be the unitary translation operator on $\mathcal{H}$:

```math
(\mathbf{A} f)(x) = f(x-1)
```

and let $\mathbf{P}_0, \mathbf{P}_1$ be the orthogonal projection operators onto the even and odd subspaces:

```math
(\mathbf{P}_0 f)(x) = f(x) P_0(x), \quad (\mathbf{P}_1 f)(x) = f(x) P_1(x)
```

### Proposition 3: Operator Intertwining Relation
*The operators $B$, $\mathbf{A}$, $\mathbf{P}_0$, and $\mathbf{P}_1$ satisfy the exact commutation relation on $\mathcal{H}$:*

```math
B \mathbf{A}^2 = \mathbf{A} B \mathbf{P}_0 + \mathbf{A}^3 B \mathbf{P}_1
```

*Proof.* We prove the identity by showing that the inner product of both sides with an arbitrary test function $g \in \mathcal{H}$ is identical. By definition, the transfer operator $B$ is the adjoint of the Koopman operator $U_T$, so for any $f, g \in \mathcal{H}$:
```math
\langle B \mathbf{A}^2 f, g \rangle = \langle \mathbf{A}^2 f, g \circ T \rangle = \int_{\mathbb{Z}_2} f(x-2) g(T(x)) d\mu_2(x)
```
Performing the substitution $y = x-2$ (where $d\mu_2(y) = d\mu_2(x)$ by translation invariance of the Haar measure) yields:
```math
\langle B \mathbf{A}^2 f, g \rangle = \int_{\mathbb{Z}_2} f(y) g(T(y+2)) d\mu_2(y)
```
Since $\mathbf{P}_0$ and $\mathbf{P}_1$ partition $\mathbb{Z}_2$ into even and odd sectors, we can decompose the integral and apply the pointwise relation from Lemma 1 ($T(y+2) = T(y)+1$ for even $y$, and $T(y+2) = T(y)+3$ for odd $y$):
```math
\langle B \mathbf{A}^2 f, g \rangle = \int_{P_0} f(y) g(T(y)+1) d\mu_2(y) + \int_{P_1} f(y) g(T(y)+3) d\mu_2(y)
```
Using the definition of the projections $\mathbf{P}_0, \mathbf{P}_1$ and the translation operator $(\mathbf{A}^{-k}g)(z) = g(z+k)$, this becomes:
```math
\langle B \mathbf{A}^2 f, g \rangle = \int_{\mathbb{Z}_2} (\mathbf{P}_0 f)(y) (\mathbf{A}^{-1} g)(T(y)) d\mu_2(y) + \int_{\mathbb{Z}_2} (\mathbf{P}_1 f)(y) (\mathbf{A}^{-3} g)(T(y)) d\mu_2(y)
```
```math
\langle B \mathbf{A}^2 f, g \rangle = \langle B \mathbf{P}_0 f, \mathbf{A}^{-1} g \rangle + \langle B \mathbf{P}_1 f, \mathbf{A}^{-3} g \rangle
```
Since $\mathbf{A}$ is unitary, the adjoint of $\mathbf{A}^{-k}$ is $\mathbf{A}^k$. Thus:
```math
\langle B \mathbf{A}^2 f, g \rangle = \langle \mathbf{A} B \mathbf{P}_0 f, g \rangle + \langle \mathbf{A}^3 B \mathbf{P}_1 f, g \rangle = \langle (\mathbf{A} B \mathbf{P}_0 + \mathbf{A}^3 B \mathbf{P}_1) f, g \rangle
```
Since this holds for all $g \in \mathcal{H}$, the operator identity $B \mathbf{A}^2 = \mathbf{A} B \mathbf{P}_0 + \mathbf{A}^3 B \mathbf{P}_1$ holds exactly. $\square$

### 2.1 Parity-Twisted Baumslag-Solitar Relations
The Baumslag-Solitar group $BS(2,3)$ has the presentation:

```math
BS(2,3) = \langle a, b \mid a b^2 a^{-1} = b^3 \rangle
```

A unitary representation of $BS(2,3)$ can be constructed on the Hilbert space $L^2(\mathbb{Q}_2, \mu_2)$ over the 2-adic field $\mathbb{Q}_2$. Under the 2-adic Haar measure $\mu_2$, scaling by $k \in \mathbb{Q}_2$ changes the volume as $\mu_2(kE) = |k|_2 \mu_2(E)$. Since $|2/3|_2 = |2|_2/|3|_2 = 1/2$, the unitary scaling operator $a$ and its inverse $a^{-1}$ are defined as:

```math
(a f)(x) = \left|\frac{2}{3}\right|_2^{1/2} f\left(\frac{2}{3}x\right) = \frac{1}{\sqrt{2}} f\left(\frac{2}{3}x\right)
```

```math
(a^{-1} f)(x) = \left|\frac{3}{2}\right|_2^{1/2} f\left(\frac{3}{2}x\right) = \sqrt{2} f\left(\frac{3}{2}x\right)
```

Let $b = \mathbf{A}$ be the translation operator $(b f)(x) = f(x-1)$. We verify the group relation explicitly:

```math
(a b^2 a^{-1} f)(x) = \frac{1}{\sqrt{2}} (b^2 a^{-1} f)\left(\frac{2}{3}x\right) = \frac{1}{\sqrt{2}} (a^{-1} f)\left(\frac{2}{3}x - 2\right)
```

```math
= \frac{1}{\sqrt{2}} \sqrt{2} f\left(\frac{3}{2}\left(\frac{2}{3}x - 2\right)\right) = f(x-3) = (b^3 f)(x)
```

Thus $a b^2 a^{-1} = b^3$ holds exactly.

Under the Collatz map, the scaling factor is piecewise: it is 2 on the even sector, and $3/2$ on the odd sector. Thus, the transfer operator $B$ combines scaling by 2 (which satisfies the $BS(1,2)$ relation) and scaling by $3/2$ (which satisfies the $BS(2,3)$ relation). Rather than defining a strict group representation of $BS(2,3)$ (which is obstructed by the piecewise nature of the map), this relation is properly formalized as a representation of a **groupoid C\*-algebra** or the **C\*-crossed product** $\mathcal{A} \rtimes \mathbb{N}$ associated with the partial isometries generating the branches of the 2-adic tree. The operator relation:

```math
B \mathbf{A}^2 = (\mathbf{A} \mathbf{P}_0 + \mathbf{A}^3 \mathbf{P}_1) B
```

represents a **parity-twisted operator cocycle** of the Baumslag-Solitar relation. The projections $\mathbf{P}_0, \mathbf{P}_1$ branch the dynamics, forcing translation by $1$ in the even sector and translation by $3$ in the odd sector.

### 2.2 Noncommutative Geometry and the 2-Adic Spectral Triple
To formalize this metric structure, we employ Alain Connes' framework of Noncommutative Geometry [3] adapted to ultrametric spaces following Pearson and Bellissard [4]. We define a **spectral triple** $(\mathcal{A}, \mathcal{H}, D)$ where the commutative C\*-algebra is $\mathcal{A} = C(\mathbb{Z}_2)$ of continuous functions on $\mathbb{Z}_2$, the Hilbert space is $\mathcal{H} = L^2(\mathbb{Z}_2, \mu_2)$, and the Dirac operator $D$ is the Taibleson-Vladimirov fractional differentiation operator of order 1 on $\mathbb{Z}_2$ [8, 9]:

```math
(D f)(x) = \int_{\mathbb{Z}_2} \frac{f(x) - f(y)}{|x-y|_2^2} d\mu_2(y)
```

We establish the properties of this spectral triple rigorously below:

#### Proposition 4: Self-Adjointness and Domain of $D$
*The Taibleson-Vladimirov operator $D$ is a self-adjoint operator on the dense domain:*

```math
\text{Dom}(D) = \left\{ f \in L^2(\mathbb{Z}_2, \mu_2) \ \middle|\ \sum_{j=1}^\infty \lambda_j^2 \|P_j f\|^2 < \infty \right\}
```

*where $P_j$ is the orthogonal projection onto the $j$-th wavelet scale eigenspace, and $\lambda_j = \frac{3 \cdot 2^{j-1} - 1}{2}$.*

*Proof.* Let $\{ \psi_{j, k} \}$ be the orthonormal basis of Kozyrev wavelets (or Haar wavelets) on $\mathbb{Z}_2$. For each scale $j \ge 1$ and index $k \in \{1, \dots, 2^{j-1}\}$, the function $\psi_{j, k}$ is constant on balls of radius $2^{-j}$ and has mean zero on balls of radius $2^{-j+1}$.
For any wavelet $f = \psi_{j, k}$, we evaluate $D f(x)$ for $x$ in the support of $f$. We decompose the integration domain $\mathbb{Z}_2$ into concentric spheres $S_m(x) = \{y \in \mathbb{Z}_2 \mid |x-y|_2 = 2^{-m}\}$:
1. **For $m \ge j$ (so $|x-y|_2 \le 2^{-j}$):**
   The point $y$ lies in the same subball of radius $2^{-j}$ as $x$, where $f$ is constant. Thus, $f(y) = f(x)$ and $f(x) - f(y) = 0$.
2. **For $m = j-1$ (so $|x-y|_2 = 2^{-j+1}$):**
   The point $y$ lies in the sibling subball of radius $2^{-j}$ within the parent ball of radius $2^{-j+1}$. Since $f$ has mean zero on the parent ball and takes constant opposite values on the two sibling subballs, we have $f(y) = -f(x)$. Thus, $f(x) - f(y) = 2f(x)$.
3. **For $m < j-1$ (so $|x-y|_2 > 2^{-j+1}$):**
   The point $y$ lies outside the support ball of the wavelet $f$. Hence, $f(y) = 0$, giving $f(x) - f(y) = f(x)$.

Splitting the integral over these regions:
```math
(D f)(x) = \int_{S_{j-1}(x)} \frac{2f(x)}{|x-y|_2^2} d\mu_2(y) + \sum_{m=0}^{j-2} \int_{S_m(x)} \frac{f(x)}{|x-y|_2^2} d\mu_2(y)
```
On each sphere $S_m(x)$, the distance $|x-y|_2 = 2^{-m}$ is constant. Since the Haar measure of the sphere of radius $2^{-k}$ is $\mu_2(S_k(x)) = 2^{-k-1}$, we compute:
```math
(D f)(x) = 2^{2j-2} \cdot 2f(x) \mu_2(S_{j-1}(x)) + f(x) \sum_{m=0}^{j-2} 2^{2m} \mu_2(S_m(x))
```
```math
= 2^{2j-1} f(x) \cdot 2^{-j} + f(x) \sum_{m=0}^{j-2} 2^{2m} \cdot 2^{-m-1}
```
```math
= 2^{j-1} f(x) + \frac{1}{2} f(x) \sum_{m=0}^{j-2} 2^m = 2^{j-1} f(x) + \frac{2^{j-1} - 1}{2} f(x) = \frac{3 \cdot 2^{j-1} - 1}{2} f(x)
```
Thus, the wavelets of scale $j$ are eigenfunctions of $D$ with eigenvalues $\lambda_j = \frac{3 \cdot 2^{j-1} - 1}{2}$. The constant function $1$ has eigenvalue $\lambda_0 = 0$. Since $D$ is diagonalized by the orthonormal wavelet basis with real eigenvalues, it is self-adjoint on the domain of square-summable eigenvalue weights $\text{Dom}(D)$. $\square$

#### Proposition 5: Compact Resolvent Axiom
*The operator $D$ has a compact resolvent; specifically, $(D^2 + \mathbb{I})^{-1/2}$ is a compact operator.*

*Proof.* The eigenvalues of $(D^2 + \mathbb{I})^{-1/2}$ are given by $\mu_0 = 1$ (for the constant functions, multiplicity 1) and:
```math
\mu_j = \left( \frac{1}{4}(3 \cdot 2^{j-1} - 1)^2 + 1 \right)^{-1/2} \quad \text{for } j \ge 1
```
The eigenspace associated with scale $j \ge 1$ has dimension equal to the number of wavelets at that scale, which is $2^{j} - 2^{j-1} = 2^{j-1}$. Each eigenvalue has finite multiplicity, and:
```math
\lim_{j \to \infty} \mu_j = 0
```
Since $(D^2 + \mathbb{I})^{-1/2}$ is a diagonal operator with eigenvalues tending to zero and finite multiplicities, it is compact. $\square$

#### Proposition 6: Bounded Commutators Axiom
*For any locally constant function $f \in \mathcal{A}$, the commutator $[D, f]$ is a bounded (and indeed Hilbert-Schmidt) operator on $\mathcal{H}$.*

*Proof.* For any $g \in \text{Dom}(D)$, the action of the commutator is:
```math
([D, f]g)(x) = \int_{\mathbb{Z}_2} \frac{(f(x) - f(y)) g(y)}{|x-y|_2^2} d\mu_2(y)
```
Thus, $[D, f]$ is an integral operator with kernel $K(x, y) = \frac{f(x) - f(y)}{|x-y|_2^2}$. Since $f$ is locally constant on $\mathbb{Z}_2$, there exists a truncation depth $M$ such that $f(x) = f(y)$ whenever $|x-y|_2 \le 2^{-M}$. Consequently, the kernel $K(x, y) = 0$ for all $|x-y|_2 \le 2^{-M}$. 
For $|x-y|_2 > 2^{-M}$, the distance is bounded below, and the kernel is bounded:
```math
|K(x, y)| \le \frac{2 \|f\|_\infty}{2^{-2M}} = 2^{2M+1} \|f\|_\infty
```
The Hilbert-Schmidt norm of $[D, f]$ is:
```math
\|[D, f]\|_{HS}^2 = \iint_{\mathbb{Z}_2 \times \mathbb{Z}_2} |K(x, y)|^2 d\mu_2(x) d\mu_2(y) \le \iint_{|x-y|_2 > 2^{-M}} 4 \cdot 2^{4M} \|f\|_\infty^2 d\mu_2(x) d\mu_2(y) < \infty
```
Since the Hilbert-Schmidt norm is finite, $[D, f]$ is bounded. $\square$

By Pearson and Bellissard [4], the Connes metric distance:
```math
d_D(x, y) = \sup \{ |f(x) - f(y)| : f \in \mathcal{A}, \|[D, f]\| \le 1 \}
```
is equivalent to the standard 2-adic metric $|x-y|_2$.

#### Proposition 7: The Parity-Switching Connection Commutator
*Let $\omega$ be the parity-switching connection operator on $\mathcal{H}$ defined by:*
```math
\omega = \frac{1}{2} ( |1_0\rangle \langle 1_1| + |1_1\rangle \langle 1_0| )
```
*where $|1_0\rangle = \sqrt{2}\mathbf{P}_0 1$ and $|1_1\rangle = \sqrt{2}\mathbf{P}_1 1$ are the normalized indicators of the even and odd sectors. The commutator $[B, \omega]$ is exactly the rank-1 operator:*
```math
[B, \omega] = \frac{1}{2} |u\rangle \langle v|
```
*where $u(x) = (-1)^x$ is the parity function, and $v(y) = 1$ if $y \equiv 0, 1 \pmod 4$ and $-1$ if $y \equiv 2, 3 \pmod 4$.*

*Proof.* We evaluate the actions of $B\omega$ and $\omega B$:
- **1. Action of $B\omega$:**
  Recall that $|1_0\rangle = \sqrt{2}\mathbf{P}_0 \mathbf{1}$ and $|1_1\rangle = \sqrt{2}\mathbf{P}_1 \mathbf{1}$ are the normalized indicators of the even and odd sectors, where $\mathbf{1}$ is the constant 1 function (which is normalized, $\|\mathbf{1}\| = 1$).
  Evaluating the transfer operator $B$ on the normalized state $|1_0\rangle$:
  $$(B|1_0\rangle)(x) = \frac{1}{2} |1_0\rangle(2x) + \frac{1}{2} |1_0\rangle(3^{-1}(2x-1))$$
  Since $2x$ is even, $|1_0\rangle(2x) = \sqrt{2}$. Since $3^{-1}(2x-1)$ is odd, $|1_0\rangle(3^{-1}(2x-1)) = 0$.
  This yields $(B|1_0\rangle)(x) = \frac{\sqrt{2}}{2} = \frac{1}{\sqrt{2}}$ for all $x$. Thus, $B|1_0\rangle = \frac{1}{\sqrt{2}}|1\rangle$.
  Similarly, for $|1_1\rangle$:
  $$(B|1_1\rangle)(x) = \frac{1}{2} |1_1\rangle(2x) + \frac{1}{2} |1_1\rangle(3^{-1}(2x-1))$$
  Since $2x$ is even, $|1_1\rangle(2x) = 0$. Since $3^{-1}(2x-1)$ is odd, $|1_1\rangle(3^{-1}(2x-1)) = \sqrt{2}$.
  This yields $B|1_1\rangle = \frac{1}{\sqrt{2}}|1\rangle$.
  Substituting these into $B\omega$:
  $$B\omega = \frac{1}{2} ( |B 1_0\rangle \langle 1_1| + |B 1_1\rangle \langle 1_0| ) = \frac{1}{2} \left( \frac{1}{\sqrt{2}} |1\rangle \langle 1_1| + \frac{1}{\sqrt{2}} |1\rangle \langle 1_0| \right) = \frac{1}{2} |1\rangle \langle \frac{1}{\sqrt{2}}(1_1 + 1_0)|$$
  Since $\frac{1}{\sqrt{2}}(|1_0\rangle + |1_1\rangle) = \mathbf{P}_0 \mathbf{1} + \mathbf{P}_1 \mathbf{1} = |1\rangle$, we obtain:
  $$B\omega = \frac{1}{2} |1\rangle \langle 1|$$

- **2. Action of $\omega B$:**
  We evaluate $\langle 1_0, Bf \rangle$ and $\langle 1_1, Bf \rangle$ for any $f \in \mathcal{H}$ using the adjoint relation $\langle g, Bf \rangle = \langle B^\dagger g, f \rangle$, where $B^\dagger$ is the Koopman operator $(B^\dagger g)(y) = g(T(y))$.
  For the unnormalized indicator function of the even sector $\mathbf{1}_{even} = \mathbf{P}_0 \mathbf{1}$, its preimage under $T$ is the indicator of $\{y \in \mathbb{Z}_2 \mid T(y) \text{ even}\} = \{y \in \mathbb{Z}_2 \mid y \equiv 0, 1 \pmod 4\}$, which is $\mathbf{1}_{y \equiv 0, 1 \pmod 4}$. Thus:
  $$B^\dagger \mathbf{1}_{even} = \mathbf{1}_{y \equiv 0, 1 \pmod 4} = \frac{1+v}{2}$$
  where $v(y) = 1$ if $y \equiv 0, 1 \pmod 4$ and $-1$ if $y \equiv 2, 3 \pmod 4$.
  Since $|1_0\rangle = \sqrt{2} \mathbf{1}_{even}$, the adjoint action is:
  $$B^\dagger |1_0\rangle = \sqrt{2} B^\dagger \mathbf{1}_{even} = \sqrt{2} \mathbf{1}_{y \equiv 0, 1 \pmod 4} = \frac{1}{\sqrt{2}}(1+v)$$
  Taking the inner product:
  $$\langle 1_0, Bf \rangle = \langle B^\dagger 1_0, f \rangle = \int_{\mathbb{Z}_2} \sqrt{2} \mathbf{1}_{y \equiv 0, 1 \pmod 4}(y) f(y) d\mu_2(y) = \frac{1}{\sqrt{2}} \langle 1+v, f \rangle$$
  Similarly, for the odd sector, the preimage of $\mathbf{1}_{odd}$ under $T$ is $\mathbf{1}_{y \equiv 2, 3 \pmod 4} = \frac{1-v}{2}$. Thus, $B^\dagger |1_1\rangle = \sqrt{2} B^\dagger \mathbf{1}_{odd} = \frac{1}{\sqrt{2}}(1-v)$, and:
  $$\langle 1_1, Bf \rangle = \langle B^\dagger 1_1, f \rangle = \int_{\mathbb{Z}_2} \sqrt{2} \mathbf{1}_{y \equiv 2, 3 \pmod 4}(y) f(y) d\mu_2(y) = \frac{1}{\sqrt{2}} \langle 1-v, f \rangle$$
  Evaluating the operator action of $\omega B$ on a state $f$:
  $$\omega B |f\rangle = \frac{1}{2} |1_0\rangle \langle 1_1, Bf \rangle + \frac{1}{2} |1_1\rangle \langle 1_0, Bf \rangle$$
  $$= \frac{1}{2} |1_0\rangle \left( \frac{1}{\sqrt{2}} \langle 1-v, f \rangle \right) + \frac{1}{2} |1_1\rangle \left( \frac{1}{\sqrt{2}} \langle 1+v, f \rangle \right)$$
  Using $|1_0\rangle = \sqrt{2} \mathbf{P}_0 \mathbf{1}$ and $|1_1\rangle = \sqrt{2} \mathbf{P}_1 \mathbf{1}$, this simplifies to:
  $$\omega B = \frac{1}{2} |\mathbf{P}_0 \mathbf{1}\rangle \langle 1-v| + \frac{1}{2} |\mathbf{P}_1 \mathbf{1}\rangle \langle 1+v|$$

- **3. Subtracting the two terms yields:**
  Since $|1\rangle = |\mathbf{P}_0 \mathbf{1}\rangle + |\mathbf{P}_1 \mathbf{1}\rangle$, we expand $B\omega$:
  $$B\omega = \frac{1}{2} |\mathbf{P}_0 \mathbf{1}\rangle \langle 1| + \frac{1}{2} |\mathbf{P}_1 \mathbf{1}\rangle \langle 1|$$
  Thus:
  $$[B, \omega] = B\omega - \omega B = \frac{1}{2} |\mathbf{P}_0 \mathbf{1}\rangle ( \langle 1| - \langle 1-v| ) + \frac{1}{2} |\mathbf{P}_1 \mathbf{1}\rangle ( \langle 1| - \langle 1+v| )$$
  $$= \frac{1}{2} |\mathbf{P}_0 \mathbf{1}\rangle \langle v| - \frac{1}{2} |\mathbf{P}_1 \mathbf{1}\rangle \langle v| = \frac{1}{2} ( |\mathbf{P}_0 \mathbf{1}\rangle - |\mathbf{P}_1 \mathbf{1}\rangle ) \langle v|$$
  $$= \frac{1}{2} |u\rangle \langle v|$$
  where $u = \mathbf{P}_0 \mathbf{1} - \mathbf{P}_1 \mathbf{1}$ is the parity function $u(x) = (-1)^x$. This completes the proof. $\square$

---

## §3. Finite-Dimensional Truncation and the Boundary Defect

To execute numerical simulations on the finite cyclic ring $\mathbb{Z}/2^d\mathbb{Z}$, we choose how we project the operators onto the finite-dimensional Hilbert space $\mathcal{H}_d \cong \mathbb{C}^{2^d}$:

### 3.1 The Algebraic Modular Representation ($B_{\text{alg}}$)
We define the modular transfer operator using modular division by 2 and modular inversion of 3:

```math
(B_{\text{alg}} \psi)(x) = \frac{1}{2} \psi(2x \bmod 2^d) + \frac{1}{2} \psi((2x-1)3^{-1} \bmod 2^d)
```

Since $3$ is always coprime to $2^d$, it has a unique modular inverse $3^{-1} \in \mathbb{Z}/2^d\mathbb{Z}$. Under this representation, the ring homomorphism is exactly preserved at the boundary because modular addition and multiplication are closed in $\mathbb{Z}/2^d\mathbb{Z}$. Consequently, the relation has **exactly zero defect**:

```math
\| B_{\text{alg}} \mathbf{A}^2 - (\mathbf{A} B_{\text{alg}} \mathbf{P}_0 + \mathbf{A}^3 B_{\text{alg}} \mathbf{P}_1) \|_F = 0.00e+00 \quad \text{for all } d
```

### 3.2 The Numerical Representation ($B_{\text{num}}$)
We define the numerical transfer operator $B_{\text{num}}$ on $L^2(\mathbb{Z}/2^d\mathbb{Z})$ associated to the integer shortcut Collatz map:

```math
(B_{\text{num}} f)(x) = \frac{1}{2} \sum_{y \in T^{-1}(x)} f(y)
```

where $T^{-1}(x)$ is the set of preimages of $x$ under the classical integer shortcut Collatz map $T: \mathbb{Z} \to \mathbb{Z}$ defined by $T(y) = y/2$ for even $y$ and $T(y) = (3y+1)/2$ for odd $y$.

This models the actual physical arithmetic executed on standard computer hardware, where the modulus is treated as a subset $\{0, 1, \dots, 2^d-1\} \subset \mathbb{Z}$ with truncation. When $y \ge 2^{d+1}/3$, the value $3y+1$ exceeds $2^{d+1}$, and executing the integer division by 2 in $\mathbb{Z}$ before the modulo operation causes a boundary wrap-around mismatch of exactly one unit compared to modular division. This results in a constant Frobenius norm defect:

```math
\| B_{\text{num}} \mathbf{A}^2 - (\mathbf{A} B_{\text{num}} \mathbf{P}_0 + \mathbf{A}^3 B_{\text{num}} \mathbf{P}_1) \|_F = 2.00 \quad \text{for all } d
```

The non-zero entries of the defect matrix are strictly localized at:
- Row 0, Column $2^d-2$ (value $+1.0$)
- Row 2, Column $2^d-1$ (value $+1.0$)
- Row $2^{d-1}$, Column $2^d-2$ (value $-1.0$)
- Row $2^{d-1}+2$, Column $2^d-1$ (value $-1.0$)

The defect is exactly $2.00$ because the overflow mismatch occurs at exactly these four transitions, yielding four matrix elements of magnitude $1.0$ (whose squared sum is $4.0$, giving a Frobenius norm of $\sqrt{4} = 2.00$). Because this defect is localized at the boundary and does not grow with $d$, it forms a measure-zero boundary anomaly that vanishes in the infinite-volume limit $d \to \infty$.

---

## §4. Operator Commutator Scaling

The commutator $K_d = [\mathbf{A}_d, B_{\text{alg},d}] = \mathbf{A}_d B_{\text{alg},d} - B_{\text{alg},d} \mathbf{A}_d$ measures the operator curvature. We establish an exact closed-form expression for the normalized Frobenius norm of the commutator:

```math
\mathcal{C}(d) = \frac{\| \mathbf{A}_d B_{\text{alg},d} - B_{\text{alg},d} \mathbf{A}_d \|_F}{\sqrt{2^d}} = \sqrt{1 - 2^{1-d}}
```

*Proof of Curvature Scaling.* By evaluating the matrix entries, the action of the commutator $K_d$ on a vector $\psi$ is given by:
```math
(K_d \psi)(x) = \frac{1}{2} \left[ \psi(2x-2) - \psi(2x-1) + \psi((2x-3)3^{-1}) - \psi((2x-4)3^{-1}) \right]
```
For a given row $x \in \{0, \dots, 2^{d-1}-1\}$, the non-zero entries of Row $x$ are located at the columns:
- $c_1 = 2x-2 \pmod{2^d}$ (even, weight $+1/2$)
- $c_2 = 2x-1 \pmod{2^d}$ (odd, weight $-1/2$)
- $c_3 = (2x-3)3^{-1} \pmod{2^d}$ (odd, weight $+1/2$)
- $c_4 = (2x-4)3^{-1} \pmod{2^d}$ (even, weight $-1/2$)

These columns are always distinct modulo $2^d$, except for a single potential collision between $c_2$ and $c_3$:
```math
2x-1 \equiv (2x-3)3^{-1} \pmod{2^d} \implies 6x-3 \equiv 2x-3 \pmod{2^d} \implies 4x \equiv 0 \pmod{2^d}
```
In the range $x \in \{0, \dots, 2^{d-1}-1\}$, the equation $4x \equiv 0 \pmod{2^d}$ has exactly two solutions: $x=0$ and $x=2^{d-2}$.
- For these two degenerate rows, $c_2$ and $c_3$ coincide, and their coefficients cancel out: $(K_d)_{x, c_2} = -1/2 + 1/2 = 0$. The row contains only 2 non-zero elements ($c_1$ and $c_4$), each of magnitude $1/2$. The sum of squares for these rows is $(1/2)^2 + (-1/2)^2 = 1/2$.
- For all other $2^{d-1}-2$ rows, the four columns are distinct, so the sum of squares is $4 \times (1/2)^2 = 1$.

By the row symmetry of the commutator ($K_d$ has identical rows $x$ and $x + 2^{d-1}$), the total Frobenius norm squared of the commutator is:
```math
\| K_d \|_F^2 = 2 \sum_{x=0}^{2^{d-1}-1} \sum_{y=0}^{2^d-1} |(K_d)_{x,y}|^2 = 2 \left[ (2^{d-1}-2) \times 1 + 2 \times \frac{1}{2} \right] = 2^d - 2
```
Normalizing by the dimension $\sqrt{2^d}$ yields:
```math
\mathcal{C}(d) = \frac{\sqrt{2^d-2}}{\sqrt{2^d}} = \sqrt{1 - 2^{1-d}}
```
In the infinite-volume limit, we obtain the scaling limit exactly:
```math
\lim_{d \to \infty} \mathcal{C}(d) = 1.0000
```
$\square$

The normalized curvature converges to exactly $1.0$ from below:
- $d=3 \implies \mathcal{C} = \sqrt{3/4} \approx 0.8660$
- $d=6 \implies \mathcal{C} = \sqrt{31/32} \approx 0.9842$
- $d=10 \implies \mathcal{C} = \sqrt{511/512} \approx 0.9990$

---

## §5. Spectral Implications and Dynamical Consequences

The algebraic structure established in §1–§4 yields direct constraints on the spectral and dynamical behavior of the Collatz transfer operator.

### 5.1 Commutator Kernels & Joint Eigenfunctions
The non-vanishing commutator suggests that any joint eigenfunction of translation and $B$ (other than the constant function) must lie in the kernel of $[\mathbf{A}, B]$. In finite-dimensional truncations of dimension $2^d$, we state and prove the exact dimension of this commutator kernel:

### Theorem 8: Dimension of the Commutator Kernel
*Let $\mathbf{A}_d$ and $B_{\text{alg},d}$ be the finite-dimensional representations of the translation and algebraic transfer operators on $\mathcal{H}_d \cong \mathbb{C}^{2^d}$. The commutator $K_d = [\mathbf{A}_d, B_{\text{alg},d}] = \mathbf{A}_d B_{\text{alg},d} - B_{\text{alg},d} \mathbf{A}_d$ has a kernel of dimension exactly $2^{d-1}+1$ for all $d \geq 2$.*

*Proof.* We restrict our attention to $d \geq 2$. Let $\psi \in \mathbb{C}^{2^d}$. Modulo $2^d$, the action of the commutator $K_d$ is:
```math
(K_d \psi)(x) = \frac{1}{2} \left[ \psi(2x-2) - \psi(2x-1) + \psi((2x-3)3^{-1}) - \psi((2x-4)3^{-1}) \right]
```

**Step 1: Row Symmetry.**
Replacing $x$ with $x + 2^{d-1}$ in the commutator formula yields:
1. $2(x+2^{d-1}) - 2 \equiv 2x - 2 \pmod{2^d}$
2. $2(x+2^{d-1}) - 1 \equiv 2x - 1 \pmod{2^d}$
3. $(2(x+2^{d-1}) - 3)3^{-1} \equiv (2x-3)3^{-1} + 2^d 3^{-1} \equiv (2x-3)3^{-1} \pmod{2^d}$
4. $(2(x+2^{d-1}) - 4)3^{-1} \equiv (2x-4)3^{-1} + 2^d 3^{-1} \equiv (2x-4)3^{-1} \pmod{2^d}$
where we use the fact that $3^{-1}$ exists in $\mathbb{Z}/2^d\mathbb{Z}$, so $2^d 3^{-1} \equiv 0 \pmod{2^d}$. It follows that $(K_d \psi)(x + 2^{d-1}) = (K_d \psi)(x)$ for all $x$, meaning $K_d$ satisfies the row identity:
```math
\text{Row } x = \text{Row } (x + 2^{d-1}) \quad \text{for all } x \in \{0, \dots, 2^{d-1}-1\}
```
Consequently, the rank of $K_d$ is equal to the rank of the $2^{d-1} \times 2^d$ submatrix $M_d$ consisting of the first $2^{d-1}$ rows.

**Step 2: Column Sums.**
Both $\mathbf{A}_d$ and $B_{\text{alg},d}$ are column-stochastic matrices. Indeed, for $B_{\text{alg},d}$, the sum of column $y$ is:
- If $y$ is even, the equation $2x \equiv y \pmod{2^d}$ has exactly two solutions: $x_1 = y/2$ and $x_2 = y/2 + 2^{d-1}$. Both entries in $B_{\text{alg},d}$ are $1/2$, which sum to $1$.
- If $y$ is odd, the equation $(2x-1)3^{-1} \equiv y \pmod{2^d} \implies 2x \equiv 3y+1 \pmod{2^d}$ (which is even) has exactly two solutions: $x_1 = (3y+1)/2$ and $x_2 = (3y+1)/2 + 2^{d-1}$. Both entries in $B_{\text{alg},d}$ are $1/2$, which sum to $1$.

Since the product of column-stochastic matrices is column-stochastic, both $\mathbf{A}_d B_{\text{alg},d}$ and $B_{\text{alg},d} \mathbf{A}_d$ are column-stochastic. Thus, their difference $K_d$ has column sums that are all exactly zero, which implies:
```math
\sum_{x=0}^{2^d-1} \text{Row } x = \mathbf{0}
```
Using the row symmetry:
```math
\sum_{x=0}^{2^d-1} \text{Row } x = 2 \sum_{x=0}^{2^{d-1}-1} \text{Row } x = \mathbf{0} \implies \sum_{x=0}^{2^{d-1}-1} \text{Row } x = \mathbf{0}
```
This explicit linear relation among the $2^{d-1}$ rows of $M_d$ yields the upper bound:
```math
\text{rank}(K_d) \leq 2^{d-1} - 1
```

**Step 3: Graph-Theoretic Exact Rank.**
To prove the rank is exactly $2^{d-1}-1$, we show that the first $2^{d-1}-1$ rows of $M_d$ are linearly independent. 
Observe that each column $y$ in $2 M_d$ contains exactly two non-zero entries (one $+1$ and one $-1$):
- For an even column $y = 2k$, the entries are $+1$ at row $k+1 \pmod{2^{d-1}}$ and $-1$ at row $3k+2 \pmod{2^{d-1}}$.
- For an odd column $y = 2k+1$, the entries are $-1$ at row $k+1 \pmod{2^{d-1}}$ and $+1$ at row $3k+3 \pmod{2^{d-1}}$.

Thus, $2 M_d$ is the vertex-edge incidence matrix of a directed graph $G$ on $V = 2^{d-1}$ vertices. A standard theorem in graph theory states that the rank of the incidence matrix of a graph with $V$ vertices and $C$ connected components is exactly $V - C$.
The vertices of $G$ are $\mathbb{Z}/2^{d-1}\mathbb{Z}$, and the edges connect:
- $v \leftrightarrow 3v - 1 \pmod{2^{d-1}}$ (from even columns)
- $v \leftrightarrow 3v \pmod{2^{d-1}}$ (from odd columns)

We prove that the graph $G$ is connected ($C=1$) by induction on $d$:
- **Base Case**: For $d=2$, the graph $G$ has 2 vertices $\{0, 1\}$ with the edge $0 \sim 3(0)-1 \equiv 1 \pmod 2$. Thus, $G$ is connected.
- **Inductive Step**: Assume the graph $G_{d-1}$ at depth $d-1$ is connected for $d \geq 3$. Let $G_d$ denote the graph at depth $d$. Define the projection $\pi: G_d \to G_{d-1}$ by $\pi(x) = x \pmod{2^{d-2}}$. We show $G_d$ is connected by establishing the following properties:
  1. **Regular Covering Property**: The fiber of each vertex $v \in V(G_{d-1})$ under $\pi$ consists of exactly two vertices $\{v, v + 2^{d-2}\} \subset V(G_d)$. The deck transformation group is $\Gamma = \{id, \tau\} \cong \mathbb{Z}/2\mathbb{Z}$, generated by the involution $\tau(x) = x + 2^{d-2} \pmod{2^{d-1}}$. The map $\tau$ is a graph automorphism of $G_d$ because it preserves the types of all directed edges. To verify this, we write the adjacency operator $A_{G_d}$ on $L^2(G_d)$ as a sum of four transition operators $A_{G_d} = T_1 + T_2 + T_3 + T_4$, where:
     - $(T_1 f)(x) = f(3x \bmod 2^{d-1})$
     - $(T_2 f)(x) = f((3x-1) \bmod 2^{d-1})$
     - $(T_3 f)(x) = f(3^{-1}x \bmod 2^{d-1})$
     - $(T_4 f)(x) = f(3^{-1}(x+1) \bmod 2^{d-1})$
     
     We verify that $\tau$ commutes with each transition operator $T_i$ on $L^2(G_d)$:
     - **For $T_1$**: 
       $$T_1(\tau f)(x) = (\tau f)(3x) = f(3x + 2^{d-2})$$
       $$\tau(T_1 f)(x) = (T_1 f)(x + 2^{d-2}) = f(3(x + 2^{d-2})) = f(3x + 3 \cdot 2^{d-2}) = f(3x + 2^{d-2} + 2^{d-1}) \equiv f(3x + 2^{d-2}) \pmod{2^{d-1}}$$
       Thus, $T_1 \tau = \tau T_1$.
     - **For $T_2$**:
       $$T_2(\tau f)(x) = (\tau f)(3x-1) = f(3x - 1 + 2^{d-2})$$
       $$\tau(T_2 f)(x) = (T_2 f)(x + 2^{d-2}) = f(3(x + 2^{d-2}) - 1) = f(3x - 1 + 3 \cdot 2^{d-2}) \equiv f(3x - 1 + 2^{d-2}) \pmod{2^{d-1}}$$
       Thus, $T_2 \tau = \tau T_2$.
     - **For $T_3$**: Let $3^{-1} = 2k+1$ modulo $2^{d-1}$. Then $3^{-1} 2^{d-2} = (2k+1) 2^{d-2} = k 2^{d-1} + 2^{d-2} \equiv 2^{d-2} \pmod{2^{d-1}}$.
       $$T_3(\tau f)(x) = (\tau f)(3^{-1}x) = f(3^{-1}x + 2^{d-2})$$
       $$\tau(T_3 f)(x) = (T_3 f)(x + 2^{d-2}) = f(3^{-1}(x + 2^{d-2})) = f(3^{-1}x + 3^{-1} 2^{d-2}) \equiv f(3^{-1}x + 2^{d-2}) \pmod{2^{d-1}}$$
       Thus, $T_3 \tau = \tau T_3$.
     - **For $T_4$**:
       $$T_4(\tau f)(x) = (\tau f)(3^{-1}(x+1)) = f(3^{-1}(x+1) + 2^{d-2})$$
       $$\tau(T_4 f)(x) = (T_4 f)(x + 2^{d-2}) = f(3^{-1}(x + 2^{d-2} + 1)) = f(3^{-1}(x+1) + 3^{-1} 2^{d-2}) \equiv f(3^{-1}(x+1) + 2^{d-2}) \pmod{2^{d-1}}$$
       Thus, $T_4 \tau = \tau T_4$.
       
     Since $\tau$ commutes with all $T_i$, it commutes with $A_{G_d}$. The group $\Gamma = \{id, \tau\}$ acts freely on $V(G_d)$ because $x + 2^{d-2} \equiv x \pmod{2^{d-1}}$ would imply $2^{d-2} \equiv 0 \pmod{2^{d-1}}$, which is impossible since $2^{d-1} > 2^{d-2}$ for all $d \geq 3$. Since $\Gamma$ acts freely and by graph automorphisms, and its orbits are precisely the fibers of $\pi$, the projection $\pi: G_d \to G_{d-1}$ is a regular 2-fold graph covering.
  2. **Local Neighborhood Isomorphism**: To verify that the covering projection $\pi$ is locally bijective on edges, we define $G_d$ as a 4-regular multigraph with labeled edges of types 1, 2, 3, and 4. For any vertex $x \in V_d$, the incident edges of types 1, 2, 3, and 4 connect $x$ to $3x$, $3x-1$, $3^{-1}x$, and $3^{-1}(x+1) \pmod{2^{d-1}}$. Under the projection $\pi$, these targets map to:
     - $\pi(3x) = 3\pi(x) \pmod{2^{d-2}}$
     - $\pi(3x-1) = 3\pi(x)-1 \pmod{2^{d-2}}$
     - $\pi(3^{-1}x) = 3^{-1}\pi(x) \pmod{2^{d-2}}$
     - $\pi(3^{-1}(x+1)) = 3^{-1}(\pi(x)+1) \pmod{2^{d-2}}$
     which are precisely the target vertices of the four labeled edges incident to $\pi(x)$ in $G_{d-1}$. This defines a bijection between the sets of directed edges incident to $x$ in $G_d$ and those incident to $\pi(x)$ in $G_{d-1}$.
  3. **Nontrivial Loop Lifting (Monodromy)**: In $G_{d-1}$, the vertex $y = 2^{d-3} \in \mathbb{Z}/2^{d-2}\mathbb{Z}$ has a loop (a self-connecting edge of type 1) because $3y = 3 \cdot 2^{d-3} = 2^{d-3} + 2^{d-2} \equiv 2^{d-3} \pmod{2^{d-2}}$. The fiber of $y$ in $G_d$ consists of $y_1 = 2^{d-3}$ and $y_2 = 2^{d-3} + 2^{d-2}$. In $G_d$, evaluating the type-1 edge at $x = y_1$ gives:
     $$
     3 y_1 = 3 \cdot 2^{d-3} = 2^{d-3} + 2^{d-2} = y_2 \pmod{2^{d-1}}
     $$
     Thus, the loop at $y$ in $G_{d-1}$ lifts to the vertical edge $\{2^{d-3}, 2^{d-3} + 2^{d-2}\}$ in $G_d$, which connects the two sheets of the covering.
  4. **Connectivity of the Cover**: For any $u, w \in V(G_d)$, we lift paths from $\pi(u)$ and $\pi(w)$ to $y$ in $G_{d-1}$. The lifts end at either $y_1$ or $y_2$. Since the vertical edge $\{y_1, y_2\}$ connects the two sheets, $u$ and $w$ are connected in $G_d$. Since $u, w$ were arbitrary, $G_d$ is connected.
Thus, $G$ is connected ($C = 1$), which guarantees:
```math
\text{rank}(K_d) = \text{rank}(M_d) = V - 1 = 2^{d-1} - 1
```
By the Rank-Nullity Theorem:
```math
\dim(\ker(K_d)) = 2^d - \text{rank}(K_d) = 2^d - (2^{d-1} - 1) = 2^{d-1} + 1
```
This completes the proof. $\square$

Table 1 displays the numerical verification of this kernel dimension across different truncation depths $d$. In the numerical computation, the kernel dimension is computed via Singular Value Decomposition (SVD) by counting the number of singular values of $K_d$ below a threshold of $10^{-10}$. We emphasize that Table 1 is presented as empirical confirmation of the exact dimension, which is established rigorously by the algebraic proof of Theorem 8, rather than as a proof of the claim.

**Table 1:** Numerical verification of the commutator rank and kernel dimension.
| Depth $d$ | Dimension $2^d$ | Commutator Rank | Kernel Dimension $\dim(\ker(K_d))$ | Formula $2^{d-1}+1$ |
| :--- | :--- | :--- | :--- | :--- |
| 3 | 8 | 3 | 5 | $2^2 + 1 = 5$ |
| 4 | 16 | 7 | 9 | $2^3 + 1 = 9$ |
| 5 | 32 | 15 | 17 | $2^4 + 1 = 17$ |
| 6 | 64 | 31 | 33 | $2^5 + 1 = 33$ |
| 7 | 128 | 63 | 65 | $2^6 + 1 = 65$ |
| 8 | 256 | 127 | 129 | $2^7 + 1 = 129$ |
| 9 | 512 | 255 | 257 | $2^8 + 1 = 257$ |

However, any global $L^2(\mathbb{Z}_2)$ joint eigenfunction of translation and $B$ must lie in the projective limit intersection of these kernels, $\bigcap_d \ker(K_d)$. Whether this intersection contains any non-constant functions remains an open question (see §7). The asymptotic curvature $\mathcal{C}_\infty = 1$ provides evidence that the joint spectral space is highly constrained.

---

## §6. Limitations and Challenges in Extending to Global Dynamics

The central question in Collatz dynamics is: **How does the global behavior of trajectories on the rational integers $\mathbb{Z}^+$ descend from the local behavior on the completions?** The completions of $\mathbb{Q}$ are the 2-adic integers $\mathbb{Z}_2$, the 3-adic integers $\mathbb{Z}_3$, and the Archimedean field $\mathbb{R}$. The rational integers embed diagonally:

```math
\mathbb{Z} \hookrightarrow \mathbb{R} \times \mathbb{Q}_2 \times \mathbb{Q}_3
```

For a global proof of the Collatz conjecture, any local operator structure on $\mathbb{Z}_2$ must be compatible with the diagonal embedding. We identify three distinct compatibility obstructions that present significant challenges to such an extension, and frame these as conceptual open areas rather than completed results:

### 6.1 The 3-Adic Scale-Inversion Conflict
The 2-adic relation $B \mathbf{A}^2 = (\mathbf{A} \mathbf{P}_0 + \mathbf{A}^3 \mathbf{P}_1) B$ holds on $L^2(\mathbb{Z}_2)$ because $3$ is invertible in $\mathbb{Z}_2$. However, when embedding into the 3-adic integers $\mathbb{Z}_3$:
- The scaling by 3 (the tripling step) is **not invertible** in $\mathbb{Z}_3$ (it is a shift on the 3-adic tree, which is a partial isometry with a non-trivial kernel).
- The translation $x \mapsto x+1$ shifts the 3-adic carry propagation in $\mathbb{Z}_3$.
- The commutation relations between translation and scaling in $\mathbb{Z}_3$ do not simplify to a unitary group representation, preventing a clean tensor product factorization across the 2-adic and 3-adic sectors.

### 6.2 Scale-Dependency at the Archimedean Place
In the continuous scaling limit on $\mathbb{R}_+^\times$, the Collatz map is approximated by $T(x) \approx \frac{3}{2} x$ for large odd $x$. The additive $+1$ is a scale-dependent perturbation that decays as $O(1/x)$ for large $x$.
- For large $x$, the dynamics converge to a random walk with drift $\ln(3)/2 - \ln(2) \approx -0.14$ [1].
- For small $x$, the $+1$ term dominates and prevents the state from escaping to zero, trapping it in the cyclic attractor $\{1, 4, 2\}$.
- Because the $+1$ translation is not a scale-invariant shift on $\mathbb{R}_+^\times$, we cannot define a scale-invariant Dirac operator $D_\infty$ that commutes with the translation connection across all scales.

### 6.3 The Global Rationality and Descent Obstruction
The periodic points of $T$ are dense in the compact space $\mathbb{Z}_2$ (yielding uncountably many 2-adic cycles). The Collatz conjecture states that the only cycles lying in the rational integers $\mathbb{Z}^+ \subset \mathbb{Z}_2$ are the trivial cycle $\{1, 4, 2\}$.
- The operator relation holds for all 2-adic numbers.
- To isolate the integer cycles, one must restrict the domain to the diagonal embedding.
- This diagonal restriction breaks the translation-invariance of the operators, making it extremely difficult to construct a local index theorem that detects only the global integer cycles without picking up the uncountable background of 2-adic cycles.

---

## §7. Open Problems

To further develop this framework and establish its utility in dynamical systems and number theory, we propose the following open questions:

1. **Triviality of the Projective Kernel Intersection:**
   Can the projective limit intersection of the kernels of $[\mathbf{A}_d, B_{\text{alg},d}]$ as $d \to \infty$ be proven to be trivial (containing only constant functions) on $L^2(\mathbb{Z}_2)$? A proof of this triviality would establish the absence of non-trivial translation-invariant states under Collatz dynamics.

2. **Connes Metric Distance and Stopping Times:**
   Can the Connes metric distance $d_{D+\omega}(x, y)$ associated to the covariant derivative $D + \omega$ be explicitly computed, and is it related to the Collatz stopping time or trajectory length?

---

## §8. Bibliography

1. Lagarias, J. C. (1985). The $3x+1$ problem and its generalizations. *The American Mathematical Monthly*, 92(1), 3-23.
2. Terras, R. (1976). A generalization of the $3x+1$ problem. *Acta Arithmetica*, 30(3), 241-253.
3. Connes, A. (1994). *Noncommutative Geometry*. Academic Press.
4. Pearson, J., & Bellissard, J. (2009). Noncommutative Riemannian geometry on ultrametric Cantor sets. *Journal of Noncommutative Geometry*, 3(3), 447-510.
5. Ruelle, D. (1978). *Thermodynamic Formalism*. Addison-Wesley.
6. Mayer, D. H. (1990). On the thermodynamic formalism for the Gauss map. *Communications in Mathematical Physics*, 130(2), 311-333.
7. Matthews, K. R. (1998). Some conjectures on the class of generalized Collatz mappings. *Acta Arithmetica*, 84, 29-37.
8. Vladimirov, V. S., Volovich, I. V., & Zelenov, E. I. (1994). *p-Adic Analysis and Mathematical Physics*. World Scientific.
9. Kochubei, A. N. (2001). *Pseudo-Differential Equations and Stochastics over Non-Archimedean Fields*. Marcel Dekker.
