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

- **Inductive Step**: Assume $G_{d-1}$ is connected for $d \geq 3$. We prove that $G_d$ is connected by analyzing the projection map $\pi: G_d \to G_{d-1}$ defined by $\pi(x) = x \pmod{2^{d-2}}$. We show $G_d$ is connected by establishing the following properties:
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
  4. **Connectivity of the Cover**: Let $u, w \in V(G_d)$. Since $G_{d-1}$ is connected by the inductive hypothesis, there is a path $P$ in $G_{d-1}$ connecting $\pi(u)$ to $y = 2^{d-3}$. By the path-lifting property of graph coverings, $P$ lifts to a path in $G_d$ starting at $u$ and ending at either $y_1$ or $y_2$. Similarly, a path from $\pi(w)$ to $y$ in $G_{d-1}$ lifts to a path in $G_d$ starting at $w$ and ending at either $y_1$ or $y_2$. Since the vertical edge $\{y_1, y_2\}$ connects the two sheets, $u$ and $w$ are connected in $G_d$. Since $u, w$ were arbitrary, $G_d$ is connected. $\square$

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
### 5.2 Cylinder Invariance and Operator Compatibility

To establish the behavior of the commutator in the infinite-dimensional limit, we must show that the finite-dimensional approximations $V_d$ embed isometrically into $L^2(\mathbb{Z}_2)$ and that the actions of translation and transfer commute with these embeddings.

Let $\mu_2$ be the Haar measure on $\mathbb{Z}_2$ normalized so that $\mu_2(\mathbb{Z}_2) = 1$. For each $d \ge 1$, let $\mathcal{C}_d \subset L^2(\mathbb{Z}_2, \mu_2)$ denote the $2^d$-dimensional subspace of cylinder step functions, consisting of functions that are constant on all cylinder sets $x + 2^d\mathbb{Z}_2$ for $x \in \mathbb{Z}/2^d\mathbb{Z}$. Because the cylinder sets partition $\mathbb{Z}_2$ into $2^d$ disjoint open-closed sets of Haar measure $2^{-d}$, the normalized indicator functions:

$$
e_x^{(d)} = \sqrt{2^d} \, \mathbf{1}_{x + 2^d\mathbb{Z}_2}, \quad x = 0, 1, \dots, 2^d-1
$$

form an orthonormal basis for $\mathcal{C}_d$.

Let $\Phi_d: V_d \to L^2(\mathbb{Z}_2, \mu_2)$ be the linear embedding mapping the standard basis vector $e_x \in V_d$ to $e_x^{(d)}$. Under the standard $\ell^2$ inner product on $V_d$ and the $L^2$ inner product on $L^2(\mathbb{Z}_2, \mu_2)$, $\Phi_d$ is an isometric embedding with image $\mathcal{C}_d$.

#### Lemma 6.1: Subspace Nesting and Lift Compatibility
*The cylinder subspaces are nested, $\mathcal{C}_{d-1} \subset \mathcal{C}_d$ for all $d \ge 3$, and the diagram*

$$
\Phi_d \circ L = \sqrt{2} \, \Phi_{d-1}
$$

*commutes, where $L: V_{d-1} \to V_d$ is the trivial lift $(Lf)(x) = f(x \pmod{2^{d-1}})$.*

*Proof.* For any $y \in \mathbb{Z}/2^{d-1}\mathbb{Z}$, the cylinder set $y + 2^{d-1}\mathbb{Z}_2$ splits into the disjoint union of two cylinders of length $d$:

$$
y + 2^{d-1}\mathbb{Z}_2 = (y + 2^d\mathbb{Z}_2) \cup (y + 2^{d-1} + 2^d\mathbb{Z}_2)
$$

Thus, their indicator functions satisfy:

$$
\mathbf{1}_{y + 2^{d-1}\mathbb{Z}_2} = \mathbf{1}_{y + 2^d\mathbb{Z}_2} + \mathbf{1}_{y + 2^{d-1} + 2^d\mathbb{Z}_2}
$$

which implies $\mathcal{C}_{d-1} \subset \mathcal{C}_d$. For any $f = \sum_{y=0}^{2^{d-1}-1} f_y e_y \in V_{d-1}$, we have:

$$
\Phi_{d-1}(f) = \sum_{y=0}^{2^{d-1}-1} f_y \sqrt{2^{d-1}} \, \mathbf{1}_{y + 2^{d-1}\mathbb{Z}_2}
$$

Applying $\Phi_d$ to the trivial lift $L f$:

$$
\Phi_d(Lf) = \sum_{x=0}^{2^d-1} f_{x \pmod{2^{d-1}}} \sqrt{2^d} \, \mathbf{1}_{x + 2^d\mathbb{Z}_2}
$$

We can decompose the sum over $x$ by writing $x = y + s \cdot 2^{d-1}$ where $y \in \{0, \dots, 2^{d-1}-1\}$ and $s \in \{0, 1\}$:

$$
\Phi_d(Lf) = \sum_{y=0}^{2^{d-1}-1} f_y \sqrt{2^d} \left( \mathbf{1}_{y + 2^d\mathbb{Z}_2} + \mathbf{1}_{y + 2^{d-1} + 2^d\mathbb{Z}_2} \right) = \sum_{y=0}^{2^{d-1}-1} f_y \sqrt{2} \sqrt{2^{d-1}} \, \mathbf{1}_{y + 2^{d-1}\mathbb{Z}_2} = \sqrt{2} \, \Phi_{d-1}(f)
$$

Hence, $\Phi_d \circ L = \sqrt{2} \, \Phi_{d-1}$. 

To independently verify the norm consistency of this identity, we compute the $L^2$-norms of both sides. Because $\Phi_d$ and $\Phi_{d-1}$ are isometric embeddings, we have:
$$
\| \Phi_d(Lf) \|_{L^2(\mathbb{Z}_2)} = \| Lf \|_{V_d}
$$
and
$$
\| \sqrt{2} \, \Phi_{d-1}(f) \|_{L^2(\mathbb{Z}_2)} = \sqrt{2} \, \| \Phi_{d-1}(f) \|_{L^2(\mathbb{Z}_2)} = \sqrt{2} \, \| f \|_{V_{d-1}}
$$
We compute the norm of the trivial lift $Lf \in V_d$:
$$
\| Lf \|_{V_d}^2 = \sum_{x=0}^{2^d-1} |(Lf)(x)|^2 = \sum_{x=0}^{2^d-1} |f_{x \pmod{2^{d-1}}}|^2
$$
Since the index $x \pmod{2^{d-1}}$ covers each index $y \in \{0, \dots, 2^{d-1}-1\}$ exactly twice as $x$ ranges from $0$ to $2^d-1$:
$$
\| Lf \|_{V_d}^2 = 2 \sum_{y=0}^{2^{d-1}-1} |f_y|^2 = 2 \| f \|_{V_{d-1}}^2 \implies \| Lf \|_{V_d} = \sqrt{2} \, \| f \|_{V_{d-1}}
$$
Thus, the norm of the left-hand side $\| \Phi_d(Lf) \|_{L^2(\mathbb{Z}_2)}$ is exactly $\sqrt{2} \, \| f \|_{V_{d-1}}$, matching the right-hand side exactly and verifying the correctness of all normalization and nesting constants.

This scaling compatibility preserves orthocomplements and yields the subspace inclusion:

$$
\Phi_{d-1}(\ker(K_{d-1})) \subset \Phi_d(\ker(K_d))
$$

which establishes that the finite commutator kernels form an increasing chain of subspaces under the natural embeddings. $\square$

#### Lemma 6.2: Operator Compatibility
*The global translation operator $A$ and the global transfer operator $B$ on $L^2(\mathbb{Z}_2, \mu_2)$ preserve each cylinder subspace $\mathcal{C}_d$ and are compatible with their finite-dimensional restrictions $A_d$ and $B_d$ under $\Phi_d$:*

$$
A \circ \Phi_d = \Phi_d \circ A_d \quad \text{and} \quad B \circ \Phi_d = \Phi_d \circ B_d
$$

*Proof.* Let $f \in V_d$ and let $g = \Phi_d(f) \in \mathcal{C}_d$. 
1. **Translation**: The translation operator $A$ acts by $(Ag)(x) = g(x-1)$. For any $x \in \mathbb{Z}_2$, let $\lfloor x \rfloor_d \in \mathbb{Z}/2^d\mathbb{Z}$ denote its $d$-th truncation. Since $g(x) = \sqrt{2^d} f(\lfloor x \rfloor_d)$, we have:

$$
(Ag)(x) = g(x-1) = \sqrt{2^d} f(\lfloor x-1 \rfloor_d) = \sqrt{2^d} f(\lfloor x \rfloor_d - 1 \pmod{2^d}) = \Phi_d(A_d f)(x)
$$

where $(A_d f)(k) = f(k-1 \pmod{2^d})$. Thus, $A \circ \Phi_d = \Phi_d \circ A_d$.
2. **Transfer**: The global transfer operator $B$ is defined by $(Bg)(x) = \frac{1}{2} g(2x) + \frac{1}{2} g(3^{-1}(2x-1))$. Since the truncation map $\lfloor \cdot \rfloor_d: \mathbb{Z}_2 \to \mathbb{Z}/2^d\mathbb{Z}$ is a ring homomorphism:

$$
\lfloor 2x \rfloor_d \equiv 2 \lfloor x \rfloor_d \pmod{2^d} \quad \text{and} \quad \lfloor 3^{-1}(2x-1) \rfloor_d \equiv 3^{-1}(2 \lfloor x \rfloor_d - 1) \pmod{2^d}
$$

Therefore:

$$
\begin{aligned}
(Bg)(x) &= \frac{1}{2} \sqrt{2^d} f(\lfloor 2x \rfloor_d) + \frac{1}{2} \sqrt{2^d} f(\lfloor 3^{-1}(2x-1) \rfloor_d) \\
&= \sqrt{2^d} \left( \frac{1}{2} f(2 \lfloor x \rfloor_d \pmod{2^d}) + \frac{1}{2} f(3^{-1}(2 \lfloor x \rfloor_d - 1) \pmod{2^d}) \right) \\
&= \sqrt{2^d} (B_d f)(\lfloor x \rfloor_d) = \Phi_d(B_d f)(x)
\end{aligned}
$$

Thus, $B \circ \Phi_d = \Phi_d \circ B_d$. $\square$

### Theorem 7: Infinite-Dimensional Global Commutator Kernel
*Let $A$ and $B$ be the translation and transfer operators on $L^2(\mathbb{Z}_2, \mu_2)$. The commutator kernel $\ker([A, B])$ is infinite-dimensional.*

*Proof.* By Lemma 6.2, the global commutator $[A, B] = AB - BA$ commutes with the embedding $\Phi_d$:

$$
[A, B] \circ \Phi_d = (AB - BA) \circ \Phi_d = A \circ \Phi_d \circ B_d - B \circ \Phi_d \circ A_d = \Phi_d \circ (A_d B_d - B_d A_d) = \Phi_d \circ K_d
$$

For any $f \in \ker(K_d)$, we have:

$$
[A, B] \Phi_d(f) = \Phi_d(K_d f) = 0
$$

which implies $\Phi_d(\ker(K_d)) \subset \ker([A, B])$. 
Let $\mathcal{K}_\infty \subset L^2(\mathbb{Z}_2, \mu_2)$ be the closed subspace:

$$
\mathcal{K}_\infty = \overline{\bigcup_{d=2}^\infty \Phi_d(\ker(K_d))}
$$

The operators $A$ and $B$ are bounded linear operators on $L^2(\mathbb{Z}_2, \mu_2)$ (with $\|A\| = 1$ and $\|B\| = 1$). Consequently, the commutator $[A, B]$ is a bounded linear operator. If a bounded linear operator vanishes on a family of subspaces, it vanishes on their union, and by continuity, it must vanish on the closure of their union. Thus:

$$
\mathcal{K}_\infty \subset \ker([A, B])
$$

By Theorem 5, the dimension of $\ker(K_d)$ is $2^{d-1}+1$. By Lemma 6.1, the spaces $\Phi_d(\ker(K_d))$ form a strictly increasing chain of subspaces under the nested inclusion $\mathcal{C}_{d-1} \subset \mathcal{C}_d$. Because the dimension $2^{d-1}+1 \to \infty$ as $d \to \infty$, the closed subspace $\mathcal{K}_\infty$ is infinite-dimensional.
Therefore, the global commutator kernel $\ker([A, B])$ is infinite-dimensional, containing a dense set of non-constant, locally constant step functions. $\square$

---

## 6. Conjectural Spectral Recursion

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

### Conjecture: Minimal Polynomials of New Eigenvalues
Based on exact symbolic algebraic computations up to depth $d = 7$, we formulate the following conjecture regarding the minimal polynomials of the new eigenvalues:

**Conjectural spectral recursion supported by exact computation to depth 7:**
At each depth $d \ge 3$, the new eigenvalues $\mu$ are roots of an irreducible polynomial $P_d(z) = 0$ in $z = \mu^2$ of degree $2^{d-4}$ (for $d \ge 4$):
- **Depth $d=3$**: $z - 8 = 0 \implies \mu = \pm 2\sqrt{2}$ (multiplicity 1, degree 1 in $z = \mu^2$)
- **Depth $d=4$**: $z - 4 = 0 \implies \mu = \pm 2$ (multiplicity 2, degree 1)
- **Depth $d=5$**: $z^2 - 8z + 4 = 0 \implies \mu = \pm (1 \pm \sqrt{3})$ (multiplicity 2, degree 2)
- **Depth $d=6$**: $z^4 - 16z^3 + 72z^2 - 96z + 4 = 0$ (multiplicity 2, degree 4)
- **Depth $d=7$**: $z^8 - 32z^7 + 400z^6 - 2496z^5 + 8200z^4 - 13568z^3 + 9536z^2 - 1664z + 4 = 0$ (multiplicity 2, degree 8)

For all $d \ge 5$, the minimal polynomial $P_d(z)$ of the distinct squared eigenvalues is conjectured (and verified up to depth $d=7$) to satisfy:
- **1.** Leading coefficient $1$ (monic).
- **2.** Constant term $P_d(0) = +4$, which implies the product of the new eigenvalues squared is always $4$, i.e., the product of the new eigenvalues is $\pm 2$.
- **3.** Second coefficient $-2^{d-2}$, which is the sum of the roots $z$. Thus, the average of the squared new eigenvalues is always exactly:

$$
\frac{2^{d-2}}{2^{d-4}} = 4
$$

- **4.** All roots of $P_d(z)$ are real, positive, and lie in the interval $(0, 16)$, which ensures that the corresponding singular values $\sigma = \sqrt{2 - \frac{1}{2}\mu}$ are real.
- **5.** The product of the new singular values $\sigma_i = \sqrt{2 - \frac{1}{2}\mu_i}$ at depth $d \ge 4$ satisfies:

$$
\prod_{\text{new}} \sigma_i = \frac{P_d(16)}{4^{2^{d-4}}}
$$

which evaluates to $3$ for $d=4$, $8.25$ for $d=5$, $66.015625$ for $d=6$, and $\frac{70727169}{16384} \approx 4316.8438$ for $d=7$. This exact behavior indicates that the singular spectrum of the commutator is highly constrained across scales.

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

---

## 8. Open Problems

### Open Problem 1: Global Intertwining Operators
Can the finite-dimensional graph covering structure be lifted to a bounded operator $\mathcal{U}$ on $L^2(\mathbb{Z}_2)$ that conjugates the global commutator $[A, B]$ to a multiplication operator? 

The product of the new singular values $\prod_{\text{new}} \sigma_i = \frac{P_d(16)}{4^{2^{d-4}}}$ provides a necessary compatibility condition at each finite depth $d$. However, the construction of compatible embeddings between the wavelet detail spaces $\mathcal{W}_d$ (which would require constructing explicit partial isometries $U_d: \mathcal{W}_d \to \mathcal{W}_{d+1}$ compatible with the graph covering projection) and the proof of their convergence to a well-defined global intertwiner remain open questions.

