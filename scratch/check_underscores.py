#!/usr/bin/env python3
"""Check for potential underscore conflicts in inline math."""
import re
from pathlib import Path

files = [
    Path('docs/unified_monograph.md'),
    Path('docs/geometric_index_theorem.md'),
    Path('README.md'),
]

for fp in files:
    text = fp.read_text(encoding='utf-8')
    lines = text.split('\n')
    in_fenced = False
    total_problematic = 0
    
    for i, line in enumerate(lines, 1):
        s = line.strip()
        # Strip blockquote markers
        while s.startswith('>'):
            s = s[1:].lstrip()
        if s.startswith('```'):
            in_fenced = not in_fenced
            continue
        if in_fenced:
            continue
        
        # Count total underscores on this line that are inside $...$ blocks
        # Simple approach: count all _ in the line that appear between $ delimiters
        in_math = False
        underscore_count = 0
        j = 0
        while j < len(line):
            ch = line[j]
            if ch == '$' and (j == 0 or line[j-1] != '\\'):
                if j + 1 < len(line) and line[j+1] == '$':
                    j += 2  # skip $$
                    continue
                in_math = not in_math
            elif ch == '_' and in_math:
                underscore_count += 1
            j += 1
        
        if underscore_count >= 4:
            total_problematic += 1
            print(f"  {fp.name}:{i} ({underscore_count} underscores)")
            if total_problematic <= 5:
                print(f"    {line[:150]}")
    
    print(f"\n{fp.name}: {total_problematic} lines with 4+ underscores in inline math\n")
