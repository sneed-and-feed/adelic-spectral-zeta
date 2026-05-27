import os

spf_path = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\SchreierPerronFrobenius.lean'
ms_path = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\MathlibSpectral.lean'

with open(spf_path, 'r', encoding='utf-8') as f:
    lines = f.read().split('\n')

start_idx = -1
end_idx = -1
for i, line in enumerate(lines):
    if line.startswith('-- For ℝ, IsHermitian means Aᵀ = A'):
        start_idx = i
    if line.startswith('namespace SchreierSpectral'):
        if start_idx != -1 and i > start_idx:
            # We want the second "namespace SchreierSpectral" which comes after the private lemmas
            end_idx = i
            break

if start_idx != -1 and end_idx != -1:
    private_lemmas = lines[start_idx:end_idx]
    # Remove 'private ' from 'private lemma'
    for i in range(len(private_lemmas)):
        if private_lemmas[i].startswith('private lemma'):
            private_lemmas[i] = private_lemmas[i].replace('private lemma', 'lemma')
    
    new_spf = lines[:start_idx] + lines[end_idx:]
    with open(spf_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(new_spf))
        
    with open(ms_path, 'a', encoding='utf-8') as f:
        f.write('\n'.join(private_lemmas))
        f.write('\nend Matrix\n')
    print("Successfully moved private lemmas!")
else:
    print("Could not find bounds:", start_idx, end_idx)
