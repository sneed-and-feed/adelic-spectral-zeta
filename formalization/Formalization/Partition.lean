set_option maxHeartbeats 2000000
set_option maxRecDepth 2000000

-- Euler's pentagonal number recurrence
-- p(n) = sum_{k != 0} (-1)^(k-1) p(n - g_k)
-- where g_k = k(3k-1)/2

def compute_next_p_list (p_prev : List Int) (n : Nat) : Int :=
  let ks := List.range n |>.map (· + 1)
  ks.foldl (init := 0) fun acc k =>
    let g1 := (k * (3 * k - 1)) / 2
    let g2 := (k * (3 * k + 1)) / 2
    let sign : Int := if k % 2 == 1 then 1 else -1
    let term1 := if g1 ≤ n then sign * p_prev.get! (n - g1) else 0
    let term2 := if g2 ≤ n then sign * p_prev.get! (n - g2) else 0
    acc + term1 + term2

def compute_partitions_list : Nat → List Int
  | 0 => [1]
  | n + 1 =>
    let p_prev := compute_partitions_list n
    p_prev ++ [compute_next_p_list p_prev (n + 1)]

def p (n : Nat) : Int :=
  (compute_partitions_list n).get! n

-- Ramanujan's partition congruences
-- We prove these for small bounds computationally (0 sorry, 0 axiom)

theorem ramanujan_4 : p 4 % 5 = 0 := by rfl
theorem ramanujan_9 : p 9 % 5 = 0 := by rfl
theorem ramanujan_14 : p 14 % 5 = 0 := by rfl
theorem ramanujan_19 : p 19 % 5 = 0 := by rfl

-- Second Ramanujan Congruence: p(7k+5) = 0 mod 7
theorem ramanujan_5 : p 5 % 7 = 0 := by rfl
theorem ramanujan_12 : p 12 % 7 = 0 := by rfl
theorem ramanujan_19_mod7 : p 19 % 7 = 0 := by rfl

-- Third Ramanujan Congruence: p(11k+6) = 0 mod 11
theorem ramanujan_6 : p 6 % 11 = 0 := by rfl
theorem ramanujan_17 : p 17 % 11 = 0 := by rfl
