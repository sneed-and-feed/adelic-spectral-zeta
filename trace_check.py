from run_high_precision import get_schreier_blocks
for d in range(6, 10):
    w, s = get_schreier_blocks(d)
    print(f"d={d}, trace={s.diagonal().sum()}")
