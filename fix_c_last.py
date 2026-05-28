
import re

with open("formalization/Formalization/CyclicWeightCharpoly.lean", "r", encoding="utf-8") as f:
    content = f.read()

# Replace c2
c2_old = """        have c2 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          change (0 : ℕ) = (n + 1) % (n + 2) at h'
          have h_lt : n + 1 < n + 2 := by omega
          rw [Nat.mod_eq_of_lt h_lt] at h'
          omega"""

c2_new = """        have c2 : (0 : ZMod (n + 2)) = ((n + 1 : ℕ) : ZMod (n + 2)) ↔ False := by
          apply iff_false_intro; intro h
          have h' := congrArg ZMod.val h
          change (0 : ℕ) = (n + 1) % (n + 2) at h'
          omega"""

# Replace c3
c3_old = """        have c3 : (0 : ZMod (n + 2)) = (n + 1 : ZMod (n + 2)) + 1 ↔ True := by
          apply iff_true_intro
          have h_eq : n + 1 + 1 = n + 2 := by omega
          have h_val : ((n + 1 : ZMod (n + 2)) + 1).val = (n + 1 + 1) % (n + 2) := Eq.refl _
          apply ZMod.val_injective
          rw [h_val, h_eq, Nat.mod_self]
          rfl"""

c3_new = """        have c3 : (0 : ZMod (n + 2)) = ((n + 1 : ℕ) : ZMod (n + 2)) + 1 ↔ True := by
          apply iff_true_intro
          apply ZMod.val_injective
          change (0 : ℕ) = (n + 1 + 1) % (n + 2)
          omega"""

# Replace c_last
c_last_old = """        have c_last : ((Fin.last (n+1) : Fin (n+2)) : ZMod (n+2)) = n + 1 := rfl"""

c_last_new = """        have c_last : ((Fin.last (n+1) : Fin (n+2)) : ZMod (n+2)) = ((n + 1 : ℕ) : ZMod (n+2)) := by
          apply Fin.ext
          change n + 1 = (n + 1) % (n + 2)
          exact (Nat.mod_eq_of_lt (by omega)).symm"""

content = content.replace(c2_old, c2_new)
content = content.replace(c3_old, c3_new)
content = content.replace(c_last_old, c_last_new)

# Also fix the line 238 "change 0 = " if it has not been replaced
content = content.replace("change 0 = (n + 1) % (n + 2) at h'", "change (0 : ℕ) = (n + 1) % (n + 2) at h'")

with open("formalization/Formalization/CyclicWeightCharpoly.lean", "w", encoding="utf-8") as f:
    f.write(content)

