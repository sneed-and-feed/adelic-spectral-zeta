"""
Adelic Spectral Zeta: run_correlation.py
"""

import os
import json
import random
import numpy as np
from scipy.stats import pearsonr, spearmanr
from adelic_spectral_zeta.p_adic_biology import parse_mmcif_sequence, sequence_p_adic_distance, calculate_3d_rmsd, get_properties

AMINO_ACIDS = list("ARNDCQEGHILKMFPSTWYV")

def shuffle_sequence(seq):
    seq_list = list(seq)
    random.shuffle(seq_list)
    return "".join(seq_list)

def get_shuffled_property_mapping():
    original_props = [get_properties(aa) for aa in AMINO_ACIDS]
    shuffled_props = original_props.copy()
    random.shuffle(shuffled_props)
    return dict(zip(AMINO_ACIDS, shuffled_props))

def randomized_p_adic_valuation(aa1: str, aa2: str, prop_map):
    if aa1 == aa2:
        return 1, 1, 1
    p1 = prop_map.get(aa1, (False, False, False))
    p2 = prop_map.get(aa2, (False, False, False))
    v2 = 1 if p1[0] == p2[0] else 0
    v3 = 1 if p1[1] == p2[1] else 0
    v5 = 1 if p1[2] == p2[2] else 0
    return v2, v3, v5

def randomized_sequence_p_adic_distance(seq1: str, seq2: str, p: int, prop_map):
    length = min(len(seq1), len(seq2))
    if length == 0:
        return float('inf')
    v_seq = 0
    for i in range(length):
        v2, v3, v5 = randomized_p_adic_valuation(seq1[i], seq2[i], prop_map)
        if p == 2:
            v_seq += v2
        elif p == 3:
            v_seq += v3
        elif p == 5:
            v_seq += v5
    normalized_v = v_seq / length
    return p ** (-normalized_v)

def bootstrap_pearson(x, y, n_bootstrap=10000, alpha=0.05):
    boot_corrs = []
    np.random.seed(42)
    n = len(x)
    for _ in range(n_bootstrap):
        indices = np.random.choice(n, size=n, replace=True)
        x_boot = [x[i] for i in indices]
        y_boot = [y[i] for i in indices]
        if np.std(x_boot) > 1e-9 and np.std(y_boot) > 1e-9:
            corr, _ = pearsonr(x_boot, y_boot)
            if not np.isnan(corr):
                boot_corrs.append(corr)
    boot_corrs = np.array(boot_corrs)
    lower = np.percentile(boot_corrs, 100 * (alpha / 2))
    upper = np.percentile(boot_corrs, 100 * (1 - alpha / 2))
    return lower, upper

def run_randomized_embedding_trials(sequences, pairs, rmsd_vals, n_trials=1000):
    random.seed(42)
    corrs = []
    for _ in range(n_trials):
        prop_map = get_shuffled_property_mapping()
        trial_dists = []
        for t1, t2 in pairs:
            seq1 = sequences[t1]
            seq2 = sequences[t2]
            d2 = randomized_sequence_p_adic_distance(seq1, seq2, 2, prop_map)
            d3 = randomized_sequence_p_adic_distance(seq1, seq2, 3, prop_map)
            d5 = randomized_sequence_p_adic_distance(seq1, seq2, 5, prop_map)
            trial_dists.append(d2 + d3 + d5)
        corr, _ = pearsonr(trial_dists, rmsd_vals)
        if not np.isnan(corr):
            corrs.append(corr)
    return np.array(corrs)

def run_sequence_shuffling_trials(sequences, pairs, rmsd_vals, n_trials=1000):
    random.seed(42)
    corrs = []
    for _ in range(n_trials):
        trial_dists = []
        for t1, t2 in pairs:
            seq1_shuf = shuffle_sequence(sequences[t1])
            seq2_shuf = shuffle_sequence(sequences[t2])
            d2 = sequence_p_adic_distance(seq1_shuf, seq2_shuf, p=2)
            d3 = sequence_p_adic_distance(seq1_shuf, seq2_shuf, p=3)
            d5 = sequence_p_adic_distance(seq1_shuf, seq2_shuf, p=5)
            trial_dists.append(d2 + d3 + d5)
        corr, _ = pearsonr(trial_dists, rmsd_vals)
        if not np.isnan(corr):
            corrs.append(corr)
    return np.array(corrs)

def main():
    data_dir = os.path.abspath("../../data")
    af_dir = os.path.join(data_dir, "alphafold")
    
    # Targets: P24941 (Human), P97377 (Mouse), P23573 (Fruit fly), P23437 (Frog)
    targets = {
        "Human": "AF-P24941-F1-model_v6.cif",
        "Mouse": "AF-P97377-F1-model_v6.cif",
        "Frog": "AF-P23437-F1-model_v6.cif",
        "FruitFly": "AF-P23573-F1-model_v6.cif"
    }
    
    sequences = {}
    for name, file in targets.items():
        filepath = os.path.join(af_dir, file)
        seq = parse_mmcif_sequence(filepath)
        sequences[name] = seq
        print(f"[{name}] Sequence length: {len(seq)}")

    # Pairwise comparisons
    pairs = [
        ("Human", "Mouse"),
        ("Human", "Frog"),
        ("Human", "FruitFly"),
        ("Mouse", "Frog"),
        ("Mouse", "FruitFly"),
        ("Frog", "FruitFly")
    ]
    
    results = []
    
    for t1, t2 in pairs:
        seq1 = sequences[t1]
        seq2 = sequences[t2]
        file1 = os.path.join(af_dir, targets[t1])
        file2 = os.path.join(af_dir, targets[t2])
        
        # Calculate distances
        d2 = sequence_p_adic_distance(seq1, seq2, p=2)
        d3 = sequence_p_adic_distance(seq1, seq2, p=3)
        d5 = sequence_p_adic_distance(seq1, seq2, p=5)
        
        # Sum of p-adic distances as an aggregated Adelic metric
        d_adelic = d2 + d3 + d5
        
        # Physical 3D RMSD
        rmsd = calculate_3d_rmsd(file1, file2)
        
        results.append({
            "Pair": f"{t1}-{t2}",
            "d2": d2,
            "d3": d3,
            "d5": d5,
            "d_adelic": d_adelic,
            "rmsd": rmsd
        })
        print(f"{t1}-{t2} => Adelic Dist: {d_adelic:.4f} | 3D RMSD: {rmsd:.4f} A")
        
    # Statistical Correlation
    x = [r["d_adelic"] for r in results]
    y = [r["rmsd"] for r in results]
    
    pearson_corr, p_p = pearsonr(x, y)
    spearman_corr, p_s = spearmanr(x, y)
    
    # 1. Bootstrap Confidence Interval for Pearson Correlation
    boot_lower, boot_upper = bootstrap_pearson(x, y, n_bootstrap=10000)
    
    # 2. Null Model I: Randomized p-adic properties
    random_emb_corrs = run_randomized_embedding_trials(sequences, pairs, y, n_trials=1000)
    mean_rand_emb = np.mean(random_emb_corrs)
    p_rand_emb = np.mean(random_emb_corrs >= pearson_corr)
    
    # 3. Null Model II: Sequence shuffling control
    seq_shuf_corrs = run_sequence_shuffling_trials(sequences, pairs, y, n_trials=1000)
    mean_seq_shuf = np.mean(seq_shuf_corrs)
    p_seq_shuf = np.mean(seq_shuf_corrs >= pearson_corr)
    
    print("\n=== Correlation Analysis ===")
    print(f"Pearson Correlation: {pearson_corr:.4f} (p-value: {p_p:.4f})")
    print(f"95% Bootstrap CI for Pearson: [{boot_lower:.4f}, {boot_upper:.4f}]")
    print(f"Spearman Rank Correlation: {spearman_corr:.4f} (p-value: {p_s:.4f})")
    
    print("\n=== Null Models & Control Experiments ===")
    print(f"Null Model I: Randomized p-adic Embedding (Properties)")
    print(f"  Mean Correlation under Null: {mean_rand_emb:.4f}")
    print(f"  Empirical p-value: {p_rand_emb:.4f} (fraction of random trials >= real correlation)")
    
    print(f"Null Model II: Sequence Shuffling Control")
    print(f"  Mean Correlation under Null: {mean_seq_shuf:.4f}")
    print(f"  Empirical p-value: {p_seq_shuf:.4f} (fraction of random trials >= real correlation)")
    
    with open("results.json", "w") as f:
        json.dump({
            "pairwise_metrics": results,
            "pearson": pearson_corr,
            "pearson_p_value": p_p,
            "bootstrap_ci": [boot_lower, boot_upper],
            "spearman": spearman_corr,
            "spearman_p_value": p_s,
            "null_model_properties": {
                "mean_correlation": float(mean_rand_emb),
                "empirical_p_value": float(p_rand_emb)
            },
            "null_model_shuffling": {
                "mean_correlation": float(mean_seq_shuf),
                "empirical_p_value": float(p_seq_shuf)
            }
        }, f, indent=2)

if __name__ == "__main__":
    main()
