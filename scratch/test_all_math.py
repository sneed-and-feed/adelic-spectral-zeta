import re
import os
import subprocess

def extract_math(content):
    formulas = []
    masked = list(content)
    
    def mask_range(start, end):
        for idx in range(start, end):
            if masked[idx] != '\n':
                masked[idx] = ' '
                
    # 1a. Display math blocks ```math ... ```
    pos = 0
    while True:
        start = content.find('```math', pos)
        if start == -1:
            break
        end = content.find('```', start + 7)
        if end == -1:
            break
        formula = content[start+7:end].strip()
        formulas.append(('display-codeblock', formula, start, end + 3))
        mask_range(start, end + 3)
        pos = end + 3

    # 1b. Display math blocks $$ ... $$
    pos = 0
    while True:
        if pos >= len(content):
            break
        start = content.find('$$', pos)
        if start == -1:
            break
        if masked[start] == ' ':
            pos = start + 2
            continue
        end = content.find('$$', start + 2)
        if end == -1:
            break
        formula = content[start+2:end].strip()
        formulas.append(('display', formula, start, end + 2))
        mask_range(start, end + 2)
        pos = end + 2


    # 2. Inline math blocks $`` ... ``$ or $` ... `$ or $ ... $
    # Let's find $`` ... ``$
    pos = 0
    while True:
        start = content.find('$``', pos)
        if start == -1:
            break
        end = content.find('``$', start + 3)
        if end == -1:
            break
        formula = content[start+3:end].strip()
        formulas.append(('inline-backtick2', formula, start, end + 3))
        mask_range(start, end + 3)
        pos = end + 3

    # Let's find $` ... `$
    pos = 0
    while True:
        start = content.find('$`', pos)
        if start == -1:
            break
        end = content.find('`$', start + 2)
        if end == -1:
            break
        # Make sure we don't overlap with $``
        if start > 0 and content[start-1] == '`':
            pos = start + 1
            continue
        if masked[start] == ' ':
            pos = start + 1
            continue
        formula = content[start+2:end].strip()
        formulas.append(('inline-backtick1', formula, start, end + 2))
        mask_range(start, end + 2)
        pos = end + 2

    # Let's find $ ... $ (excluding the above) using masked content
    masked_content = "".join(masked)
    inline_simple = re.finditer(r'(?<!\$)\$(?!\$)([^$\n`]+)(?<!\$)\$(?!\$)', masked_content)
    for match in inline_simple:
        formula_text = content[match.start()+1:match.end()-1].strip()
        formulas.append(('inline-simple', formula_text, match.start(), match.end()))

    return formulas

def test_formulas_with_katex(filepath):
    print(f"\n========================================\nChecking math in: {filepath}\n========================================")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    formulas = extract_math(content)
    print(f"Found {len(formulas)} math blocks.")
    
    # We will write a temp JS script to test all these formulas in KaTeX
    js_lines = [
        "const katex = require('katex');",
        "const formulas = " + repr([f[1] for f in formulas]) + ";",
        "formulas.forEach((f, idx) => {",
        "    try {",
        "        katex.renderToString(f);",
        "    } catch (err) {",
        "        console.log(JSON.stringify({index: idx, formula: f, error: err.message}));",
        "    }",
        "});"
    ]
    
    temp_js_path = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\scratch\temp_test.js"
    with open(temp_js_path, 'w', encoding='utf-8') as f:
        f.write("\n".join(js_lines))
        
    try:
        res = subprocess.run(["node", "temp_test.js"], cwd=r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\scratch", capture_output=True, text=True, check=True, shell=True)
        errors = res.stdout.strip().split('\n')
        has_errors = False
        for err_str in errors:
            if not err_str:
                continue
            has_errors = True
            err_info = re.sub(r'\\\\', r'\\', err_str) # clean up escape sequences for display
            print(f"Error details: {err_info}")
        if not has_errors:
            print("All formulas successfully parsed by KaTeX!")
    except subprocess.CalledProcessError as e:
        print(f"Node execution failed: {e.stderr}")
        
    if os.path.exists(temp_js_path):
        os.remove(temp_js_path)

def main():
    test_formulas_with_katex(r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\README.md")
    test_formulas_with_katex(r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\unified_monograph.md")
    test_formulas_with_katex(r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\geometric_index_theorem.md")
    
    monograph_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\monograph"
    if os.path.exists(monograph_dir):
        for f in sorted(os.listdir(monograph_dir)):
            if f.endswith('.md'):
                test_formulas_with_katex(os.path.join(monograph_dir, f))

if __name__ == '__main__':
    main()
