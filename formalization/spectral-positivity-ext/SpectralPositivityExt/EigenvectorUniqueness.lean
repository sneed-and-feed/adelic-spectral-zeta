import Mathlib.Data.Matrix.Basic
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Connectivity
import Mathlib.Data.Real.Basic
import Mathlib.Algebra.Order.Group.Abs
import Mathlib.LinearAlgebra.Matrix.Spectrum
import Mathlib.Analysis.InnerProductSpace.PiL2
import SpectralPositivityExt.WalkPropagation

open Matrix
open Classical

namespace Matrix

variable {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]

lemma eigenvector_zero_of_walk {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    (u : n → ℝ) (hu_nn : ∀ i, 0 ≤ u i)
    (lam : ℝ) (hu_eig : A.mulVec u = lam • u)
    {i j : n}
    (w : SimpleGraph.Walk (supportGraph A hA_symm) i j) :
    u i = 0 → u j = 0 := by
  induction w with
  | nil => intro h; exact h
  | cons h rest ih =>
    clear i j
    rename_i u_start u_next u_end
    intro hui
    have h_adj_pos : 0 < A u_start u_next := h.1
    have h_eq : (A.mulVec u) u_start = lam * u u_start := by
      have := congr_fun hu_eig u_start
      rw [Pi.smul_apply, smul_eq_mul] at this
      exact this
    dsimp [mulVec, dotProduct] at h_eq
    rw [hui, mul_zero] at h_eq
    have h_sum_nn : ∀ l ∈ Finset.univ, 0 ≤ A u_start l * u l := fun l _ => mul_nonneg (hA_nn u_start l) (hu_nn l)
    have h_term_zero : A u_start u_next * u u_next = 0 := by
      have h_le : A u_start u_next * u u_next ≤ ∑ l, A u_start l * u l := Finset.single_le_sum h_sum_nn (Finset.mem_univ u_next)
      linarith [h_sum_nn u_next (Finset.mem_univ u_next)]
    have hux_zero : u u_next = 0 := by
      cases mul_eq_zero.mp h_term_zero with
      | inl h1 => exact False.elim (ne_of_gt h_adj_pos h1)
      | inr h2 => exact h2
    exact ih hux_zero

lemma connected_eigenvector_unique {A : Matrix n n ℝ}
    (hA_symm : ∀ i j, A i j = A j i) (hA_nn : ∀ i j, 0 ≤ A i j)
    (hA_conn : SimpleGraph.Connected (supportGraph A hA_symm))
    (μ : ℝ) (v w : n → ℝ) (hv_pos : ∀ i, 0 < v i)
    (hv_eig : A.mulVec v = μ • v) (hw_eig : A.mulVec w = μ • w) :
    ∃ c : ℝ, w = c • v := by
  let ratios := fun i => w i / v i
  let t := Finset.inf' Finset.univ Finset.univ_nonempty ratios
  use t
  have h_diff_nn : ∀ k, 0 ≤ (w - t • v) k := by
    intro k
    simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
    have hk : t ≤ ratios k := Finset.inf'_le ratios (Finset.mem_univ k)
    rw [sub_nonneg]
    have h_mul : t * v k ≤ (w k / v k) * v k := mul_le_mul_of_nonneg_right hk (le_of_lt (hv_pos k))
    rwa [div_mul_cancel₀ _ (ne_of_gt (hv_pos k))] at h_mul
  have h_diff_eig : A.mulVec (w - t • v) = μ • (w - t • v) := by
    rw [mulVec_sub, mulVec_smul, hw_eig, hv_eig, smul_sub, smul_comm]
  by_cases h_diff_zero : w - t • v = 0
  · exact sub_eq_zero.mp h_diff_zero
  · exfalso
    obtain ⟨i₀, _, hi₀⟩ := Finset.exists_mem_eq_inf' Finset.univ_nonempty ratios
    have h_min_achieved : (w - t • v) i₀ = 0 := by
      simp only [Pi.sub_apply, Pi.smul_apply, smul_eq_mul]
      have ht_eq : t = w i₀ / v i₀ := hi₀
      rw [ht_eq, div_mul_cancel₀ _ (ne_of_gt (hv_pos i₀)), sub_self]
    have h_all_zero : ∀ k, (w - t • v) k = 0 := by
      intro k
      have h_reach : SimpleGraph.Reachable (supportGraph A hA_symm) i₀ k := hA_conn.preconnected i₀ k
      obtain ⟨w_walk⟩ := h_reach
      exact eigenvector_zero_of_walk hA_symm hA_nn (w - t • v) h_diff_nn μ h_diff_eig w_walk h_min_achieved
    have h_diff_zero_again : w - t • v = 0 := by ext k; exact h_all_zero k
    exact h_diff_zero h_diff_zero_again

end Matrix
