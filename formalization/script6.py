with open('test_eval6.lean', 'w', encoding='utf-8') as f:
    f.write('import Formalization.RamanujanTau\n')
    f.write('open PowerSeries\n')
    f.write('lemma tau_one : tau 1 = 1 := by sorry\n')
