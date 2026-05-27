import os
import json
from scipy.stats import pearsonr, spearmanr
from p_adic_biology import parse_mmcif_sequence, sequence_p_adic_distance, calculate_3d_rmsd

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
    
    print("\n=== Correlation Analysis ===")
    print(f"Pearson Correlation: {pearson_corr:.4f} (p-value: {p_p:.4f})")
    print(f"Spearman Rank Correlation: {spearman_corr:.4f} (p-value: {p_s:.4f})")
    
    with open("results.json", "w") as f:
        json.dump({
            "pairwise_metrics": results,
            "pearson": pearson_corr,
            "spearman": spearman_corr
        }, f, indent=2)

if __name__ == "__main__":
    main()
