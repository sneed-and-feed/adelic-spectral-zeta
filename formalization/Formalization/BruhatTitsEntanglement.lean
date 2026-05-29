import Mathlib
import Formalization.AFAlgebraCategory

open CategoryTheory

/-!
# Holographic Trace on the Bruhat-Tits Tree
-/

/-- A uniform trivalent tree is a simple graph that is a tree and where every vertex has degree 3. -/
structure TrivalentTree (V : Type*) where
  graph : SimpleGraph V
  is_tree : graph.IsTree
  [locally_finite : ∀ v, Fintype (graph.neighborSet v)]
  is_trivalent : ∀ v, graph.degree v = 3
