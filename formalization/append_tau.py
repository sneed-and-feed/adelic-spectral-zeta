import re

def append_tau(n):
    with open('Formalization/RamanujanTau.lean', 'r', encoding='utf-8') as f:
        content = f.read()

    # Strip existing decide theorems
    content = re.sub(r'theorem ramanujan_congruence_finite_\d+ : ramanujan_congruence_comp \d+ = true := by decide\n', '', content)
    
    # Write stripped content back to RamanujanTau.lean
    with open('Formalization/RamanujanTau.lean', 'w', encoding='utf-8') as f:
        f.write(content.strip() + '\n\n')
        
    # Append the new ones
    with open('Formalization/RamanujanTauCompute.lean', 'a', encoding='utf-8') as f:
        for i in range(1, n + 1):
            f.write(f'theorem ramanujan_congruence_finite_{i} : ramanujan_congruence_comp {i} = true := by decide\n')

if __name__ == '__main__':
    append_tau(100)
