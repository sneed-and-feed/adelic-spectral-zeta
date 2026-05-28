import os

formalization_dir = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization'

for file in os.listdir(formalization_dir):
    if file.endswith('.lean'):
        path = os.path.join(formalization_dir, file)
        with open(path, 'r', encoding='utf-8') as f:
            text = f.read()
        if 'import SpectralPositivityExt' in text:
            print(f'Found in {file}')
            text = text.replace('import SpectralPositivityExt', 'import Formalization.MathlibSpectral')
            with open(path, 'w', encoding='utf-8') as f:
                f.write(text)
                
# Also remove the spectral-positivity-ext package dependency from lakefile
lakefile_path = r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\lakefile.lean'
with open(lakefile_path, 'r', encoding='utf-8') as f:
    text = f.read()
text = text.replace('require «spectral-positivity-ext» from "./spectral-positivity-ext"', '')
with open(lakefile_path, 'w', encoding='utf-8') as f:
    f.write(text)
    
print("Replaced all!")
