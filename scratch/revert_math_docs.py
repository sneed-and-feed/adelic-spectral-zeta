import re
import os

def process_file(filepath):
    print(f"Reverting math subscripts in: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # We want to replace {t_n}^* with t_n^* and {t_k}^* with t_k^*
    # Also handle {t_n}^* and {t_k}^* inside any other expressions
    new_content = content
    new_content = re.sub(r'\{t_n\}\^\*', r't_n^*', new_content)
    new_content = re.sub(r'\{t_k\}\^\*', r't_k^*', new_content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Updated!")
    else:
        print("No changes needed.")

def main():
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in root or '.pytest_cache' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                process_file(os.path.join(root, file))

if __name__ == '__main__':
    main()
