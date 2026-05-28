import Mathlib
import Mathlib.Data.ZMod.Basic

variable {n : ℕ} (hn : n ≥ 3)

noncomputable def index_equiv : ZMod (2^(n-1)) ≃ (ZMod (2^(n-2)) × ZMod 2) :=
  calc ZMod (2^(n-1))
    ≃ Fin (2^(n-1)) := Equiv.cast (by rfl)
    _ ≃ Fin (2^(n-2) * 2) := Equiv.cast (by rw [← pow_succ]; congr 1; omega)
    _ ≃ Fin (2^(n-2)) × Fin 2 := finProdFinEquiv.symm
    _ ≃ ZMod (2^(n-2)) × ZMod 2 := Equiv.cast (by rfl)
