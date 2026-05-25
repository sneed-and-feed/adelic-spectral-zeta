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

lemma edge_lift_not_unique : ¬ ∀ {d : ℕ} (hd : d ≥ 3) {x x' x'' : ZMod (2^(d-1))} {v : ZMod (2^(d-2))},
    pi x' = v → pi x'' = v → (G_d d).Adj x x' → (G_d d).Adj x x'' → x' = x'' := by
  intro h
  have h_spec := h (d:=5) (by decide) (x:=(1 : ZMod 16)) (x':=(3 : ZMod 16)) (x'':=(11 : ZMod 16)) (v:=(3 : ZMod 8))
  have h1 : pi (d:=5) (3 : ZMod 16) = (3 : ZMod 8) := rfl
  have h2 : pi (d:=5) (11 : ZMod 16) = (3 : ZMod 8) := rfl
  have h3 : (G_d 5).Adj (1 : ZMod 16) (3 : ZMod 16) := by
    refine ⟨by decide, Or.inl rfl⟩
  have h4 : (G_d 5).Adj (1 : ZMod 16) (11 : ZMod 16) := by
    refine ⟨by decide, Or.inr (Or.inr (Or.inl ?_))⟩
    have : (3 : ZMod 16) * 11 = 33 := rfl
    have : (33 : ZMod 16) = 1 := rfl
    rfl
  have h_eq : (3 : ZMod 16) = (11 : ZMod 16) := h_spec h1 h2 h3 h4
  revert h_eq; decide
