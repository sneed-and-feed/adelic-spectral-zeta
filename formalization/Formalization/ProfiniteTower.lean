import Mathlib
import Mathlib.Topology.Category.LightProfinite.Basic
import Mathlib.Topology.Category.LightProfinite.AsLimit

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

/-- The functor defining the 2-adic projective system. -/
@[simps]
def zmodTower : ℕᵒᵖ ⥤ FintypeCat where
  obj d := FintypeCat.of (ZMod (2^(unop d)))
  map {c d} h := FintypeCat.homMk (ZMod.castHom (pow_dvd_pow 2 (leOfHom h.unop)) (ZMod (2^(unop d))))
  map_id X := by
    have h : ZMod.castHom (pow_dvd_pow 2 (leOfHom (𝟙 X).unop)) (ZMod (2 ^ unop X)) = RingHom.id _ := ZMod.castHom_self
    simp [h]
  map_comp {X Y Z} f g := by
    ext x
    dsimp
    exact (cast_comp_cast (leOfHom f.unop) (leOfHom g.unop) x).symm

-- ============================================================================
-- 2. THE PROFINTIE LIMIT
-- ============================================================================

/-- The 2-adic integers $\mathbb{Z}_2$, constructed as a Light Profinite set.
    This provides the sequential limit topology automatically. -/
noncomputable def Z_2_Profinite : LightProfinite :=
  limit (zmodTower ⋙ FintypeCat.toLightProfinite)

end AdelicSpectral
