import os

path = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\SchreierSpectral.lean'
with open(path, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace('import Formalization.MathlibSpectral.WalkPropagation', 'import Formalization.MathlibSpectral')
with open(path, 'w', encoding='utf-8') as f:
    f.write(text)
print('Done SchreierSpectral')

path2 = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\SpectralPositivity\Matrix\PerronFrobenius.lean'
if os.path.exists(path2):
    with open(path2, 'r', encoding='utf-8') as f:
        text = f.read()
    text = text.replace('import SpectralPositivityExt', 'import Formalization.MathlibSpectral')
    with open(path2, 'w', encoding='utf-8') as f:
        f.write(text)
    print('Done PerronFrobenius')

path3 = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\SchreierPerronFrobenius.lean'
with open(path3, 'r', encoding='utf-8') as f:
    text = f.read()
# just in case
text = text.replace('import Formalization.MathlibSpectral.WalkPropagation', 'import Formalization.MathlibSpectral')
with open(path3, 'w', encoding='utf-8') as f:
    f.write(text)
print('Done SchreierPerronFrobenius')
