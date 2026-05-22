# Mathematical Proof: Spectral Gap of the Collatz Transfer Operator on $`C^\alpha(\mathbb{Z}_2)`$

This document presents a formal, rigorous mathematical proof of the existence of a spectral gap for the transfer operator associated with the shortcut Collatz map on the ring of 2-adic integers $`\mathbb{Z}_2`$, restricted to the Banach space of $`\alpha`$-Hölder continuous functions.

---

## 1. Setup and Definition of Dynamics

Let $`\mathbb{Z}_2 = \varprojlim \mathbb{Z}/2^d\mathbb{Z}`$ be the ring of 2-adic integers, equipped with the standard 2-adic valuation $`v_2: \mathbb{Z}_2 \to \mathbb{Z} \cup \{\infty\}`$ and the ultrametric:
```math
d_2(x, y) = |x - y|_2 = 2^{-v_2(x - y)}
```
The shortcut Collatz map $`T: \mathbb{Z}_2 \to \mathbb{Z}_2`$ is defined by:
```math
T(x) = \begin{cases} \frac{x}{2} & \text{if } x \equiv 0 \pmod{2} \\ \frac{3x+1}{2} & \text{if } x \equiv 1 \pmod{2} \end{cases}
```

### Lemma 1: Preimage Structure of $`T`$
*For every $`x \in \mathbb{Z}_2`$, the set of preimages $`T^{-1}(x)`$ contains exactly two elements:*
```math
y_0 = 2x \quad (\text{even}) \quad \text{and} \quad y_1 = \frac{2x-1}{3} \quad (\text{odd})
```
*Consequently, $`T`$ is a continuous 2-to-1 covering map of $`\mathbb{Z}_2`$.*

*Proof.* 
1.  **Existence & Parity of Even Preimage:** Let $`y_0 = 2x`$. Since $`y_0`$ is even, $`T(y_0) = y_0/2 = x`$. Thus $`y_0 \in T^{-1}(x)`$ and is even.
2.  **Existence & Parity of Odd Preimage:** Let $`y_1 = (2x-1)/3`$. In $`\mathbb{Z}_2`$, $`3`$ is a unit (since $`|3|_2 = 2^{-0} = 1`$), so $`3^{-1}`$ exists and is in $`\mathbb{Z}_2`$, meaning $`y_1 \in \mathbb{Z}_2`$. Evaluating modulo 2:
    ```math
    3 y_1 = 2x-1 \equiv 1 \pmod{2} \implies 1 \cdot y_1 \equiv 1 \pmod{2} \implies y_1 \equiv 1 \pmod{2}
    ```
    Thus $`y_1`$ is odd. Applying $`T`$ yields:
    ```math
    T(y_1) = \frac{3y_1+1}{2} = \frac{3\frac{2x-1}{3}+1}{2} = x
    ```
    So $`y_1 \in T^{-1}(x)`$ and is odd.
3.  **Uniqueness:** Any preimage $`y`$ must be even or odd. If $`y`$ is even, $`y/2 = x \implies y = 2x`$. If $`y`$ is odd, $`(3y+1)/2 = x \implies 3y+1 = 2x \implies y = (2x-1)/3`$. Thus, $`T^{-1}(x)`$ has exactly these two elements. $`\square`$

---

## 2. Metric Contraction of the Inverse Branches

Let the inverse branches of $`T`$ be $`g_0, g_1: \mathbb{Z}_2 \to \mathbb{Z}_2`$ defined by:
```math
g_0(x) = 2x, \quad g_1(x) = \frac{2x-1}{3}
```

### Lemma 2: Lipschitz Contraction of Inverse Branches
*For all $`x, y \in \mathbb{Z}_2`$, the inverse branches $`g_0`$ and $`g_1`$ satisfy:*
```math
|g_0(x) - g_0(y)|_2 = \frac{1}{2} |x - y|_2
```
```math
|g_1(x) - g_1(y)|_2 = \frac{1}{2} |x - y|_2
```

*Proof.*
1.  **Even Branch:**
    ```math
    |g_0(x) - g_0(y)|_2 = |2x - 2y|_2 = |2|_2 |x - y|_2 = \frac{1}{2} |x - y|_2
    ```
2.  **Odd Branch:**
    ```math
    |g_1(x) - g_1(y)|_2 = \left| \frac{2x-1}{3} - \frac{2y-1}{3} \right)_2 = \left| \frac{2(x-y)}{3} \right)_2 = \frac{|2|_2}{|3|_2} |x - y|_2
    ```
    Since $`3 \equiv 1 \pmod{2}`$, $`3`$ is not divisible by $`2`$, so $`v_2(3) = 0 \implies |3|_2 = 1`$. Thus:
    ```math
    |g_1(x) - g_1(y)|_2 = \frac{1/2}{1} |x - y|_2 = \frac{1}{2} |x - y|_2
    ```
    Both branches contract the 2-adic distance by exactly the factor $`1/2`$. $`\square`$

---

## 3. The Lasota-Yorke Inequality

Let $`C(\mathbb{Z}_2)`$ be the Banach space of continuous functions on $`\mathbb{Z}_2`$ under the supremum norm $`\|f\|_\infty = \sup_{x \in \mathbb{Z}_2} |f(x)|`$.
For $`\alpha > 0`$, let $`C^\alpha(\mathbb{Z}_2)`$ be the space of $`\alpha`$-Hölder continuous functions on $`\mathbb{Z}_2`$ equipped with the norm:
```math
\|f\|_\alpha = \|f\|_\infty + v_\alpha(f)
```
where
```math
v_\alpha(f) = \sup_{x \neq y} \frac{|f(x) - f(y)|}{|x - y|_2^\alpha}
```
The transfer operator $`B: C(\mathbb{Z}_2) \to C(\mathbb{Z}_2)`$ is:
```math
(B f)(x) = \frac{1}{2} f(g_0(x)) + \frac{1}{2} f(g_1(x))
```

### Lemma 3: Contraction of the Hölder Seminorm
*For any $`f \in C^\alpha(\mathbb{Z}_2)`$, the transfer operator $`B`$ satisfies:*
```math
v_\alpha(B f) \le 2^{-\alpha} v_\alpha(f)
```

*Proof.* Let $`x \neq y`$ in $`\mathbb{Z}_2`$. We evaluate:
```math
\frac{|(B f)(x) - (B f)(y)|}{|x - y|_2^\alpha} \le \frac{1}{2} \frac{|f(g_0(x)) - f(g_0(y))|}{|x - y|_2^\alpha} + \frac{1}{2} \frac{|f(g_1(x)) - f(g_1(y))|}{|x - y|_2^\alpha}
```
Using the contraction properties from Lemma 2:
```math
\frac{|f(g_0(x)) - f(g_0(y))|}{|x - y|_2^\alpha} = \frac{|f(g_0(x)) - f(g_0(y))|}{|g_0(x) - g_0(y)|_2^\alpha} \cdot \left( \frac{|g_0(x) - g_0(y)|_2}{|x - y|_2} \right)^\alpha \le v_\alpha(f) \cdot \left(\frac{1}{2}\right)^\alpha
```
Applying the same scaling to the $`g_1`$ term:
```math
\frac{|f(g_1(x)) - f(g_1(y))|}{|x - y|_2^\alpha} = \frac{|f(g_1(x)) - f(g_1(y))|}{|g_1(x) - g_1(y)|_2^\alpha} \cdot \left( \frac{|g_1(x) - g_1(y)|_2}{|x - y|_2} \right)^\alpha \le v_\alpha(f) \cdot \left(\frac{1}{2}\right)^\alpha
```
Substituting these bounds back into the inequality:
```math
\frac{|(B f)(x) - (B f)(y)|}{|x - y|_2^\alpha} \le \frac{1}{2} 2^{-\alpha} v_\alpha(f) + \frac{1}{2} 2^{-\alpha} v_\alpha(f) = 2^{-\alpha} v_\alpha(f)
```
Taking the supremum over all $`x \neq y`$, we establish $`v_\alpha(B f) \le 2^{-\alpha} v_\alpha(f)`$. $`\square`$

### Theorem 4: Lasota-Yorke Inequality
*For all $`f \in C^\alpha(\mathbb{Z}_2)`$, we have:*
```math
\|B f\|_\alpha \le 2^{-\alpha} \|f\|_\alpha + (1 - 2^{-\alpha}) \|f\|_\infty
```

*Proof.* Since $`B`$ is a Markov operator (non-negative and $`B 1 = 1`$), it is bounded on $`C(\mathbb{Z}_2)`$ with norm exactly $`1`$:
```math
\|B f\|_\infty \le \frac{1}{2} \|f\|_\infty + \frac{1}{2} \|f\|_\infty = \|f\|_\infty
```
Adding the seminorm contraction from Lemma 3:
```math
\|B f\|_\alpha = \|B f\|_\infty + v_\alpha(B f) \le \|f\|_\infty + 2^{-\alpha} v_\alpha(f)
```
Adding and subtracting $`2^{-\alpha} \|f\|_\infty`$:
```math
\|B f\|_\alpha \le 2^{-\alpha} (\|f\|_\infty + v_\alpha(f)) + (1 - 2^{-\alpha}) \|f\|_\infty = 2^{-\alpha} \|f\|_\alpha + (1 - 2^{-\alpha}) \|f\|_\infty
```
This is the standard Lasota-Yorke inequality with contraction coefficient $`\theta = 2^{-\alpha} < 1`$. $`\square`$

---

## 4. Quasi-Compactness and the Ionescu-Tulcea & Marinescu Theorem

To prove quasi-compactness, we use the classical Ionescu-Tulcea and Marinescu (ITM) theorem:

### Theorem (Ionescu-Tulcea & Marinescu)
*Let $`(V, \|\cdot\|_V)`$ and $`(W, \|\cdot\|_W)`$ be two Banach spaces such that $`V \subset W`$ is a dense subspace and the injection $`V \hookrightarrow W`$ is a compact operator.*
*Let $`L: W \to W`$ be a bounded linear operator such that $`L(V) \subset V`$, and there exist constants $`C > 0`$, $`C' > 0`$, and $`\theta < 1`$ such that:*
1.  $`\|L f\|_W \le C \|f\|_W`$ *for all $`f \in W`$.*
2.  $`\|L f\|_V \le \theta \|f\|_V + C' \|f\|_W`$ *for all $`f \in V`$.*

*Then $`L`$ viewed as an operator on $`V`$ is quasi-compact: its essential spectral radius is bounded by $`\theta`$, and the spectrum of $`L`$ on $`V`$ in the region $`\{ z \in \mathbb{C} \mid |z| > \theta \}`$ consists of a finite number of eigenvalues of finite multiplicity.*

### Theorem 5: Quasi-Compactness of $`B`$
*The transfer operator $`B`$ is quasi-compact on the Banach space $`C^\alpha(\mathbb{Z}_2)`$, and its essential spectral radius satisfies:*
```math
r_{ess}(B) \le 2^{-\alpha} < 1
```

*Proof.* We check the hypotheses of the ITM theorem with $`V = C^\alpha(\mathbb{Z}_2)`$ and $`W = C(\mathbb{Z}_2)`$:
1.  **Dense Embedding:** The space of locally constant functions on $`\mathbb{Z}_2`$ is dense in both $`C^\alpha(\mathbb{Z}_2)`$ and $`C(\mathbb{Z}_2)`$. Since it is a subspace of both, $`C^\alpha(\mathbb{Z}_2)`$ is dense in $`C(\mathbb{Z}_2)`$.
2.  **Compact Embedding:** $`\mathbb{Z}_2`$ is compact. By the ultrametric version of the Arzelà-Ascoli theorem, a subset of $`C(\mathbb{Z}_2)`$ is relatively compact if and only if it is bounded and equicontinuous. A bounded subset of $`C^\alpha(\mathbb{Z}_2)`$ satisfies $`|f(x) - f(y)| \le M |x-y|_2^\alpha`$, which implies uniform equicontinuity. Thus, the unit ball of $`C^\alpha(\mathbb{Z}_2)`$ is relatively compact in $`C(\mathbb{Z}_2)`$, proving the embedding is compact.
3.  **Operator Bounds:**
    *   $`\|B f\|_\infty \le \|f\|_\infty`$ (proven in Theorem 4, with $`C = 1`$).
    *   $`\|B f\|_\alpha \le 2^{-\alpha} \|f\|_\alpha + (1 - 2^{-\alpha}) \|f\|_\infty`$ (proven in Theorem 4, with $`\theta = 2^{-\alpha} < 1`$ and $`C' = 1 - 2^{-\alpha}`$).

All conditions are satisfied. By the ITM theorem, $`B`$ is quasi-compact on $`C^\alpha(\mathbb{Z}_2)`$ and $`r_{ess}(B) \le 2^{-\alpha}`$. $`\square`$

---

## 5. Characterization of the Peripheral Spectrum & Spectral Gap

The peripheral spectrum consists of eigenvalues on the unit circle:
```math
\sigma_{per}(B) = \{ z \in \sigma(B) \mid |z| = 1 \}
```

### Lemma 6 (Revised): Uniqueness of Dominant Eigenvalue
*The only eigenvalue of $`B`$ on $`C^\alpha(\mathbb{Z}_2)`$ on the unit circle is $`1.0`$. The eigenspace is one-dimensional and consists of constant functions.*

*Proof.* Let $`f \in C^\alpha(\mathbb{Z}_2)`$ satisfy $`Bf = \lambda f`$ with $`|\lambda| = 1`$. Then for every $`n \ge 1`$:
```math
v_\alpha(f) = v_\alpha(\lambda^{-n} B^n f) = v_\alpha(B^n f)
```
By iterating Lemma 3, $`v_\alpha(B^n f) \le 2^{-n\alpha} v_\alpha(f)`$. Thus:
```math
v_\alpha(f) \le 2^{-n\alpha} v_\alpha(f) \quad \text{for all } n \ge 1
```
Since $`2^{-\alpha} < 1`$, taking $`n \to \infty`$ yields $`v_\alpha(f) = 0`$. Therefore $`f`$ is constant. Since $`B`$ is Markov ($`B 1 = 1`$), any constant $`f = c \cdot 1`$ satisfies $`Bf = f`$, forcing $`\lambda = 1`$. $`\square`$

### Theorem 7: Spectral Gap
*The transfer operator $`B`$ has a spectral gap on $`C^\alpha(\mathbb{Z}_2)`$. That is, there exists a constant $`r \in (2^{-\alpha}, 1)`$ such that the spectrum of $`B`$ satisfies:*
```math
\sigma(B) \subset \{1.0\} \cup \{ z \in \mathbb{C} \mid |z| \le r \}
```

*Proof.* By Theorem 5, the essential spectral radius is bounded by $`2^{-\alpha} < 1`$. Therefore, any spectrum in the region $`\{z \mid |z| > 2^{-\alpha}\}`$ must consist of isolated eigenvalues of finite multiplicity.
By Lemma 6, the only eigenvalue on the unit circle is $`1.0`$.
Since the spectrum of a bounded operator is closed, and the only point of the spectrum on the unit circle is the isolated eigenvalue $`1.0`$, the remaining eigenvalues in the region $`\{z \mid |z| > 2^{-\alpha}\}`$ must be bounded away from the unit circle.
Thus, there exists some $`r < 1`$ such that all eigenvalues other than $`1.0`$ satisfy $`|z| \le r`$.
This establishes the spectral gap. $`\square`$
