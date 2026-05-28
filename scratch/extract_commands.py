"""
Extract all unique LaTeX commands/macros in docs/unified_monograph.md.
"""
from pathlib import Path
import re

# Read monograph
text = Path('docs/unified_monograph.md').read_text(encoding='utf-8')

# Helper to extract math
def strip_blockquote(line):
    s = line
    while s.lstrip().startswith('>'):
        s = s.lstrip()[1:]
        if s.startswith(' '):
            s = s[1:]
    return s

def extract_math(content):
    formulas = []
    # 1. Display math blocks ```math ... ```
    pos = 0
    while True:
        start = content.find('```math', pos)
        if start == -1:
            break
        end = content.find('```', start + 7)
        if end == -1:
            break
        formula = content[start+7:end].strip()
        formulas.append(formula)
        pos = end + 3

    # 2. Inline math blocks $` ... `$
    pos = 0
    while True:
        start = content.find('$`', pos)
        if start == -1:
            break
        end = content.find('`$', start + 2)
        if end == -1:
            break
        formula = content[start+2:end].strip()
        formulas.append(formula)
        pos = end + 2
        
    return formulas

formulas = extract_math(text)
print(f"Extracted {len(formulas)} formulas.")

# Find all words starting with backslash
commands = set()
for formula in formulas:
    cmds = re.findall(r'\\[a-zA-Z]+', formula)
    for c in cmds:
        commands.add(c)
        
print(f"Found {len(commands)} unique LaTeX commands:")
for c in sorted(commands):
    print(f"  {c}")
