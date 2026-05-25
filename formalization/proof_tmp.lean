lemma pi_canonicalLift {d : ℕ} (w : ZMod (2^(d-2))) :
    pi (canonicalLift w) = w := by
  unfold canonicalLift
  rw [pi_natCast, ZMod.natCast_zmod_val]

lemma pi_eq_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) (w : ZMod (2^(d-2))) :
    pi z = w ↔ z = canonicalLift w ∨ z = tau (canonicalLift w) := by
  constructor
  · intro h
    have h_sub : pi (z - canonicalLift w) = 0 := by
      rw [pi_sub, h, pi_canonicalLift, sub_self]
    have h_zero_iff := (pi_eq_zero_iff hd (z - canonicalLift w)).mp h_sub
    rcases h_zero_iff with h1 | h2
    · left
      exact sub_eq_zero.mp h1
    · right
      have h3 : z = tau (canonicalLift w) := by
        unfold tau
        calc z = z - canonicalLift w + canonicalLift w := by ring
             _ = (2^(d-2) : ZMod (2^(d-1))) + canonicalLift w := by rw [h2]
             _ = canonicalLift w + ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
      exact h3
  · rintro (h | h)
    · rw [h, pi_canonicalLift]
    · rw [h, tau_pi hd, pi_canonicalLift]

lemma s_card_eq_double {d : ℕ} (hd : d ≥ 3) (u v : ZMod (2^(d-2))) :
    let s := Finset.filter (fun (p : ZMod (2^(d-1)) × ZMod (2^(d-1))) =>
      pi p.1 = v ∧ pi p.2 = u ∧ (G_d d).Adj p.1 p.2) Finset.univ
    (s.card : ℚ) = 2 * weightedMatrix hd v u := by
  intro s
  have h_sum : (s.card : ℚ) = ∑ p : ZMod (2^(d-1)) × ZMod (2^(d-1)), 
      if pi p.1 = v ∧ pi p.2 = u ∧ (G_d d).Adj p.1 p.2 then (1:ℚ) else 0 := by
    rw [← Finset.sum_boole]
  rw [h_sum]
  let x := canonicalLift v
  let y := canonicalLift u
  have h_cases_1 : ∀ p₁, pi p₁ = v ↔ p₁ = x ∨ p₁ = tau x := fun p₁ => pi_eq_iff hd p₁ v
  have h_cases_2 : ∀ p₂, pi p₂ = u ↔ p₂ = y ∨ p₂ = tau y := fun p₂ => pi_eq_iff hd p₂ u
  have h_sum_prod : (∑ p : ZMod (2^(d-1)) × ZMod (2^(d-1)), if pi p.1 = v ∧ pi p.2 = u ∧ (G_d d).Adj p.1 p.2 then (1:ℚ) else 0) =
    ∑ p₁ : ZMod (2^(d-1)), ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := Fintype.sum_prod_type
  rw [h_sum_prod]

  let S_x : Finset (ZMod (2^(d-1))) := {x, tau x}
  let S_y : Finset (ZMod (2^(d-1))) := {y, tau y}

  have h_sum_subset_x : (∑ p₁ : ZMod (2^(d-1)), ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₁ in S_x, ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    symm
    apply Finset.sum_subset (Finset.subset_univ S_x)
    intro p₁ _ hp₁
    have h_not : ¬(pi p₁ = v) := by
      intro h_pi
      have h_or : p₁ = x ∨ p₁ = tau x := (h_cases_1 p₁).mp h_pi
      simp only [S_x, Finset.mem_insert, Finset.mem_singleton] at hp₁
      tauto
    have : (∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) = 0 := by
      apply Finset.sum_eq_zero
      intro p₂ _
      simp [h_not]
    exact this

  have h_sum_subset_y : ∀ p₁, (∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₂ in S_y, if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    intro p₁
    symm
    apply Finset.sum_subset (Finset.subset_univ S_y)
    intro p₂ _ hp₂
    have h_not : ¬(pi p₂ = u) := by
      intro h_pi
      have h_or : p₂ = y ∨ p₂ = tau y := (h_cases_2 p₂).mp h_pi
      simp only [S_y, Finset.mem_insert, Finset.mem_singleton] at hp₂
      tauto
    simp [h_not]

  rw [h_sum_subset_x]
  have h_sum_subset_y_sum : (∑ p₁ in S_x, ∑ p₂ : ZMod (2^(d-1)), if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₁ in S_x, ∑ p₂ in S_y, if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    apply Finset.sum_congr rfl
    intro p₁ _
    exact h_sum_subset_y p₁

  have h_neq : ∀ z : ZMod (2^(d-1)), z ≠ tau z := by
    intro z h_eq
    have h_tau : tau z = z + ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := rfl
    rw [h_tau] at h_eq
    have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
      calc ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = z + ((2^(d-2) : ℕ) : ZMod (2^(d-1))) - z := by ring
        _ = z - z := by rw [← h_eq]
        _ = 0 := by ring
    have h_pow : 2^(d-2) < 2^(d-1) := by
      have h_lt : d - 2 < d - 1 := by omega
      exact Nat.pow_lt_pow_right (by decide) h_lt
    have h_val : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := ZMod.val_natCast_of_lt h_pow
    rw [h_zero] at h_val
    have h_val_zero : (0 : ZMod (2^(d-1))).val = 0 := ZMod.val_zero
    rw [h_val_zero] at h_val
    have h_pos : 0 < 2^(d-2) := by positivity
    linarith

  have h_x_neq : x ≠ tau x := h_neq x
  have h_y_neq : y ≠ tau y := h_neq y

  have h_pi_x : pi x = v := pi_canonicalLift v
  have h_pi_tau_x : pi (tau x) = v := by rw [tau_pi hd, h_pi_x]
  have h_pi_y : pi y = u := pi_canonicalLift u
  have h_pi_tau_y : pi (tau y) = u := by rw [tau_pi hd, h_pi_y]

  have h_simplify_sum : (∑ p₁ in S_x, ∑ p₂ in S_y, if pi p₁ = v ∧ pi p₂ = u ∧ (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) =
      ∑ p₁ in S_x, ∑ p₂ in S_y, if (G_d d).Adj p₁ p₂ then (1:ℚ) else 0 := by
    apply Finset.sum_congr rfl
    intro p₁ hp₁
    apply Finset.sum_congr rfl
    intro p₂ hp₂
    have h1 : pi p₁ = v := by
      simp only [S_x, Finset.mem_insert, Finset.mem_singleton] at hp₁
      rcases hp₁ with h | h
      · rw [h]; exact h_pi_x
      · rw [h]; exact h_pi_tau_x
    have h2 : pi p₂ = u := by
      simp only [S_y, Finset.mem_insert, Finset.mem_singleton] at hp₂
      rcases hp₂ with h | h
      · rw [h]; exact h_pi_y
      · rw [h]; exact h_pi_tau_y
    simp [h1, h2]

  rw [h_sum_subset_y_sum, h_simplify_sum]

  have h_eval : (∑ p₁ in S_x, ∑ p₂ in S_y, if (G_d d).Adj p₁ p₂ then (1:ℚ) else 0) = 
      2 * ((if (G_d d).Adj x y then (1:ℚ) else 0) + (if (G_d d).Adj x (tau y) then (1:ℚ) else 0)) := by
    simp only [S_x, S_y, Finset.sum_insert, Finset.sum_singleton, Finset.mem_singleton, h_x_neq, h_y_neq, not_false_eq_true]
    have h_tau_y : ((G_d d).Adj (tau x) y ↔ (G_d d).Adj x (tau y)) := tau_adj_bicond hd x y
    have h_tau_tau : ((G_d d).Adj (tau x) (tau y) ↔ (G_d d).Adj x y) := by
      rw [tau_adj_bicond hd, tau_tau hd]
    simp only [h_tau_y, h_tau_tau]
    ring

  rw [h_eval]
  have h_weighted : weightedMatrix hd v u = (if (G_d d).Adj x y then (1:ℚ) else 0) + (if (G_d d).Adj x (tau y) then (1:ℚ) else 0) := by
    unfold weightedMatrix A'_matrix
    simp only [Matrix.reindex_apply, Equiv.symm_symm, Matrix.submatrix_apply]
    erw [sheetSplitInv_zero hd v, sheetSplitInv_zero hd u, sheetSplitInv_one hd u]
    change (if (G_d d).Adj (canonicalLift v) (canonicalLift u) then (1:ℚ) else 0) +
           (if (G_d d).Adj (canonicalLift v) (tau (canonicalLift u)) then (1:ℚ) else 0) = _
    rfl

  rw [h_weighted]
