import Formalization.CollatzConnectivity
import Mathlib.Tactic

open Classical

lemma inv3_mul {d : ℕ} (hd : d ≥ 3) (x y : ZMod (2^(d-1))) (h : x = 3 * y) : y = inv3 hd * x := by
  have h2 : inv3 hd * x = inv3 hd * (3 * y) := by rw [h]
  have h3 : (inv3 hd * 3) * y = y := by
    have h_inv := inv3_mul_three hd
    rw [h_inv, one_mul]
  rw [← mul_assoc] at h2
  rw [h3] at h2
  exact h2.symm

lemma inv3_mul_add {d : ℕ} (hd : d ≥ 3) (x y : ZMod (2^(d-1))) (h : x = 3 * y - 1) : y = inv3 hd * (x + 1) := by
  have h1 : x + 1 = 3 * y := by
    calc x + 1 = 3 * y - 1 + 1 := by rw [h]
         _ = 3 * y := by ring
  exact inv3_mul hd (x + 1) y h1

lemma G_d_degree_le {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) :
    (Finset.univ.filter (fun y => (G_d d).Adj x y)).card ≤ 4 := by
  have h_sub : Finset.univ.filter (fun y => (G_d d).Adj x y) ⊆ ({3 * x, 3 * x - 1, inv3 hd * x, inv3 hd * (x + 1)} : Finset (ZMod (2^(d-1)))) := by
    intro y hy
    rw [Finset.mem_filter] at hy
    simp only [Finset.mem_insert, Finset.mem_singleton]
    rcases hy.2.2 with h | h | h | h
    · exact Or.inl h
    · exact Or.inr (Or.inl h)
    · exact Or.inr (Or.inr (Or.inl (inv3_mul hd x y h)))
    · exact Or.inr (Or.inr (Or.inr (inv3_mul_add hd x y h)))
  have h2 := Finset.card_le_card h_sub
  have h3 : ({3 * x, 3 * x - 1, inv3 hd * x, inv3 hd * (x + 1)} : Finset (ZMod (2^(d-1)))).card ≤ 4 := by
    refine (Finset.card_insert_le _ _).trans ?_
    refine (add_le_add_right (Finset.card_insert_le _ _) 1).trans ?_
    refine (add_le_add_right (add_le_add_right (Finset.card_insert_le _ _) 1) 1).trans ?_
    exact le_refl _
  exact h2.trans h3
