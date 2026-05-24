import os
import re

def find_single_line_math(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # We want to find any occurrences of $$ ... $$ on a single line.
    # A single-line block starts with $$ and ends with $$ on the same line.
    lines = content.split('\n')
    single_line_count = 0
    for idx, line in enumerate(lines):
        # Find all occurrences of $$ in the line
        # If there are two or more $$, it's a candidate
        matches = list(re.finditer(r'\$\$(.*?)\$\$', line))
        if matches:
            print(f"{filepath}:L{idx+1}: {line.strip()}")
            single_line_count += 1
            
    print(f"Total single line blocks in {filepath}: {single_line_count}\n")

def main():
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in root or '.pytest_cache' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                find_single_line_math(os.path.join(root, file))

if __name__ == '__main__':
    main()
