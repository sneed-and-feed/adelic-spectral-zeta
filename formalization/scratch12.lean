import Mathlib

def poly_mul_trunc (n : ℕ) (p q : List ℤ) : List ℤ :=
  (List.range (n + 1)).map fun k =>
    ((List.range (k + 1)).map fun i =>
      (p.getD i 0) * (q.getD (k - i) 0)).sum

def poly_sub (p q : List ℤ) : List ℤ :=
  let len := max p.length q.length
  (List.range len).map fun i => p.getD i 0 - q.getD i 0

def poly_one : List ℤ := [1]
def poly_X_pow (k : ℕ) : List ℤ := List.replicate k 0 ++ [1]

def term (k : ℕ) : List ℤ := poly_sub poly_one (poly_X_pow k)

def poly_pow_trunc (n : ℕ) (p : List ℤ) : ℕ → List ℤ
  | 0 => [1]
  | m + 1 => poly_mul_trunc n p (poly_pow_trunc n p m)

def ramanujan_term_trunc (n : ℕ) (k : ℕ) : List ℤ :=
  poly_pow_trunc n (term k) 24

def ramanujan_prod_trunc (n : ℕ) : ℕ → List ℤ
  | 0 => [1]
  | m + 1 => poly_mul_trunc n (ramanujan_term_trunc n (m + 1)) (ramanujan_prod_trunc n m)

def tau_comp (n : ℕ) : ℤ :=
  if n == 0 then 0 else
  let p := ramanujan_prod_trunc n n
  p.getD (n - 1) 0

def divisor_sum_11_comp (n : ℕ) : ℤ :=
  (List.range n).map (fun i =>
    let d := i + 1
    if n % d == 0 then (d : ℤ) ^ 11 else 0) |>.sum

def ramanujan_congruence_comp (n : ℕ) : Bool :=
  (tau_comp n - divisor_sum_11_comp n) % 691 == 0

#eval ramanujan_congruence_comp 1
#eval ramanujan_congruence_comp 2
#eval ramanujan_congruence_comp 3
