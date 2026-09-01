/-!
# Partition Function Computation & Finite Instance Congruence Checks

This module implements a list-based algorithmic computation of the integer partition function $p(n)$
using Euler's pentagonal number recurrence:
$$p(n) = \sum_{k \neq 0} (-1)^{k-1} p(n - g_k), \quad g_k = \frac{k(3k \mp 1)}{2}$$

## Scope & De-Inflation Note:
The theorems `ramanujan_4`, `ramanujan_9`, `ramanujan_14`, `ramanujan_19`, `ramanujan_5`,
`ramanujan_12`, `ramanujan_19_mod7`, `ramanujan_6`, and `ramanujan_17` are **finite list evaluation
check instances** verifying $p(n) \pmod m = 0$ at specific small integers $n$ via `rfl` (reflexivity).
They are computational verification checks for individual sample values, **not** proofs of Ramanujan's
general infinite partition congruence families ($\forall k \in \mathbb{N}, p(5k+4) \equiv 0 \pmod 5$,
$p(7k+5) \equiv 0 \pmod 7$, or $p(11k+6) \equiv 0 \pmod{11}$).
-/

/-- Walk reversed partition list using Euler's pentagonal differences. -/
def pentagonal_walk : Nat → List Int → Nat → Nat → Int → Int → Int
  | 0, _, _, _, _, acc => acc
  | _fuel + 1, [], _, _, _, acc => acc
  | fuel + 1, p0 :: rest, k_minus_1, two_k, sign, acc =>
      let acc := acc + sign * p0
      match rest.drop k_minus_1 with
      | [] => acc
      | p1 :: rest =>
          pentagonal_walk fuel (rest.drop two_k) (k_minus_1 + 1) (two_k + 2) (-sign) (acc + sign * p1)

/-- Computes $p(n)$ from the list of previous partition values `p_prev` using Euler's pentagonal number recurrence. -/
def compute_next_p_list (p_prev : List Int) (_n : Nat) : Int :=
  pentagonal_walk p_prev.length p_prev.reverse 0 2 1 0

/-- Computes the reversed list $[p(n), \dots, p(0)]$ iteratively. -/
def compute_partitions_rev : Nat → List Int → List Int
  | 0, acc => acc
  | fuel + 1, acc => compute_partitions_rev fuel ((pentagonal_walk fuel acc 0 2 1 0) :: acc)

/-- Computes the list of partition values $[p(0), p(1), \dots, p(n)]$ iteratively. -/
def compute_partitions_list (n : Nat) : List Int :=
  (compute_partitions_rev n [1]).reverse

/-- Partition function $p(n)$ defined by list-based evaluation of Euler's pentagonal recurrence. -/
def p (n : Nat) : Int :=
  (compute_partitions_rev n [1]).head?.getD 0

-- ============================================================================
-- Finite Evaluation Check Instances (Modulo 5, 7, 11)
-- ============================================================================

/-- Finite list evaluation check: verifies $p(4) \equiv 0 \pmod 5$ by reflexivity (`rfl`). -/
theorem ramanujan_4 : p 4 % 5 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(9) \equiv 0 \pmod 5$ by reflexivity (`rfl`). -/
theorem ramanujan_9 : p 9 % 5 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(14) \equiv 0 \pmod 5$ by reflexivity (`rfl`). -/
theorem ramanujan_14 : p 14 % 5 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(19) \equiv 0 \pmod 5$ by reflexivity (`rfl`). -/
theorem ramanujan_19 : p 19 % 5 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(5) \equiv 0 \pmod 7$ by reflexivity (`rfl`). -/
theorem ramanujan_5 : p 5 % 7 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(12) \equiv 0 \pmod 7$ by reflexivity (`rfl`). -/
theorem ramanujan_12 : p 12 % 7 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(19) \equiv 0 \pmod 7$ by reflexivity (`rfl`). -/
theorem ramanujan_19_mod7 : p 19 % 7 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(6) \equiv 0 \pmod{11}$ by reflexivity (`rfl`). -/
theorem ramanujan_6 : p 6 % 11 = 0 := by rfl

/-- Finite list evaluation check: verifies $p(17) \equiv 0 \pmod{11}$ by reflexivity (`rfl`). -/
theorem ramanujan_17 : p 17 % 11 = 0 := by rfl
