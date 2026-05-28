import re

def fix_file(filepath):
    print(f"Fixing indented math blocks in: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Regex to match indented ```math blocks:
    # Group 1: indentation (spaces/tabs)
    # Group 2: the math content inside
    # We want to replace:
    # [indent]```math
    # [indent][content]
    # [indent]```
    # with:
    # [indent]$$
    # [indent][content]
    # [indent]$$
    
    # We can match this using a regex with a backreference to the indentation.
    # Note: re.MULTILINE is required to match ^ at line starts.
    pattern = r'^([ \t]+)```math\n([\s\S]*?)\n\1```'
    
    def replace_match(match):
        indent = match.group(1)
        math_content = match.group(2)
        # Convert to $$ delimiters with the same indentation
        return f"{indent}$$\n{math_content}\n{indent}$$"

    new_content, count = re.subn(pattern, replace_match, content, flags=re.MULTILINE)
    
    if count > 0:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"SUCCESS: Replaced {count} indented math blocks.")
        return True
    else:
        print("NO CHANGES: No indented math blocks found.")
        return False

def main():
    files = [
        r"docs/collatz_gauge_geometry.md",
        r"docs/commutator_rank_kernel_note.md",
        r"docs/monograph/05_artin_l_functions_rigidity.md"
    ]
    
    import os
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    
    for f in files:
        full_path = os.path.join(repo_dir, f)
        if os.path.exists(full_path):
            fix_file(full_path)
        else:
            print(f"File not found: {full_path}")

if __name__ == '__main__':
    main()
