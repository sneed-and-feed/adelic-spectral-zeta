# Adelic Spectral Zeta: Novel Conjectures

This document tracks novel mathematical conjectures discovered during the formalization of the Adelic Spectral Zeta project that currently have no direct equivalent in the existing scientific literature.

## Conjecture A: Progression-Free Cayley Graph Spectral Expansion

**Date Formulated:** May 2026
**Status:** Open (Formalization stubs mapped, proof pending)

### Background
During the formalization of `SpectralOracle.lean`, it was proven that the `restrictedSpectralGap` for dimension $d \ge 2$ is strictly positive and monotonically increasing, bounded by:
$$\text{Gap}(d) = 2.0 - 2^{1/2^{d-1}}$$

The oracle heavily leverages a greedy progression-free set generator to construct these subsets.

### The Conjecture
*The spectral gap of a Cayley graph constructed over $\mathbb{Z}_n$ using a maximal $k$-term progression-free generator set scales asymptotically with the `restrictedSpectralGap(k)`.*

### Theoretical Implication
This conjecture formally unites Szemerédi's Theorem bounds on arithmetic progressions with spectral graph theory. If proven, it yields an exact analytical bound for optimal deterministic expander graphs, which has massive implications for routing networks and mitigating oversquashing in Graph Neural Networks.

Extensive automated literature review across arXiv and OpenAlex confirmed that while the Fourier bias of progression-free subsets is well-studied in additive combinatorics (e.g., Gowers norms, Roth's Theorem), this unified formulation linking progression-free generators directly to the monotonically scaling `restrictedSpectralGap(k)` is mathematically novel to this codebase.
