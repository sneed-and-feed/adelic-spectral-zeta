import re
import os
from pathlib import Path

def extract_math_with_context(content):
    lines = content.split('\n')
    math_items = []
    
    # First, let's mask out code blocks
    in_code_block = False
    masked_lines = []
    for line in lines:
        if line.strip().startswith('```'):
            if not line.strip().startswith('```math'):
                in_code_block = not in_code_block
                masked_lines.append(None)
                continue
        if in_code_block:
            masked_lines.append(None)
        else:
            masked_lines.append(line)

    # Find display math blocks
    # 1. ```math ... ```
    i = 0
    while i < len(lines):
        if masked_lines[i] is not None and masked_lines[i].strip().startswith('```math'):
            start_line = i + 1
            j = i + 1
            block_content = []
            while j < len(lines) and not lines[j].strip().startswith('```'):
                block_content.append(lines[j])
                j += 1
            expr = '\n'.join(block_content)
            math_items.append({
                'type': 'block-code',
                'expr': expr,
                'start_line': start_line + 1,
                'end_line': j + 1,
                'is_in_table': False
            })
            i = j + 1
        else:
            i += 1

    # 2. $$ ... $$
    # We will search each non-masked line for $$
    for idx, line in enumerate(lines):
        if masked_lines[idx] is None:
            continue
        # Find display math in $$ ... $$
        # Let's count $$ in the line
        pos = 0
        while True:
            start = line.find('$$', pos)
            if start == -1:
                break
            end = line.find('$$', start + 2)
            if end == -1:
                break
            expr = line[start+2:end]
            math_items.append({
                'type': 'block-dollar',
                'expr': expr,
                'start_line': idx + 1,
                'end_line': idx + 1,
                'is_in_table': '|' in line
            })
            pos = end + 2

    # Find inline math
    # 1. $` ... `$ or $`` ... ``$
    for idx, line in enumerate(lines):
        if masked_lines[idx] is None:
            continue
        # First, $`` ... ``$
        pos = 0
        while True:
            start = line.find('$``', pos)
            if start == -1:
                break
            end = line.find('``$', start + 3)
            if end == -1:
                break
            expr = line[start+3:end]
            math_items.append({
                'type': 'inline-backtick2',
                'expr': expr,
                'start_line': idx + 1,
                'end_line': idx + 1,
                'is_in_table': '|' in line
            })
            pos = end + 3

        # Then $` ... `$
        pos = 0
        while True:
            start = line.find('$`', pos)
            if start == -1:
                break
            if start > 0 and line[start-1] == '`':
                pos = start + 1
                continue
            end = line.find('`$', start + 2)
            if end == -1:
                break
            expr = line[start+2:end]
            math_items.append({
                'type': 'inline-backtick1',
                'expr': expr,
                'start_line': idx + 1,
                'end_line': idx + 1,
                'is_in_table': '|' in line
            })
            pos = end + 2

        # Then standard $ ... $
        # We need to make sure we don't match already matched ones.
        # Let's do a simple regex on masked out line
        # First mask out backtick math in this line
        line_masked = list(line)
        def mask_range(s, e):
            for k in range(s, e):
                line_masked[k] = ' '
        
        # Mask $$
        pos = 0
        while True:
            start = line.find('$$', pos)
            if start == -1: break
            end = line.find('$$', start + 2)
            if end == -1: break
            mask_range(start, end + 2)
            pos = end + 2
            
        # Mask $``
        pos = 0
        while True:
            start = line.find('$``', pos)
            if start == -1: break
            end = line.find('``$', start + 3)
            if end == -1: break
            mask_range(start, end + 3)
            pos = end + 3
            
        # Mask $`
        pos = 0
        while True:
            start = line.find('$`', pos)
            if start == -1: break
            end = line.find('`$', start + 2)
            if end == -1: break
            mask_range(start, end + 2)
            pos = end + 2
            
        line_masked_str = "".join(line_masked)
        inline_simple = re.finditer(r'(?<!\$)\$(?!\$)([^$\n`]+)(?<!\$)\$(?!\$)', line_masked_str)
        for match in inline_simple:
            expr = line[match.start()+1:match.end()-1]
            math_items.append({
                'type': 'inline-simple',
                'expr': expr,
                'start_line': idx + 1,
                'end_line': idx + 1,
                'is_in_table': '|' in line
            })

    return math_items

def audit_file(filepath):
    content = Path(filepath).read_text(encoding='utf-8')
    items = extract_math_with_context(content)
    
    issues = []
    for item in items:
        expr = item['expr']
        line = item['start_line']
        is_table = item['is_in_table']
        
        # Check 1: less than or greater than
        # We look for literal < or > but NOT as part of \lt or \gt or \le or \ge or \langle or \rangle
        # Easy way: replace known safe ones and check if < or > remains
        test_expr = expr
        test_expr = test_expr.replace(r'\lt', '')
        test_expr = test_expr.replace(r'\gt', '')
        test_expr = test_expr.replace(r'\le', '')
        test_expr = test_expr.replace(r'\ge', '')
        test_expr = test_expr.replace(r'\langle', '')
        test_expr = test_expr.replace(r'\rangle', '')
        
        if '<' in test_expr:
            issues.append((line, f"Contains literal '<' (should be \\lt or \\le): {expr}"))
        if '>' in test_expr:
            issues.append((line, f"Contains literal '>' (should be \\gt or \\ge): {expr}"))
            
        # Check 2: pipe character inside table cell math
        if is_table and '|' in expr:
            # Check if it is escaped. If it's \| it is escaped, but as we saw, it might get stripped or behave weirdly.
            # \vert or \Vert are much better.
            issues.append((line, f"Table cell math contains vertical bar '|' (should be \\vert or \\Vert or \\mid): {expr}"))

    return issues

def main():
    files = [
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\README.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\unified_monograph.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\geometric_index_theorem.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\scratch\appendix_f_test.md"
    ]
    
    for fp in files:
        if not os.path.exists(fp):
            continue
        print(f"\nAuditing: {fp}")
        issues = audit_file(fp)
        if not issues:
            print("  No issues found.")
        for line, desc in issues:
            print(f"  Line {line}: {desc}")

if __name__ == '__main__':
    main()
