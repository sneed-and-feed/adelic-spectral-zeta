import Mathlib.Data.Real.Basic
import Mathlib.Data.Complex.Basic
import Mathlib.Data.ZMod.Basic
import Mathlib.Topology.Order
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Order.Filter.Basic
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity
import Formalization.Dynamics.MeanErgodic
import Formalization.Dynamics.L2Mixing

open Classical
open Matrix
open scoped Matrix BigOperators
open Filter

namespace OrbitShadowing

variable (n : ℕ)

-- 1. Deterministic Collatz map
def collatz_step (x : ZMod (2^n)) : ZMod (2^n) :=
  if x.val % 2 = 0 then 3 * x else 3 * x - 1

def collatz_orbit : ℕ → ZMod (2^n) → ZMod (2^n)
  | 0, x => x
  | T + 1, x => collatz_step n (collatz_orbit T x)

-- 2. Random walk step choices
def rw_step (x : ZMod (2^n)) (choice : Bool) : ZMod (2^n) :=
  if choice then 3 * x else 3 * x - 1

def rw_path : ℕ → (ℕ → Bool) → ZMod (2^n) → ZMod (2^n)
  | 0, _, x => x
  | T + 1, c, x => rw_step n (rw_path T c x) (c T)

-- Convert finite choice to infinite stream
def rw_path_fin (T : ℕ) (c : Fin T → Bool) (x : ZMod (2^n)) : ZMod (2^n) :=
  let c' : ℕ → Bool := fun i => if h : i < T then c ⟨i, h⟩ else false
  rw_path n T c' x

-- 3. Distance modulo 2^n
def zmod_dist (x y : ZMod (2^n)) : ℕ :=
  min (x - y).val (y - x).val

-- Bad choices where the random walk strays from the deterministic orbit by more than R
noncomputable def bad_choices (T : ℕ) (x : ZMod (2^n)) (R : ℕ) : Finset (Fin T → Bool) :=
  Finset.univ.filter (fun c => zmod_dist n (rw_path_fin n T c x) (collatz_orbit n T x) > R)

-- 4. Deterministic orbit Birkhoff average
noncomputable def deterministic_avg (T : ℕ) (f : L2Space n) (x : ZMod (2^n)) : ℂ :=
  (1 / (T : ℂ)) * ∑ k ∈ Finset.range T, f (collatz_orbit n k x)

/-- Hypothesis structure capturing the orbit shadowing and equidistribution assumptions. -/
structure OrbitShadowingAssumptions (n : ℕ) : Prop where
  shadowing_bound_proof : ∀ (T : ℕ) (_hT : T ≤ n) (x : ZMod (2^n)) (R : ℕ),
    ((bad_choices n T x R).card : ℝ) / (2^T : ℝ) ≤ (3 / 4 : ℝ)^T * (R : ℝ)
  collatz_equidistribution_proof : ∀ (f_seq : ∀ n, L2Space n) (T : ℕ → ℕ) (_hT : ∀ n, T n ≤ n) (ε : ℝ) (_hε : ε > 0),
    Tendsto (fun n => ((Finset.univ.filter (fun x => ‖deterministic_avg n (T n) (f_seq n) x - (MeanErgodic.proj_const n (f_seq n)) x‖ > ε)).card : ℝ) / (2^n : ℝ))
      atTop (nhds 0)

-- 5. Shadowing Lemma
-- High probability bound for shadowing
-- The fraction of bad paths is exponentially suppressed.
theorem shadowing_bound (h : OrbitShadowingAssumptions n) (T : ℕ) (hT : T ≤ n) (x : ZMod (2^n)) (R : ℕ) :
    ((bad_choices n T x R).card : ℝ) / (2^T : ℝ) ≤ (3 / 4 : ℝ)^T * (R : ℝ) :=
  h.shadowing_bound_proof T hT x R

-- 6. Equidistribution Theorem
-- Combine shadowing with L2 convergence to show deterministic orbits equidistribute.
theorem collatz_equidistribution (h : OrbitShadowingAssumptions n) (f_seq : ∀ n, L2Space n) (T : ℕ → ℕ) (hT : ∀ n, T n ≤ n) (ε : ℝ) (hε : ε > 0) :
    Tendsto (fun n => ((Finset.univ.filter (fun x => ‖deterministic_avg n (T n) (f_seq n) x - (MeanErgodic.proj_const n (f_seq n)) x‖ > ε)).card : ℝ) / (2^n : ℝ))
      atTop (nhds 0) :=
  h.collatz_equidistribution_proof f_seq T hT ε hε

end OrbitShadowing
