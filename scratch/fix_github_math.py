#!/usr/bin/env python3
"""
Convert all inline math from $...$ back to $`...`$ (backtick-dollar) format.

The standard $...$ format causes underscore conflicts on lines with multiple
subscripts — GitHub's Markdown parser pairs underscores as italics before
MathJax can process them.

The $`...`$ format wraps content in a code span which protects it from
Markdown parsing. The previous failures with this format were caused by
LaTeX issues (\{ → \lbrace, * → \ast) that have since been fixed.
"""

import re
import sys
from pathlib import Path


def strip_blockquote(line):
    s = line
    while s.lstrip().startswith('>'):
        s = s.lstrip()[1:]
        if s.startswith(' '):
            s = s[1:]
    return s


def convert_dollar_to_backtick_dollar(text):
    """Convert all $...$ inline math to $`...`$ format.
    
    Carefully avoids:
    - $$ (display math)
    - Content inside fenced code blocks (```...```)
    - Already-converted $`...`$ expressions
    """
    lines = text.split('\n')
    result = []
    in_fenced_block = False
    
    for line in lines:
        content = strip_blockquote(line).strip()
        
        if content.startswith('```'):
            in_fenced_block = not in_fenced_block
            result.append(line)
            continue
        
        if in_fenced_block:
            result.append(line)
            continue
        
        # Process this line: find all $...$ patterns and convert to $`...`$
        new_line = []
        i = 0
        while i < len(line):
            if line[i] == '$':
                # Check for $$ (display math) - skip
                if i + 1 < len(line) and line[i+1] == '$':
                    new_line.append('$$')
                    i += 2
                    continue
                
                # Check for $` (already backtick-dollar) - skip
                if i + 1 < len(line) and line[i+1] == '`':
                    # Already in $`...`$ format, copy as-is
                    j = i + 2
                    while j < len(line) - 1:
                        if line[j] == '`' and line[j+1] == '$':
                            new_line.append(line[i:j+2])
                            i = j + 2
                            break
                        j += 1
                    else:
                        new_line.append(line[i])
                        i += 1
                    continue
                
                # Standard $...$ — find the closing $
                j = i + 1
                while j < len(line):
                    if line[j] == '$':
                        # Check it's not $$ 
                        if j + 1 < len(line) and line[j+1] == '$':
                            j += 2
                            continue
                        # Found closing $
                        content = line[i+1:j]
                        if content:  # Don't convert empty math
                            new_line.append('$`')
                            new_line.append(content)
                            new_line.append('`$')
                        else:
                            new_line.append('$$')  # Empty $$ is likely display math
                        i = j + 1
                        break
                    j += 1
                else:
                    # No closing $ found — keep as-is
                    new_line.append(line[i])
                    i += 1
            else:
                new_line.append(line[i])
                i += 1
        
        result.append(''.join(new_line))
    
    return '\n'.join(result)


def count_patterns(text):
    """Count math patterns outside fenced blocks."""
    lines = text.split('\n')
    backtick = 0
    standard = 0
    in_fenced = False
    
    for line in lines:
        content = strip_blockquote(line).strip()
        if content.startswith('```'):
            in_fenced = not in_fenced
            continue
        if in_fenced:
            continue
        
        # Count $`
        backtick += line.count('$`')
        
        # Count standalone $ (not $$ or $`)
        i = 0
        while i < len(line):
            if line[i] == '$':
                if i + 1 < len(line) and line[i+1] in ('$', '`'):
                    i += 2
                    continue
                if i > 0 and line[i-1] == '`':
                    i += 1
                    continue
                standard += 1
            i += 1
    
    return {'$`...`$': backtick // 2, '$...$': standard // 2}


def main():
    repo_root = Path(__file__).parent.parent
    files = [
        repo_root / 'README.md',
        repo_root / 'docs' / 'unified_monograph.md',
        repo_root / 'docs' / 'geometric_index_theorem.md',
    ]
    
    dry_run = '--dry-run' in sys.argv
    
    print("=" * 60)
    print("Convert $...$ → $`...`$ (Backtick-Dollar)")
    print("=" * 60)
    if dry_run:
        print("[DRY RUN]")
    print()
    
    for fp in files:
        if not fp.exists():
            print(f"SKIP: {fp.name}")
            continue
        
        text = fp.read_text(encoding='utf-8')
        before = count_patterns(text)
        
        fixed = convert_dollar_to_backtick_dollar(text)
        after = count_patterns(fixed)
        
        changed = text != fixed
        
        if changed and not dry_run:
            fp.write_text(fixed, encoding='utf-8')
        
        status = '✓ Updated' if changed and not dry_run else '(would update)' if changed else '(no change)'
        print(f"{fp.name}:")
        print(f"  Before: {before}")
        print(f"  After:  {after}")
        print(f"  {status}")
        print()


if __name__ == '__main__':
    main()
