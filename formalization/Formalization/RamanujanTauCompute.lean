import Formalization.RamanujanTau

/-!
# Ramanujan Tau Computational Verification

This file isolates the kernel `decide` computations that verify
the congruence $\tau(n) \equiv \sigma_{11}(n) \pmod{691}$ across the 
fundamental weight-12 cusp period ($n=1, \dots, 12$) using pure kernel arithmetic
(avoiding `native_decide` and preserving 0-sorry verification).
-/

set_option maxRecDepth 2000000
set_option maxHeartbeats 0

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
