import os
import subprocess

file_path = "Formalization/TestZMod.lean"

code_template = """
import Mathlib

lemma fin_succ_eq_succ_add_one (n : ℕ) (i j : Fin (n + 1)) :
    (Fin.succ i : Fin (n + 2)) = Fin.succ j + 1 ↔ (i : ℕ) = (j : ℕ) + 1 := by
  constructor
  · intro h
    have h1 : (Fin.succ i : ℕ) = ((Fin.succ j + 1 : Fin (n + 2)) : ℕ) := congrArg Fin.val h
    have h2 : (Fin.succ j + 1 : Fin (n + 2)) = Fin.succ (Fin.succ j) := rfl
    sorry
  · intro h
    ext
    have h2 : (Fin.succ j + 1 : Fin (n + 2)) = Fin.succ (Fin.succ j) := rfl
    sorry

lemma fin_succ_eq_castSucc_add_one (n : ℕ) (i j : Fin (n + 1)) :
    (Fin.succ i : Fin (n + 2)) = Fin.castSucc j + 1 ↔ (i : ℕ) = (j : ℕ) := by
  sorry
"""

with open(file_path, "w", encoding="utf-8") as f:
    f.write(code_template)

res = subprocess.run(["lake", "build", "Formalization.TestZMod"], capture_output=True, text=True)
print(res.stdout)
print(res.stderr)
