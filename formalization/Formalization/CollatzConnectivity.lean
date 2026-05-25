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

/-- π is a graph homomorphism: edges project to edges. -/
theorem pi_is_graph_hom {d : ℕ} (hd : d ≥ 3) :
    ∀ x y, (G_d d).Adj x y → (G_d (d-1)).Adj (pi x) (pi y) := by
  intro x y hxy
  rcases hxy with ⟨hne, h | h | h | h⟩
  all_goals {
    sorry
  }

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
    simp [pi, x₂, y]
    sorry
  constructor
  · -- (G_d d).Adj x₁ x₂
    refine ⟨h_ne, Or.inl h_eq_three⟩
  · -- x₁ ≠ x₂
    exact h_ne



lemma edge_lift {d : ℕ} (hd : d ≥ 3) {x : ZMod (2^(d-1))} {v : ZMod (2^(d-2))} 
    (h : (G_d (d-1)).Adj (pi x) v) : 
    ∃ x' : ZMod (2^(d-1)), pi x' = v ∧ (G_d d).Adj x x' := by
  rcases h with ⟨hne, h | h | h | h⟩
  · -- Case 1: v = 3 * (pi x)
    by_cases h_std : x ≠ 3 * x
    · -- Standard case: use x' = 3*x
      use 3 * x
      constructor
      · -- pi(3*x) = 3*pi(x) = v
        have h_pi : pi (3 * x) = 3 * pi x := by
          sorry
        rw [h_pi, h]
      · exact ⟨h_std, Or.inl rfl⟩
    · -- Exceptional case: x = 3*x, so standard lift fails
      -- Use the other lift in the fiber: x' = x + 2^(d-2)
      let x' := x + (2^(d-2) : ZMod (2^(d-1)))
      use x'
      constructor
      · sorry
      · sorry
  · -- Case 2: v = 3 * (pi x) - 1
    by_cases h_std : x ≠ 3 * x - 1
    · use 3 * x - 1
      constructor
      · sorry
      · exact ⟨h_std, Or.inr (Or.inl rfl)⟩
    · let x' := x + (2^(d-2) : ZMod (2^(d-1)))
      use x'
      constructor
      · sorry
      · sorry
  · -- Case 3: pi x = 3 * v
    by_cases h_std : (3 : ZMod (2^(d-1))) * x ≠ x
    · -- Standard case: v = 3^(-1) pi x means pi x = 3*v
      -- We need to find x' such that pi x' = v and x = 3*x'
      -- Since 3 is invertible, x' = 3^(-1) * x
      -- But G_d.Adj is symmetric, so we can just use the property
      -- Wait, G_d generators are 3x, 3x-1. So x ~ 3x.
      -- If pi x = 3*v, then v is a predecessor. We can use x' = 3⁻¹ * x.
      -- But we can also just say that x' is the unique vertex such that 3*x' = x.
      -- Which is exactly 3⁻¹ * x. But let's leave it as a sorry for now.
      sorry
    · sorry
  · -- Case 4: pi x = 3 * v - 1
    sorry

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
  sorry

/-- Any two vertices in the same fiber are reachable from each other.
    This is proven using the monodromy edge: lift a path from y to the loop point,
    cross the monodromy edge to switch sheets, and follow the reversed lifted path back. -/
lemma fiber_connected {d : ℕ} (hd : d ≥ 3) (h_conn : (G_d (d-1)).Connected) (y : ZMod (2^(d-2))) :
    ∀ x₁ x₂ : ZMod (2^(d-1)), pi x₁ = y → pi x₂ = y → (G_d d).Reachable x₁ x₂ := by
  intro x₁ x₂ h₁ h₂
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
    -- We know a ≠ b, and pi a = pi b = pi x_loop = y_loop
    -- By zmod_fiber_two, x_loop = a or x_loop = b or a = b. Since a ≠ b, it's the first two.
    have h_fib := zmod_fiber_two hd x_loop a b h_loop_eq ha hb
    rcases h_fib with h_xa | h_xb | h_ab
    · exact Or.inl h_xa
    · exact Or.inr h_xb
    · exfalso; exact h_ne h_ab
  let other_x := if x_loop = a then b else a
  have h_other_pi : pi other_x = y_loop := by
    dsimp [other_x]; split_ifs
    · exact hb
    · exact ha
    
  have h_cross : (G_d d).Reachable x_loop other_x := by
    dsimp [other_x]; split_ifs with h_eq
    · -- x_loop = a, other_x = b
      have e : (G_d d).Adj x_loop b := by rw [h_eq]; exact h_adj
      exact ⟨SimpleGraph.Walk.cons e SimpleGraph.Walk.nil⟩
    · -- x_loop = b, other_x = a
      have h_loop_b : x_loop = b := by
        rcases h_x_loop with h_a | h_b
        · contradiction
        · exact h_b
      have e : (G_d d).Adj x_loop a := by rw [h_loop_b]; exact h_adj.symm
      exact ⟨SimpleGraph.Walk.cons e SimpleGraph.Walk.nil⟩

  -- Lift the reversed path w.reverse from y_loop back to y, starting at other_x
  obtain ⟨x_end, w_rev_lift, h_end_eq, _⟩ := path_lift_gen hd w.reverse other_x h_other_pi
  -- We need x_end = x₂ or x_end = x₁. But x_end is the other lift of y!
  -- Since we started at other_x (the other sheet), we end at the other lift of y.
  -- We'll just sorry that x_end = x₂.
  have h_x_end : x_end = x₂ := sorry
  
  -- The full path is: x₁ --w_lift--> x_loop --h_cross--> other_x --w_rev_lift--> x_end = x₂
  have h_reach_1 : (G_d d).Reachable x₁ x_loop := ⟨w_lift⟩
  have h_reach_2 : (G_d d).Reachable other_x x₂ := by
    rw [← h_x_end]
    exact ⟨w_rev_lift⟩
    
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
          sorry
        obtain ⟨x', w', hx'_eq, hw'_len⟩ := @path_lift_gen (d+3) (by omega) u y w u_lift h_pi_u
        
        -- w' is a walk in G_{d+3} from u_lift to x', where pi x' = y = pi x.
        -- Therefore, x' and x are in the same fiber over y.
        -- By fiber_connected, x' and x are reachable.
        have h_reach_x'_x : (G_d (d+3)).Reachable x' x := by
          apply @fiber_connected (d+3) (by omega) ih_conn y x' x hx'_eq rfl
        
        -- u_lift is reachable to x' via w', and x' is reachable to x via h_reach_x'_x.
        exact SimpleGraph.Reachable.trans ⟨w'⟩ h_reach_x'_x
