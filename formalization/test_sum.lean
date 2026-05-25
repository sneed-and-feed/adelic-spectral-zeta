import Formalization.CollatzSpectral

open Matrix CollatzSpectral

lemma sum_zmod_two {β : Type*} [AddCommMonoid β] (f : ZMod 2 → β) :
    ∑ i : ZMod 2, f i = f 0 + f 1 := by
  -- ZMod 2 has exactly elements 0 and 1
  have : (Finset.univ : Finset (ZMod 2)) = {0, 1} := rfl
  rw [this]
  simp
