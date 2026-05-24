#!/usr/bin/env python3
"""
Diagnose potential MathJax rendering failures in both inline and block math.
Checks for LaTeX constructs that are known to fail in GitHub's MathJax.
"""
import re
from pathlib import Path


def strip_blockquote(line):
    s = line
    while s.lstrip().startswith('>'):
        s = s.lstrip()[1:]
        if s.startswith(' '):
            s = s[1:]
    return s


def extract_all_math(text):
    """Extract all math expressions with their locations."""
    lines = text.split('\n')
    math_exprs = []
    in_fenced = False
    in_math_block = False
    math_start = 0
    math_lines = []
    
    for i, line in enumerate(lines, 1):
        content = strip_blockquote(line).strip()
        
        if content.startswith('```math'):
            in_math_block = True
            math_start = i
            math_lines = []
            in_fenced = True
            continue
        elif content == '```' and in_math_block:
            in_math_block = False
            in_fenced = False
            expr = '\n'.join(math_lines)
            math_exprs.append(('block', math_start, i, expr))
            continue
        elif content.startswith('```') and not in_math_block:
            in_fenced = not in_fenced
            continue
        
        if in_math_block:
            math_lines.append(line)
            continue
        
        if in_fenced:
            continue
        
        # Extract inline $...$ (now standard dollar)
        j = 0
        while j < len(line):
            if line[j] == '$':
                if j + 1 < len(line) and line[j+1] == '$':
                    j += 2
                    continue
                # Find closing $
                k = j + 1
                while k < len(line):
                    if line[k] == '$' and (k + 1 >= len(line) or line[k+1] != '$'):
                        expr = line[j+1:k]
                        math_exprs.append(('inline', i, i, expr))
                        j = k + 1
                        break
                    k += 1
                else:
                    j += 1
            else:
                j += 1
    
    return math_exprs


def check_issues(expr_type, start, end, expr):
    """Check for known MathJax failure patterns."""
    issues = []
    
    # 1. Check for \left\{ or \right\} (GitHub may strip backslash)
    if r'\left\{' in expr or r'\right\}' in expr:
        issues.append('Contains \\left\\{ or \\right\\} — may fail on GitHub (use \\left\\lbrace / \\right\\rbrace)')
    
    # 2. Check for bare \{ or \} outside \left/\right
    # Already handled in previous commit with \lbrace/\rbrace
    
    # 3. Check for very long expressions
    if len(expr) > 3000:
        issues.append(f'Very long expression ({len(expr)} chars) — may hit GitHub size limits')
    
    # 4. Check for \ast (should be fine, was already fixed)
    
    # 5. Check for HTML-like tags that might confuse the parser
    if re.search(r'<[a-zA-Z]', expr):
        issues.append('Contains HTML-like tags that may confuse GitHub parser')
    
    # 6. Check for unbalanced braces
    depth = 0
    for ch in expr:
        if ch == '{':
            depth += 1
        elif ch == '}':
            depth -= 1
        if depth < 0:
            issues.append('Unbalanced braces (extra closing brace)')
            break
    if depth > 0:
        issues.append(f'Unbalanced braces ({depth} unclosed)')
    
    # 7. Check for newlines in inline math (not allowed)
    if expr_type == 'inline' and '\n' in expr:
        issues.append('Inline math contains newlines')
    
    # 8. Check for empty math
    if not expr.strip():
        issues.append('Empty math expression')
    
    # 9. Check for | in inline math (pipe character can conflict with tables)
    if expr_type == 'inline' and '|' in expr:
        # Only a problem if the line is inside a table (has | at start/end)
        pass  # We'd need the full line context for this
    
    return issues


def main():
    files = [
        Path('README.md'),
        Path('docs/unified_monograph.md'),
        Path('docs/geometric_index_theorem.md'),
    ]
    
    total_issues = 0
    
    for fp in files:
        text = fp.read_text(encoding='utf-8')
        exprs = extract_all_math(text)
        
        file_issues = []
        for expr_type, start, end, expr in exprs:
            issues = check_issues(expr_type, start, end, expr)
            if issues:
                file_issues.append((expr_type, start, end, expr[:80], issues))
        
        print(f"\n{fp.name}: {len(exprs)} math expressions, {len(file_issues)} with potential issues")
        for expr_type, start, end, preview, issues in file_issues:
            loc = f"L{start}" if start == end else f"L{start}-{end}"
            print(f"  [{expr_type}] {loc}: {preview}...")
            for issue in issues:
                print(f"    ⚠ {issue}")
        
        total_issues += len(file_issues)
    
    print(f"\n{'='*60}")
    print(f"Total: {total_issues} expressions with potential issues")


if __name__ == '__main__':
    main()
