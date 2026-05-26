import Mathlib.Analysis.InnerProductSpace.PiL2
open Classical

lemma evec_orth (n : Type*) [Fintype n] [DecidableEq n]
    (evec : OrthonormalBasis n ℝ (EuclideanSpace ℝ n))
    (i_max j : n) (h_neq : j ≠ i_max)
    (v_B w_i w_j : n → ℝ)
    (ci cj : ℝ) (hw_j_neq : w_j ≠ 0)
    (hi : w_i = ci • v_B) (hj : w_j = cj • v_B) 
    (h_wi : w_i = evec i_max) (h_wj : w_j = evec j) :
    False := by
  have hcj_neq : cj ≠ 0 := by
    intro h
    rw [h, zero_smul] at hj
    exact hw_j_neq hj
  have h_eq : (evec i_max : EuclideanSpace ℝ n) = (ci / cj) • (evec j : EuclideanSpace ℝ n) := by
    ext k
    have hik := congr_fun hi k
    have hjk := congr_fun hj k
    have h_wi_k : (evec i_max : EuclideanSpace ℝ n) k = w_i k := by rw [h_wi]
    have h_wj_k : (evec j : EuclideanSpace ℝ n) k = w_j k := by rw [h_wj]
    rw [h_wi_k, h_wj_k]
    simp only [Pi.smul_apply, smul_eq_mul] at hik hjk ⊢
    calc
      w_i k = ci * v_B k := hik
      _ = ci * (w_j k / cj) := by rw [hjk, mul_div_cancel_right₀ (v_B k) hcj_neq]
      _ = (ci / cj) * w_j k := by ring
  let b := evec.toBasis
  have h_eq_b : b i_max = (ci / cj) • b j := h_eq
  have h1 : b.repr (b i_max) i_max = 1 := by
    rw [Basis.repr_self]
    exact Finsupp.single_eq_same
  have h2 : b.repr (b j) i_max = 0 := by
    rw [Basis.repr_self]
    exact Finsupp.single_eq_of_ne (Ne.symm h_neq)
  have h3 : b.repr ((ci / cj) • b j) i_max = 0 := by
    rw [map_smul, Finsupp.smul_apply, smul_eq_mul, h2, mul_zero]
  rw [h_eq_b] at h1
  rw [h3] at h1
  norm_num at h1
