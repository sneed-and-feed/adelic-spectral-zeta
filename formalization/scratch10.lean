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
  let p := ramanujan_prod_trunc n n
  -- p represents prod_{k=1}^n (1 - X^k)^24 truncated to X^n
  -- tau n is coeff of X^n in X * p
  -- so it is coeff of X^{n-1} in p
  p.getD (n - 1) 0

def divisor_sum_11 (n : ℕ) : ℤ :=
  (Finset.filter (fun d => n % d = 0) (Finset.Icc 1 n)).sum (fun d => (d : ℤ) ^ 11)

def ramanujan_congruence_comp (n : ℕ) : Prop :=
  (tau_comp n - divisor_sum_11 n) % 691 = 0

theorem cong_1 : ramanujan_congruence_comp 1 := by decide
theorem cong_2 : ramanujan_congruence_comp 2 := by decide
theorem cong_3 : ramanujan_congruence_comp 3 := by decide
theorem cong_4 : ramanujan_congruence_comp 4 := by decide
