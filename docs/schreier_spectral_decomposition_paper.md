# Formal Verification of Spectral Decomposition for Schreier Graph Towers

**Abstract**
This paper presents a formal verification framework for the spectral decomposition of Schreier graph towers. We detail the construction of the Schreier graph family, its symmetric and antisymmetric block decompositions, and the formal proofs of the Perron-Frobenius spectral gap. Furthermore, we formalize the spectral recursion polynomials that govern the eigenvalues across the tower. A key contribution of this work is the formalization and verification of dynamic test vector scaling, defined by $L(d) = \lfloor d/2 \rfloor$, which provides an efficient, verified methodology for bounding spectral properties. This work establishes a rigorous foundation for spectral graph theory in formal proof systems, focusing entirely on the graph-theoretic and algebraic properties of the Schreier towers, isolated from external number-theoretic or dynamical conjectures.

## 1. Introduction

The spectral theory of graphs provides deep insights into the structural properties of networks, random walks, and expander graphs. For families of graphs that grow iteratively—such as towers of Schreier graphs—the spectrum of each successive graph often exhibits recursive properties that can be exploited for efficient computation and analysis. As these towers grow exponentially in size, computational techniques must shift from direct matrix diagonalization to recursive algebraic methods and bounded approximation.

In recent years, the formal verification of complex mathematical structures has become increasingly important. While significant progress has been made in formalizing abstract algebra and basic graph theory, the formal verification of advanced spectral graph theory remains a challenging frontier. This paper addresses this gap by formalizing the spectral decomposition of Schreier graph towers inside a mechanized proof assistant.

Our focus is entirely on the algebraic decomposition of the adjacency matrices into symmetric and antisymmetric blocks, a technique that drastically simplifies the computation of the spectrum. We provide formally verified bounds on the Perron-Frobenius eigenvalue and the associated spectral gap. To manage the complexity of higher levels of the tower, we introduce and formally verify the method of dynamic test vector scaling, where the length of the test vectors scales as $L(d) = \lfloor d/2 \rfloor$ with the depth $d$ of the tower. This allows the formal system to verify spectral bounds using truncated, computationally tractable vectors without sacrificing mathematical rigor.

## 2. The Schreier Graph Family

### 2.1 Definition of the Graph Tower
Let $G$ be a finitely generated group and $S$ be a finite symmetric generating set. Given a chain of subgroups $`H_0 \supset H_1 \supset H_2 \supset \dots \supset H_d \dots`$ of finite index, the Schreier graph at depth $d$, denoted $`\Gamma_d = \text{Sch}(G, H_d, S)`$, is defined with the vertex set $`V_d = G/H_d`$ (the right cosets of $`H_d`$). The edges are given by right multiplication: for every coset $`C \in V_d`$ and generator $s \in S$, there is a directed edge from $C$ to $Cs$. Because $S$ is symmetric, $`\Gamma_d`$ is an undirected, $|S|$-regular graph.

The sequence $`\{\Gamma_d\}_{d=0}^\infty`$ forms a *tower of Schreier graphs*. The natural quotient maps $`\pi_d : G/H_{d} \to G/H_{d-1}`$ induce graph coverings $`\Gamma_d \to \Gamma_{d-1}`$. This covering property is essential, as it guarantees that the spectrum of $`\Gamma_{d-1}`$ is fully contained within the spectrum of $`\Gamma_d`$.

### 2.2 Adjacency Matrices and Operators
The adjacency matrix $`A_d`$ of $`\Gamma_d`$ acts on the Hilbert space $`L^2(V_d)`$. For a function $`f: V_d \to \mathbb{R}`$, the adjacency operator is defined as:

$$
(A_d f)(v) = \sum_{s \in S} f(vs)
$$

Since $`\Gamma_d`$ is regular, the top eigenvalue is exactly $|S|$, corresponding to the constant function. The formal verification of the tower requires a rigorous encoding of these finite dimensional Hilbert spaces and the linear operators acting upon them, particularly emphasizing the lifting of functions from $`L^2(V_{d-1})`$ to $`L^2(V_d)`$.

### 2.3 Structural Symmetries
The covering map implies a structural symmetry. If $`[H_{d-1} : H_d] = 2`$, which is common in binary tower constructions, there is an associated deck transformation—an involution $`\sigma_d : V_d \to V_d`$ that swaps the two vertices in the fiber of each vertex in $`V_{d-1}`$. This involution commutes with the adjacency operator $`A_d`$, a property we will exploit to block-diagonalize the matrix.

## 3. Symmetric and Antisymmetric Block Decomposition

### 3.1 Involution and Subspace Splitting
The involution $`\sigma_d`$ on the vertex set $`V_d`$ naturally induces an operator on $`L^2(V_d)`$, denoted $`P_{\sigma}`$. Since $`\sigma_d^2 = \text{id}`$, the operator satisfies $`P_{\sigma}^2 = I`$, meaning its eigenvalues are $+1$ and $-1$. Consequently, the vector space $`L^2(V_d)`$ splits into a direct sum of two orthogonal subspaces:

$$
L^2(V_d) = \mathcal{V}_d^+ \oplus \mathcal{V}_d^-
$$

where $`\mathcal{V}_d^+`$ consists of functions symmetric under the involution (i.e., $`f(\sigma_d v) = f(v)`$), and $`\mathcal{V}_d^-`$ consists of antisymmetric functions (i.e., $`f(\sigma_d v) = -f(v)`$).

### 3.2 The Symmetric Block $M^+$
Functions in $`\mathcal{V}_d^+`$ are precisely those that are constant on the fibers of the covering map. Therefore, $`\mathcal{V}_d^+`$ is naturally isomorphic to $`L^2(V_{d-1})`$. The restriction of the adjacency operator $`A_d`$ to $`\mathcal{V}_d^+`$, which we denote as $M^+$, is unitarily equivalent to $`A_{d-1}`$. This formalizes the notion that the spectrum of the smaller graph is inherited by the larger graph.

### 3.3 The Antisymmetric Block $M^-$
The restriction of $`A_d`$ to the antisymmetric subspace $`\mathcal{V}_d^-`$ yields the block matrix $M^-$. The eigenvalues of $M^-$ are exactly the "new" eigenvalues of $`\Gamma_d`$ that do not appear in $`\Gamma_{d-1}`$. 

In the formal proof assistant, we define an explicit unitary transformation $`U_d`$ that block-diagonalizes $`A_d`$:

$$
U_d^\dagger A_d U_d = \begin{pmatrix} M^+ & 0 \\ 0 & M^- \end{pmatrix}
$$

The verification of this decomposition relies on proving that $`A_d`$ and $`P_\sigma`$ commute, followed by an application of the spectral theorem for finite-dimensional commuting operators.

### 3.4 Formal Verification of the Orthogonal Decomposition
The mechanized proof of this decomposition requires:
1. Definition of the involution $\sigma_d$.
2. Proof of commutation: $`A_d P_\sigma = P_\sigma A_d`$.
3. Construction of the projection operators $`\Pi^+ = \frac{1}{2}(I + P_\sigma)`$ and $`\Pi^- = \frac{1}{2}(I - P_\sigma)`$.
4. Verification that $\Pi^+ + \Pi^- = I$ and $\Pi^+ \Pi^- = 0$.
By formally verifying this block decomposition, we reduce the computational effort of analyzing $\Gamma_d$ by a factor of two, recursively allowing the analysis to focus solely on the $M^-$ blocks at each depth.

## 4. Perron-Frobenius Spectral Gap

### 4.1 The Perron-Frobenius Theorem for Schreier Graphs
Because $`\Gamma_d`$ is a connected, undirected, $|S|$-regular graph, the Perron-Frobenius theorem guarantees that the maximum eigenvalue is exactly $`\lambda_0 = |S|`$, and it is simple. The corresponding eigenvector is the all-ones vector $\mathbf{1}$, which resides in the symmetric subspace $`\mathcal{V}_d^+`$ (and ultimately originates from the base graph $`\Gamma_0`$).

The spectral gap $\Delta_d$ is defined as the difference between the degree $|S|$ and the second largest eigenvalue in absolute value:

$$
\Delta_d = |S| - \max_{\lambda_i \neq |S|} |\lambda_i|
$$

### 4.2 Formally Verified Bounds on the Spectral Gap
In many applications, we wish to prove that $`\Gamma_d`$ forms an expander family, which requires showing that $`\Delta_d`$ is bounded below by a strictly positive constant independent of $d$. 
To mechanize this, we must verify the Rayleigh quotient bound for the second eigenvalue:

$$
\lambda_1 \le \max_{x \perp \mathbf{1}, x \neq 0} \frac{x^T A_d x}{x^T x}
$$

Because the spectrum of $\Gamma_d$ is the union of the spectra of $M^+$ and $M^-$, bounding the spectral gap of the tower is equivalent to recursively bounding the top eigenvalues of the $M^-$ blocks.

### 4.3 Expander Mixing Lemma Implications
A formally verified bound on the spectral gap immediately yields a verified instance of the Expander Mixing Lemma for the Schreier tower. The formalization of this lemma demonstrates that for any two subsets of vertices $X, Y \subset V_d$, the number of edges between $X$ and $Y$, denoted $E(X,Y)$, satisfies:

$$
\left| E(X,Y) - \frac{|S| \cdot |X| \cdot |Y|}{|V_d|} \right| \le (|S| - \Delta_d) \sqrt{|X| |Y|}
$$

This provides a rigid combinatorial verification of the pseudo-random properties of the Schreier graphs entirely within the type-safe environment of the proof assistant.

## 5. Spectral Recursion Polynomials

### 5.1 Characteristic Polynomials of the Tower
Let $`P_d(x) = \det(xI - A_d)`$ be the characteristic polynomial of $`\Gamma_d`$. Using the block decomposition, we can factor $`P_d(x)`$ as:

$$
P_d(x) = \det(xI - M^+) \det(xI - M^-)
$$

Since $M^+$ is equivalent to $`A_{d-1}`$, we have $`P_d(x) = P_{d-1}(x) Q_d(x)`$, where $`Q_d(x) = \det(xI - M^-)`$. This factorization demonstrates that the spectrum grows by incorporating the roots of the polynomials $`Q_d(x)`$ at each level.

### 5.2 The Chebyshev-like Recurrence Relation
For certain symmetric generating sets and algebraic constructions of Schreier towers, the polynomials $Q_d(x)$ satisfy a recurrence relation analogous to the Chebyshev polynomials. Specifically, we can express the adjacency operator at depth $d$ as a polynomial evaluated on a base operator, mapping the spectrum algebraically. 

The formalization defines the recurrence map $R(x)$, such that:

$$
\lambda \in \text{Spec}(A_{d-1}) \iff R(\lambda) \subset \text{Spec}(A_d)
$$

This algebraic constraint forces the eigenvalues to follow specific trajectories as $d \to \infty$.

### 5.3 Mechanized Proofs of Spectral Lifting
The theorem prover mechanizes the identity $`P_d(x) = P_{d-1}(x) Q_d(x)`$ via block matrix determinants. The proof involves:
1. Defining the determinant of block-diagonal matrices in the formal library.
2. Formally relating the matrix polynomial evaluation to the characteristic roots.
3. Using induction on $d$ to express $`P_d(x)`$ as $`P_0(x) \prod_{k=1}^d Q_k(x)`$.
This recursive polynomial structure forms the backbone of the automated verification tactics used to check the eigenvalues at arbitrary depth.

## 6. Dynamic Test Vector Scaling $L(d) = \lfloor d/2 \rfloor$

### 6.1 The Need for Bounded Verification
Computing the exact spectral gap for $`\Gamma_d`$ becomes computationally intractable in a formal proof assistant as $d$ increases, due to the exponential growth of the state space $`|V_d|`$. To rigorously bound the Rayleigh quotient of $M^-$ without constructing the full matrix, we utilize sparse test vectors.

### 6.2 Definition of the Dynamic Scaling Heuristic
We construct a family of test vectors $v_d$ for the $M^-$ block. Instead of relying on full dense vectors, we truncate the vectors to a local neighborhood of a fixed base vertex. To optimize the formal verification time while maintaining sufficient accuracy for bounding the spectral radius, we scale the depth of this neighborhood, which we call the *test vector length* $L$.

The dynamically scaled test vector length is defined as:

$$
L(d) = \lfloor d/2 \rfloor
$$

This choice balances the expressivity of the test vector (which must be long enough to capture the long-range combinatorial structure of the graph) with the computational overhead in the proof assistant (which scales exponentially with $L$).

### 6.3 Formal Proof of Bound Preservation under $L(d)$ Truncation
To verify that the dynamically scaled test vector provides a valid bound, we formally prove that:

$$
\rho(M^-) \ge \frac{v_d^T M^- v_d}{v_d^T v_d}
$$

where $v_d$ is the truncated test vector of length $L(d)$.
The formal proof requires establishing that $`v_d`$ lies entirely within the antisymmetric subspace $`\mathcal{V}_d^-`$ (i.e., $`P_\sigma v_d = -v_d`$) and that it is orthogonal to the all-ones vector. 

The truncation error introduced by stopping at radius $L(d) = \lfloor d/2 \rfloor$ is bounded formally. We mechanize the proof that the boundary terms of the truncated vector contribute a rigorously bounded deficit to the Rayleigh quotient, ensuring that the inequality remains strictly valid and logically sound inside the theorem prover.

### 6.4 Computational Complexity in the Proof Assistant
By limiting the support of the test vector to a ball of radius $\lfloor d/2 \rfloor$, the number of non-zero entries in $`v_d`$ is bounded by $O(|S|^{\lfloor d/2 \rfloor})$. Because the inner product $`v_d^T M^- v_d`$ is evaluated entirely via symbolic and bounded rational arithmetic within the proof assistant kernel, reducing the exponent from $d$ to $d/2$ squares the maximum depth $d$ that can be formally verified within standard memory limits. This dynamic scaling is the primary innovation allowing the formal verification of deep Schreier graph towers.

## 7. Implementation in Formal Proof Systems

### 7.1 Encoding Matrix Algebra
The foundation of the mechanization is a robust library for finite-dimensional Hilbert spaces. We represent vectors as strongly typed arrays indexed by finite types, and linear operators as matrices. The inner product, norm, and Rayleigh quotient are defined using exact rational arithmetic to avoid floating-point approximations, ensuring absolute soundness.

### 7.2 Representing Graph Towers
The tower of groups $`H_d`$ is encoded using records and typeclasses, defining the subgroup relation and index dynamically. The Schreier graph vertices are represented as quotient types. The covering map $`\pi_d`$ and the involution $`\sigma_d`$ are explicitly constructed as computable functions.

### 7.3 Tactics for Spectral Bounds
We developed custom proof tactics to automate the application of the dynamic test vector $L(d)$. Given a depth $d$, the tactic:
1. Automatically synthesizes the antisymmetric test vector $v_d$ with radius $L(d) = \lfloor d/2 \rfloor$.
2. Generates the exact rational values for the numerator and denominator of the Rayleigh quotient.
3. Automatically proves the orthogonality conditions.
4. Concludes the lower bound on the spectral radius of $M^-$ and the resulting upper bound on the spectral gap.

## 8. Conclusion
The formal verification of the spectral decomposition of Schreier graph towers demonstrates the viability of mechanized proof systems for advanced spectral graph theory. By formally establishing the symmetric and antisymmetric block decomposition, we provided a rigorous foundation for bounding the Perron-Frobenius spectral gap. 

The introduction of dynamic test vector scaling, $L(d) = \lfloor d/2 \rfloor$, bridges the gap between deep mathematical theory and practical computational verification. By scaling the test vector support logarithmically with the graph size, we enabled the mechanized bounding of eigenvalues at significant depths without overwhelming the theorem prover's kernel. This framework not only validates the structural properties of these graphs but also provides a reusable toolkit for formally verifying the spectral properties of other bounded-degree expander graph families.

## References
[1] Alon, N. (1986). Eigenvalues and expanders. *Combinatorica*, 6(2), 83-96.
[2] Hoory, S., Linial, N., & Wigderson, A. (2006). Expander graphs and their applications. *Bulletin of the American Mathematical Society*, 43(4), 439-561.
[3] Grigorchuk, R., & Żuk, A. (2001). The lamplighter group as a group generated by a 2-state automaton, and its spectrum. *Geometriae Dedicata*, 87(1-3), 209-244.
[4] MacWilliams, F. J., & Sloane, N. J. A. (1977). The Theory of Error-Correcting Codes. North-Holland.
[5] Hales, T. C., et al. (2017). A formal proof of the Kepler conjecture. *Forum of Mathematics, Pi*, 5, e2.
