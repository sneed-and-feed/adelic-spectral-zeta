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

def weightedMatrix (d : ℕ) (v u : ZMod (2^(d-2))) : ℤ :=
  A_prime d (v, 0) (u, 0) + A_prime d (v, 0) (u, 1)

def getAdj (d : ℕ) : List (List ℤ) :=
  (List.range (2^(d-1))).map fun v => (List.range (2^(d-1))).map fun u => adjMatrix d (v : ZMod (2^(d-1))) (u : ZMod (2^(d-1)))

def getWeighted (d : ℕ) : List (List ℤ) :=
  (List.range (2^(d-2))).map fun v => (List.range (2^(d-2))).map fun u => weightedMatrix d (v : ZMod (2^(d-2))) (u : ZMod (2^(d-2)))

def getAntisym (d : ℕ) : List (List ℤ) :=
  (List.range (2^(d-2))).map fun v => (List.range (2^(d-2))).map fun u => antisymMatrix d (v : ZMod (2^(d-2))) (u : ZMod (2^(d-2)))

def getDiff (d : ℕ) : List (List ℤ) :=
  let n := 2^(d-2)
  let W := getWeighted d
  let A := getAdj (d-1)
  let Aa := getAntisym d
  (List.range n).map fun v => (List.range n).map fun u =>
    (W.get! v).get! u - (2 * ((A.get! v).get! u) - ((Aa.get! v).get! u))

#eval getDiff 5
