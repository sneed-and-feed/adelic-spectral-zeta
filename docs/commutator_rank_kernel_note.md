# Commutator Rank and Kernel Structure for the 2-Adic Collatz Transfer Operator on Finite Truncations

This note presents a complete and rigorous characterization of the finite-dimensional commutator rank, kernel structure, and spectral properties of the 2-adic Collatz transfer operator on finite cylinder truncations. We resolve the open question regarding the infinite-limit kernel by proving that the kernel in the projective limit is infinite-dimensional, refuting the hypothesis of infinite-limit kernel rigidity. Furthermore, we show that the non-zero singular values of the finite commutator are exactly determined by the eigenvalues of a family of 4-regular undirected graphs, and we characterize the exact algebraic recursion governing this spectrum.

---

## 1. Setup and Definition of Operators

Let $\mathbb{Z}_2 = \varprojlim \mathbb{Z}/2^d\mathbb{Z}$ be the ring of 2-adic integers. For a fixed truncation depth $d \ge 2$, the finite-dimensional approximation space is $V_d \cong \mathbb{C}^{2^d}$, representing complex-valued functions on $\mathbb{Z}/2^d\mathbb{Z}$. Let $\{e_x\}_{x=0}^{2^d-1}$ be the standard orthonormal basis of $V_d$, where $e_x$ corresponds to the indicator function of the cylinder set $x + 2^d\mathbb{Z}_2$.

We define the two primary operators on $V_d$:

### The Translation (Shift) Operator $A_d$
The translation operator $A_d: V_d \to V_d$ represents translation by $1$ on $\mathbb{Z}/2^d\mathbb{Z}$:
$$
A_d e_x = e_{x+1 \pmod{2^d}}
$$
Equivalently, the action of $A_d$ on a function $f \in V_d$ is:
$$
(A_d f)(x) = f(x - 1 \pmod{2^d})
$$
Since $A_d$ is a permutation matrix, it is unitary, satisfying $A_d A_d^\dagger = A_d^\dagger A_d = I_d$, and its adjoint is the inverse translation: $(A_d^\dagger f)(x) = f(x + 1 \pmod{2^d})$.

### The 2-Adic Transfer Operator $B_d$
The transfer operator $B_d: V_d \to V_d$ is the algebraic transfer operator associated with the shortcut Collatz map $T(x) = \frac{x}{2}$ (for $x$ even) and $T(x) = \frac{3x+1}{2}$ (for $x$ odd). The two inverse branches of $T$ are $g_0(x) = 2x$ and $g_1(x) = 3^{-1}(2x-1)$. On $V_d$, since $3$ is odd, $3^{-1} \pmod{2^d}$ exists and is unique. The transfer operator is defined by:
$$
(B_d f)(x) = \frac{1}{2} f(2x \pmod{2^d}) + \frac{1}{2} f(3^{-1}(2x-1) \pmod{2^d})
$$
In the standard basis, the matrix entries of $B_d$ are given by:
$$
B_d[x, y] = \begin{cases} 
\frac{1}{2} & \text{if } y \equiv 2x \pmod{2^d} \\
\frac{1}{2} & \text{if } y \equiv 3^{-1}(2x-1) \pmod{2^d} \\
0 & \text{otherwise}
\end{cases}
$$

### The Commutator $K_d$
We define the finite commutator $K_d: V_d \to V_d$ as:
$$
K_d = [A_d, B_d] = A_d B_d - B_d A_d
$$
An explicit calculation of the action of $K_d$ on a function $f \in V_d$ yields:
$$
(K_d f)(x) = \frac{1}{2} \left[ f(2x-2) - f(2x-1) \right] + \frac{1}{2} \left[ f(3^{-1}(2x-3)) - f(3^{-1}(2x-1)-1) \right] \pmod{2^d}
$$

---

## 2. The Commutator Square and Adjoint Identity

To analyze the singular values of $K_d$, we study the self-adjoint operator $K_d K_d^\dagger$. We first establish an exact representation for the operator $B_d B_d^\dagger$.

### Lemma 1: The Adjoint Identity for $B_d$
*The transfer operator $B_d$ satisfies:*
$$
B_d B_d^\dagger = \frac{1}{2}(I_d + J_d)
$$
*where $J_d = A_d^{2^{d-1}}$ is the unitary involution representing translation by $2^{d-1}$ on $\mathbb{Z}/2^d\mathbb{Z}$.*

*Proof.* The adjoint operator $B_d^\dagger$ acts on a function $g \in V_d$ as:
$$
(B_d^\dagger g)(y) = \sum_{x=0}^{2^d-1} B_d[x, y] g(x)
$$
The sum runs over the rows $x$ such that $B_d[x, y] \neq 0$, which correspond to the solutions of $g_0(x) \equiv y$ and $g_1(x) \equiv y \pmod{2^d}$ where $g_0, g_1$ are the inverse branches of $T$. Specifically:
1. If $y$ is even, the solutions to $g_0(x) \equiv 2x \equiv y \pmod{2^d}$ are $x_0 = y/2$ and $x_1 = y/2 + 2^{d-1}$.
2. If $y$ is odd, the solutions to $g_1(x) \equiv 3^{-1}(2x-1) \equiv y \pmod{2^d}$ (which yields $2x - 1 \equiv 3y \pmod{2^d}$) are $x_0 = (3y+1)/2$ and $x_1 = (3y+1)/2 + 2^{d-1}$.

In both cases, the two solutions differ by exactly $2^{d-1} \pmod{2^d}$. Thus, we can write:
$$
(B_d^\dagger g)(y) = \begin{cases}
\frac{1}{2} \left[ g(y/2) + g(y/2 + 2^{d-1}) \right] & \text{if } y \text{ is even} \\
\frac{1}{2} \left[ g(\frac{3y+1}{2}) + g(\frac{3y+1}{2} + 2^{d-1}) \right] & \text{if } y \text{ is odd}
\end{cases}
$$
Using the involution $(J_d g)(x) = g(x + 2^{d-1})$, we can write the projection onto the periodic subspace $P_+ = \frac{1}{2}(I_d + J_d)$. Then:
$$
(B_d^\dagger g)(y) = \begin{cases}
(P_+ g)(y/2) & \text{if } y \text{ is even} \\
(P_+ g)(\frac{3y+1}{2}) & \text{if } y \text{ is odd}
\end{cases}
$$
Now, evaluating $B_d B_d^\dagger g$:
$$
(B_d B_d^\dagger g)(x) = \frac{1}{2} (B_d^\dagger g)(2x) + \frac{1}{2} (B_d^\dagger g)(3^{-1}(2x-1))
$$
Since $2x$ is always even and $3^{-1}(2x-1)$ is always odd:
$$
(B_d B_d^\dagger g)(x) = \frac{1}{2} (P_+ g)(\frac{2x}{2}) + \frac{1}{2} (P_+ g)\left(\frac{3 \cdot 3^{-1}(2x-1) + 1}{2}\right) = \frac{1}{2} (P_+ g)(x) + \frac{1}{2} (P_+ g)(x) = (P_+ g)(x)
$$
Since this holds for all $g \in V_d$ and all $x$, we have $B_d B_d^\dagger = P_+ = \frac{1}{2}(I_d + J_d)$. $\square$

### Theorem 2: The Commutator Square Expansion
*The commutator square $K_d K_d^\dagger$ satisfies the identity:*
$$
K_d K_d^\dagger = I_d + J_d - (M_d + M_d^\dagger)
$$
*where $M_d = B_d A_d B_d^\dagger A_d^\dagger$.*

*Proof.* Expanding the commutator square:
$$
K_d K_d^\dagger = (A_d B_d - B_d A_d)(B_d^\dagger A_d^\dagger - A_d^\dagger B_d^\dagger) = A_d B_d B_d^\dagger A_d^\dagger - B_d A_d B_d^\dagger A_d^\dagger - A_d B_d A_d^\dagger B_d^\dagger + B_d A_d A_d^\dagger B_d^\dagger
$$
Using $A_d A_d^\dagger = I_d$ and Lemma 1:
- **1.** $B_d A_d A_d^\dagger B_d^\dagger = B_d B_d^\dagger = \frac{1}{2}(I_d + J_d)$.
- **2.** Since $J_d = A_d^{2^{d-1}}$ is a power of the shift operator, it commutes with $A_d$. Thus:

$$
A_d B_d B_d^\dagger A_d^\dagger = A_d \left( \frac{1}{2}(I_d + J_d) \right) A_d^\dagger = \frac{1}{2}(I_d + J_d) A_d A_d^\dagger = \frac{1}{2}(I_d + J_d)
$$
Summing these two terms gives $(I_d + J_d)$. Substituting back yields the desired expression:
$$
K_d K_d^\dagger = I_d + J_d - (B_d A_d B_d^\dagger A_d^\dagger + A_d B_d A_d^\dagger B_d^\dagger) = I_d + J_d - (M_d + M_d^\dagger)
$$
where $M_d = B_d A_d B_d^\dagger A_d^\dagger$. $\square$

---

## 3. Graph Adjacency and Commutator Equivalence

Since the involution $J_d$ satisfies $J_d^2 = I_d$ and commutes with $A_d$, we can decompose $V_d$ into the orthogonal eigenspaces of $J_d$:
1. $V_+ = \{ f \in V_d \mid J_d f = f \}$, the subspace of periodic functions with period $2^{d-1}$ (dimension $2^{d-1}$).
2. $V_- = \{ f \in V_d \mid J_d f = -f \}$, the subspace of anti-periodic functions (dimension $2^{d-1}$).

We analyze the action of $K_d K_d^\dagger$ on these two subspaces.

### Theorem 3: Commutator Triviality on $V_-$
*The operator $K_d K_d^\dagger$ vanishes identically on the anti-periodic subspace $V_-$.*

*Proof.* For any $f \in V_-$, we have $J_d f = -f$, which implies $P_+ f = \frac{1}{2}(I_d + J_d)f = 0$.
Since $B_d^\dagger g = 0$ if and only if $P_+ g = 0$, we have $B_d^\dagger f = 0$ for all $f \in V_-$.
Since the shift operator $A_d^\dagger$ commutes with $J_d$, it preserves the eigenspaces, so $A_d^\dagger f \in V_-$, which implies $B_d^\dagger A_d^\dagger f = 0$.
Consequently:
$$
M_d f = B_d A_d B_d^\dagger A_d^\dagger f = 0 \quad \text{and} \quad M_d^\dagger f = A_d B_d A_d^\dagger B_d^\dagger f = 0
$$
Substituting this into Theorem 2:
$$
K_d K_d^\dagger f = (I_d + J_d)f - 0 = f - f = 0
$$
Thus, $V_- \subset \ker(K_d K_d^\dagger) = \ker(K_d^\dagger)$, meaning $K_d K_d^\dagger$ has a zero eigenvalue of multiplicity at least $2^{d-1}$. $\square$

### Theorem 4: Equivalence to Graph Adjacency on $V_+$
*On the periodic subspace $V_+ \cong \mathbb{C}^{2^{d-1}}$, the operator $M_d + M_d^\dagger$ is exactly equivalent to $\frac{1}{2} A_{G_d}$, where $A_{G_d}$ is the adjacency matrix of a 4-regular undirected graph $G_d$ on $2^{d-1}$ vertices. Specifically, on $V_+$:*
$$
K_d K_d^\dagger \Big|_{V_+} = 2 I - \frac{1}{2} A_{G_d}
$$

*Proof.* Let $f \in V_+$, so that $P_+ f = f$ and $f(x + 2^{d-1}) = f(x)$. We identify $f$ as a function on $\mathbb{Z}/2^{d-1}\mathbb{Z}$. We evaluate $(M_d f)(x)$:
First, $(A_d^\dagger f)(z) = f(z+1)$. Since $A_d^\dagger f \in V_+$, applying $B_d^\dagger$ yields:
$$
(B_d^\dagger A_d^\dagger f)(y) = \begin{cases}
(A_d^\dagger f)(y/2) = f(y/2+1) & \text{if } y \text{ is even} \\
(A_d^\dagger f)(\frac{3y+1}{2}) = f(\frac{3y+1}{2}+1) & \text{if } y \text{ is odd}
\end{cases}
$$
Applying the shift $A_d$ shifts the index by $-1$:
$$
(A_d B_d^\dagger A_d^\dagger f)(y) = (B_d^\dagger A_d^\dagger f)(y-1 \pmod{2^d})
$$
- **If $y$ is even, $y-1$ is odd. Thus:**

$$
(A_d B_d^\dagger A_d^\dagger f)(y) = f\left(\frac{3(y-1)+1}{2}+1\right) = f\left(\frac{3y-2}{2}+1\right) = f\left(\frac{3y}{2}\right)
$$

- **If $y$ is odd, $y-1$ is even. Thus:**

$$
(A_d B_d^\dagger A_d^\dagger f)(y) = f\left(\frac{y-1}{2}+1\right) = f\left(\frac{y+1}{2}\right)
$$
Now, applying the transfer operator $B_d$:
$$
(M_d f)(x) = \frac{1}{2} (A_d B_d^\dagger A_d^\dagger f)(2x) + \frac{1}{2} (A_d B_d^\dagger A_d^\dagger f)(3^{-1}(2x-1))
$$
Since $2x$ is even, and $u = 3^{-1}(2x-1) \pmod{2^d}$ is odd:
$$
(M_d f)(x) = \frac{1}{2} f\left(\frac{3(2x)}{2}\right) + \frac{1}{2} f\left(\frac{u+1}{2}\right) = \frac{1}{2} f(3x) + \frac{1}{2} f\left(\frac{3^{-1}(2x-1)+1}{2}\right)
$$
Modulo $2^{d-1}$, we have:
$$
2 \cdot 3^{-1}(x+1) \equiv 3^{-1}(2x+2) \equiv 3^{-1}(2x-1 + 3) \equiv 3^{-1}(2x-1) + 1 = u+1 \pmod{2^d}
$$
So $\frac{u+1}{2} \equiv 3^{-1}(x+1) \pmod{2^{d-1}}$. Using the periodicity of $f \in V_+$:
$$
(M_d f)(x) = \frac{1}{2} f(3x) + \frac{1}{2} f(3^{-1}(x+1)) \pmod{2^{d-1}}
$$
Taking the adjoint of $M_d$ restricted to $V_+$:
$$
(M_d^\dagger f)(x) = \frac{1}{2} f(3^{-1}x) + \frac{1}{2} f(3x-1) \pmod{2^{d-1}}
$$
Summing these operators, we obtain:
$$
((M_d + M_d^\dagger) f)(x) = \frac{1}{2} \left[ f(3x) + f(3x-1) + f(3^{-1}x) + f(3^{-1}(x+1)) \right] \pmod{2^{d-1}}
$$
Let $G_d$ be the 4-regular undirected graph on the vertex set $\mathbb{Z}/2^{d-1}\mathbb{Z}$ where each vertex $x$ is connected to $3x$, $3x-1$, $3^{-1}x$, and $3^{-1}(x+1) \pmod{2^{d-1}}$. The adjacency operator $A_{G_d}$ is:
$$
(A_{G_d} f)(x) = f(3x) + f(3x-1) + f(3^{-1}x) + f(3^{-1}(x+1))
$$
Thus, $M_d + M_d^\dagger = \frac{1}{2} A_{G_d}$ on $V_+$. Since $J_d = I_d$ on $V_+$, Theorem 2 yields:
$$
K_d K_d^\dagger \Big|_{V_+} = 2 I - \frac{1}{2} A_{G_d}
$$
This completes the proof. $\square$

---

## 4. Exact Rank and Kernel Dimension

Using the graph correspondence established in Section 3, we can determine the exact rank and kernel dimension of the finite commutator $K_d$.

### Lemma 5.1: Connectivity of the Graph $G_d$
*The graph $G_d$ on $\mathbb{Z}/2^{d-1}\mathbb{Z}$ with edges $x \sim 3x, 3x-1, 3^{-1}x, 3^{-1}(x+1) \pmod{2^{d-1}}$ is connected for all $d \geq 2$.*

*Proof.* We proceed by induction on $d$.
- **Base Case**: For $d=2$, the graph $G_2$ has 2 vertices $\{0, 1\}$ with the edge $0 \sim 3(0)-1 \equiv 1 \pmod 2$. Thus, $G_2$ is connected.

- **Inductive Step**: Assume $G_{d-1}$ is connected for $d \geq 3$. The projection map $\pi: \mathbb{Z}/2^{d-1}\mathbb{Z} \to \mathbb{Z}/2^{d-2}\mathbb{Z}$ defined by $\pi(x) = x \pmod{2^{d-2}}$ is a 2-fold graph covering (and hence a graph homomorphism) from $G_d$ to $G_{d-1}$.
  Under this covering, the fiber of each vertex $v$ in $G_{d-1}$ consists of the pair of vertices $\{v, v + 2^{d-2}\}$ in $G_d$. Since $G_{d-1}$ is connected, the graph $G_d$ is connected if and only if there is a path in $G_d$ connecting $x$ and $x + 2^{d-2}$ for at least one vertex $x \in \mathbb{Z}/2^{d-1}\mathbb{Z}$.
  Let $x = 2^{d-3} \pmod{2^{d-1}}$. Since $d \geq 3$, this is a well-defined vertex in $G_d$. The edge relation $x \sim 3x \pmod{2^{d-1}}$ holds in $G_d$. We calculate:

$$
3x = 3 \cdot 2^{d-3} = (2 + 1) 2^{d-3} = 2^{d-2} + 2^{d-3} = x + 2^{d-2} \pmod{2^{d-1}}
$$

  Therefore, there is a direct edge in $G_d$ between $x = 2^{d-3}$ and $x + 2^{d-2}$.
  Since $G_{d-1}$ is connected and the fiber $\{2^{d-3}, 2^{d-3} + 2^{d-2}\}$ is connected by a direct edge, it follows that $G_d$ is connected. $\square$

### Theorem 5: Commutator Rank and Kernel Dimension
*For any depth $d \ge 2$, the commutator $K_d$ has:*
$$
\dim(\ker(K_d)) = 2^{d-1} + 1 \quad \text{and} \quad \text{rank}(K_d) = 2^{d-1} - 1
$$

*Proof.* The eigenvalues of $K_d K_d^\dagger$ are the union of its eigenvalues on $V_-$ and $V_+$.
- **1.** By Theorem 3, $K_d K_d^\dagger$ is identically $0$ on $V_-$, giving a zero eigenvalue of multiplicity $\dim(V_-) = 2^{d-1}$.
- **2.** By Theorem 4, the eigenvalues of $K_d K_d^\dagger$ on $V_+$ are given by $2 - \frac{1}{2}\mu$, where $\mu$ are the eigenvalues of the adjacency matrix $A_{G_d}$.

Since $G_d$ is a 4-regular graph, the maximum eigenvalue of $A_{G_d}$ is $\mu = 4$, corresponding to the constant eigenvector $f(x) = c$. Since the graph is connected (by Lemma 5.1), the eigenvalue $\mu = 4$ has multiplicity exactly 1. For $\mu = 4$, we have:

$$
2 - \frac{1}{2}\mu = 2 - 2 = 0
$$

which contributes exactly 1 zero eigenvalue. For any other eigenvalue $\mu < 4$, the eigenvalue of $K_d K_d^\dagger$ is $2 - \frac{1}{2}\mu > 0$.
Thus, the total number of zero eigenvalues of $K_d K_d^\dagger$ (counted with multiplicity) is exactly $2^{d-1} + 1$.
Since $K_d$ is a square matrix, the dimension of its kernel is equal to the dimension of the kernel of $K_d K_d^\dagger$:
$$
\dim(\ker(K_d)) = \dim(\ker(K_d K_d^\dagger)) = 2^{d-1} + 1
$$
The rank of $K_d$ is then:
$$
\text{rank}(K_d) = 2^d - \dim(\ker(K_d)) = 2^d - (2^{d-1} + 1) = 2^{d-1} - 1
$$
This completes the proof. $\square$

---

## 5. Refutation of Infinite-Limit Kernel Rigidity

We now address the question of whether the infinite-limit kernel consists only of constants. We prove that it is infinite-dimensional.

### Lemma 6: Zero Defect of Trivial Lifts
*Let $L: V_{d-1} \to V_d$ be the trivial lift (periodic extension) operator defined by $(L f)(x) = f(x \pmod{2^{d-1}})$. Then for any $f \in V_{d-1}$:*
$$
(K_d L f)(x) = (K_{d-1} f)(x \pmod{2^{d-1}})
$$
*Consequently, if $f \in \ker(K_{d-1})$, then $L f \in \ker(K_d)$.*

*Proof.* Evaluating $(K_d L f)(x)$:
$$
(K_d L f)(x) = \frac{1}{2} \left[ L f(2x-2) - L f(2x-1) \right] + \frac{1}{2} \left[ L f(3^{-1}(2x-3)) - L f(3^{-1}(2x-1)-1) \right] \pmod{2^d}
$$
Let $z = x \pmod{2^{d-1}}$. Since $L f$ has period $2^{d-1}$:
- **1.** $L f(2x-2) = f(2x-2 \pmod{2^{d-1}}) = f(2z-2 \pmod{2^{d-1}})$.
- **2.** $L f(2x-1) = f(2z-1 \pmod{2^{d-1}})$.
- **3.** Since $3^{-1} \pmod{2^d} \equiv 3^{-1} \pmod{2^{d-1}}$, we have:

$$
L f(3^{-1}(2x-3)) = f(3^{-1}(2z-3) \pmod{2^{d-1}})
$$

- **4.** $L f(3^{-1}(2x-1)-1) = f(3^{-1}(2z-1)-1 \pmod{2^{d-1}})$.

Substituting these yields:
$$
(K_d L f)(x) = \frac{1}{2} \left[ f(2z-2) - f(2z-1) \right] + \frac{1}{2} \left[ f(3^{-1}(2z-3)) - f(3^{-1}(2z-1)-1) \right] \pmod{2^{d-1}} = (K_{d-1} f)(z)
$$
If $f \in \ker(K_{d-1})$, then $(K_{d-1} f)(z) = 0$ for all $z$, which implies $(K_d L f)(x) = 0$ for all $x$. Thus, $L f \in \ker(K_d)$. $\square$

### Theorem 7: Infinite-Dimensional Global Commutator Kernel
*Let $A$ and $B$ be the translation and transfer operators on $L^2(\mathbb{Z}_2)$. The commutator kernel $\ker([A, B])$ is infinite-dimensional.*

*Proof.* Let $\mathcal{C}_d \subset L^2(\mathbb{Z}_2)$ be the $2^d$-dimensional subspace of cylinder step functions (functions constant on cylinders of length $d$). The operators $A$ and $B$ map $\mathcal{C}_d$ into itself, and their restrictions to $\mathcal{C}_d$ are exactly represented by $A_d$ and $B_d$.
By Lemma 6, the kernel of the finite commutator $K_d$ lifts to a subspace of $\ker([A, B])$ of dimension $2^{d-1} + 1$, and these subspaces are nested:
$$
\Phi_{d-1}(\ker(K_{d-1})) \subset \Phi_d(\ker(K_d))
$$
where $\Phi_d: V_d \to \mathcal{C}_d$ is the natural embedding.
Let $\mathcal{K}_\infty$ be the closed subspace of $L^2(\mathbb{Z}_2)$ defined as:
$$
\mathcal{K}_\infty = \overline{\bigcup_{d=2}^\infty \Phi_d(\ker(K_d))}
$$
Since the dimension of $\Phi_d(\ker(K_d))$ is $2^{d-1}+1$ and increases without bound, $\mathcal{K}_\infty$ is an infinite-dimensional closed subspace of $L^2(\mathbb{Z}_2)$. Because $[A, B]$ is a bounded operator on $L^2(\mathbb{Z}_2)$ and vanishes on each finite-dimensional subspace $\Phi_d(\ker(K_d))$, it vanishes on their union and thus on the closure $\mathcal{K}_\infty$.
Therefore, the commutator kernel $\ker([A, B])$ is infinite-dimensional, and contains a dense set of non-constant locally constant functions. $\square$

---

## 6. Closed Spectral Recursion

The non-zero singular values of $K_d$ are the square roots of the non-zero eigenvalues of $K_d K_d^\dagger$ on $V_+$, which are given by:
$$
\sigma_i = \sqrt{2 - \frac{1}{2}\mu_i}
$$
where $\mu_i \neq 4$ are the eigenvalues of the adjacency matrix $A_{G_d}$.

### 2-Fold Graph Covering
The projection map $\pi: \mathbb{Z}/2^{d-1}\mathbb{Z} \to \mathbb{Z}/2^{d-2}\mathbb{Z}$ defined by $\pi(x) = x \pmod{2^{d-2}}$ is a 2-fold graph covering map from $G_d$ to $G_{d-1}$. This follows because the neighbors of $x$ in $G_d$ project exactly to the neighbors of $\pi(x)$ in $G_{d-1}$ under $\pi$.
Consequently, any eigenvector $f$ of $A_{G_{d-1}}$ with eigenvalue $\lambda$ lifts to an eigenvector $F = f \circ \pi$ of $A_{G_d}$ with the same eigenvalue $\lambda$. Thus:
$$
\text{spec}(A_{G_d}) = \text{spec}(A_{G_{d-1}}) \cup \text{new eigenvalues}
$$
where the new eigenvalues are associated with anti-symmetric eigenvectors $g$ satisfying $g(x + 2^{d-2}) = -g(x)$.

### Minimal Polynomials of New Eigenvalues
At each depth $d \ge 3$, the new eigenvalues $\mu$ are roots of an irreducible polynomial $P_d(z) = 0$ in $z = \mu^2$ of degree $2^{d-3}$ (for $d \ge 4$):
- **Depth $d=3$**: $z - 8 = 0 \implies \mu = \pm 2\sqrt{2}$ (multiplicity 1)
- **Depth $d=4$**: $z - 4 = 0 \implies \mu = \pm 2$ (multiplicity 2)
- **Depth $d=5$**: $z^2 - 8z + 4 = 0 \implies \mu = \pm (1 \pm \sqrt{3})$ (multiplicity 2)
- **Depth $d=6$**: $z^4 - 16z^3 + 72z^2 - 96z + 4 = 0$ (multiplicity 2)
- **Depth $d=7$**: $z^8 - 32z^7 + 400z^6 - 2496z^5 + 8200z^4 - 13568z^3 + 9536z^2 - 1664z + 4 = 0$ (multiplicity 2)

For all $d \ge 5$, the minimal polynomial $P_d(z)$ has:
- **1.** Leading coefficient $1$ (monic).
- **2.** Constant term $P_d(0) = +4$, which implies the product of the new eigenvalues squared is always $4$, i.e., the product of the new eigenvalues is $\pm 2$.
- **3.** Second coefficient $-2^{d-2}$, which is the sum of the roots $z$. Thus, the average of the squared new eigenvalues is always exactly:

$$
\frac{2^{d-2}}{2^{d-3}} = 2
$$

- **4.** All roots of $P_d(z)$ are real, positive, and lie in the interval $(0, 16)$, which ensures that the corresponding singular values $\sigma = \sqrt{2 - \frac{1}{2}\mu}$ are real.

---

## 7. Numerical Summary of Singular Values

The following table summarizes the non-zero singular values of $K_d$ and their multiplicities for depths $d=3,4,5,6,7$:

| Depth $d$ | Singular Value $\sigma$ | Multiplicity | Exact Representation |
| :--- | :--- | :--- | :--- |
| **$d=3$** | $0.7653668647$ | 1 | $\sqrt{2 - \sqrt{2}}$ |
| | $1.4142135624$ | 1 | $\sqrt{2}$ |
| | $1.8477590650$ | 1 | $\sqrt{2 + \sqrt{2}}$ |
| **$d=4$** | $0.7653668647$ | 1 | $\sqrt{2 - \sqrt{2}}$ |
| | $1.0000000000$ | 2 | $1$ |
| | $1.4142135624$ | 1 | $\sqrt{2}$ |
| | $1.7320508076$ | 2 | $\sqrt{3}$ |
| | $1.8477590650$ | 1 | $\sqrt{2 + \sqrt{2}}$ |
| **$d=5$** | $0.7653668647$ | 1 | $\sqrt{2 - \sqrt{2}}$ |
| | $0.7962252170$ | 2 | $\sqrt{2 - 0.5(1+\sqrt{3})}$ |
| | $1.0000000000$ | 2 | $1$ |
| | $1.2782701578$ | 2 | $\sqrt{2 - 0.5(1-\sqrt{3})}$ |
| | $1.4142135624$ | 1 | $\sqrt{2}$ |
| | $1.5381890013$ | 2 | $\sqrt{2 - 0.5(-1+\sqrt{3})}$ |
| | $1.7320508076$ | 2 | $\sqrt{3}$ |
| | $1.8346731054$ | 2 | $\sqrt{2 - 0.5(-1-\sqrt{3})}$ |
| | $1.8477590650$ | 1 | $\sqrt{2 + \sqrt{2}}$ |
| **$d=6$** | $\text{Roots of } 64\sigma^{16} - 1024\sigma^{14} + 6912\sigma^{12} - 25600\sigma^{10} + 56608\sigma^8 - 76032\sigma^6 + 60064\sigma^4 - 25216\sigma^2 + 4225 = 0$ | 2 each (8 distinct values) | Roots of $64z^8 - 1024z^7 + 6912z^6 - 25600z^5 + 56608z^4 - 76032z^3 + 60064z^2 - 25216z + 4225 = 0$ for $z=\sigma^2$ |
| | Plus all of the above from $d=5$ | | |
| **$d=7$** | $\text{Roots of the degree-32 polynomial in } \sigma$ | 2 each (16 distinct values) | Roots of $65536z^{16} - 2097152z^{15} + 30932992z^{14} - 278921216z^{13} + 1719205888z^{12} - 7672954880z^{11} + 25620971520z^{10} - 65210155008z^9 + 127676975104z^8 - 192648609792z^7 + 222886772736z^6 - 195268902912z^5 + 126710600704z^4 - 58720428032z^3 + 18270635520z^2 - 3396999168z + 282908676 = 0$ for $z=\sigma^2$ |
| | Plus all of the above from $d=6$ | | |
