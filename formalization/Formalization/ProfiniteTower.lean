import Mathlib
import Mathlib.Topology.Category.LightProfinite.Basic

open CategoryTheory
open CategoryTheory.Limits
open LightProfinite
open Opposite

namespace AdelicSpectral

-- ============================================================================
-- 1. THE 2-ADIC PROJECTIVE SYSTEM
-- ============================================================================

lemma cast_comp_cast {c d e : ℕ} (h1 : d ≤ c) (h2 : e ≤ d) (x : ZMod (2^c)) :
  (ZMod.cast (ZMod.cast x : ZMod (2^d)) : ZMod (2^e)) = (ZMod.cast x : ZMod (2^e)) := by
  let f1 := ZMod.castHom (pow_dvd_pow 2 h1) (ZMod (2^d))
  let f2 := ZMod.castHom (pow_dvd_pow 2 h2) (ZMod (2^e))
  let f3 := ZMod.castHom (pow_dvd_pow 2 (le_trans h2 h1)) (ZMod (2^e))
  have h_comp : f2.comp f1 = f3 := ZMod.castHom_comp _ _
  have h_eval : (f2.comp f1) x = f3 x := by rw [h_comp]
  exact h_eval

/-- The tower of finite rings `ZMod (2^d)`. -/
def zmodTowerObj (d : ℕᵒᵖ) : FintypeCat :=
  FintypeCat.of (ZMod (2^(unop d)))

/-- The transition maps `ZMod (2^d) → ZMod (2^c)` for `c ≤ d`. -/
def zmodTowerMap {c d : ℕᵒᵖ} (h : c ⟶ d) : zmodTowerObj c ⟶ zmodTowerObj d :=
  let hc : unop d ≤ unop c := leOfHom h.unop
  (ZMod.castHom (pow_dvd_pow 2 hc) (ZMod (2^(unop d))) : ZMod (2^(unop c)) → ZMod (2^(unop d)))

/-- The functor defining the 2-adic projective system. -/
@[simps]
def zmodTower : ℕᵒᵖ ⥤ FintypeCat where
  obj := zmodTowerObj
  map := zmodTowerMap
  map_id X := by
    ext x
    dsimp [zmodTowerMap]
    rw [ZMod.cast_id]
  map_comp f g := by
    ext x
    dsimp [zmodTowerMap]
    let h1 : unop _ ≤ unop _ := leOfHom f.unop
    let h2 : unop _ ≤ unop _ := leOfHom g.unop
    exact (cast_comp_cast h1 h2 x).symm

-- ============================================================================
-- 2. THE PROFINTIE LIMIT
-- ============================================================================

/-- The 2-adic integers $\mathbb{Z}_2$, constructed as a Light Profinite set.
    This provides the sequential limit topology automatically. -/
noncomputable def Z_2_Profinite : LightProfinite :=
  LightProfinite.of zmodTower

end AdelicSpectral
