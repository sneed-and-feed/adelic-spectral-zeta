import Formalization.RamanujanTau
set_option maxRecDepth 200000
theorem test2 : ramanujan_congruence_comp 2 = true := by decide
