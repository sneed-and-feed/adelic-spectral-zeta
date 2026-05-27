with open('test_eval7.lean', 'w', encoding='utf-8') as f:
    f.write('import Mathlib\n')
    f.write('open PowerSeries\n')
    f.write('def X_series : PowerSeries ℤ := X\n')
    f.write('def ramanujan_trunc (N : ℕ) : PowerSeries ℤ :=\n')
    f.write('  (Finset.range N).prod (fun n => (1 - (X_series ^ (n + 1))) ^ 24)\n')
    f.write('def tau (n : ℕ) : ℤ :=\n')
    f.write('  coeff ℤ n (X_series * ramanujan_trunc n)\n')
