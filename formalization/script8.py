with open('test_eval8.lean', 'w', encoding='utf-8') as f:
    f.write('import Mathlib\n')
    f.write('import Formalization.RamanujanTau\n')
    f.write('open PowerSeries\n')
    f.write('lemma tau_one : tau 1 = 1 := by\n')
    f.write('  dsimp [tau]\n')
    f.write('  rw [coeff_succ_X_mul, ramanujan_trunc]\n')
    f.write('  -- \prod (1 - X^(n+1))^24\n')
    f.write('  sorry\n')
