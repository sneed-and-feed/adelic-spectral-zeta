import re
import os

def process_file(filepath):
    print(f"Processing: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # Precise matching pattern that avoids optional wildcard/brace-swallowing:
    # Subscript: _n, _k, _{n}, _{k}
    # Superscript: ^*, ^\ast, ^{*}, ^{\ast}
    pattern = re.compile(r't_(?:([nk])|\{([nk])\})\^(?:\*|\\ast|\{\*\}|\{\\ast\})')
    
    def repl(m):
        var = m.group(1) or m.group(2)
        return f"t_{{{var}}}^\\ast"

    new_content = pattern.sub(repl, content)

    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print("Updated successfully!")
    else:
        print("No changes made.")

def run_tests():
    # Self-test cases
    pattern = re.compile(r't_(?:([nk])|\{([nk])\})\^(?:\*|\\ast|\{\*\}|\{\\ast\})')
    def repl(m):
        var = m.group(1) or m.group(2)
        return f"t_{{{var}}}^\\ast"

    test_cases = [
        ("t_n^*", "t_{n}^\\ast"),
        ("t_k^*", "t_{k}^\\ast"),
        ("t_{n}^*", "t_{n}^\\ast"),
        ("t_n^{*}", "t_{n}^\\ast"),
        ("t_n^{\\ast}", "t_{n}^\\ast"),
        ("\\frac{z}{t_n^*}", "\\frac{z}{t_{n}^\\ast}"),
        ("\\frac{z}{t_k^*}", "\\frac{z}{t_{k}^\\ast}"),
        ("s = 1/2 + i t_n^*", "s = 1/2 + i t_{n}^\\ast"),
        ("\\{t_n^*\\}", "\\{t_{n}^\\ast\\}"),
        ("\\frac{1}{t_n^* - z}", "\\frac{1}{t_{n}^\\ast - z}"),
    ]

    for src, expected in test_cases:
        res = pattern.sub(repl, src)
        assert res == expected, f"Regex failed for: {src} -> got {res}, expected {expected}"
    print("All regex self-tests passed successfully!")

def main():
    run_tests()
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    process_file(os.path.join(repo_dir, "README.md"))
    process_file(os.path.join(repo_dir, "docs", "unified_monograph.md"))
    process_file(os.path.join(repo_dir, "docs", "geometric_index_theorem.md"))

if __name__ == '__main__':
    main()

