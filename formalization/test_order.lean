import Mathlib

lemma three_pow_two_pow (k : ℕ) (hk : k ≥ 1) :
    ∃ (a : ℤ), Odd a ∧ (3 : ℤ)^(2^k) = 1 + a * 2^(k+2) := by
  induction' k, hk using Nat.le_induction with k hk ih
  · use 1
    constructor
    · exact odd_one
    · norm_num
  · rcases ih with ⟨a, ha, h_eq⟩
    use a + a^2 * 2^(k+1)
    constructor
    · obtain ⟨c, hc⟩ := ha
      rw [hc]
      use c + (2 * c + 1)^2 * 2^k
      have h2 : (2 : ℤ) ^ (k + 1) = 2 * (2 : ℤ)^k := by
        rw [pow_add, pow_one, mul_comm]
      rw [h2]
      ring
    · have h1 : (3 : ℤ)^(2^(k+1)) = ((3 : ℤ)^(2^k))^2 := by
        rw [pow_add, pow_one, pow_mul]
      rw [h1, h_eq]
      ring

lemma three_pow_two_pow_mod_pow_two (n : ℕ) (hn : n ≥ 3) :
    (3 : ZMod (2^n))^(2^(n-2)) = 1 := by
  obtain ⟨a, _, h_eq⟩ := three_pow_two_pow (n - 2) (by omega)
  have h_pow : ((3 : ℤ) : ZMod (2^n))^(2^(n-2)) = (((3 : ℤ)^(2^(n-2)) : ℤ) : ZMod (2^n)) := by
    simp only [Int.cast_pow]
  have h3 : ((3 : ℤ) : ZMod (2^n)) = 3 := by norm_cast
  rw [h3] at h_pow
  rw [h_pow]
  have h_k : n - 2 + 2 = n := by omega
  have h_eq2 : (3 : ℤ)^(2^(n-2)) = 1 + a * 2^n := by
    have h_eq' := h_eq
    rw [h_k] at h_eq'
    exact h_eq'
  rw [h_eq2]
  push_cast
  have h_zero2 : (2 : ZMod (2^n))^n = 0 := by
    have h : (2 : ZMod (2^n))^n = ((2^n : ℕ) : ZMod (2^n)) := by norm_cast
    rw [h]
    exact (ZMod.natCast_zmod_eq_zero_iff_dvd (2 ^ n) (2 ^ n)).mpr (dvd_refl (2 ^ n))
  rw [h_zero2]
  ring

lemma three_pow_two_pow_mod_pow_two_ne_one (n : ℕ) (hn : n ≥ 3) :
    (3 : ZMod (2^n))^(2^(n-3)) ≠ 1 := by
  by_cases hn3 : n = 3
  · subst hn3
    decide
  · have hn4 : n ≥ 4 := by omega
    obtain ⟨a, ha, h_eq⟩ := three_pow_two_pow (n - 3) (by omega)
    intro h_one
    have h_pow : ((3 : ℤ) : ZMod (2^n))^(2^(n-3)) = (((3 : ℤ)^(2^(n-3)) : ℤ) : ZMod (2^n)) := by
      simp only [Int.cast_pow]
    have h3 : ((3 : ℤ) : ZMod (2^n)) = 3 := by norm_cast
    rw [h3] at h_pow
    rw [h_pow] at h_one
    have h_k : n - 3 + 2 = n - 1 := by omega
    have h_eq2 : (3 : ℤ)^(2^(n-3)) = 1 + a * 2^(n-1) := by
      have h_eq' := h_eq
      rw [h_k] at h_eq'
      exact h_eq'
    rw [h_eq2] at h_one
    push_cast at h_one
    have h_cancel : (1 : ZMod (2^n)) + ↑a * (2 : ZMod (2^n)) ^ (n - 1) = 1 → ↑a * (2 : ZMod (2^n)) ^ (n - 1) = 0 := by
      intro h
      calc ↑a * (2 : ZMod (2^n)) ^ (n - 1) = (1 : ZMod (2^n)) + ↑a * (2 : ZMod (2^n)) ^ (n - 1) - 1 := by ring
        _ = 1 - 1 := by rw [h]
        _ = 0 := by ring
    have h_zero := h_cancel h_one
    have h_zero_int : ((a * 2^(n-1) : ℤ) : ZMod (2^n)) = 0 := by
      calc ((a * 2^(n-1) : ℤ) : ZMod (2^n)) = ↑a * (2 : ZMod (2^n)) ^ (n - 1) := by push_cast; rfl
        _ = 0 := h_zero
    have h_dvd : ((2^n : ℕ) : ℤ) ∣ a * 2^(n-1) := by
      exact (ZMod.intCast_zmod_eq_zero_iff_dvd (a * 2 ^ (n - 1)) (2 ^ n)).mp h_zero_int
    have h_dvd2 : (2 : ℤ) ∣ a := by
      have h_pow_split : ((2^n : ℕ) : ℤ) = 2 * 2^(n-1) := by
        have hn_split : 2^n = 2^(1 + (n - 1)) := by congr 1; omega
        calc ((2^n : ℕ) : ℤ) = ((2^(1 + (n - 1)) : ℕ) : ℤ) := by rw [hn_split]
          _ = ((2^1 * 2^(n-1) : ℕ) : ℤ) := by rw [pow_add]
          _ = 2 * 2^(n-1) := by push_cast; ring
      rw [h_pow_split] at h_dvd
      have h_pos : (2^(n-1) : ℤ) ≠ 0 := by positivity
      exact mul_dvd_mul_iff_right h_pos |>.mp h_dvd
    have h_even : Even a := even_iff_two_dvd.mpr h_dvd2
    have h_odd : Odd a := ha
    exact Int.even_iff_not_odd.mp h_even h_odd

lemma order_three_mod_pow_two (n : ℕ) (hn : n ≥ 3) :
    orderOf (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) = 2^(n-2) := by
  have h_not : ¬ (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) ^ 2 ^ (n - 3) = 1 := by
    intro h
    have h_eq_val : (((ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) ^ (2 ^ (n - 3)) : (ZMod (2^n))ˣ) : ZMod (2^n)) = (1 : ZMod (2^n)) := by
      rw [h]
      rfl
    push_cast at h_eq_val
    have h_ne := three_pow_two_pow_mod_pow_two_ne_one n hn
    exact h_ne h_eq_val
  have h_fin : (ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide)) : (ZMod (2^n))ˣ) ^ 2 ^ (n - 2) = 1 := by
    ext
    push_cast
    exact three_pow_two_pow_mod_pow_two n hn
  have h_pow_eq : 2 ^ (n - 2) = 2 ^ (n - 3 + 1) := by
    congr 1
    omega
  rw [h_pow_eq]
  rw [h_pow_eq] at h_fin
  exact orderOf_eq_prime_pow h_not h_fin
