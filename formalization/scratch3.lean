import Mathlib

lemma odd_is_unit {n : ℕ} {x : ZMod (2^n)} (hx : x.val % 2 = 1) : IsUnit x := by
  have hc : Nat.Coprime x.val 2 := by
    rw [Nat.coprime_two_right, Nat.odd_iff]
    exact hx
  have hc_pow : Nat.Coprime x.val (2^n) := Nat.Coprime.pow_right n hc
  have h_is_unit_cast : IsUnit (x.val : ZMod (2^n)) := (ZMod.isUnit_iff_coprime x.val (2^n)).mpr hc_pow
  have : (x.val : ZMod (2^n)) = x := ZMod.natCast_zmod_val x
  rwa [← this]

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
    exact Nat.odd_iff.mpr (Nat.coprime_two_right.mp h_coprime2)

lemma odd_card (n : ℕ) (hn : n ≥ 1) : 
  {x : ZMod (2^n) | Odd x.val}.toFinset.card = 2^(n-1) := by
  have h_tot : Nat.totient (2^n) = 2^(n-1) := by
    have h1 : (2^n).totient = 2^(n-1) * (2 - 1) := Nat.totient_prime_pow Nat.prime_two (show 0 < n by omega)
    calc (2^n).totient = 2^(n-1) * 1 := by rw [h1]
      _ = 2^(n-1) := by ring
  
  have h_card_units : Fintype.card (ZMod (2^n))ˣ = Nat.totient (2^n) := ZMod.card_units_eq_totient (2^n)
  
  let f : {x : ZMod (2^n) // IsUnit x} ≃ (ZMod (2^n))ˣ :=
    Equiv.ofBijective (fun ⟨x, hx⟩ ↦ hx.unit) (by
      constructor
      · intro ⟨a, ha⟩ ⟨b, hb⟩ hab
        ext
        have h_val : (ha.unit : ZMod (2^n)) = (hb.unit : ZMod (2^n)) := by
          exact congr_arg Units.val hab
        exact h_val
      · intro u
        use ⟨(u : ZMod (2^n)), u.isUnit⟩
        ext
        rfl
    )
  
  have h_eq_set : {x : ZMod (2^n) | Odd x.val} = {x : ZMod (2^n) | IsUnit x} := by
    ext x
    exact odd_iff_isUnit hn x
  
  have h_card_sub : {x : ZMod (2^n) | IsUnit x}.toFinset.card = Fintype.card {x : ZMod (2^n) // IsUnit x} := by
    exact Set.toFinset_card {x : ZMod (2^n) | IsUnit x}
  
  have h_card_equiv : Fintype.card {x : ZMod (2^n) // IsUnit x} = Fintype.card (ZMod (2^n))ˣ := Fintype.card_congr f
  
  rw [h_eq_set, h_card_sub, h_card_equiv, h_card_units, h_tot]
