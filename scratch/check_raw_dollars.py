"""
Scan docs/unified_monograph.md for any remaining standard dollar delimiters or raw $ characters.
"""
from pathlib import Path
import re

filepath = Path('docs/unified_monograph.md')
text = filepath.read_text(encoding='utf-8')
lines = text.split('\n')

in_fenced = False
for i, line in enumerate(lines, 1):
    # Strip blockquote marker
    content = line.lstrip()
    if content.startswith('>'):
        content = content[1:].lstrip()
        
    if content.startswith('```'):
        in_fenced = not in_fenced
        continue
        
    if in_fenced:
        continue
        
    # Check for $ characters
    # Find all $ characters and check their context
    pos = 0
    while True:
        pos = line.find('$', pos)
        if pos == -1:
            break
            
        # Check context: is it $` ?
        if pos + 1 < len(line) and line[pos+1] == '`':
            # This is start of inline backtick math, skip to closing
            close_pos = line.find('`$', pos + 2)
            if close_pos != -1:
                pos = close_pos + 2
                continue
            else:
                print(f"L{i}: Unbalanced $` (no matching `$) - context: {line[max(0, pos-10):pos+30]}")
                pos += 2
                continue
                
        # Is it `$` ?
        if pos > 0 and line[pos-1] == '`':
            # This is end of inline backtick math, we should have processed it already
            pos += 1
            continue
            
        # Is it $$?
        if pos + 1 < len(line) and line[pos+1] == '$':
            print(f"L{i}: Found display math delimiter $$ - context: {line[max(0, pos-10):pos+20]}")
            pos += 2
            continue
            
        # Is it escaped \$?
        if pos > 0 and line[pos-1] == '\\':
            # Escaped dollar, this is fine
            pos += 1
            continue
            
        # If we got here, it's a raw/standard $!
        print(f"L{i}: Found raw/standard $ character at position {pos} - context: {line[max(0, pos-15):pos+30]}")
        pos += 1
