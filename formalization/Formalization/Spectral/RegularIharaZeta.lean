import Mathlib.LinearAlgebra.Matrix.Determinant.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Dart
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Formalization.Spectral.IharaBass
import Formalization.Spectral.IharaZeta

/-!
# Ihara-Bass Formula for Regular Graphs

This module specializes the general Ihara-Bass polynomial determinant identity
to $d$-regular finite graphs, including trivalent ($d = 3$) and 4-regular graphs
arising from 2-adic trees, Bruhat-Tits buildings, and Schreier graphs.

## Main Definitions
- `regularIharaBassMatrix`: The regular Ihara-Bass characteristic matrix $(1 + (d - 1) u^2) I - u A$.

## Main Theorems
- `degree_diagonal_sub_one_of_regular`: Diagonal degree matrix minus identity simplifies to $(d - 1) I$.
- `card_dart_of_regular`: Total number of darts $|D| = d |V|$ for a $d$-regular graph.
- `ihara_bass_regular_polynomial`: Ihara-Bass determinant identity for general $d$-regular graphs.
- `ihara_bass_trivalent_polynomial`: Ihara-Bass identity for 3-regular graphs ($d = 3$, factor $1 + 2u^2$).
- `ihara_bass_4regular_polynomial`: Ihara-Bass identity for 4-regular graphs ($d = 4$, factor $1 + 3u^2$).

## References
- Ihara, Y. (1966). *On discrete subgroups of the two by two projective linear group over p-adic fields*.
- Bass, H. (1992). *The Ihara-Selberg zeta function of a tree lattice*.
- Sunada, T. (1986). *L-functions in geometry and some applications*.
-/

open Matrix
open scoped Matrix

section RegularIharaZeta

variable {V : Type*} [Fintype V] [DecidableEq V]
variable (G : SimpleGraph V) [DecidableRel G.Adj]
variable {d : ℕ}
variable (R : Type*) [CommRing R]
variable (u : R)

/-- The Ihara-Bass characteristic matrix for a $d$-regular graph with adjacency matrix $A$:
$(1 + (d - 1) u^2) I - u A$. -/
noncomputable def regularIharaBassMatrix {V : Type*} [Fintype V] [DecidableEq V] {R : Type*} [CommRing R]
    (d : ℕ) (A : Matrix V V R) (u : R) : Matrix V V R :=
  (1 + ((d : R) - 1) * u^2) • 1 - u • A

omit [DecidableEq V] in
/-- For a $d$-regular graph, the number of directed darts equals $d \cdot |V|$. -/
lemma card_dart_of_regular (h_reg : G.IsRegularOfDegree d) :
    Fintype.card G.Dart = d * Fintype.card V := by
  rw [G.dart_card_eq_sum_degrees]
  simp [h_reg.degree_eq, Finset.sum_const, mul_comm]

/-- For a $d$-regular graph, the diagonal degree matrix minus identity is $((d : R) - 1) \cdot I$. -/
lemma degree_diagonal_sub_one_of_regular (h_reg : G.IsRegularOfDegree d) :
    Matrix.diagonal (fun v => (G.degree v : R)) - (1 : Matrix V V R) = ((d : R) - 1) • (1 : Matrix V V R) := by
  ext i j
  by_cases h : i = j
  · subst h
    simp [Matrix.sub_apply, Matrix.smul_apply, h_reg.degree_eq]
  · simp [Matrix.sub_apply, Matrix.smul_apply, h]

/-- The vertex-level block simplifies to the regular Ihara-Bass matrix. -/
lemma regular_ihara_bass_block_eq (h_reg : G.IsRegularOfDegree d) :
    1 - u • G.adjMatrix R + u^2 • (Matrix.diagonal (fun v => (G.degree v : R)) - 1) =
    (1 + ((d : R) - 1) * u^2) • (1 : Matrix V V R) - u • G.adjMatrix R := by
  rw [degree_diagonal_sub_one_of_regular G (R := R) h_reg]
  ext i j
  by_cases h : i = j
  · subst h
    simp [Matrix.add_apply, Matrix.sub_apply, Matrix.smul_apply]
    ring
  · simp [Matrix.add_apply, Matrix.sub_apply, Matrix.smul_apply, h]

/-- **Ihara-Bass Determinantal Formula for Regular Graphs**:
For any $d$-regular finite graph $G$, the Hashimoto edge-adjacency determinant satisfies:
$$ \det(I - u T) \det(I - u J) (1 - u^2)^{|V|} = \det((1 + (d - 1) u^2) I - u A) (1 - u^2)^{d |V|} $$
-/
theorem ihara_bass_regular_polynomial (h_reg : G.IsRegularOfDegree d) :
    det (1 - u • HashimotoMatrix G R) * det (1 - u • Dart.involutionMatrix G R) * (1 - u^2)^(Fintype.card V) =
    det ((1 + ((d : R) - 1) * u^2) • 1 - u • G.adjMatrix R) * (1 - u^2)^(d * Fintype.card V) := by
  have h_base := ihara_bass_polynomial G R u
  rw [card_dart_of_regular G h_reg] at h_base
  rw [regular_ihara_bass_block_eq G (R := R) u h_reg] at h_base
  exact h_base

/-- **Ihara-Bass Formula for Regular Graphs (Matrix Formulation)**:
Alternative statement expressed via `regularIharaBassMatrix`. -/
theorem ihara_bass_regular_polynomial' (h_reg : G.IsRegularOfDegree d) :
    det (1 - u • HashimotoMatrix G R) * det (1 - u • Dart.involutionMatrix G R) * (1 - u^2)^(Fintype.card V) =
    det (regularIharaBassMatrix d (G.adjMatrix R) u) * (1 - u^2)^(d * Fintype.card V) :=
  ihara_bass_regular_polynomial G R u h_reg

/-- **Specialization to 3-regular (trivalent) graphs**:
For $d = 3$ (e.g., Bruhat-Tits tree $\mathcal{T}_3$ quotients, 2-adic Ramanujan graphs),
the characteristic factor is $(1 + 2u^2) I - u A$. -/
theorem ihara_bass_trivalent_polynomial (h_reg : G.IsRegularOfDegree 3) :
    det (1 - u • HashimotoMatrix G R) * det (1 - u • Dart.involutionMatrix G R) * (1 - u^2)^(Fintype.card V) =
    det ((1 + 2 * u^2) • 1 - u • G.adjMatrix R) * (1 - u^2)^(3 * Fintype.card V) := by
  have h := ihara_bass_regular_polynomial G R u (d := 3) h_reg
  have h3 : ((3 : ℕ) : R) - 1 = (2 : R) := by
    push_cast
    ring
  rw [h3] at h
  exact h

/-- **Specialization to 4-regular graphs**:
For $d = 4$ (e.g., 4-regular 2-adic Schreier graphs $\Gamma_n$),
the characteristic factor is $(1 + 3u^2) I - u A$. -/
theorem ihara_bass_4regular_polynomial (h_reg : G.IsRegularOfDegree 4) :
    det (1 - u • HashimotoMatrix G R) * det (1 - u • Dart.involutionMatrix G R) * (1 - u^2)^(Fintype.card V) =
    det ((1 + 3 * u^2) • 1 - u • G.adjMatrix R) * (1 - u^2)^(4 * Fintype.card V) := by
  have h := ihara_bass_regular_polynomial G R u (d := 4) h_reg
  have h4 : ((4 : ℕ) : R) - 1 = (3 : R) := by
    push_cast
    ring
  rw [h4] at h
  exact h

end RegularIharaZeta
