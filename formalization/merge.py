import os

with open('Formalization/Sorry2.lean', 'r', encoding='utf-8') as f:
    lines = f.readlines()

lemmas = lines[8:300]

with open('Formalization/SpectralCircle.lean', 'r', encoding='utf-8') as f:
    target_lines = f.readlines()

out_lines = []
for line in target_lines:
    if line.strip() == '-- 4. ORBIT WEIGHT MAGNITUDE':
        out_lines.append(line)
    elif line.strip() == '-- ============================================================================' and out_lines and out_lines[-1].strip() == '-- 4. ORBIT WEIGHT MAGNITUDE':
        out_lines.append(line)
        out_lines.append('\n/-- Each orbit of ×3 on odd residues has weight product with magnitude √2.\n    This follows from the cyclotomic product identity (proven in CyclotomicProduct.lean)\n    combined with the symmetry C₂ = -C₁. -/\n')
        out_lines.extend(lemmas)
    else:
        out_lines.append(line)

with open('Formalization/SpectralCircle.lean', 'w', encoding='utf-8') as f:
    f.writelines(out_lines)