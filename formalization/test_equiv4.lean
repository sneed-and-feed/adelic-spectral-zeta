import Mathlib
import Mathlib.Data.ZMod.Basic

variable {n : ℕ} (hn : n ≥ 3)

noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) :=
  calc ZMod (2^(n-1))
    ≃ Fin (2^(n-1)) := ZMod.equivFin (2^(n-1))
    _ ≃ Fin (2^(n-2) * 2) := Fin.castIso (by rw [← pow_succ, Nat.sub_add_cancel (by omega)])
    _ ≃ Fin (2^(n-2)) × Fin 2 := finProdFinEquiv.symm
    _ ≃ ZMod (2^(n-2)) × ZMod 2 := Equiv.prodCongr (ZMod.equivFin _).symm (ZMod.equivFin _).symm
