import re
import os

def convert_file(filepath):
    print(f"Converting math blocks in: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # We want to find all display math blocks delimited by $$ ... $$
    # We must be careful not to match inside code blocks.
    # So we split by code blocks first.
    parts = re.split(r'(```[\s\S]*?```)', content)
    
    modified = False
    for i in range(len(parts)):
        if parts[i].startswith('```'):
            continue
            
        # Find all $$ ... $$ blocks
        # We use a regex that matches $$ ... $$ (non-greedy)
        # We want to replace each matched $$ ... $$ block if it's not already on its own lines.
        # Let's find matches:
        subparts = []
        pos = 0
        for match in re.finditer(r'\$\$([\s\S]*?)\$\$', parts[i]):
            # Add text before match
            subparts.append(parts[i][pos:match.start()])
            
            math_content = match.group(1)
            # Check if there is non-whitespace character after the opening $$
            # or before the closing $$ on their respective lines.
            
            # Let's trim whitespace at the start and end of math_content
            # but preserve the structure.
            lines = math_content.split('\n')
            
            # If there's only one line, or if the first/last lines are not empty:
            # We want the output to be:
            # $$
            # math_content (trimmed)
            # $$
            trimmed_content = math_content.strip()
            new_block = f"$$\n{trimmed_content}\n$$"
            
            # Let's check if it actually changed
            original_block = match.group(0)
            if original_block != new_block:
                modified = True
                subparts.append(new_block)
            else:
                subparts.append(original_block)
                
            pos = match.end()
            
        subparts.append(parts[i][pos:])
        parts[i] = "".join(subparts)
        
    if modified:
        new_content = "".join(parts)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Saved changes to {filepath}")
    else:
        print(f"No changes needed for {filepath}")

def main():
    files = [
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\README.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\unified_monograph.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\geometric_index_theorem.md"
    ]
    for filepath in files:
        if os.path.exists(filepath):
            convert_file(filepath)
        else:
            print(f"File not found: {filepath}")

if __name__ == '__main__':
    main()
