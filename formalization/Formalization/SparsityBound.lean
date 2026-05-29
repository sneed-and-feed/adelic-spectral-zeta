import Mathlib

open Nat Classical

noncomputable section

def finAddEquiv {a b : ℕ} : Fin (a + b) ≃ Fin a ⊕ Fin b := finSumFinEquiv.symm

def arrowSumEquiv {α β γ : Type*} : (α ⊕ β → γ) ≃ (α → γ) × (β → γ) :=
  Equiv.sumArrowEquivProdArrow α β γ

def pathEquiv {p r : ℕ} (rem : ℕ) : 
  (Fin (r + rem) → Fin p) ≃ (Fin r → Fin p) × (Fin rem → Fin p) :=
  Equiv.trans (Equiv.arrowCongr finAddEquiv (Equiv.refl _)) arrowSumEquiv

def S_Equiv {A B : Type*} :
  { uv : (A × B) × (A × B) // uv.1.1 = uv.2.1 } ≃ A × B × B where
  toFun uv := (uv.1.1.1, uv.1.1.2, uv.1.2.2)
  invFun t := ⟨((t.1, t.2.1), (t.1, t.2.2)), rfl⟩
  left_inv := fun ⟨((a, b₁), (a', b₂)), h⟩ => by
    dsimp at h ⊢
    cases h
    rfl
  right_inv := fun ⟨a, b₁, b₂⟩ => rfl

def X_Equiv {X A B : Type*} (E : X ≃ A × B) :
  { uv : X × X // (E uv.1).1 = (E uv.2).1 } ≃ A × B × B :=
  Equiv.trans
    (Equiv.subtypeEquiv (Equiv.prodCongr E E) (by intro uv; rfl))
    S_Equiv

def treeEquiv (d p r : ℕ) (h : r ≤ d) : (Fin d → Fin p) ≃ (Fin r → Fin p) × (Fin (d - r) → Fin p) :=
  let hd : r + (d - r) = d := Nat.add_sub_of_le h
  let E1 : (Fin d → Fin p) ≃ (Fin (r + (d - r)) → Fin p) :=
    Equiv.arrowCongr (finCongr hd.symm) (Equiv.refl _)
  Equiv.trans E1 (pathEquiv (d - r))

abbrev shared_prefix_pairs (d p r : ℕ) (h : r ≤ d) : Type :=
  { uv : (Fin d → Fin p) × (Fin d → Fin p) // (treeEquiv d p r h uv.1).1 = (treeEquiv d p r h uv.2).1 }

lemma card_shared_prefix (d p r : ℕ) (h : r ≤ d) :
    Fintype.card (shared_prefix_pairs d p r h) = p ^ r * p ^ (d - r) * p ^ (d - r) := by
  have H := X_Equiv (treeEquiv d p r h)
  rw [Fintype.card_congr H]
  simp only [Fintype.card_prod, Fintype.card_fun, Fintype.card_fin]
  ring

lemma total_pairs_card (d p : ℕ) :
    Fintype.card ((Fin d → Fin p) × (Fin d → Fin p)) = p ^ (2 * d) := by
  simp only [Fintype.card_prod, Fintype.card_fun, Fintype.card_fin]
  ring

def shared_fraction (d p r : ℕ) (h : r ≤ d) : ℚ :=
  (Fintype.card (shared_prefix_pairs d p r h) : ℚ) / (Fintype.card ((Fin d → Fin p) × (Fin d → Fin p)) : ℚ)

lemma fraction_eq_p_inv_r (d p r : ℕ) (hp : p > 0) (h : r ≤ d) :
    shared_fraction d p r h = (1 : ℚ) / (p : ℚ) ^ r := by
  rw [shared_fraction, card_shared_prefix, total_pairs_card]
  have h1 : p ^ r * p ^ (d - r) * p ^ (d - r) = p ^ (2 * d - r) := by
    rw [← pow_add, ← pow_add]
    congr 1
    omega
  rw [h1]
  push_cast
  have h_denom : (p : ℚ) ^ (2 * d) = (p : ℚ) ^ (2 * d - r) * (p : ℚ) ^ r := by
    rw [← pow_add]
    congr 1
    omega
  rw [h_denom]
  have Htop : (p : ℚ) ^ (2 * d - r) ≠ 0 := by
    exact pow_ne_zero _ (Nat.cast_ne_zero.mpr (Nat.pos_iff_ne_zero.mp hp))
  rw [div_mul_eq_div_div, div_self Htop, one_div]

def sparsity (d p r : ℕ) (h : r ≤ d) : ℚ :=
  1 - shared_fraction d p r h

/--
Agent 1: Sparsity Bound
Formalize in Lean 4: For a p-ary tree of depth d, the fraction of block pairs that share a common ancestor at depth r is exactly p^(-r). Therefore sparsity = 1 - p^(-r). Prove for p=2: req_depth=1 → 50%, req_depth=3 → 87.5%, req_depth=6 → 98.4%. This is finite combinatorics over tree paths — induction on d.
-/
theorem sparsity_bound (d p r : ℕ) (hp : p > 0) (h : r ≤ d) :
    sparsity d p r h = 1 - (1 : ℚ) / (p : ℚ) ^ r := by
  rw [sparsity, fraction_eq_p_inv_r d p r hp h]

theorem sparsity_p2_r1 (d : ℕ) (h : 1 ≤ d) : sparsity d 2 1 h = 1 / 2 := by
  rw [sparsity_bound d 2 1 (by decide) h]
  norm_num

theorem sparsity_p2_r3 (d : ℕ) (h : 3 ≤ d) : sparsity d 2 3 h = 7 / 8 := by
  rw [sparsity_bound d 2 3 (by decide) h]
  norm_num

theorem sparsity_p2_r6 (d : ℕ) (h : 6 ≤ d) : sparsity d 2 6 h = 63 / 64 := by
  rw [sparsity_bound d 2 6 (by decide) h]
  norm_num
