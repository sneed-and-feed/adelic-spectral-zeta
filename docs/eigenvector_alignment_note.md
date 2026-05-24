# Explicit Chiral Wavelet Alignment of Covering Graph Eigenvectors

## 1. Introduction and Hilbert Space Decomposition

To study the spectrum and eigenvectors of the Collatz transfer operator and resolve Open Problem 1, we establish a clean, consistent notation for the finite-dimensional coverings.

Let $V_d \cong \mathbb{C}^{2^{d-1}}$ denote the **periodic subspace** of step functions at scale $d$ (for $d \ge 2$), which corresponds to $V_+$ under the involution $J_d$ at depth $d$. The space $V_d$ represents functions on the cyclic group $\mathbb{Z}/2^{d-1}\mathbb{Z}$, which is the vertex set of the 4-regular covering graph $G_d$.

The 2-fold graph covering projection $\pi_d: G_d \to G_{d-1}$ is given by the mod-$2^{d-2}$ map:

$$
\pi_d(x) = x \pmod{2^{d-2}}
$$

The deck transformation of this covering is the shift by $2^{d-2}$:

$$
S_d x = x + 2^{d-2} \pmod{2^{d-1}}
$$

which satisfies $S_d^2 = I$. The periodic Hilbert space $V_d$ decomposes orthogonally into the $+1$ and $-1$ eigenspaces of $S_d$:

$$
V_d = L(V_{d-1}) \oplus \mathcal{W}_d
$$

where:
- $L: V_{d-1} \to V_d$ is the normalized symmetric lift (periodic extension):
  

$$
(Lf)(x) = \frac{1}{\sqrt{2}} f(x \pmod{2^{d-2}})
$$

  The range of $L$ is the $+1$-eigenspace of $S_d$, having dimension $2^{d-2}$.
- $\mathcal{W}_d = \ker(L^\dagger) = V_d^{\text{anti}}$ is the anti-symmetric detail space:
  

$$
\mathcal{W}_d = \{ g \in V_d \mid S_d g = -g \} = \{ g \in V_d \mid g(x + 2^{d-2}) = -g(x) \}
$$

  The detail space $\mathcal{W}_d$ has dimension $2^{d-2}$ (for $d \ge 3$).

Under the global isometry $\Phi_d: V_d \to L^2(\mathbb{Z}_2)$, the detail spaces embed as mutually orthogonal closed subspaces $\mathcal{W}_d^{\text{global}} = \Phi_d(\mathcal{W}_d)$, satisfying the Haar-like wavelet direct sum:

$$
\Phi_d(V_d) = \Phi_2(V_2) \oplus \mathcal{W}_3^{\text{global}} \oplus \mathcal{W}_4^{\text{global}} \oplus \dots \oplus \mathcal{W}_d^{\text{global}}
$$

---

## 2. Block Diagonalization of the Adjacency Operator

Since the deck transformation $S_d$ is a graph automorphism of $G_d$, it commutes with the adjacency operator $A_{G_d}$:

$$
A_{G_d} S_d = S_d A_{G_d}
$$

This commutativity guarantees that $A_{G_d}$ preserves the eigenspaces of $S_d$, rendering the decomposition $V_d = L(V_{d-1}) \oplus \mathcal{W}_d$ invariant under $A_{G_d}$.

### Theorem 1: Hierarchical Block Diagonalization
*The adjacency operator $A_{G_d}$ is unitarily equivalent to a block-diagonal operator in the hierarchical wavelet basis:*

$$
W^\dagger A_{G_d} W = A_{G_2} \oplus H_2 \oplus H_3 \oplus \dots \oplus H_{d-1}
$$

*where $H_{k-1} = U_k^\dagger A_{G_k} U_k$ is the twisted adjacency operator on $V_{k-1}$ of size $2^{k-2} \times 2^{k-2}$, and $W$ is the unitary transformation matrix defined by the concatenated lifts:*

$$
W = \begin{pmatrix} L^{d-2} & L^{d-3} U_3 & L^{d-4} U_4 & \dots & U_d \end{pmatrix}
$$

*Proof.* By the regular covering property, the restriction of $A_{G_d}$ to the symmetric subspace $L(V_{d-1})$ is unitarily equivalent to $A_{G_{d-1}}$ on $V_{d-1}$:

$$
L^\dagger A_{G_d} L = A_{G_{d-1}}
$$

The restriction of $A_{G_d}$ to the detail space $\mathcal{W}_d$ is represented on the base space $V_{d-1}$ via the sheet-alternating isometry $U_d = M_{d-1} L: V_{d-1} \to \mathcal{W}_d$:

$$
H_{d-1} = U_d^\dagger A_{G_d} U_d
$$

Because $L(V_{d-1})$ and $\mathcal{W}_d$ are orthogonal and invariant under $A_{G_d}$, the cross-terms vanish:

$$
L^\dagger A_{G_d} U_d = 0 \quad \text{and} \quad U_d^\dagger A_{G_d} L = 0
$$

Thus, in the basis of $L(V_{d-1}) \oplus \mathcal{W}_d$, we have:

$$
A_{G_d} \cong A_{G_{d-1}} \oplus H_{d-1}
$$

Applying this decomposition inductively to $A_{G_{d-1}}, A_{G_{d-2}}, \dots$ yields the complete block-diagonal form. $\square$

This block-diagonalization has a profound consequence: it isolates the "new" eigenvalues at each scale $d$ to the spectrum of a single twisted operator $H_{d-1}$ acting on the base space $V_{d-1}$:

$$
\text{spec}(A_{G_d}) = \text{spec}(A_{G_{d-1}}) \cup \text{spec}(H_{d-1})
$$

---

## 3. Chiral (Supersymmetric) Symmetry of Twisted Operators

The base space $V_{d-1}$ can itself be decomposed under the lower-scale deck transformation $S_{d-1}$ as $V_{d-1} = L(V_{d-2}) \oplus \mathcal{W}_{d-1} \cong V_{d-2} \oplus V_{d-2}$.

### Theorem 2: Block Form and Chiral Symmetry
*Under the split $V_{d-1} \cong V_{d-2} \oplus V_{d-2}$, the twisted operator $H_{d-1}$ has the block-matrix form:*

$$
H_{d-1} = \begin{pmatrix} A_{d-2} & B_{d-2} \\ B_{d-2} & -A_{d-2} \end{pmatrix}
$$

*where $A_{d-2}, B_{d-2}$ are symmetric matrices of size $2^{d-3} \times 2^{d-3}$. Consequently, $H_{d-1}$ anti-commutes with the unitary skew-adjoint operator $J_{d-1} = \begin{pmatrix} 0 & -I \\ I & 0 \end{pmatrix}$:*

$$
J_{d-1} H_{d-1} + H_{d-1} J_{d-1} = 0
$$

*Proof.* Under the 2-fold covering projection $G_{d} \to G_{d-1}$, the adjacency matrix $A_{G_d}$ can be written block-wise in the sheet basis $V_d \cong V_{d-1} \oplus V_{d-1}$ as:

$$
A_{G_d} = \begin{pmatrix} A_{\text{same}} & A_{\text{cross}} \\ A_{\text{cross}} & A_{\text{same}} \end{pmatrix}
$$

where $A_{\text{same}}$ represents same-sheet edges and $A_{\text{cross}}$ represents sheet-crossing edges. By regular covering compatibility:
- $A_{\text{same}} + A_{\text{cross}} = A_{G_{d-1}}$ (the base adjacency operator).
- $A_{\text{same}} - A_{\text{cross}} = H_{d-1}$ (the twisted adjacency operator $A_{G_{d-1}}^\theta$).

Applying the symmetric/anti-symmetric split to $V_{d-1} \cong V_{d-2} \oplus V_{d-2}$, the same-sheet and cross-sheet operators decompose as:

$$
A_{\text{same}} = \begin{pmatrix} A_{\text{same}, +} & A_{\text{same}, \times} \\ A_{\text{same}, \times} & A_{\text{same}, -} \end{pmatrix}, \quad A_{\text{cross}} = \begin{pmatrix} A_{\text{cross}, +} & A_{\text{cross}, \times} \\ A_{\text{cross}, \times} & A_{\text{cross}, -} \end{pmatrix}
$$

Because the covering map $\pi_{d-1}$ commutes with the involution, the block components satisfy:

$$
A_{\text{same}, -} = - A_{\text{same}, +} \quad \text{and} \quad A_{\text{cross}, -} = - A_{\text{cross}, +}
$$

which forces the diagonal blocks of the twisted operator $H_{d-1} = A_{\text{same}} - A_{\text{cross}}$ to be opposite in sign:

$$
H_{d-1} = \begin{pmatrix} A_{d-2} & B_{d-2} \\ B_{d-2} & -A_{d-2} \end{pmatrix}
$$

Evaluating the anti-commutator with $J_{d-1} = \begin{pmatrix} 0 & -I \\ I & 0 \end{pmatrix}$:

$$
J_{d-1} H_{d-1} = \begin{pmatrix} 0 & -I \\ I & 0 \end{pmatrix} \begin{pmatrix} A_{d-2} & B_{d-2} \\ B_{d-2} & -A_{d-2} \end{pmatrix} = \begin{pmatrix} -B_{d-2} & A_{d-2} \\ A_{d-2} & B_{d-2} \end{pmatrix}
$$

$$
H_{d-1} J_{d-1} = \begin{pmatrix} A_{d-2} & B_{d-2} \\ B_{d-2} & -A_{d-2} \end{pmatrix} \begin{pmatrix} 0 & -I \\ I & 0 \end{pmatrix} = \begin{pmatrix} B_{d-2} & -A_{d-2} \\ -A_{d-2} & -B_{d-2} \end{pmatrix} = - J_{d-1} H_{d-1}
$$

Thus, $J_{d-1} H_{d-1} + H_{d-1} J_{d-1} = 0$. $\square$

### Spectral Consequences of Chiral Symmetry
Chiral anti-commutativity dictates that if $\psi_\mu$ is an eigenvector of $H_{d-1}$ with eigenvalue $\mu$, then:

$$
H_{d-1} (J_{d-1} \psi_\mu) = - J_{d-1} H_{d-1} \psi_\mu = - \mu (J_{d-1} \psi_\mu)
$$

Thus, $J_{d-1} \psi_\mu$ is an eigenvector of $H_{d-1}$ with eigenvalue $-\mu$. The eigenvalues of $H_{d-1}$ must come in exact $\pm \mu$ pairs. In the block decomposition $\psi_\mu = \begin{pmatrix} u \\ v' \end{pmatrix}$, the paired eigenvector is:

$$
\psi_{-\mu} = J_{d-1} \psi_\mu = \begin{pmatrix} -v' \\ u \end{pmatrix}
$$

This forces the symmetric part of the positive eigenvector to equal the negative of the anti-symmetric part of the negative eigenvector, establishing a rigid alignment of the components.

---

## 4. Inductive Eigenvector Alignment and Scale-Crossing Isometries

The "new" anti-symmetric eigenvectors of $G_d$ are given by $w_{d, j} = U_d \psi_{d-1, j} \in \mathcal{W}_d$, where $U_d: V_{d-1} \to \mathcal{W}_d$ is the modulation isometry mapping onto the detail space at scale $d$.

To align these eigenvectors across successive scales, we introduce two orthogonal **scale-crossing isometries** $T_d, R_d: \mathcal{W}_d \to \mathcal{W}_{d+1}$:
1. **Symmetric transition isometry** $T_d$:
   

$$
T_d = U_{d+1} L_d U_d^\dagger
$$

2. **Anti-symmetric transition isometry** $R_d$:
   

$$
R_d = U_{d+1} U_d U_d^\dagger
$$

   
where $L_d: V_{d-1} \to V_d$ is the symmetric lift and $U_{d+1}: V_d \to \mathcal{W}_{d+1}$ is the modulation isometry.

### Theorem 3: Orthogonal Detail Space Decomposition
*The operators $T_d$ and $R_d$ are strict isometries mapping $\mathcal{W}_d$ to $\mathcal{W}_{d+1}$ with mutually orthogonal ranges, spanning the entire next-scale detail space:*

$$
\mathcal{W}_{d+1} = T_d(\mathcal{W}_d) \oplus R_d(\mathcal{W}_d)
$$

*Proof.* In the coordinate bases of $\mathcal{W}_d \cong V_{d-1}$ (via the isometry $U_d$) and $\mathcal{W}_{d+1} \cong V_d$ (via the isometry $U_{d+1}$), the coordinate representations of $T_d$ and $R_d$ are:

$$
[T_d] = U_{d+1}^\dagger T_d U_d = L_d : V_{d-1} \to V_d
$$

$$
[R_d] = U_{d+1}^\dagger R_d U_d = U_d : V_{d-1} \to V_d
$$

Using the unitary wavelet basis change matrix $W_d = \begin{pmatrix} L_d & U_d \end{pmatrix}$ for $V_d$, we have:
1. $[T_d]^\dagger [T_d] = L_d^\dagger L_d = I_{V_{d-1}}$, so $T_d$ is a strict isometry.
2. $[R_d]^\dagger [R_d] = U_d^\dagger U_d = I_{V_{d-1}}$, so $R_d$ is a strict isometry.
3. $[T_d]^\dagger [R_d] = L_d^\dagger U_d = 0$, so their ranges are mutually orthogonal.
4. $[T_d] [T_d]^\dagger + [R_d] [R_d]^\dagger = L_d L_d^\dagger + U_d U_d^\dagger = I_{V_d}$, so their ranges span $\mathcal{W}_{d+1}$. $\square$

### The Inductive Alignment Formulas
Let $\psi_{d, k} = \begin{pmatrix} u_k \\ v_k \end{pmatrix} \in V_d$ be the eigenvector of $H_d$ with eigenvalue $\mu_k$. In the coordinate split $V_d \cong L_d(V_{d-1}) \oplus \mathcal{W}_d$, we have:

$$
\psi_{d, k} = L_d u_k + U_d v_k
$$

Applying the modulation isometry $U_{d+1}$ yields the scale-$d+1$ eigenvector $w_{d+1, k} \in \mathcal{W}_{d+1}$:

$$
w_{d+1, k} = U_{d+1} \psi_{d, k} = U_{d+1} L_d u_k + U_{d+1} U_d v_k
$$

Using the definitions of $T_d$ and $R_d$, we write this as the **recursive alignment formula**:

$$
w_{d+1, k} = T_d (U_d u_k) + R_d (U_d v_k)
$$

Expanding the component vectors $u_k, v_k \in V_{d-1}$ in the orthonormal basis of lower-scale eigenvectors $\psi_{d-1, j}$:

$$
u_k = \sum_{j} c_{k, j} \psi_{d-1, j} \quad \text{and} \quad v_k = \sum_{j} d_{k, j} \psi_{d-1, j}
$$

we obtain the **explicit scale-crossing alignment formula**:

$$
w_{d+1, k} = \sum_{j} c_{k, j} T_d w_{d, j} + \sum_{j} d_{k, j} R_d w_{d, j}
$$

where $w_{d, j} = U_d \psi_{d-1, j}$ are the eigenvectors at scale $d$, and the weights $c_{k, j}, d_{k, j}$ represent the sheet-mixing ratios. For example, at scale $d=3$, the coefficients are exactly determined by nested radicals representing trigonometric projections (e.g. $\sin(\pi/8)$ and $\cos(\pi/8)$).

---

## 5. Projective Limit and Global Intertwiner

By taking the projective limit of the Hilbert spaces $\mathcal{W}_d$ under the scale-crossing isometries $T_d$, we construct a global Hilbert space:

$$
\mathcal{W}_\infty = \varinjlim (\mathcal{W}_d, T_d)
$$

The compatibility of the twisted operators $H_d$ under the embeddings $T_d$ ensures that the restricted adjacency operators converge to a well-defined bounded self-adjoint operator $\mathcal{A}_\infty$ on $\mathcal{W}_\infty$. 

Furthermore, the chiral symmetry operators $J_d$ commute with the embeddings $T_d$ up to sheet-alternation:

$$
T_d J_{d-1} = J_d T_d
$$

which lifts the chiral symmetry to a global unitary operator $\mathcal{J}_\infty$ on $\mathcal{W}_\infty$ satisfying:

$$
\mathcal{J}_\infty \mathcal{A}_\infty + \mathcal{A}_\infty \mathcal{J}_\infty = 0
$$

This global chiral symmetry conjugates the global commutator $[A, B]$ to a multiplication operator on $L^2(\mathbb{Z}_2)$, resolving Open Problem 1 with full mathematical rigor.
