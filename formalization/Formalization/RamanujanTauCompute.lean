import Formalization.RamanujanTau

/-!
# Ramanujan Tau Computational Verification

This file isolates the heavy kernel `decide` computations that verify
the congruence $\tau(n) \equiv \sigma_{11}(n) \pmod{691}$ up to $n=100$.

By separating this from the core `RamanujanTau.lean`, we keep the 
main `lake build` fast while preserving the 0-sorry verification.
-/

set_option maxRecDepth 2000000
set_option maxHeartbeats 0

-- Extracted by script to evaluate pure kernel arithmetic.
-- (The generated proofs go here)
theorem ramanujan_congruence_finite_1 : ramanujan_congruence_comp 1 = true := by decide
theorem ramanujan_congruence_finite_2 : ramanujan_congruence_comp 2 = true := by decide
theorem ramanujan_congruence_finite_3 : ramanujan_congruence_comp 3 = true := by decide
theorem ramanujan_congruence_finite_4 : ramanujan_congruence_comp 4 = true := by decide
theorem ramanujan_congruence_finite_5 : ramanujan_congruence_comp 5 = true := by decide
theorem ramanujan_congruence_finite_6 : ramanujan_congruence_comp 6 = true := by decide
theorem ramanujan_congruence_finite_7 : ramanujan_congruence_comp 7 = true := by decide
theorem ramanujan_congruence_finite_8 : ramanujan_congruence_comp 8 = true := by decide
theorem ramanujan_congruence_finite_9 : ramanujan_congruence_comp 9 = true := by decide
theorem ramanujan_congruence_finite_10 : ramanujan_congruence_comp 10 = true := by decide
theorem ramanujan_congruence_finite_11 : ramanujan_congruence_comp 11 = true := by decide
theorem ramanujan_congruence_finite_12 : ramanujan_congruence_comp 12 = true := by decide
theorem ramanujan_congruence_finite_13 : ramanujan_congruence_comp 13 = true := by decide
theorem ramanujan_congruence_finite_14 : ramanujan_congruence_comp 14 = true := by decide
theorem ramanujan_congruence_finite_15 : ramanujan_congruence_comp 15 = true := by decide
theorem ramanujan_congruence_finite_16 : ramanujan_congruence_comp 16 = true := by decide
theorem ramanujan_congruence_finite_17 : ramanujan_congruence_comp 17 = true := by decide
theorem ramanujan_congruence_finite_18 : ramanujan_congruence_comp 18 = true := by decide
theorem ramanujan_congruence_finite_19 : ramanujan_congruence_comp 19 = true := by decide
theorem ramanujan_congruence_finite_20 : ramanujan_congruence_comp 20 = true := by decide
theorem ramanujan_congruence_finite_21 : ramanujan_congruence_comp 21 = true := by decide
theorem ramanujan_congruence_finite_22 : ramanujan_congruence_comp 22 = true := by decide
theorem ramanujan_congruence_finite_23 : ramanujan_congruence_comp 23 = true := by decide
theorem ramanujan_congruence_finite_24 : ramanujan_congruence_comp 24 = true := by decide
theorem ramanujan_congruence_finite_25 : ramanujan_congruence_comp 25 = true := by decide
theorem ramanujan_congruence_finite_26 : ramanujan_congruence_comp 26 = true := by decide
theorem ramanujan_congruence_finite_27 : ramanujan_congruence_comp 27 = true := by decide
theorem ramanujan_congruence_finite_28 : ramanujan_congruence_comp 28 = true := by decide
theorem ramanujan_congruence_finite_29 : ramanujan_congruence_comp 29 = true := by decide
theorem ramanujan_congruence_finite_30 : ramanujan_congruence_comp 30 = true := by decide
theorem ramanujan_congruence_finite_31 : ramanujan_congruence_comp 31 = true := by decide
theorem ramanujan_congruence_finite_32 : ramanujan_congruence_comp 32 = true := by decide
theorem ramanujan_congruence_finite_33 : ramanujan_congruence_comp 33 = true := by decide
theorem ramanujan_congruence_finite_34 : ramanujan_congruence_comp 34 = true := by decide
theorem ramanujan_congruence_finite_35 : ramanujan_congruence_comp 35 = true := by decide
theorem ramanujan_congruence_finite_36 : ramanujan_congruence_comp 36 = true := by decide
theorem ramanujan_congruence_finite_37 : ramanujan_congruence_comp 37 = true := by decide
theorem ramanujan_congruence_finite_38 : ramanujan_congruence_comp 38 = true := by decide
theorem ramanujan_congruence_finite_39 : ramanujan_congruence_comp 39 = true := by decide
theorem ramanujan_congruence_finite_40 : ramanujan_congruence_comp 40 = true := by decide
theorem ramanujan_congruence_finite_41 : ramanujan_congruence_comp 41 = true := by decide
theorem ramanujan_congruence_finite_42 : ramanujan_congruence_comp 42 = true := by decide
theorem ramanujan_congruence_finite_43 : ramanujan_congruence_comp 43 = true := by decide
theorem ramanujan_congruence_finite_44 : ramanujan_congruence_comp 44 = true := by decide
theorem ramanujan_congruence_finite_45 : ramanujan_congruence_comp 45 = true := by decide
theorem ramanujan_congruence_finite_46 : ramanujan_congruence_comp 46 = true := by decide
theorem ramanujan_congruence_finite_47 : ramanujan_congruence_comp 47 = true := by decide
theorem ramanujan_congruence_finite_48 : ramanujan_congruence_comp 48 = true := by decide
theorem ramanujan_congruence_finite_49 : ramanujan_congruence_comp 49 = true := by decide
theorem ramanujan_congruence_finite_50 : ramanujan_congruence_comp 50 = true := by decide
theorem ramanujan_congruence_finite_51 : ramanujan_congruence_comp 51 = true := by decide
theorem ramanujan_congruence_finite_52 : ramanujan_congruence_comp 52 = true := by decide
theorem ramanujan_congruence_finite_53 : ramanujan_congruence_comp 53 = true := by decide
theorem ramanujan_congruence_finite_54 : ramanujan_congruence_comp 54 = true := by decide
theorem ramanujan_congruence_finite_55 : ramanujan_congruence_comp 55 = true := by decide
theorem ramanujan_congruence_finite_56 : ramanujan_congruence_comp 56 = true := by decide
theorem ramanujan_congruence_finite_57 : ramanujan_congruence_comp 57 = true := by decide
theorem ramanujan_congruence_finite_58 : ramanujan_congruence_comp 58 = true := by decide
theorem ramanujan_congruence_finite_59 : ramanujan_congruence_comp 59 = true := by decide
theorem ramanujan_congruence_finite_60 : ramanujan_congruence_comp 60 = true := by decide
theorem ramanujan_congruence_finite_61 : ramanujan_congruence_comp 61 = true := by decide
theorem ramanujan_congruence_finite_62 : ramanujan_congruence_comp 62 = true := by decide
theorem ramanujan_congruence_finite_63 : ramanujan_congruence_comp 63 = true := by decide
theorem ramanujan_congruence_finite_64 : ramanujan_congruence_comp 64 = true := by decide
theorem ramanujan_congruence_finite_65 : ramanujan_congruence_comp 65 = true := by decide
theorem ramanujan_congruence_finite_66 : ramanujan_congruence_comp 66 = true := by decide
theorem ramanujan_congruence_finite_67 : ramanujan_congruence_comp 67 = true := by decide
theorem ramanujan_congruence_finite_68 : ramanujan_congruence_comp 68 = true := by decide
theorem ramanujan_congruence_finite_69 : ramanujan_congruence_comp 69 = true := by decide
theorem ramanujan_congruence_finite_70 : ramanujan_congruence_comp 70 = true := by decide
theorem ramanujan_congruence_finite_71 : ramanujan_congruence_comp 71 = true := by decide
theorem ramanujan_congruence_finite_72 : ramanujan_congruence_comp 72 = true := by decide
theorem ramanujan_congruence_finite_73 : ramanujan_congruence_comp 73 = true := by decide
theorem ramanujan_congruence_finite_74 : ramanujan_congruence_comp 74 = true := by decide
theorem ramanujan_congruence_finite_75 : ramanujan_congruence_comp 75 = true := by decide
theorem ramanujan_congruence_finite_76 : ramanujan_congruence_comp 76 = true := by decide
theorem ramanujan_congruence_finite_77 : ramanujan_congruence_comp 77 = true := by decide
theorem ramanujan_congruence_finite_78 : ramanujan_congruence_comp 78 = true := by decide
theorem ramanujan_congruence_finite_79 : ramanujan_congruence_comp 79 = true := by decide
theorem ramanujan_congruence_finite_80 : ramanujan_congruence_comp 80 = true := by decide
theorem ramanujan_congruence_finite_81 : ramanujan_congruence_comp 81 = true := by decide
theorem ramanujan_congruence_finite_82 : ramanujan_congruence_comp 82 = true := by decide
theorem ramanujan_congruence_finite_83 : ramanujan_congruence_comp 83 = true := by decide
theorem ramanujan_congruence_finite_84 : ramanujan_congruence_comp 84 = true := by decide
theorem ramanujan_congruence_finite_85 : ramanujan_congruence_comp 85 = true := by decide
theorem ramanujan_congruence_finite_86 : ramanujan_congruence_comp 86 = true := by decide
theorem ramanujan_congruence_finite_87 : ramanujan_congruence_comp 87 = true := by decide
theorem ramanujan_congruence_finite_88 : ramanujan_congruence_comp 88 = true := by decide
theorem ramanujan_congruence_finite_89 : ramanujan_congruence_comp 89 = true := by decide
theorem ramanujan_congruence_finite_90 : ramanujan_congruence_comp 90 = true := by decide
theorem ramanujan_congruence_finite_91 : ramanujan_congruence_comp 91 = true := by decide
theorem ramanujan_congruence_finite_92 : ramanujan_congruence_comp 92 = true := by decide
theorem ramanujan_congruence_finite_93 : ramanujan_congruence_comp 93 = true := by decide
theorem ramanujan_congruence_finite_94 : ramanujan_congruence_comp 94 = true := by decide
theorem ramanujan_congruence_finite_95 : ramanujan_congruence_comp 95 = true := by decide
theorem ramanujan_congruence_finite_96 : ramanujan_congruence_comp 96 = true := by decide
theorem ramanujan_congruence_finite_97 : ramanujan_congruence_comp 97 = true := by decide
theorem ramanujan_congruence_finite_98 : ramanujan_congruence_comp 98 = true := by decide
theorem ramanujan_congruence_finite_99 : ramanujan_congruence_comp 99 = true := by decide
theorem ramanujan_congruence_finite_100 : ramanujan_congruence_comp 100 = true := by decide
