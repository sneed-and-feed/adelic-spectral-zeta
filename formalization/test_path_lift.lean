import Mathlib
import Mathlib.Combinatorics.SimpleGraph.Basic
import Mathlib.Combinatorics.SimpleGraph.Connectivity

def G_d (d : ℕ) : SimpleGraph (ZMod (2^(d-1))) := sorry

def pi {d : ℕ} (x : ZMod (2^(d-1))) : ZMod (2^(d-2)) := sorry

lemma path_lift_unique {d : ℕ} (hd : d ≥ 3) {a b : ZMod (2^(d-2))} (w : (G_d (d-1)).Walk a b) :
    ∀ {u x_u v x_v : ZMod (2^(d-1))} (hu : pi u = a) (hv : pi v = a)
      (wu : (G_d d).Walk u x_u) (wv : (G_d d).Walk v x_v),
      pi x_u = b → pi x_v = b → wu.length = w.length → wv.length = w.length →
      u ≠ v → x_u ≠ x_v := by
  sorry

lemma test {d : ℕ} (hd : d ≥ 3) (y y_loop : ZMod (2^(d-2)))
  (x₁ other_x x_loop x_end : ZMod (2^(d-1)))
  (w : (G_d (d-1)).Walk y y_loop)
  (w_lift : (G_d d).Walk x₁ x_loop)
  (w_rev_lift : (G_d d).Walk other_x x_end)
  (hw_len : w_lift.length = w.length)
  (hw_rev_len : w_rev_lift.length = w.reverse.length)
  (h_other_pi : pi other_x = y_loop)
  (h_loop_eq : pi x_loop = y_loop)
  (h_end_eq : pi x_end = y)
  (h₁ : pi x₁ = y)
  (h_other_neq : other_x ≠ x_loop) :
  x_end ≠ x₁ := by
  apply path_lift_unique hd w.reverse h_other_pi h_loop_eq w_rev_lift w_lift.reverse h_end_eq h₁
  · exact hw_rev_len
  · simp [hw_len]
  · exact h_other_neq
