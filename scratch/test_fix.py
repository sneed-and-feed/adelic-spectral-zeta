with open('docs/collatz_gauge_geometry.md', 'r', encoding='utf-8') as f:
    content = f.read()
from fix_all_math import fix_unclosed_dollars
fixed = fix_unclosed_dollars(content)
lines = fixed.split('\n')
for i in range(740, min(765, len(lines))):
    print(f'{i+1}: {repr(lines[i])}')
