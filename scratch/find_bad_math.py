import re
import os

def check_math_string(s, filepath, line_num):
    # Find all \left and \right occurrences
    all_lefts = list(re.finditer(r'\\left\b', s))
    all_rights = list(re.finditer(r'\\right\b', s))
    
    left_pattern = re.compile(r'\\left\s*([(\[|]|\\\{|\\langle|\\lfloor|\\lceil|\\vert|\\Vert|\\.|\\lvert|\\rvert|\\lVert|\\rVert)')
    right_pattern = re.compile(r'\\right\s*([)\]|]|\\\}|\\rangle|\\rfloor|\\rceil|\\vert|\\Vert|\\.|\\lvert|\\rvert|\\lVert|\\rVert)')
    
    valid_lefts = list(left_pattern.finditer(s))
    valid_rights = list(right_pattern.finditer(s))
    
    # Let's print if there's any mismatch
    if len(all_lefts) != len(valid_lefts) or len(all_rights) != len(valid_rights) or len(valid_lefts) != len(valid_rights):
        print(f"[{filepath}:{line_num}]")
        print(f"  All lefts count: {len(all_lefts)}, Valid lefts count: {len(valid_lefts)}")
        print(f"  All rights count: {len(all_rights)}, Valid rights count: {len(valid_rights)}")
        print(f"  Math: {s.strip()}")
        print("-" * 40)

def check_file(filepath):
    print(f"Checking: {os.path.basename(filepath)}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Find all $$ ... $$ blocks
    block_math = re.finditer(r'\$\$(.*?)\$\$', content, re.DOTALL)
    for match in block_math:
        line_num = content[:match.start()].count('\n') + 1
        check_math_string(match.group(1), filepath, line_num)
        
    # Find all $ ... $ blocks (inline)
    # Be careful not to match $$ as two empty inline blocks
    inline_math = re.finditer(r'(?<!\$)\$(?!\$)(.*?)(?<!\$)\$(?!\$)', content, re.DOTALL)
    for match in inline_math:
        line_num = content[:match.start()].count('\n') + 1
        check_math_string(match.group(1), filepath, line_num)

def main():
    docs_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    for root, dirs, files in os.walk(docs_dir):
        if '.git' in root or '.pytest_cache' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                path = os.path.join(root, file)
                check_file(path)

if __name__ == '__main__':
    main()
