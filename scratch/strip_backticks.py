import re
import os

def strip_backticks_from_content(content):
    # Split the content by code blocks to avoid changing math inside code blocks
    parts = re.split(r'(```[\s\S]*?```)', content)
    
    modified = False
    for i in range(len(parts)):
        if parts[i].startswith('```'):
            continue
        
        # Replace $`` ... ``$ with $ ... $
        new_part, count1 = re.subn(r'\$``([\s\S]*?)``\$', r'$\1$', parts[i])
        if count1 > 0:
            modified = True
            parts[i] = new_part
            
        # Replace $` ... `$ with $ ... $
        new_part, count2 = re.subn(r'\$`([\s\S]*?)`\$', r'$\1$', parts[i])
        if count2 > 0:
            modified = True
            parts[i] = new_part

    return "".join(parts) if modified else None

def process_file(filepath):
    print(f"Checking: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    new_content = strip_backticks_from_content(content)
    if new_content is not None:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Successfully stripped backticks from {filepath}")
    else:
        print(f"No backticked math found in {filepath}")

def main():
    files = [
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\README.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\unified_monograph.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\geometric_index_theorem.md"
    ]
    for filepath in files:
        if os.path.exists(filepath):
            process_file(filepath)
        else:
            print(f"File not found: {filepath}")

if __name__ == '__main__':
    main()
