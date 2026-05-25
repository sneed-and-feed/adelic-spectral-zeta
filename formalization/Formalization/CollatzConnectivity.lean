import Mathlib.Data.ZMod.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Connectivity
import Mathlib.Tactic

-- ============================================================
-- 1. GRAPH DEFINITION
-- ============================================================

/-- The Schreier graph G_d on ZMod (2^(d-1)) with four generators:
    x ~ 3x, 3x-1, 3⁻¹x, 3⁻¹(x+1)  (mod 2^(d-1)) -/
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

-- ============================================================
-- 2. THE 2-FOLD COVERING PROJECTION
-- ============================================================

/-- Projection π: G_d → G_{d-1} given by reduction mod 2^(d-2). -/
def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) :=
  ZMod.castHom (show 2^(d-2) ∣ 2^(d-1) by exact pow_dvd_pow _ (by omega)) (ZMod (2^(d-2))) x

lemma pi_add {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x + y) = pi x + pi y :=
  map_add _ _ _

lemma pi_mul {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x * y) = pi x * pi y :=
  map_mul _ _ _

lemma pi_natCast {d : ℕ} (n : ℕ) : pi (n : ZMod (2^(d-1))) = (n : ZMod (2^(d-2))) :=
  map_natCast _ _

lemma pi_sub {d : ℕ} (x y : ZMod (2^(d-1))) : pi (x - y) = pi x - pi y :=
  map_sub _ _ _

lemma pi_mul_three {d : ℕ} (x : ZMod (2^(d-1))) : pi (3 * x) = 3 * pi x := by
  have : pi 3 = 3 := by
    have h : (3 : ZMod (2^(d-1))) = ((3 : ℕ) : ZMod (2^(d-1))) := by norm_num
    rw [h, pi_natCast]
    norm_num
  rw [pi_mul, this]

lemma pi_sub_one {d : ℕ} (x : ZMod (2^(d-1))) : pi (x - 1) = pi x - 1 := by
  have : pi 1 = 1 := by
    have h : (1 : ZMod (2^(d-1))) = ((1 : ℕ) : ZMod (2^(d-1))) := by norm_num
    rw [h, pi_natCast]
    norm_num
  rw [pi_sub, this]

lemma pi_mul_three_sub_one {d : ℕ} (x : ZMod (2^(d-1))) : pi (3 * x - 1) = 3 * pi x - 1 := by
  rw [pi_sub_one, pi_mul_three]

lemma pi_eq_zero_iff {d : ℕ} (hd : d ≥ 3) (z : ZMod (2^(d-1))) :
    pi z = 0 ↔ z = 0 ∨ z = (2^(d-2) : ZMod (2^(d-1))) := by
  constructor
  · -- Forward:
    intro hz
    have h_cast : ((z.val : ℕ) : ZMod (2^(d-2))) = 0 := by
      have hz2 : pi z = 0 := hz
      have h_z : z = (z.val : ZMod (2^(d-1))) := (ZMod.natCast_zmod_val z).symm
      rw [h_z] at hz2
      rw [pi_natCast] at hz2
      exact hz2
    have h_div : 2^(d-2) ∣ z.val := by
      exact (CharP.cast_eq_zero_iff (ZMod (2^(d-2))) (2^(d-2)) z.val).mp h_cast
    have h_bound : z.val < 2^(d-1) := ZMod.val_lt z
    have h_cases : z.val = 0 ∨ z.val = 2^(d-2) := by
      obtain ⟨k, hk⟩ := h_div
      have h_pos : 0 < 2^(d-2) := by positivity
      have h_exp : 2^(d-1) = 2 * 2^(d-2) := by
        have h_sub : d - 1 = (d - 2) + 1 := by omega
        rw [h_sub, pow_add, pow_one, mul_comm]
      have h_k : k < 2 := by
        have hk' : k * 2^(d-2) = z.val := by rw [mul_comm]; exact hk.symm
        nlinarith [h_bound, hk', h_pos, h_exp]
      have h_k_eq : k = 0 ∨ k = 1 := by omega
      rcases h_k_eq with h_k_eq | h_k_eq
      · left; rw [hk, h_k_eq]; ring
      · right; rw [hk, h_k_eq]; ring
    rcases h_cases with h_cases | h_cases
    · left
      have h_zero_val : (0 : ZMod (2^(d-1))).val = 0 := ZMod.val_zero
      have h2 : z.val = (0 : ZMod (2^(d-1))).val := by rw [h_cases, h_zero_val]
      exact ZMod.val_injective (2^(d-1)) h2
    · right
      have h_cast2 : (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
      have h_target : ((2^(d-2) : ℕ) : ZMod (2^(d-1))).val = 2^(d-2) := by
        have h_bound2 : 2^(d-2) < 2^(d-1) := by
          have h_sub : d - 2 < d - 1 := by omega
          exact Nat.pow_lt_pow_right (by decide) h_sub
        exact ZMod.val_natCast_of_lt h_bound2
      have h2 : z.val = (2^(d-2) : ZMod (2^(d-1))).val := by 
        rw [h_cast2]
        rw [h_target]
        exact h_cases
      exact ZMod.val_injective (2^(d-1)) h2
  · -- Backward: trivial
    rintro (rfl | rfl)
    · simp [pi]
    · have h_cast2 : (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
      rw [h_cast2]
      rw [pi_natCast]
      have h_div : 2^(d-2) ∣ 2^(d-2) := dvd_refl _
      exact (CharP.cast_eq_zero_iff (ZMod (2^(d-2))) (2^(d-2)) (2^(d-2))).mpr h_div

/-- π is a graph homomorphism in the relational sense: edges project to edges or self-loops (which collapse to a single point). -/
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

-- ============================================================
-- 3. NONTRIVIAL LOOP LIFTING (MONODROMY)
-- ============================================================

/-- The vertex y = 2^(d-3) in G_{d-1} has a type-1 loop (self-edge)
    because 3 * 2^(d-3) ≡ 2^(d-3) (mod 2^(d-2)). -/
theorem loop_at_y {d : ℕ} (hd : d ≥ 3) :
    let y := (2^(d-3) : ZMod (2^(d-2)))
    (3 : ZMod (2^(d-2))) * y = y := by
  intro y
  have h_pow : 2 * 2^(d-3) = 2^(d-2) := by
    have hd_sub : d - 2 = d - 3 + 1 := by omega
    rw [hd_sub, pow_add, pow_one, mul_comm]
  have h3 : (3 : ZMod (2^(d-2))) = 2 + 1 := by norm_num
  calc (3 : ZMod (2^(d-2))) * y
    _ = (2 + 1) * y := by rw [h3]
    _ = 2 * y + 1 * y := add_mul 2 1 y
    _ = 2 * y + y := by rw [one_mul]
    _ = (2 * 2^(d-3) : ℕ) + y := by
      -- need to push nat cast
      have : 2 * y = ((2 * 2^(d-3) : ℕ) : ZMod (2^(d-2))) := by
        push_cast
        rfl
      rw [this]
    _ = (2^(d-2) : ℕ) + y := by rw [h_pow]
    _ = 0 + y := by
      have : ((2^(d-2) : ℕ) : ZMod (2^(d-2))) = 0 := ZMod.natCast_self _
      rw [this]
    _ = y := zero_add y

/-- This loop lifts to a vertical edge connecting the two sheets in G_d. -/
theorem nontrivial_loop_lift {d : ℕ} (hd : d ≥ 3) :
    let y := (2^(d-3) : ZMod (2^(d-2)))
    ∃ x₁ x₂ : ZMod (2^(d-1)), 
      pi x₁ = y ∧ pi x₂ = y ∧ (G_d d).Adj x₁ x₂ ∧ x₁ ≠ x₂ := by
  intro y
  -- The two lifts of y are:
  -- x₁ = 2^(d-3)  (the "lower" sheet)
  -- x₂ = 2^(d-3) + 2^(d-2)  (the "upper" sheet)
  let x₁ := (2^(d-3) : ZMod (2^(d-1)))
  let x₂ := (2^(d-3) + 2^(d-2) : ZMod (2^(d-1)))
  have h_ne : x₁ ≠ x₂ := by
    intro h
    have : x₂ - x₁ = 0 := sub_eq_zero.mpr h.symm
    have h_sub : x₂ - x₁ = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by
      calc x₂ - x₁ = (2^(d-3) + 2^(d-2) : ZMod (2^(d-1))) - 2^(d-3) := rfl
      _ = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
    rw [h_sub] at this
    have h3 : 2^(d-1) ∣ 2^(d-2) := by
      exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2^(d-2))).mp this
    have h4 : 2^(d-1) ≤ 2^(d-2) := Nat.le_of_dvd (by positivity) h3
    have h5 : d - 2 < d - 1 := by omega
    have h6 : 2^(d-2) < 2^(d-1) := Nat.pow_lt_pow_right (by decide) h5
    linarith
  have h_eq_three : x₂ = 3 * x₁ := by
    simp [x₁, x₂]
    have h_pow : (2^(d-2) : ZMod (2^(d-1))) = 2 * (2^(d-3) : ZMod (2^(d-1))) := by
      push_cast
      have h_sub : d - 2 = d - 3 + 1 := by omega
      rw [h_sub, pow_add, pow_one]
      ring
    rw [h_pow]
    ring
  use x₁, x₂
  constructor
  · -- π(x₁) = y
    simp [pi, x₁, y]
  constructor
  · -- π(x₂) = y
    simp [x₂, y]
    rw [pi_add]
    have h_pi_1 : pi (2^(d-3) : ZMod (2^(d-1))) = (2^(d-3) : ZMod (2^(d-2))) := by
      have h_cast : (2^(d-3) : ZMod (2^(d-1))) = ((2^(d-3) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
      rw [h_cast, pi_natCast]
      push_cast; rfl
    have h_pi_2 : pi (2^(d-2) : ZMod (2^(d-1))) = 0 := by
      have h_cast : (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
      rw [h_cast, pi_natCast]
      have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-2))) = 0 := ZMod.natCast_self _
      exact h_zero
    rw [h_pi_1, h_pi_2, add_zero]
  constructor
  · -- (G_d d).Adj x₁ x₂
    refine ⟨h_ne, Or.inl h_eq_three⟩
  · -- x₁ ≠ x₂
    exact h_ne



def tau {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-1)) :=
  x + (2^(d-2) : ℕ)

lemma tau_tau {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : tau (tau x) = x := by
  simp [tau]
  have h : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = 0 := by
    have h_pow : 2^(d-2) + 2^(d-2) = 2^(d-1) := by
      have hd_sub : d - 1 = d - 2 + 1 := by omega
      rw [hd_sub, pow_add, pow_one]
      ring
    have h_cast : (2^(d-2) : ZMod (2^(d-1))) + (2^(d-2) : ZMod (2^(d-1))) = ((2^(d-2) + 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; rfl
    rw [h_cast, h_pow]
    exact ZMod.natCast_self _
  rw [add_assoc, h, add_zero]

lemma tau_neq {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : tau x ≠ x := by
  intro h
  have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
    calc ((2^(d-2) : ℕ) : ZMod (2^(d-1))) = tau x - x := by
           dsimp [tau]
           ring
         _ = 0 := by
           have h1 : tau x - x = x - x := by rw [h]
           rw [h1, sub_self]
  have h_dvd : 2^(d-1) ∣ 2^(d-2) := by
    exact (CharP.cast_eq_zero_iff (ZMod (2^(d-1))) (2^(d-1)) (2^(d-2))).mp h_zero
  have h_pos : 0 < 2^(d-2) := by positivity
  have h_le : 2^(d-1) ≤ 2^(d-2) := Nat.le_of_dvd h_pos h_dvd
  have h_lt : 2^(d-2) < 2^(d-1) := by
    have h_sub : d - 1 = d - 2 + 1 := by omega
    rw [h_sub, pow_add, pow_one]
    omega
  omega

lemma tau_pi {d : ℕ} (hd : d ≥ 3) (x : ZMod (2^(d-1))) : pi (tau x) = pi x := by
  change pi (x + ((2^(d-2) : ℕ) : ZMod (2^(d-1)))) = pi x
  rw [pi_add, pi_natCast]
  have h_zero : ((2^(d-2) : ℕ) : ZMod (2^(d-2))) = 0 := ZMod.natCast_self _
  rw [h_zero, add_zero]

lemma tau_is_hom {d : ℕ} (hd : d ≥ 3) {x y : ZMod (2^(d-1))} :
    (G_d d).Adj x y → (G_d d).Adj (tau x) (tau y) := by
  intro hxy
  rcases hxy with ⟨hne, h | h | h | h⟩
  · refine ⟨?_, Or.inl ?_⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc y + ↑(2 ^ (d - 2)) = 3 * x + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (x + ↑(2 ^ (d - 2))) - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 0 := by rw [h_zero]
           _ = 3 * (x + ↑(2 ^ (d - 2))) := by ring
  · refine ⟨?_, Or.inr (Or.inl ?_)⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc y + ↑(2 ^ (d - 2)) = 3 * x - 1 + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 1 - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 1 - 0 := by rw [h_zero]
           _ = 3 * (x + ↑(2 ^ (d - 2))) - 1 := by ring
  · refine ⟨?_, Or.inr (Or.inr (Or.inl ?_))⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc x + ↑(2 ^ (d - 2)) = 3 * y + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (y + ↑(2 ^ (d - 2))) - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 0 := by rw [h_zero]
           _ = 3 * (y + ↑(2 ^ (d - 2))) := by ring
  · refine ⟨?_, Or.inr (Or.inr (Or.inr ?_))⟩
    · intro h_eq
      apply hne
      calc x = tau (tau x) := (tau_tau hd x).symm
           _ = tau (tau y) := by rw [h_eq]
           _ = y := tau_tau hd y
    · simp [tau]
      have h_zero : ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) = 0 := by
        have h_pow : 2 * 2^(d-2) = 2^(d-1) := by
          have hd_sub : d - 1 = d - 2 + 1 := by omega
          rw [hd_sub, pow_add, pow_one, mul_comm]
        rw [h_pow]
        exact ZMod.natCast_self _
      calc x + ↑(2 ^ (d - 2)) = 3 * y - 1 + ↑(2 ^ (d - 2)) := by rw [h]
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 1 - ((2 * 2^(d-2) : ℕ) : ZMod (2^(d-1))) := by push_cast; ring
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 1 - 0 := by rw [h_zero]
           _ = 3 * (y + ↑(2 ^ (d - 2))) - 1 := by ring

def tau_hom {d : ℕ} (hd : d ≥ 3) : (G_d d) →g (G_d d) where
  toFun := tau
  map_rel' := @tau_is_hom d hd

lemma coprime_3_2_pow {d : ℕ} : Nat.Coprime 3 (2^(d-1)) := by
  have h1 : Nat.Coprime 3 2 := by decide
  exact Nat.Coprime.pow_right (d-1) h1

def inv3 {d : ℕ} (hd : d ≥ 3) : ZMod (2^(d-1)) :=
  (ZMod.unitOfCoprime 3 (coprime_3_2_pow (d:=d))).inv

lemma three_mul_inv3 {d : ℕ} (hd : d ≥ 3) : (3 : ZMod (2^(d-1))) * inv3 hd = 1 := by
  have h := (ZMod.unitOfCoprime 3 (coprime_3_2_pow (d:=d))).mul_inv
  exact h

lemma inv3_mul_three {d : ℕ} (hd : d ≥ 3) : inv3 hd * (3 : ZMod (2^(d-1))) = 1 := by
  rw [mul_comm]
  exact three_mul_inv3 hd

lemma pi_inv3 {d : ℕ} (hd : d ≥ 3) : pi (inv3 hd) * (3 : ZMod (2^(d-2))) = 1 := by
  have h1 : (inv3 hd) * (3 : ZMod (2^(d-1))) = 1 := inv3_mul_three hd
  have h2 := congrArg pi h1
  rw [pi_mul] at h2
  have h3 : pi (3 : ZMod (2^(d-1))) = (3 : ZMod (2^(d-2))) := by
    have h_cast1 : (3 : ZMod (2^(d-1))) = ((3 : ℕ) : ZMod (2^(d-1))) := by exact Eq.symm Nat.cast_ofNat
    have h_cast2 : (3 : ZMod (2^(d-2))) = ((3 : ℕ) : ZMod (2^(d-2))) := by exact Eq.symm Nat.cast_ofNat
    rw [h_cast1, h_cast2, pi_natCast]
  rw [h3] at h2
  have h4 : pi (1 : ZMod (2^(d-1))) = (1 : ZMod (2^(d-2))) := by
    have h_cast1 : (1 : ZMod (2^(d-1))) = ((1 : ℕ) : ZMod (2^(d-1))) := by exact Eq.symm Nat.cast_one
    have h_cast2 : (1 : ZMod (2^(d-2))) = ((1 : ℕ) : ZMod (2^(d-2))) := by exact Eq.symm Nat.cast_one
    rw [h_cast1, h_cast2, pi_natCast]
  rw [h4] at h2
  exact h2

lemma adj_implies_not_fixed_mul {d : ℕ} {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))}
    (hne : pi x ≠ v) (hv : v = 3 * pi x) : x ≠ 3 * x := by
  intro h
  have h_pi : pi x = pi (3 * x) := congrArg pi h
  have h_pi2 : pi (3 * x) = 3 * pi x := pi_mul_three _
  rw [h_pi2] at h_pi
  have h_v : v = pi x := by rw [hv, ←h_pi]
  exact hne h_v.symm

lemma adj_implies_not_fixed_mul_sub {d : ℕ} {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))}
    (hne : pi x ≠ v) (hv : v = 3 * pi x - 1) : x ≠ 3 * x - 1 := by
  intro h
  have h_pi : pi x = pi (3 * x - 1) := congrArg pi h
  have h_pi2 : pi (3 * x - 1) = 3 * pi x - 1 := pi_mul_three_sub_one _
  rw [h_pi2] at h_pi
  have h_v : v = pi x := by rw [hv, ←h_pi]
  exact hne h_v.symm

lemma adj_implies_not_fixed_inv {d : ℕ} (hd : d ≥ 3) {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))}
    (hne : pi x ≠ v) (hv : pi x = 3 * v) : x ≠ 3 * x := by
  intro h
  have h_pi : pi x = pi (3 * x) := congrArg pi h
  have h_pi2 : pi (3 * x) = 3 * pi x := pi_mul_three _
  rw [h_pi2] at h_pi
  have h_v : v = pi x := by
    calc v = 1 * v := by ring
         _ = pi (inv3 hd) * 3 * v := by rw [pi_inv3 hd]
         _ = pi (inv3 hd) * (3 * v) := by ring
         _ = pi (inv3 hd) * pi x := by rw [←hv]
         _ = pi (inv3 hd) * (3 * pi x) := congrArg (fun y => pi (inv3 hd) * y) h_pi
         _ = pi (inv3 hd) * 3 * pi x := by ring
         _ = 1 * pi x := by rw [pi_inv3 hd]
         _ = pi x := by ring
  exact hne h_v.symm

lemma adj_implies_not_fixed_inv_sub {d : ℕ} (hd : d ≥ 3) {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))}
    (hne : pi x ≠ v) (hv : pi x = 3 * v - 1) : x ≠ 3 * x - 1 := by
  intro h
  have h_2x : 2 * x = 1 := by
    calc 2 * x = 3 * x - x := by ring
         _ = 1 := by 
           have : 3 * x = x + 1 := by 
             calc 3 * x = (3 * x - 1) + 1 := by ring
                  _ = x + 1 := by rw [←h]
           rw [this]
           ring
  have h_unit : IsUnit (2 : ZMod (2^(d-1))) := isUnit_of_mul_eq_one (2 : ZMod (2^(d-1))) x h_2x
  have h_coprime : Nat.Coprime 2 (2^(d-1)) := by
    have h_cast : (2 : ZMod (2^(d-1))) = ((2 : ℕ) : ZMod (2^(d-1))) := by rfl
    rw [←ZMod.isUnit_iff_coprime, ←h_cast]
    exact h_unit
  have h_not_coprime : ¬ Nat.Coprime 2 (2^(d-1)) := by
    intro h_c
    have h_dvd : 2 ∣ 2^(d-1) := by exact dvd_pow_self 2 (by omega)
    have h_div : 2 ∣ Nat.gcd 2 (2^(d-1)) := Nat.dvd_gcd (dvd_refl 2) h_dvd
    have h_eq_1 : Nat.gcd 2 (2^(d-1)) = 1 := h_c
    rw [h_eq_1] at h_div
    revert h_div; decide
  exact h_not_coprime h_coprime

lemma edge_lift {d : ℕ} (hd : d ≥ 3) {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))} 
    (h : (G_d (d-1)).Adj (pi x) v) : 
    ∃ x' : ZMod (2^(d-1)), pi x' = v ∧ (G_d d).Adj x x' := by
  rcases h with ⟨hne, h | h | h | h⟩
  · -- Case 1: v = 3 * (pi x)
    use 3 * x
    constructor
    · have h_pi : pi (3 * x) = 3 * pi x := pi_mul_three _
      rw [h_pi, ←h]
    · exact ⟨adj_implies_not_fixed_mul hne h, Or.inl rfl⟩
  · -- Case 2: v = 3 * (pi x) - 1
    use 3 * x - 1
    constructor
    · have h_pi : pi (3 * x - 1) = 3 * pi x - 1 := pi_mul_three_sub_one _
      rw [h_pi, ←h]
    · exact ⟨adj_implies_not_fixed_mul_sub hne h, Or.inr (Or.inl rfl)⟩
  · -- Case 3: pi x = 3 * v
    use inv3 hd * x
    constructor
    · have h1 : pi (inv3 hd * x) = pi (inv3 hd) * pi x := pi_mul _ _
      rw [h1, h]
      have h2 : pi (inv3 hd) * (3 * v) = (pi (inv3 hd) * 3) * v := by ring
      rw [h2, pi_inv3 hd, one_mul]
    · have h_eq : x = 3 * (inv3 hd * x) := by
        calc x = 1 * x := by ring
             _ = (3 * inv3 hd) * x := by rw [three_mul_inv3 hd]
             _ = 3 * (inv3 hd * x) := by ring
      have h_adj : inv3 hd * x = 3 * x ∨ inv3 hd * x = 3 * x - 1 ∨ x = 3 * (inv3 hd * x) ∨ x = 3 * (inv3 hd * x) - 1 := by
        exact Or.inr (Or.inr (Or.inl h_eq))
      have h_ne' : x ≠ inv3 hd * x := by
        intro h_eq_x
        have h3x : 3 * x = 3 * (inv3 hd * x) := congrArg (fun y => 3 * y) h_eq_x
        rw [←h_eq] at h3x
        exact (adj_implies_not_fixed_inv hd hne h) h3x.symm
      exact ⟨h_ne', h_adj⟩
  · -- Case 4: pi x = 3 * v - 1
    use inv3 hd * (x + 1)
    constructor
    · have h1 : pi (inv3 hd * (x + 1)) = pi (inv3 hd) * pi (x + 1) := pi_mul _ _
      have h_pi_add : pi (x + 1) = pi x + 1 := by
        have h_one : pi 1 = 1 := by
          have h_cast : (1 : ZMod (2^(d-1))) = ((1 : ℕ) : ZMod (2^(d-1))) := by norm_num
          rw [h_cast, pi_natCast]
          norm_num
        rw [pi_add, h_one]
      rw [h1, h_pi_add, h]
      have h2 : pi (inv3 hd) * (3 * v - 1 + 1) = (pi (inv3 hd) * 3) * v := by ring
      rw [h2, pi_inv3 hd, one_mul]
    · have h_eq : x = 3 * (inv3 hd * (x + 1)) - 1 := by
        calc x = x + 1 - 1 := by ring
             _ = 1 * (x + 1) - 1 := by ring
             _ = (3 * inv3 hd) * (x + 1) - 1 := by rw [three_mul_inv3 hd]
             _ = 3 * (inv3 hd * (x + 1)) - 1 := by ring
      have h_adj : inv3 hd * (x + 1) = 3 * x ∨ inv3 hd * (x + 1) = 3 * x - 1 ∨ x = 3 * (inv3 hd * (x + 1)) ∨ x = 3 * (inv3 hd * (x + 1)) - 1 := by
        exact Or.inr (Or.inr (Or.inr h_eq))
      have h_ne' : x ≠ inv3 hd * (x + 1) := by
        intro h_eq_x
        have h3x : 3 * x - 1 = 3 * (inv3 hd * (x + 1)) - 1 := congrArg (fun y => 3 * y - 1) h_eq_x
        rw [←h_eq] at h3x
        exact (adj_implies_not_fixed_inv_sub hd hne h) h3x.symm
      exact ⟨h_ne', h_adj⟩

/-- Generalization of path lift for induction. -/
theorem path_lift_gen {d : ℕ} (hd : d ≥ 3) {u y : ZMod (2^(d-2))} (w : (G_d (d-1)).Walk u y) :
    ∀ x : ZMod (2^(d-1)), pi x = u → 
    ∃ x' : ZMod (2^(d-1)), ∃ w' : (G_d d).Walk x x', pi x' = y ∧ w'.length = w.length := by
  induction w with
  | nil =>
    intro x hx
    use x, SimpleGraph.Walk.nil
    exact ⟨hx, rfl⟩
  | @cons u v y h_adj w_tail ih =>
    intro x hx
    have h_adj' : (G_d (d-1)).Adj (pi x) v := by rwa [hx]
    obtain ⟨v_lift, hv_lift_eq, hv_lift_adj⟩ := edge_lift hd h_adj'
    obtain ⟨y_lift, w_tail_lift, hy_lift_eq, hw_len⟩ := ih v_lift hv_lift_eq
    use y_lift, SimpleGraph.Walk.cons hv_lift_adj w_tail_lift
    exact ⟨hy_lift_eq, by simp [hw_len]⟩

/-- Any path from 0 to y in G_{d-1} lifts to a path from 0 to some x in G_d where π(x) = y. -/
theorem path_lift {d : ℕ} (hd : d ≥ 3) {y : ZMod (2^(d-2))} (w : (G_d (d-1)).Walk 0 y) :
    ∃ x : ZMod (2^(d-1)), ∃ w' : (G_d d).Walk 0 x, pi x = y ∧ w'.length = w.length := by
  have h := path_lift_gen hd w 0 (by simp [pi])
  exact h

-- ============================================================
-- 4. FIBER CONNECTIVITY
-- ============================================================

/-- The fiber of pi has size 2. -/
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

/-- Any two vertices in the same fiber are reachable from each other.
    This is proven using the monodromy edge: lift a path from y to the loop point,
    cross the monodromy edge to switch sheets, and follow the reversed lifted path back. -/
lemma fiber_connected {d : ℕ} (hd : d ≥ 3) (h_conn : (G_d (d-1)).Connected) (y : ZMod (2^(d-2))) :
    ∀ x₁ x₂ : ZMod (2^(d-1)), pi x₁ = y → pi x₂ = y → (G_d d).Reachable x₁ x₂ := by
  intro x₁ x₂ h₁ h₂
  by_cases h_eq : x₁ = x₂
  · subst h_eq; exact SimpleGraph.Reachable.refl _
  case neg =>
  -- Let y_loop = 2^(d-3) be the loop point in G_{d-1}
  let y_loop := (2^(d-3) : ZMod (2^(d-2)))
  -- By connectivity of G_{d-1} (proven separately or assumed), there's a path from y to y_loop
  have h_path : (G_d (d-1)).Reachable y y_loop := by
    rw [SimpleGraph.connected_iff_exists_forall_reachable] at h_conn
    obtain ⟨u, hu⟩ := h_conn
    exact SimpleGraph.Reachable.trans (hu y).symm (hu y_loop)
  obtain w := h_path.some
  -- Lift the path from y to y_loop, starting at x₁
  obtain ⟨x_loop, w_lift, h_loop_eq, _⟩ := path_lift_gen hd w x₁ h₁
  -- x_loop is in the fiber over y_loop
  -- Use nontrivial_loop_lift to get the two lifts of y_loop
  obtain ⟨a, b, ha, hb, h_adj, h_ne⟩ := nontrivial_loop_lift hd
  -- x_loop is either a or b
  have h_x_loop : x_loop = a ∨ x_loop = b := by
    have h_fib := zmod_fiber_two hd x_loop a b h_loop_eq ha hb
    rcases h_fib with h_xa | h_xb | h_ab
    · exact Or.inl h_xa
    · exact Or.inr h_xb
    · exfalso; exact h_ne h_ab
  
  -- The other endpoint of the loop lift
  let other_x := tau x_loop
  have h_other_pi : pi other_x = y_loop := by
    rw [tau_pi hd, h_loop_eq]
  
  have h_other_neq : other_x ≠ x_loop := tau_neq hd x_loop

  -- Since x_loop is in {a, b}, other_x must be the other one!
  have h_cross : (G_d d).Reachable x_loop other_x := by
    have h_other_ab : other_x = a ∨ other_x = b := by
      have h_fib := zmod_fiber_two hd other_x a b h_other_pi ha hb
      rcases h_fib with h_xa | h_xb | h_ab
      · exact Or.inl h_xa
      · exact Or.inr h_xb
      · exfalso; exact h_ne h_ab
    rcases h_x_loop with h_x_a | h_x_b
    · -- x_loop = a
      have h_o_b : other_x = b := by
        rcases h_other_ab with h_o_a | h_o_b
        · exfalso; apply h_other_neq; rw [h_o_a, h_x_a]
        · exact h_o_b
      have e : (G_d d).Adj x_loop other_x := by
        rw [h_x_a, h_o_b]
        exact h_adj
      exact ⟨SimpleGraph.Walk.cons e SimpleGraph.Walk.nil⟩
    · -- x_loop = b
      have h_o_a : other_x = a := by
        rcases h_other_ab with h_o_a | h_o_b
        · exact h_o_a
        · exfalso; apply h_other_neq; rw [h_o_b, h_x_b]
      have e : (G_d d).Adj x_loop other_x := by
        rw [h_x_b, h_o_a]
        exact h_adj.symm
      exact ⟨SimpleGraph.Walk.cons e SimpleGraph.Walk.nil⟩

  -- Apply tau to the path w_lift
  -- w_lift is a walk from x₁ to x_loop
  -- so tau_w_lift is a walk from tau x₁ to tau x_loop = other_x
  let tau_w_lift := w_lift.map (tau_hom hd)
  
  -- Since x₁ and x₂ are in the fiber over y and x₁ ≠ x₂, we must have tau x₁ = x₂
  have h_tau_x1 : tau x₁ = x₂ := by
    have h_tau_x1_pi : pi (tau x₁) = y := by rw [tau_pi hd, h₁]
    have h_tau_x1_neq : tau x₁ ≠ x₁ := tau_neq hd x₁
    have h_fib := zmod_fiber_two hd (tau x₁) x₁ x₂ h_tau_x1_pi h₁ h₂
    rcases h_fib with h_1 | h_2 | h_3
    · exfalso; exact h_tau_x1_neq h_1
    · exact h_2
    · exfalso; exact h_eq h_3

  -- tau_w_lift.reverse is a walk from other_x to tau x₁ = x₂
  have h_reach_1 : (G_d d).Reachable x₁ x_loop := ⟨w_lift⟩
  have h_reach_2 : (G_d d).Reachable other_x x₂ := by
    rw [← h_tau_x1]
    exact ⟨tau_w_lift.reverse⟩
      
  exact SimpleGraph.Reachable.trans h_reach_1 (SimpleGraph.Reachable.trans h_cross h_reach_2)

-- ============================================================
-- 5. CONNECTIVITY BY INDUCTION
-- ============================================================

/-- Base case: G_2 is connected (2 vertices {0,1}, edge 0~1). -/
theorem G_2_connected : (G_d 2).Connected := by
  rw [SimpleGraph.connected_iff_exists_forall_reachable]
  use 0
  intro x
  -- ZMod 2 has only 0 and 1
  fin_cases x
  · exact ⟨SimpleGraph.Walk.nil⟩
  · -- 0 ~ 1 via generator 3x-1: 3*0-1 = -1 ≡ 1 (mod 2)
    have e : (G_d 2).Adj 0 1 := by
      refine ⟨by decide, Or.inr (Or.inl ?_)⟩
      -- 1 = 3*0 - 1 mod 2
      simp [ZMod]
    exact ⟨SimpleGraph.Walk.cons e SimpleGraph.Walk.nil⟩

/-- Inductive step: if G_{d-1} is connected, then G_d is connected. -/
theorem G_d_connected {d : ℕ} (hd : d ≥ 2) : (G_d d).Connected := by
  induction d with
  | zero => linarith
  | succ d ih =>
    cases d with
    | zero => linarith
    | succ d =>
      cases d with
      | zero => 
        -- Base case d=2
        exact G_2_connected
      | succ d =>
        -- Inductive step
        have h : d + 2 ≥ 2 := by omega
        have ih_conn : (G_d (d+2)).Connected := ih h
        have ih' := ih_conn
        -- Now prove for d+3 using the covering structure
        rw [SimpleGraph.connected_iff_exists_forall_reachable] at ih' ⊢
        obtain ⟨u, hu⟩ := ih'
        -- u is a vertex in G_{d+2} from which all vertices are reachable
        -- Vertices of G_{d+2} are ZMod (2^(d+1)). We lift u to G_{d+3} (vertices ZMod (2^(d+2))):
        let u_lift := (u.val : ZMod (2^(d+2)))
        use u_lift
        intro x
        -- Project x down to G_{d+2}
        let y := @pi (d+3) x
        -- By ih', y is reachable from u in G_{d+2}
        have hy : (G_d (d+2)).Reachable u y := hu y
        -- Convert reachability to a walk:
        have w := hy.some
        -- Lift the walk from G_{d+2} to G_{d+3} starting at u_lift
        have h_pi_u : @pi (d+3) u_lift = u := by
          have h1 : u_lift = (u.val : ZMod (2^(d+2))) := rfl
          rw [h1, pi_natCast]
          exact ZMod.natCast_zmod_val u
        obtain ⟨x', w', hx'_eq, hw'_len⟩ := @path_lift_gen (d+3) (by omega) u y w u_lift h_pi_u
        
        -- w' is a walk in G_{d+3} from u_lift to x', where pi x' = y = pi x.
        -- Therefore, x' and x are in the same fiber over y.
        -- By fiber_connected, x' and x are reachable.
        have h_reach_x'_x : (G_d (d+3)).Reachable x' x := by
          apply @fiber_connected (d+3) (by omega) ih_conn y x' x hx'_eq rfl
        
        -- u_lift is reachable to x' via w', and x' is reachable to x via h_reach_x'_x.
        exact SimpleGraph.Reachable.trans ⟨w'⟩ h_reach_x'_x
