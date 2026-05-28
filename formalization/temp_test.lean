import Mathlib
import Mathlib.LinearAlgebra.Matrix.Charpoly.Basic

open Matrix Polynomial Finset
open scoped Polynomial

variable {R : Type*} [CommRing R] {L : ℕ} [NeZero L] (W : ZMod L → R)

theorem test_succ (n : ℕ) (W : ZMod (n + 2) → R) (b : Fin (n + 2)) (hb0 : b ≠ 0) (hbn : b ≠ Fin.last (n + 1)) : True := by
  have c1 : (0 : ZMod (n+2)) = b ↔ False := by
    apply iff_false_intro; intro h
    have h' : (0 : Fin (n+2)) = b := h
    exact hb0 h'.symm
  have c2 : (0 : ZMod (n+2)) = (b + 1 : Fin (n+2)) ↔ False := by
    apply iff_false_intro
    intro h
    have h1 : (b : ℕ) + 1 < n + 2 := by
      have h_lt : (b : ℕ) < n + 2 := b.is_lt
      have h_neq : (b : ℕ) ≠ n + 1 := fun eq => hbn (Fin.ext eq)
      omega
    have h2 : (0 : Fin (n+2)) = b + 1 := h
    have h3 := congrArg Fin.val h2
    change 0 = ((b : ℕ) + 1) % (n + 2) at h3
    rw [Nat.mod_eq_of_lt h1] at h3
    have : (b : ℕ) = 0 := by omega
    apply hb0
    exact Fin.ext this
  exact trivial
