import Mathlib
import Mathlib.Topology.Category.LightProfinite.Basic
import Mathlib.CategoryTheory.Fintype
import Mathlib.CategoryTheory.Limits.Basic
import Mathlib.CategoryTheory.Opposite

open CategoryTheory
open CategoryTheory.Limits
open LightProfinite
open Opposite

namespace AdelicSpectral

def zmodTowerObj (d : ℕᵒᵖ) : FintypeCat :=
  FintypeCat.of (ZMod (2^(unop d)))

def zmodTowerMap {c d : ℕᵒᵖ} (h : c ⟶ d) : zmodTowerObj c ⟶ zmodTowerObj d :=
  let hc : unop d ≤ unop c := leOfHom h.unop
  let hom := ZMod.castHom (pow_dvd_pow 2 hc) (ZMod (2^(unop d)))
  FintypeCat.ofHom hom

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
