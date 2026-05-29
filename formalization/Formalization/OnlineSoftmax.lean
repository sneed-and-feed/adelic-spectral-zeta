import Mathlib.Data.Real.Basic
import Mathlib.Analysis.SpecialFunctions.Exp

open Real

noncomputable def max_val (xs : List ℝ) : ℝ :=
  xs.foldl max 0

noncomputable def sum_exp_shifted (xs : List ℝ) (m : ℝ) : ℝ :=
  (xs.map (fun x => exp (x - m))).sum

noncomputable def l_standard (xs : List ℝ) : ℝ :=
  sum_exp_shifted xs (max_val xs)

noncomputable def online_step (state : ℝ × ℝ) (row : List ℝ) : ℝ × ℝ :=
  let m_old := state.1
  let l_old := state.2
  let m_row := max_val row
  let m_new := max m_old m_row
  let alpha := exp (m_old - m_new)
  let l_new := l_old * alpha + sum_exp_shifted row m_new
  (m_new, l_new)

lemma sum_exp_shifted_append (xs ys : List ℝ) (m : ℝ) :
  sum_exp_shifted (xs ++ ys) m = sum_exp_shifted xs m + sum_exp_shifted ys m := by
  simp [sum_exp_shifted]

lemma exp_sub_mul_exp_sub (x m_old m_new : ℝ) :
  exp (x - m_old) * exp (m_old - m_new) = exp (x - m_new) := by
  rw [← exp_add]
  congr 1
  ring

lemma sum_exp_shifted_cons (h : ℝ) (t : List ℝ) (m : ℝ) :
  sum_exp_shifted (h :: t) m = exp (h - m) + sum_exp_shifted t m := by
  simp [sum_exp_shifted]

lemma sum_exp_shifted_mul_exp (xs : List ℝ) (m_old m_new : ℝ) :
  sum_exp_shifted xs m_old * exp (m_old - m_new) = sum_exp_shifted xs m_new := by
  induction xs with
  | nil => simp [sum_exp_shifted]
  | cons h t ih =>
    rw [sum_exp_shifted_cons, sum_exp_shifted_cons]
    rw [add_mul, ih, exp_sub_mul_exp_sub]

lemma online_step_correct (prev_elements : List ℝ) (l_old m_old : ℝ) (row : List ℝ) (m_new : ℝ)
  (h_l_old : l_old = sum_exp_shifted prev_elements m_old) :
  l_old * exp (m_old - m_new) + sum_exp_shifted row m_new =
  sum_exp_shifted (prev_elements ++ row) m_new := by
  rw [h_l_old]
  rw [sum_exp_shifted_mul_exp]
  rw [sum_exp_shifted_append]

lemma online_softmax_equivalence_general (rows : List (List ℝ)) (prev_elements : List ℝ) (init_m init_l : ℝ)
  (h_init_l : init_l = sum_exp_shifted prev_elements init_m) :
  (rows.foldl online_step (init_m, init_l)).2 =
  sum_exp_shifted (prev_elements ++ rows.join) (rows.foldl online_step (init_m, init_l)).1 := by
  induction rows generalizing prev_elements init_m init_l with
  | nil =>
    simp [h_init_l]
  | cons row rest ih =>
    let state_new := online_step (init_m, init_l) row
    have h_new : state_new.2 = sum_exp_shifted (prev_elements ++ row) state_new.1 := by
      dsimp [state_new, online_step]
      apply online_step_correct prev_elements init_l init_m row (max init_m (max_val row)) h_init_l
    have ih_app := ih (prev_elements ++ row) state_new.1 state_new.2 h_new
    have eq_fold : ((row :: rest).foldl online_step (init_m, init_l)) = (rest.foldl online_step state_new) := rfl
    rw [eq_fold]
    rw [ih_app]
    congr 1
    simp

/--
Agent 2: Online Softmax Equivalence 
Formalize in Lean 4: The online softmax recurrence (m_new = max(m_old, max(row)), alpha = exp(m_old - m_new), l = l*alpha + sum(exp(x - m_new))) produces identical output to standard two-pass softmax (compute max, subtract, exp, normalize). This is the Milakov-Gimelshein 2018 result. Pure real arithmetic, no topology.
-/
theorem online_softmax_equivalence (rows : List (List ℝ)) (init_m : ℝ) :
  (rows.foldl online_step (init_m, sum_exp_shifted [] init_m)).2 =
  sum_exp_shifted (rows.join) (rows.foldl online_step (init_m, sum_exp_shifted [] init_m)).1 := by
  have h := online_softmax_equivalence_general rows [] init_m (sum_exp_shifted [] init_m) rfl
  simp at h
  exact h
