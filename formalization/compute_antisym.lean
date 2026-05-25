import Mathlib.Data.ZMod.Basic

def G_d_adj (d : ℕ) (x y : ZMod (2^(d-1))) : Bool :=
  (x != y) && ((y == 3 * x) || (y == 3 * x - 1) || (x == 3 * y) || (x == 3 * y - 1))

def adjMatrix (d : ℕ) (x y : ZMod (2^(d-1))) : ℤ :=
  if G_d_adj d x y then 1 else 0

def sheetSplitInv (d : ℕ) (pair : ZMod (2^(d-2)) × ZMod 2) : ZMod (2^(d-1)) :=
  (pair.1.val + pair.2.val * 2^(d-2) : ℕ)

def A_prime (d : ℕ) (s r : ZMod (2^(d-2)) × ZMod 2) : ℤ :=
  adjMatrix d (sheetSplitInv d s) (sheetSplitInv d r)

def antisymMatrix (d : ℕ) (v u : ZMod (2^(d-2))) : ℤ :=
  A_prime d (v, 0) (u, 0) - A_prime d (v, 0) (u, 1)

#eval (List.range 2).map fun v => (List.range 2).map fun u => antisymMatrix 3 (v : ZMod 2) (u : ZMod 2)
#eval (List.range 4).map fun v => (List.range 4).map fun u => antisymMatrix 4 (v : ZMod 4) (u : ZMod 4)
#eval (List.range 8).map fun v => (List.range 8).map fun u => antisymMatrix 5 (v : ZMod 8) (u : ZMod 8)
