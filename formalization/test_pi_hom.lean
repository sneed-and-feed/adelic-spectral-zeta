import Mathlib

def G_d (d : ℕ) : SimpleGraph (ZMod (2^(d-1))) where
  Adj x y := 
    x ≠ y ∧ (y = 3 * x ∨ y = 3 * x - 1 ∨ x = 3 * y ∨ x = 3 * y - 1)
  symm := by
    intro x y hxy
    rcases hxy with ⟨hne, h | h | h | h⟩
    · exact ⟨hne.symm, Or.inr (Or.inr (Or.inl h))⟩
    · exact ⟨hne.symm, Or.inr (Or.inr (Or.inr h))⟩
    · exact ⟨hne.symm, Or.inl h⟩
    · exact ⟨hne.symm, Or.inr (Or.inl h)⟩
  loopless := by
    intro x hx
    exact hx.1 rfl

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_mul_three {d : ℕ} (x : ZMod (2^(d-1))) : pi (3 * x) = 3 * pi x := sorry
lemma pi_mul_three_sub_one {d : ℕ} (x : ZMod (2^(d-1))) : pi (3 * x - 1) = 3 * pi x - 1 := sorry

theorem pi_is_graph_hom_or_eq {d : ℕ} (hd : d ≥ 3) :
    ∀ x y, (G_d d).Adj x y → pi x = pi y ∨ (G_d (d-1)).Adj (pi x) (pi y) := by
  intro x y hxy
  by_cases h_eq : pi x = pi y
  · exact Or.inl h_eq
  · right
    rcases hxy with ⟨hne, h | h | h | h⟩
    · refine ⟨h_eq, Or.inl ?_⟩
      have h_pi : pi y = pi (3 * x) := by rw [h]
      rw [pi_mul_three] at h_pi
      exact h_pi
    · refine ⟨h_eq, Or.inr (Or.inl ?_)⟩
      have h_pi : pi y = pi (3 * x - 1) := by rw [h]
      rw [pi_mul_three_sub_one] at h_pi
      exact h_pi
    · refine ⟨h_eq, Or.inr (Or.inr (Or.inl ?_))⟩
      have h_pi : pi x = pi (3 * y) := by rw [h]
      rw [pi_mul_three] at h_pi
      exact h_pi
    · refine ⟨h_eq, Or.inr (Or.inr (Or.inr ?_))⟩
      have h_pi : pi x = pi (3 * y - 1) := by rw [h]
      rw [pi_mul_three_sub_one] at h_pi
      exact h_pi
