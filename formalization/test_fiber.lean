import Mathlib

lemma pi_natCast {d : ℕ} (n : ℕ) : (ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) (n : ZMod (2^(d-1)))) = (n : ZMod (2^(d-2))) := by
  simp

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_sub {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x - y) = pi x - pi y :=
  map_sub _ _ _

lemma pi_eq_zero_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) :
    pi z = 0 ↔ z = 0 ∨ z = (2^(d-2) : ZMod (2^(d-1))) := by
  sorry

lemma zmod_fiber_two {d : ℕ} (hd : d ≥ 3) {y : ZMod (2^(d-2))} :
    ∀ x₁ x₂ x₃ : ZMod (2^(d-1)), pi x₁ = y → pi x₂ = y → pi x₃ = y → x₁ = x₂ ∨ x₁ = x₃ ∨ x₂ = x₃ := by
  intro x₁ x₂ x₃ h₁ h₂ h₃
  have h_diff2 : pi (x₂ - x₁) = 0 := by rw [pi_sub, h₂, h₁, sub_self]
  have h_diff3 : pi (x₃ - x₁) = 0 := by rw [pi_sub, h₃, h₁, sub_self]
  have h_cases2 := (pi_eq_zero_iff hd (x₂ - x₁)).mp h_diff2
  have h_cases3 := (pi_eq_zero_iff hd (x₃ - x₁)).mp h_diff3
  rcases h_cases2 with h20 | h2pi
  · -- x₂ - x₁ = 0 => x₂ = x₁
    have h_eq : x₁ = x₂ := by exact (sub_eq_zero.mp h20).symm
    left; exact h_eq
  · rcases h_cases3 with h30 | h3pi
    · -- x₃ - x₁ = 0 => x₃ = x₁
      have h_eq : x₁ = x₃ := by exact (sub_eq_zero.mp h30).symm
      right; left; exact h_eq
    · -- x₂ - x₁ = 2^(d-2) and x₃ - x₁ = 2^(d-2)
      have h_sub_eq : x₂ - x₁ = x₃ - x₁ := by rw [h2pi, h3pi]
      have h_eq : x₂ = x₃ := by
        calc x₂ = (x₂ - x₁) + x₁ := (sub_add_cancel x₂ x₁).symm
        _ = (x₃ - x₁) + x₁ := by rw [h_sub_eq]
        _ = x₃ := sub_add_cancel x₃ x₁
      right; right; exact h_eq
