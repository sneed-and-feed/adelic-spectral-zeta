import Mathlib
import Mathlib.Topology.Category.LightProfinite.Basic
import Mathlib.CategoryTheory.Fintype
import Mathlib.CategoryTheory.Limits.Basic
import Mathlib.CategoryTheory.Opposite

/-!
# The 2-adic Profinite Tower

This file constructs the 2-adic integers $\mathbb{Z}_2$ as a projective limit
of the finite rings $\mathbb{Z}/2^d\mathbb{Z}$ within the category of `LightProfinite` sets.

This topological architecture formalizes the state space of the continuous 
Schreier graph on which the Collatz relation is defined.
-/

open CategoryTheory
open CategoryTheory.Limits
open LightProfinite
open Opposite

namespace AdelicSpectral

-- ============================================================================
-- 1. THE 2-ADIC PROJECTIVE SYSTEM
-- ============================================================================

/-- The tower of finite rings `ZMod (2^d)`. -/
def zmodTowerObj (d : ℕᵒᵖ) : FintypeCat :=
  FintypeCat.of (ZMod (2^(unop d)))

/-- The transition maps `ZMod (2^d) → ZMod (2^c)` for `c ≤ d`. -/
def zmodTowerMap {c d : ℕᵒᵖ} (h : c ⟶ d) : zmodTowerObj c ⟶ zmodTowerObj d :=
  let hc : unop d ≤ unop c := leOfHom h.unop
  let hom := ZMod.castHom (pow_dvd_pow 2 hc) (ZMod (2^(unop d)))
  FintypeCat.ofHom hom

/-- The functor defining the 2-adic projective system. -/
@[simps]
def zmodTower : ℕᵒᵖ ⥤ FintypeCat where
  obj := zmodTowerObj
  map := zmodTowerMap
  map_id X := by
    ext x
    exact ZMod.castHom_self x
  map_comp f g := by
    ext x
    rfl

-- ============================================================================
-- 2. THE PROFINTIE LIMIT
-- ============================================================================

/-- The 2-adic integers $\mathbb{Z}_2$, constructed as a Light Profinite set.
    This provides the sequential limit topology automatically. -/
noncomputable def Z_2_Profinite : LightProfinite :=
  LightProfinite.of zmodTower

end AdelicSpectral
