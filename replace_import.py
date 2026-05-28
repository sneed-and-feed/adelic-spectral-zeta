import os

spf_path = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\SchreierPerronFrobenius.lean'
with open(spf_path, 'r', encoding='utf-8') as f:
    text = f.read()

if 'import SpectralPositivityExt' in text:
    print('Found it!')
else:
    print('Not found!')

text = text.replace('import SpectralPositivityExt', 'import Formalization.MathlibSpectral')
with open(spf_path, 'w', encoding='utf-8') as f:
    f.write(text)

print('Done!')
