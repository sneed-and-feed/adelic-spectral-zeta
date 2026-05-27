import os

files = [
    'WalkPropagation.lean',
    'EigenvectorUniqueness.lean',
    'ConstantSign.lean',
    'SpectralDominance.lean'
]

out = []
out.append('import Mathlib.Data.Matrix.Basic')
out.append('import Mathlib.Combinatorics.SimpleGraph.Basic')
out.append('import Mathlib.Combinatorics.SimpleGraph.Connectivity')
out.append('import Mathlib.Data.Real.Basic')
out.append('import Mathlib.Algebra.Order.Group.Abs')
out.append('import Mathlib.LinearAlgebra.Matrix.Spectrum')
out.append('import Mathlib.Analysis.InnerProductSpace.PiL2')
out.append('')
out.append('open Matrix')
out.append('open Classical')
out.append('')
out.append('namespace Matrix')
out.append('')
out.append('variable {n : Type _} [Fintype n] [DecidableEq n] [Nonempty n]')
out.append('')

for f in files:
    with open(r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\spectral-positivity-ext\SpectralPositivityExt\\' + f, 'r', encoding='utf-8') as fp:
        lines = fp.read().split('\n')
        start = 0
        while start < len(lines):
            if lines[start].startswith('variable '):
                start += 1
                break
            start += 1
        end = len(lines) - 1
        while end >= 0:
            if lines[end].startswith('end Matrix'):
                break
            end -= 1
        out.extend(lines[start:end])

with open(r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\MathlibSpectral.lean', 'w', encoding='utf-8') as fp:
    fp.write('\n'.join(out))
    
print("Successfully generated MathlibSpectral.lean!")
