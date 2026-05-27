with open('test_eval9.lean', 'w', encoding='utf-8') as f:
    f.write('import Formalization.RamanujanTau\n')
    f.write('set_option maxRecDepth 200000\n')
    f.write('theorem test2 : ramanujan_congruence_comp 2 = true := by decide\n')
