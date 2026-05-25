import re

with open('Formalization/CollatzSpectral.lean', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace antisymMatrix with sheetDiffMatrix
content = content.replace('antisymMatrix', 'sheetDiffMatrix')
content = content.replace('realAntisymMatrix', 'realSheetDiffMatrix')

# Remove the mixing time bound and its comments
# It's at the end of the file, matching:
# /-- The mixing time T_{mix}(ε) for the random walk on G_d is bounded by O(d^2 + log(1/ε)).
#     This follows directly from the uniform spectral gap bound. -/
# axiom collatz_mixing_time_bound {d : ℕ} (hd : d ≥ 3) (ε : ℝ) (hε : ε > 0) :
#     ∃ C, C > 0 -- Placeholder for mixing time formulation: mixing_time G_d ε ≤ C * (d^2 + Real.log (1/ε))

pattern = re.compile(r'/-- The mixing time T_\{mix\}\(ε\).*?∃ C, C > 0.*?$', re.MULTILINE | re.DOTALL)
content = re.sub(pattern, '', content)

with open('Formalization/CollatzSpectral.lean', 'w', encoding='utf-8') as f:
    f.write(content)
