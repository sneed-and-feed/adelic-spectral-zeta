import Mathlib

def divisor_sum_11_comp (n : ℕ) : ℤ :=
  (List.range n).map (fun i =>
    let d := i + 1
    if n % d == 0 then (d : ℤ) ^ 11 else 0) |>.sum

#eval divisor_sum_11_comp 1
#eval divisor_sum_11_comp 2
