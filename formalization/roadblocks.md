# Formalization Roadblocks: Lean 4 Mathlib

*Date: May 2026*

This document outlines the definitive mathematical roadblocks encountered while attempting to formalize the `TwistedBlockPow` theorem (the $2^{n-1}$ power of the Collatz cycle matrix). Two distinct angles were attempted, and both hit insurmountable limitations in the current state of Lean 4's `Mathlib`.

## Angle 1: The Gravity Attack (p-Adic AdS/CFT & Tensor Networks)

**Goal:** Bypass the discrete matrix issues by mapping the Collatz cycle to a continuous holographic tensor network trace over a $p$-adic Bruhat-Tits tree.
**Attempted Strategies:**
1. **Bulk/Boundary Correlators:** We attempted to evaluate the continuous complex scaling dimensions ($\Delta$) over the discrete tree using the $p$-adic local zeta function $\zeta_p(s)$.
2. **Ryu-Takayanagi Entanglement Entropy:** We mapped the entropy minimal cut onto perfect tensors across the tree and attempted to rigorously define the infinite network trace using projective limits of AF-algebras (Uniformly Hyperfinite algebras).

**Why It Failed:**
1. **Missing Topological Limits:** While we successfully formalized the `IsAFAlgebra` definition via Category Theory and `DirectLimit`, `Mathlib` currently lacks the functional analysis infrastructure to prove that `Algebra.DirectLimit` preserves $C^*$-norms. It is impossible to formally complete the metric space to construct the AF-algebra limit without writing thousands of lines of foundational $C^*$-algebra theory.
2. **Missing Bruhat-Tits Infrastructure:** `Mathlib` does not have unramified extensions of $`\mathbb{Q}_p`$ ($`\mathbb{Q}_q`$) or $p$-adic zeta functions natively defined.
3. **Conceptual Mismatch:** The continuous correlators relying on ultrametric norms structurally do not map cleanly to the rigid, discrete $\{0, 1, -1\}$ cycle matrix without hallucinating invalid topological axioms.

## Angle 2: The Discrete Trace Formula (Finite Upper Half Planes)

**Goal:** Use the finite upper half plane $`H_q`$ over $`\mathbb{F}_q`$ to evaluate the trace of the adjacency operator.
**Why It Failed:**
1. **Spectral Mismatch:** The standard discrete trace formulas (like the Terras trace) yield *real* spectra because the graphs are symmetric and undirected. The `TwistedBlockPow` matrix corresponds to a *directed multigraph* with a purely *complex* spectrum. 
2. **Ring vs. Field:** The trace formulas require evaluating over a finite field $\mathbb{F}_q$. The Collatz identity matrix requires evaluating dynamically over the ring $\mathbb{Z}/2^n\mathbb{Z}$.
3. **Dynamic Characteristic Polynomials:** `Mathlib`'s type-class synthesis completely breaks when trying to compute characteristic polynomials over dynamically sized Fintypes like `ZMod (2^(n-1))`. 

## Conclusion
To clear the `sorry` for $n \ge 3$, Lean 4 first requires massive upstream PRs to `Mathlib` covering:
- Directed multigraph cycle structures.
- 2-Adic Ergodic theory and Fourier analysis over $\mathbb{Z}/p^n\mathbb{Z}$.
- Norm preservation across colimits for $C^*$-algebras.
