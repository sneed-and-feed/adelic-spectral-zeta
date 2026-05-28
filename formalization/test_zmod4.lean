import Mathlib
import Mathlib.Topology.Category.LightProfinite.Basic

open CategoryTheory
open CategoryTheory.Limits
open LightProfinite
open Opposite

namespace AdelicSpectral

def zmodTowerObj (d : ℕᵒᵖ) : FintypeCat :=
  FintypeCat.of (ZMod (2^(unop d)))

def zmodTowerMap {c d : ℕᵒᵖ} (h : c ⟶ d) : zmodTowerObj c ⟶ zmodTowerObj d :=
  let hc : unop d ≤ unop c := leOfHom h.unop
  (ZMod.castHom (pow_dvd_pow 2 hc) (ZMod (2^(unop d))) : ZMod (2^(unop c)) → ZMod (2^(unop d)))

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
    exact (ZMod.castHom_comp _ _).symm ▸ rfl
