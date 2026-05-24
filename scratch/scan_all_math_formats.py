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

    print(f"{'File':<50} | {'$$':<5} | {'$`':<5} | {'`$':<5}")
    print("-" * 75)
    for filepath in md_files:
        rel_path = os.path.relpath(filepath, repo_dir)
        try:
            with open(filepath, 'r', encoding='utf-8') as f:
                content = f.read()
            double_dollars = content.count("$$")
            dollar_backticks = content.count("$`")
            backtick_dollars = content.count("`$")
            print(f"{rel_path:<50} | {double_dollars:<5} | {dollar_backticks:<5} | {backtick_dollars:<5}")
        except Exception as e:
            print(f"{rel_path:<50} | ERROR: {e}")

if __name__ == '__main__':
    main()
