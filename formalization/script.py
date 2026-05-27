with open('test_eval5.lean', 'w', encoding='utf-8') as f:
    f.write('import Formalization.RamanujanTau\n')
    f.write('lemma test_div : divisor_sum_11 2 = 2049 := by decide\n')
