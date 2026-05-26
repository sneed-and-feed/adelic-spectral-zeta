import Mathlib.Data.ZMod.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Tactic

open Classical

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

lemma three_coprime_pow_two (d : ℕ) : Nat.Coprime 3 (2^(d-1)) := by
  sorry

noncomputable def inv3 {d : ℕ} : ZMod (2^(d-1)) :=
  (ZMod.unitOfCoprime 3 (three_coprime_pow_two d))⁻¹

lemma mul_inv3 {d : ℕ} (x : ZMod (2^(d-1))) : 3 * (inv3 * x) = x := by
  sorry

lemma inv3_mul {d : ℕ} (x y : ZMod (2^(d-1))) (h : x = 3 * y) : y = inv3 * x := by
  sorry

lemma inv3_mul_add {d : ℕ} (x y : ZMod (2^(d-1))) (h : x = 3 * y - 1) : y = inv3 * (x + 1) := by
  sorry

lemma G_d_degree_le (d : ℕ) (x : ZMod (2^(d-1))) :
    (Finset.univ.filter (fun y => (G_d d).Adj x y)).card ≤ 4 := by
  have h_sub : Finset.univ.filter (fun y => (G_d d).Adj x y) ⊆ ({3 * x, 3 * x - 1, inv3 * x, inv3 * (x + 1)} : Finset (ZMod (2^(d-1)))) := by
    intro y hy
    rw [Finset.mem_filter] at hy
    simp only [Finset.mem_insert, Finset.mem_singleton]
    rcases hy.2.2 with h | h | h | h
    · exact Or.inl h
    · exact Or.inr (Or.inl h)
    · exact Or.inr (Or.inr (Or.inl (inv3_mul x y h)))
    · exact Or.inr (Or.inr (Or.inr (inv3_mul_add x y h)))
  have h2 := Finset.card_le_card h_sub
  have h3 : ({3 * x, 3 * x - 1, inv3 * x, inv3 * (x + 1)} : Finset (ZMod (2^(d-1)))).card ≤ 4 := by
    -- we can just unfold card of insert
    refine (Finset.card_insert_le _ _).trans ?_
    refine (add_le_add_right (Finset.card_insert_le _ _) 1).trans ?_
    refine (add_le_add_right (add_le_add_right (Finset.card_insert_le _ _) 1) 1).trans ?_
    exact le_refl _
  exact h2.trans h3
