/-
  SpectralCircle.lean
  
  Core lemma: D_n acts as a monomial matrix in the character basis.
  The additive character χ satisfies:
    ∑_y D(x,y) · χ(k·y) = (1 + χ(-k)) · χ(3k·x)
  
  This is the algebraic foundation of the Spectral Circle Theorem:
  all eigenvalues of S_n lie on a circle of radius 2^{2^{-(n-1)}}.
-/

import Mathlib
import Formalization.CollatzRelMatrix
import Formalization.DFT
import Formalization.CyclotomicProduct
import Formalization.SchreierSpectralGap

open Matrix Finset Complex
open CollatzDirMatrix

-- ============================================================================
-- 1. DISTINCTNESS OF COLLATZ TARGETS
-- ============================================================================

/-- The two targets 3x and 3x-1 are always distinct in ZMod(2^n) for n ≥ 1.
    Proof: if 3x = 3x - 1, then 1 = 0 in ZMod(2^n), but 2^n ≥ 2 so this is false. -/
lemma collatzDir_targets_distinct (n : ℕ) (hn : n ≥ 1) (x : ZMod (2^n)) :
    (3 : ZMod (2^n)) * x ≠ 3 * x - 1 := by
  haveI : Fact (1 < 2^n) := ⟨Nat.one_lt_two_pow (by omega)⟩
  exact sub_ne_zero.mp <| fun h => one_ne_zero <| by
    calc (1 : ZMod (2^n)) = 3*x - (3*x - 1) := by ring
      _ = 0 := h

-- ============================================================================
-- 2. CHARACTER ACTION LEMMA (the monomial structure)
-- ============================================================================

/-- The core monomial action: D_n maps χ_k to (1 + χ(-k)) · χ_{3k}.

    For an additive character χ:
    ∑_y D(x,y) · χ(ky) = χ(k·3x) + χ(k·(3x-1))
                        = χ(3kx) + χ(3kx + (-k))
                        = χ(3kx) + χ(3kx)·χ(-k)
                        = (1 + χ(-k)) · χ(3kx)
-/
lemma collatzDirMatrix_char_action (n : ℕ) (hn : n ≥ 1)
    (χ : AddChar (ZMod (2^n)) ℂ)
    (k x : ZMod (2^n)) :
    ∑ y : ZMod (2^n), (algebraMap ℚ ℂ (collatzDirMatrix n x y)) * χ (k * y) =
    (1 + χ (-k)) * χ (3 * k * x) := by
  have : ∀ y, algebraMap ℚ ℂ (collatzDirMatrix n x y) * χ (k * y) = if y = 3 * x ∨ y = 3 * x - 1 then χ (k * y) else 0 := by
    intro y; simp only [collatzDirMatrix]; split_ifs <;> simp
  simp_rw [this, ← Finset.sum_filter]
  have : Finset.univ.filter (fun y => y = 3 * x ∨ y = 3 * x - 1) = {3 * x, 3 * x - 1} := by ext y; simp
  rw [this, Finset.sum_pair (collatzDir_targets_distinct n hn x)]
  have hk1 : k * (3 * x) = 3 * k * x := by ring
  have hk2 : k * (3 * x - 1) = 3 * k * x + (-k) := by ring
  rw [hk1, hk2, AddChar.map_add_mul]
  ring

-- ============================================================================
-- 3. ORBIT STRUCTURE (×3 on odd residues)
-- ============================================================================

lemma three_pow_two_pow (k : ℕ) (hk : k ≥ 1) :
    ∃ (a : ℤ), Odd a ∧ (3 : ℤ)^(2^k) = 1 + a * 2^(k+2) := by
  induction' k, hk using Nat.le_induction with k _ ih
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

/-- The order of 3 in (ZMod (2^n))ˣ is 2^{n-2} for n ≥ 3.
    Classical result: 3^{2^{n-3}} ≡ 1 + 2^{n-1} (mod 2^n), so
    3^{2^{n-2}} ≡ 1 but 3^{2^{n-3}} ≢ 1. -/
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

-- ============================================================================
-- 4. ORBIT WEIGHT MAGNITUDE
-- ============================================================================

/-- Each orbit of ×3 on odd residues has weight product with magnitude √2.
    This follows from the cyclotomic product identity (proven in CyclotomicProduct.lean)
    combined with the symmetry C₂ = -C₁. -/
lemma char_val {n : ℕ} {k : ZMod (2^n)} {χ : AddChar (ZMod (2^n)) ℂ} :
  χ k = χ 1 ^ k.val := by
  have hk : k = k.val • 1 := by
    rw [nsmul_one]
    exact (ZMod.natCast_zmod_val k).symm
  rw [hk]
  have h2 : (k.val • (1 : ZMod (2^n))).val = k.val := by
    rw [nsmul_one]
    exact ZMod.val_natCast_of_lt (ZMod.val_lt k)
  rw [h2]
  exact AddChar.map_nsmul_pow χ k.val 1

lemma char_neg' {n : ℕ} {χ : AddChar (ZMod (2^n)) ℂ} {x : ZMod (2^n)} :
  χ (-x) = (χ x)⁻¹ := by
  apply eq_inv_of_mul_eq_one_left
  rw [← AddChar.map_add_mul, add_left_neg, AddChar.map_zero_one]

lemma star_char_one {n : ℕ} {χ : AddChar (ZMod (2^n)) ℂ} :
  star (χ 1) = (χ 1)⁻¹ := by
  have h1 : (χ 1) ^ (2^n) = 1 := by
    have hd : (2^n) • (1 : ZMod (2^n)) = 0 := by
      change (2^n : ℕ) • 1 = 0
      rw [nsmul_one]
      exact ZMod.natCast_self (2^n)
    rw [← AddChar.map_nsmul_pow, hd, AddChar.map_zero_one]
  have h2 : ‖χ 1‖ = 1 := by
    have hn : (2^n : ℕ) ≠ 0 := by positivity
    exact Complex.norm_eq_one_of_pow_eq_one h1 hn
  apply eq_inv_of_mul_eq_one_left
  have h_sq : (‖χ 1‖ : ℂ) ^ 2 = 1 := by 
    rw [h2]
    simp
  rw [RCLike.star_def]
  have hz2 := RCLike.conj_mul (χ 1)
  rw [hz2]
  exact h_sq

lemma star_char {n : ℕ} {χ : AddChar (ZMod (2^n)) ℂ} {x : ZMod (2^n)} :
  star (χ x) = χ (-x) := by
  have hx : χ x = χ 1 ^ x.val := char_val
  rw [hx]
  have h1 : star ((χ 1) ^ x.val) = (star (χ 1)) ^ x.val := map_pow (starRingEnd ℂ) (χ 1) x.val
  rw [h1, star_char_one]
  have h_inv : ((χ 1)⁻¹) ^ x.val = ((χ 1) ^ x.val)⁻¹ := inv_pow (χ 1) x.val
  rw [h_inv, ← hx]
  exact char_neg'.symm

lemma normSq_eq_mul_star (z : ℂ) : (Complex.normSq z : ℂ) = z * star z := by
  exact (Complex.mul_conj z).symm

lemma odd_is_unit {n : ℕ} {x : ZMod (2^n)} (hx : x.val % 2 = 1) : IsUnit x := by
  have hc : Nat.Coprime x.val 2 := by
    rw [Nat.coprime_two_right, Nat.odd_iff]
    exact hx
  have hc_pow : Nat.Coprime x.val (2^n) := Nat.Coprime.pow_right n hc
  have h_is_unit_cast : IsUnit (x.val : ZMod (2^n)) := (ZMod.isUnit_iff_coprime x.val (2^n)).mpr hc_pow
  have : (x.val : ZMod (2^n)) = x := ZMod.natCast_zmod_val x
  rwa [← this]

lemma three_pow_mod_eight (m : ℕ) : (3 : ZMod 8)^m = 1 ∨ (3 : ZMod 8)^m = 3 := by
  induction m with
  | zero => left; ring
  | succ m ih =>
    rcases ih with h1 | h3
    · right; rw [pow_succ, h1]; ring
    · left; rw [pow_succ, h3]; decide

lemma odd_iff_isUnit {n : ℕ} (hn : n ≥ 1) (x : ZMod (2^n)) : Odd x.val ↔ IsUnit x := by
  constructor
  · intro h
    have h_eq : x.val % 2 = 1 := Nat.odd_iff.mp h
    exact odd_is_unit h_eq
  · intro h
    have hc : IsUnit (x.val : ZMod (2^n)) := by
      have : (x.val : ZMod (2^n)) = x := ZMod.natCast_zmod_val x
      rwa [this]
    have h_coprime : Nat.Coprime x.val (2^n) := (ZMod.isUnit_iff_coprime x.val (2^n)).mp hc
    have h_div : 2 ∣ 2^n := dvd_pow_self 2 (by omega)
    have h_coprime2 : Nat.Coprime x.val 2 := Nat.Coprime.coprime_dvd_right h_div h_coprime
    exact Nat.coprime_two_right.mp h_coprime2

lemma odd_card (n : ℕ) (hn : n ≥ 1) : 
  {x : ZMod (2^n) | Odd x.val}.toFinset.card = 2^(n-1) := by
  have h_tot : Nat.totient (2^n) = 2^(n-1) := by
    have h1 : (2^n).totient = 2^(n-1) * (2 - 1) := Nat.totient_prime_pow Nat.prime_two (show 0 < n by omega)
    rw [h1]
    ring
  have h_card_units : Fintype.card (ZMod (2^n))ˣ = Nat.totient (2^n) := ZMod.card_units_eq_totient (2^n)
  let f : {x : ZMod (2^n) // IsUnit x} ≃ (ZMod (2^n))ˣ :=
    Equiv.ofBijective (fun ⟨x, hx⟩ ↦ hx.unit) (by
      constructor
      · intro ⟨a, ha⟩ ⟨b, hb⟩ hab
        ext
        exact congr_arg Units.val hab
      · intro u
        use ⟨(u : ZMod (2^n)), u.isUnit⟩
        ext
        rfl
    )
  have h_eq_finset : {x : ZMod (2^n) | Odd x.val}.toFinset = {x : ZMod (2^n) | IsUnit x}.toFinset := by
    ext x
    rw [Set.mem_toFinset, Set.mem_toFinset]
    exact odd_iff_isUnit hn x
  have h_card_sub : {x : ZMod (2^n) | IsUnit x}.toFinset.card = Fintype.card {x : ZMod (2^n) // IsUnit x} := by
    exact Set.toFinset_card {x : ZMod (2^n) | IsUnit x}
  have h_card_equiv : Fintype.card {x : ZMod (2^n) // IsUnit x} = Fintype.card (ZMod (2^n))ˣ := Fintype.card_congr f
  calc {x : ZMod (2^n) | Odd x.val}.toFinset.card = {x : ZMod (2^n) | IsUnit x}.toFinset.card := by rw [h_eq_finset]
    _ = Fintype.card {x : ZMod (2^n) // IsUnit x} := h_card_sub
    _ = Fintype.card (ZMod (2^n))ˣ := h_card_equiv
    _ = Nat.totient (2^n) := h_card_units
    _ = 2^(n-1) := h_tot

lemma orbit_weight_magnitude_sq (n : ℕ) (hn : n ≥ 3)
    (χ : AddChar (ZMod (2^n)) ℂ)
    (hχ : IsPrimitiveRoot (χ 1) (⟨2^n, by positivity⟩ : ℕ+))
    (C : Finset (ZMod (2^n)))
    (hC_orbit : ∀ k ∈ C, (3 : ZMod (2^n)) * k ∈ C)
    (hC_size : C.card = 2^(n-2))
    (hC_odd : ∀ k ∈ C, (k.val % 2 = 1)) :
    Complex.normSq (∏ k ∈ C, (1 + χ (-k))) = 2 := by
  let ζ := χ 1
  have hn_ge_2 : 2 ≤ n := by omega
  let C_2 := C.image (fun x ↦ -x)

  have h_W1 : W_1 ζ C = ∏ k ∈ C, (1 + χ (-k)) := by
    dsimp [W_1]
    apply prod_congr rfl
    intro k _
    congr 2
    exact char_val.symm

  have h_W2 : W_2 ζ C_2 = star (W_1 ζ C) := by
    dsimp [W_1, W_2]
    rw [map_prod]
    have h_inj : Set.InjOn (fun x : ZMod (2^n) ↦ -x) C := by
      intro a _ b _ hab
      exact neg_inj.mp hab
    rw [prod_image h_inj]
    apply prod_congr rfl
    intro x _
    have h_neg_val : (-(fun x : ZMod (2^n) ↦ -x) x).val = x.val := by
      dsimp
      rw [neg_neg]
    rw [h_neg_val]
    have h_star_rhs : (starRingEnd ℂ) (1 + ζ ^ (-x).val) = 1 + star (ζ ^ (-x).val) := by
      rw [map_add, RingHom.map_one (starRingEnd ℂ)]
      rfl
    rw [h_star_rhs]
    congr 1
    have hx_char : ζ ^ (-x).val = χ (-x) := char_val.symm
    rw [hx_char]
    have h_star : star (χ (-x)) = χ x := by
      rw [star_char, neg_neg]
    rw [h_star]
    have h_x_char : χ x = ζ ^ x.val := char_val
    rw [h_x_char]
  
  have h_disjoint : Disjoint C C_2 := by
    by_contra h_not_disjoint
    rw [Finset.not_disjoint_iff] at h_not_disjoint
    rcases h_not_disjoint with ⟨x, hx_C, hx_neg_C⟩
    rw [Finset.mem_image] at hx_neg_C
    rcases hx_neg_C with ⟨y, hy_C, hy_eq⟩
    have hy_eq_neg : y = -x := by
      calc y = -(-y) := by rw [neg_neg]
        _ = -x := by rw [hy_eq]
    have h_x_unit : IsUnit x := odd_is_unit (hC_odd x hx_C)
    let u_3 : (ZMod (2^n))ˣ := ZMod.unitOfCoprime 3 (Nat.Coprime.pow_right n (by decide))

    let S := (Finset.range (2^(n-2))).image (fun m ↦ (3 : ZMod (2^n))^m * x)
    have hS_sub_all : ∀ m, (3 : ZMod (2^n))^m * x ∈ C := by
      intro m
      induction m with
      | zero => 
        simp only [pow_zero, one_mul]
        exact hx_C
      | succ m ih =>
        rw [pow_succ']
        have h4 : (3 : ZMod (2^n)) * 3^m * x = (3 : ZMod (2^n)) * (3^m * x) := by ring
        rw [h4]
        exact hC_orbit (3^m * x) ih
    have hS_sub : S ⊆ C := by
      intro z hz_in
      rw [Finset.mem_image] at hz_in
      rcases hz_in with ⟨m, _, hm_eq⟩
      rw [← hm_eq]
      exact hS_sub_all m
    have hS_card : S.card = 2^(n-2) := by
      have h_card_range : (Finset.range (2^(n-2))).card = 2^(n-2) := Finset.card_range _
      rw [← h_card_range]
      apply Finset.card_image_of_injOn
      intro a ha b hb hab
      have ha_lt : a < 2^(n-2) := Finset.mem_range.mp (Finset.mem_coe.mp ha)
      have hb_lt : b < 2^(n-2) := Finset.mem_range.mp (Finset.mem_coe.mp hb)
      have h_cancel : (3 : ZMod (2^n))^a = (3 : ZMod (2^n))^b := by
        exact IsUnit.mul_right_cancel h_x_unit hab
      have h_unit_pow : (u_3 : ZMod (2^n))^a = (u_3 : ZMod (2^n))^b := by
        push_cast
        exact h_cancel
      have h_unit_eq : u_3^a = u_3^b := by
        ext
        exact h_unit_pow
      have h_mod : a ≡ b [MOD orderOf u_3] := pow_eq_pow_iff_modEq.mp h_unit_eq
      have h_ord : orderOf u_3 = 2^(n-2) := order_three_mod_pow_two n hn
      rw [h_ord] at h_mod
      exact Nat.ModEq.eq_of_lt_of_lt h_mod ha_lt hb_lt
    have hS_eq_C : S = C := by
      apply Finset.eq_of_subset_of_card_le hS_sub
      rw [hS_card, hC_size]
    have hy_S : y ∈ S := by
      rw [hS_eq_C]
      exact hy_C
    rw [hy_eq_neg] at hy_S
    rw [Finset.mem_image] at hy_S
    rcases hy_S with ⟨m, _, hm_eq⟩
    have h_m_cancel : -x = (3 : ZMod (2^n))^m * x := hm_eq.symm
    have h_neg_one : (-1 : ZMod (2^n)) * x = (3 : ZMod (2^n))^m * x := by
      calc (-1 : ZMod (2^n)) * x = - (1 * x) := by ring
        _ = -x := by rw [one_mul]
        _ = (3 : ZMod (2^n))^m * x := h_m_cancel
    have h_neg_eq : (-1 : ZMod (2^n)) = (3 : ZMod (2^n))^m := by
      exact IsUnit.mul_right_cancel h_x_unit h_neg_one
    let f : ZMod (2^n) →+* ZMod 8 := ZMod.castHom (pow_dvd_pow 2 (show 3 ≤ n by omega)) (ZMod 8)
    have h_f : f (-1) = f ((3 : ZMod (2^n))^m) := by
      rw [h_neg_eq]
    have h_f_neg : f (-1) = -1 := by
      rw [RingHom.map_neg, RingHom.map_one]
    have h_f_3 : f 3 = 3 := by
      have h : (3 : ZMod (2^n)) = 1 + 1 + 1 := by ring
      have h8 : (3 : ZMod 8) = 1 + 1 + 1 := by ring
      rw [h, RingHom.map_add, RingHom.map_add, RingHom.map_one, ← h8]
    have h_f_pow : f ((3 : ZMod (2^n))^m) = (3 : ZMod 8)^m := by
      rw [RingHom.map_pow, h_f_3]
    rw [h_f_neg, h_f_pow] at h_f
    have h_3_pow_8 := three_pow_mod_eight m
    rcases h_3_pow_8 with h1 | h3
    · rw [h1] at h_f
      revert h_f
      decide
    · rw [h3] at h_f
      revert h_f
      decide
  
  have h_union : C ∪ C_2 = {x : ZMod (2^n) | Odd x.val}.toFinset := by
    have h_sub : C ∪ C_2 ⊆ {x : ZMod (2^n) | Odd x.val}.toFinset := by
      intro x hx
      rw [Finset.mem_union] at hx
      rcases hx with hx_C | hx_C2
      · rw [Set.mem_toFinset, Set.mem_setOf_eq]
        exact Nat.odd_iff.mpr (hC_odd x hx_C)
      · rw [Finset.mem_image] at hx_C2
        rcases hx_C2 with ⟨y, hy_C, hy_eq⟩
        have hy_odd : y.val % 2 = 1 := hC_odd y hy_C
        have hy_unit : IsUnit y := odd_is_unit hy_odd
        have h_neg_y : IsUnit (-y) := by
          have h_neg : -y = (-1 : ZMod (2^n)) * y := by ring
          rw [h_neg]
          exact IsUnit.mul isUnit_one.neg hy_unit
        rw [← hy_eq]
        rw [Set.mem_toFinset, Set.mem_setOf_eq]
        exact (odd_iff_isUnit (show n ≥ 1 by omega) (-y)).mpr h_neg_y
    have h_card_C2 : C_2.card = 2^(n-2) := by
      have hc : C.card = 2^(n-2) := hC_size
      rw [← hc]
      apply Finset.card_image_of_injOn
      intro a _ b _ hab
      exact neg_inj.mp hab
    have h_card_union : (C ∪ C_2).card = 2^(n-1) := by
      rw [Finset.card_union_of_disjoint h_disjoint, hC_size, h_card_C2]
      have h_pow_split : 2^(n-1) = 2^(n-2) + 2^(n-2) := by
        have hn_split : 2^(n-1) = 2^(1 + (n - 2)) := by congr 1; omega
        calc 2^(n-1) = 2^(1 + (n - 2)) := by rw [hn_split]
          _ = 2^1 * 2^(n-2) := by rw [pow_add]
          _ = 2 * 2^(n-2) := by ring
          _ = 2^(n-2) + 2^(n-2) := by ring
      rw [← h_pow_split]
    have h_card_odd : {x : ZMod (2^n) | Odd x.val}.toFinset.card = 2^(n-1) := odd_card n (show n ≥ 1 by omega)
    apply Finset.eq_of_subset_of_card_le h_sub
    rw [h_card_union, h_card_odd]
  
  have h_prod : W_1 ζ C * W_2 ζ C_2 = 2 := W_1_mul_W_2_eq_two ζ hχ hn_ge_2 C C_2 h_disjoint h_union rfl

  have h_normSq : (Complex.normSq (W_1 ζ C) : ℂ) = 2 := by
    rw [normSq_eq_mul_star, ← h_W2]
    exact h_prod
  
  have h_eq : Complex.normSq (W_1 ζ C) = 2 := by
    exact_mod_cast h_normSq

  rw [← h_W1]
  exact h_eq




-- ============================================================================
-- 5. SPECTRAL CIRCLE THEOREM (combining all ingredients)
-- ============================================================================

/-- All eigenvalues of the twisted block S_n have magnitude exactly 2^{2^{-(n-1)}}.

    Proof sketch:
    1. S_n restricted to odd characters is monomial (collatzDirMatrix_char_action)
    2. The ×3 orbits form 2 cycles of length 2^{n-2} (order_three_mod_pow_two)
    3. Each orbit weight has |W| = √2 (orbit_weight_magnitude_sq)
    4. Cyclic monomial eigenvalues have magnitude |W|^{1/M} = (√2)^{2^{-(n-2)}} = 2^{2^{-(n-1)}}
-/
theorem spectral_circle (n : ℕ) (hn : n ≥ 3)
    (μ : ℂ) (hμ : μ ∈ spectrum ℂ (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) :
    Complex.abs μ = (2 : ℝ) ^ ((1 : ℝ) / (2^(n-1) : ℝ)) := by
  have h_eig : Module.End.HasEigenvalue (Matrix.toLin' (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) μ := by
    rw [Module.End.hasEigenvalue_iff_mem_spectrum]
    have h_eq : spectrum ℂ (Matrix.toLin' (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ))) = spectrum ℂ (Matrix.map (twistedDirMatrix (show n ≥ 2 by omega)) (algebraMap ℚ ℂ)) := by
      exact AlgEquiv.spectrum_eq Matrix.toLinAlgEquiv' _
    rw [h_eq]
    exact hμ
  exact twisted_eigenvalue_magnitude n hn μ h_eig
