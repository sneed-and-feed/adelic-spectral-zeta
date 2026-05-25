import Mathlib.Data.ZMod.Basic

def G_d_adj (d : ℕ) (x y : ZMod (2^(d-1))) : Bool :=
  (x != y) && ((y == 3 * x) || (y == 3 * x - 1) || (x == 3 * y) || (x == 3 * y - 1))

def adjMatrix (d : ℕ) (x y : ZMod (2^(d-1))) : ℤ :=
  if G_d_adj d x y then 1 else 0

def sheetSplitInv (d : ℕ) (pair : ZMod (2^(d-2)) × ZMod 2) : ZMod (2^(d-1)) :=
  (pair.1.val + pair.2.val * 2^(d-2) : ℕ)

def A_prime (d : ℕ) (s r : ZMod (2^(d-2)) × ZMod 2) : ℤ :=
  adjMatrix d (sheetSplitInv d s) (sheetSplitInv d r)

def weightedMatrix (d : ℕ) (v u : ZMod (2^(d-2))) : ℤ :=
  A_prime d (v, 0) (u, 0) + A_prime d (v, 0) (u, 1)

def pi (d : ℕ) (v : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  (v.val : ZMod (2^(d-2)))

def get_s_card (d : ℕ) (u v : ZMod (2^(d-2))) : ℕ :=
  let univ : List (ZMod (2^(d-1)) × ZMod (2^(d-1))) :=
    (List.range (2^(d-1))).bind fun i =>
    (List.range (2^(d-1))).map fun j => ((i : ZMod (2^(d-1))), (j : ZMod (2^(d-1))))
  (univ.filter (fun p => pi d p.1 == u && pi d p.2 == v && G_d_adj d p.1 p.2)).length

def check_weighted_card (d : ℕ) : Bool :=
  let n := 2^(d-2)
  (List.range n).all fun v => (List.range n).all fun u =>
    (get_s_card d (v : ZMod n) (u : ZMod n) : ℤ) == 2 * weightedMatrix d (v : ZMod n) (u : ZMod n)

#eval check_weighted_card 3
#eval check_weighted_card 4
#eval check_weighted_card 5
