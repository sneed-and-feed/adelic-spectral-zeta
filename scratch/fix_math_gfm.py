import re
import os
from pathlib import Path

def fix_math_string(s):
    # 1. Replace <= with \le 
    s = re.sub(r'<=', r'\\le ', s)
    # 2. Replace >= with \ge 
    s = re.sub(r'>=', r'\\ge ', s)
    # 3. Replace < with \lt 
    s = s.replace('<', r'\lt ')
    # 4. Replace > with \gt 
    s = s.replace('>', r'\gt ')
    # 5. Replace \| with \Vert 
    s = s.replace(r'\|', r'\Vert ')
    # 6. Replace | with \vert 
    s = re.sub(r'(?<!\\)\|', r'\\vert ', s)
    return s

def process_content(content):
    pos = 0
    n = len(content)
    new_content = []
    last_idx = 0
    replacements_count = 0
    
    while pos < n:
        # Check for ```math
        if pos + 7 <= n and content[pos:pos+7] == '```math':
            end = content.find('```', pos + 7)
            if end != -1:
                math_expr = content[pos+7:end]
                fixed_expr = fix_math_string(math_expr)
                if fixed_expr != math_expr:
                    replacements_count += 1
                new_content.append(content[last_idx:pos+7])
                new_content.append(fixed_expr)
                last_idx = end
                pos = end + 3
                continue
            else:
                pos += 7
                continue
                
        # Check for $$
        if pos + 2 <= n and content[pos:pos+2] == '$$':
            end = content.find('$$', pos + 2)
            if end != -1:
                math_expr = content[pos+2:end]
                fixed_expr = fix_math_string(math_expr)
                if fixed_expr != math_expr:
                    replacements_count += 1
                new_content.append(content[last_idx:pos+2])
                new_content.append(fixed_expr)
                last_idx = end
                pos = end + 2
                continue
            else:
                pos += 2
                continue
                
        # Check for $`
        if pos + 2 <= n and content[pos:pos+2] == '$`':
            end = content.find('`$', pos + 2)
            if end != -1:
                math_expr = content[pos+2:end]
                fixed_expr = fix_math_string(math_expr)
                if fixed_expr != math_expr:
                    replacements_count += 1
                new_content.append(content[last_idx:pos+2])
                new_content.append(fixed_expr)
                last_idx = end
                pos = end + 2
                continue
            else:
                pos += 2
                continue
                
        # Check for $ (standard inline math, only if not part of $` or $$ or `$)
        if content[pos] == '$':
            is_escaped = False
            k = pos - 1
            while k >= 0 and content[k] == '\\':
                is_escaped = not is_escaped
                k -= 1
            if not is_escaped:
                end = pos + 1
                found = False
                while end < n and content[end] != '\n':
                    if content[end] == '$':
                        is_end_escaped = False
                        k = end - 1
                        while k >= pos and content[k] == '\\':
                            is_end_escaped = not is_end_escaped
                            k -= 1
                        if not is_end_escaped:
                            found = True
                            break
                    end += 1
                if found:
                    math_expr = content[pos+1:end]
                    fixed_expr = fix_math_string(math_expr)
                    if fixed_expr != math_expr:
                        replacements_count += 1
                    new_content.append(content[last_idx:pos+1])
                    new_content.append(fixed_expr)
                    last_idx = end
                    pos = end + 1
                    continue
        pos += 1
        
    new_content.append(content[last_idx:])
    return "".join(new_content), replacements_count

def fix_file(filepath):
    path = Path(filepath)
    if not path.exists():
        print(f"Skipping (not found): {filepath}")
        return
    
    content = path.read_text(encoding='utf-8')
    new_content, count = process_content(content)
    
    if count > 0:
        path.write_text(new_content, encoding='utf-8')
        print(f"Fixed {filepath}: {count} math blocks updated.")
    else:
        print(f"No changes needed for {filepath}.")

def main():
    files = [
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\README.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\unified_monograph.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\geometric_index_theorem.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\scratch\appendix_f_test.md"
    ]
    for fp in files:
        fix_file(fp)

if __name__ == '__main__':
    main()
