import os
import re

def main():
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    md_files = []
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in root or '.pytest_cache' in root or 'node_modules' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                md_files.append(os.path.join(root, file))

    print("Scanning for indented ```math blocks...")
    for filepath in md_files:
        rel_path = os.path.relpath(filepath, repo_dir)
        with open(filepath, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for i, line in enumerate(lines):
            # Check if line has leading whitespace followed by ```math
            m = re.match(r'^([ \t]+)```math', line)
            if m:
                print(f"{rel_path}:{i+1} - indented by {len(m.group(1))} spaces: {line.strip()}")

if __name__ == '__main__':
    main()
