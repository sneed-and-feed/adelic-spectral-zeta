import Mathlib
import Mathlib.Algebra.Order.Ring.Defs

open PowerSeries

noncomputable def X_series : PowerSeries ℤ := X

noncomputable def ramanujan_trunc (N : ℕ) : PowerSeries ℤ :=
  (Finset.range N).prod (fun n => (1 - (X_series ^ (n + 1))) ^ 24)

noncomputable def ramanujanTau (n : ℕ) : ℤ :=
  coeff ℤ n (X_series * ramanujan_trunc n)

def divisor_sum_11 (n : ℕ) : ℤ :=
  (Finset.filter (fun d => n % d = 0) (Finset.Icc 1 n)).sum (fun d => (d : ℤ) ^ 11)

def ramanujan_congruence_691 (n : ℕ) : Prop :=
  (ramanujanTau n - divisor_sum_11 n) % 691 = 0

lemma B_12_eq : bernoulli 12 = -691 / 2730 := by rfl

noncomputable def E_12 : PowerSeries ℚ :=
  PowerSeries.mk fun n => if n = 0 then 1 else (65520 / 691) * (divisor_sum_11 n : ℚ)

noncomputable def Delta_Q : PowerSeries ℚ :=
  PowerSeries.mk fun n => (ramanujanTau n : ℚ)

section ModForms

variable (M_12 : Set (PowerSeries ℚ))
variable (Delta_in_M_12 : Delta_Q ∈ M_12)
variable (E_12_in_M_12 : E_12 ∈ M_12)
variable (M_12_is_span : ∀ (f : PowerSeries ℚ), f ∈ M_12 → ∃ a b : ℚ, f = a • E_12 + b • Delta_Q)
variable (F_exists : ∃ (F_int : PowerSeries ℤ),
  (PowerSeries.map (algebraMap ℤ ℚ) F_int) ∈ M_12 ∧
  coeff ℤ 0 F_int = 1 ∧
  coeff ℤ 1 F_int = 720)

variable (tau_zero : ramanujanTau 0 = 0)
variable (tau_one : ramanujanTau 1 = 1)
variable (divisor_sum_11_one : divisor_sum_11 1 = 1)

theorem ramanujan_tau_congruence (n : ℕ) (hn : n > 0) : ramanujan_congruence_691 n := by
  rcases F_exists with ⟨F_int, hF_M12, hF_0, hF_1⟩
  rcases M_12_is_span _ hF_M12 with ⟨a, b, h_span⟩
  
  have ha : a = 1 := by
    have h := congr_arg (coeff ℚ 0) h_span
    simp [E_12, Delta_Q, tau_zero, hF_0] at h
    exact h.symm

  have hb : b = 432000 / 691 := by
    have h := congr_arg (coeff ℚ 1) h_span
    simp [E_12, Delta_Q, tau_one, divisor_sum_11_one, hF_1, ha] at h
    linarith

  have hn_eq := congr_arg (coeff ℚ n) h_span
  simp [E_12, Delta_Q, ne_of_gt hn, ha, hb] at hn_eq
  
  have h_clear : (691 : ℚ) * (coeff ℤ n F_int : ℚ) = 65520 * (divisor_sum_11 n : ℚ) + 432000 * (ramanujanTau n : ℚ) := by
    calc (691 : ℚ) * (coeff ℤ n F_int : ℚ) = 691 * ((65520 / 691) * (divisor_sum_11 n : ℚ) + (432000 / 691) * (ramanujanTau n : ℚ)) := by rw [hn_eq]
         _ = 65520 * (divisor_sum_11 n : ℚ) + 432000 * (ramanujanTau n : ℚ) := by ring
         
  have h_int : (691 * coeff ℤ n F_int : ℤ) = 65520 * divisor_sum_11 n + 432000 * ramanujanTau n := by
    exact_mod_cast h_clear

  dsimp [ramanujan_congruence_691]
  omega

end ModForms

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

def ramanujan_congruence_comp (n : ℕ) : Bool :=
  (tau_comp n - divisor_sum_11 n) % 691 == 0

set_option maxRecDepth 2000000
set_option maxHeartbeats 0
