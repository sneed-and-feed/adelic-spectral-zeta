import os
import re

def convert_text(text):
    # Pattern to find $`content`$. We use [\s\S]*? to match across newlines if any,
    # but usually it's single line. We make sure the inner content does not contain ` or $.
    # Standard replacement: $`...`$ -> $...$
    pattern = r'\$`([^`$]+)`\$'
    
    # Let's perform a recursive replacement or check if there are multiple occurrences.
    # The regex ensures that the content inside backticks does not contain backticks or dollars.
    return re.sub(pattern, r'$\1', text)

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Split content by fenced code blocks to avoid modifying anything inside them.
    # Fenced blocks start with three or more backticks (or tildes), but usually ``` is used.
    # Let's support ``` or ```` blocks.
    # Split using re.split with a capture group so the blocks are preserved in the list.
    parts = re.split(r'(```[\s\S]*?```|````[\s\S]*?````)', content)
    
    changed = False
    new_parts = []
    
    for part in parts:
        if part.startswith('```') or part.startswith('````'):
            # This is a fenced code block, keep it as is
            new_parts.append(part)
        else:
            # This is normal prose, convert inline math
            converted = convert_text(part)
            if converted != part:
                changed = True
            new_parts.append(converted)
            
    if changed:
        new_content = "".join(new_parts)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"CONVERTED: {filepath}")
        return True
    else:
        print(f"NO CHANGE: {filepath}")
        return False

def main():
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    md_files = []
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in root or '.pytest_cache' in root or 'node_modules' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                md_files.append(os.path.join(root, file))
                
    converted_count = 0
    for filepath in md_files:
        # Avoid self conversion or files we shouldn't touch (but we can touch all markdown files)
        if process_file(filepath):
            converted_count += 1
            
    print(f"\nTotal files converted: {converted_count}")

if __name__ == '__main__':
    main()
