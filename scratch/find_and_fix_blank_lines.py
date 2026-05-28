import re
import os

files = [
    r"docs/collatz_gauge_geometry.md",
    r"docs/commutator_rank_kernel_note.md",
    r"docs/monograph/05_artin_l_functions_rigidity.md"
]

repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"

def analyze_and_fix(filepath):
    print(f"\nAnalyzing: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    modified = False
    new_lines = []
    
    # We want to find any line that is indented and starts with $$ or ```math
    # and check if the previous line is blank (contains only whitespace or is empty)
    i = 0
    while i < len(lines):
        line = lines[i]
        # Check if line matches indented $$ or ```math
        # Match spaces/tabs followed by $$ or ```math, then spaces/tabs or end of line.
        match_math = re.match(r'^([ \t]+)(\$\$|```math)(?:\s|$)', line)
        if match_math:
            indent = match_math.group(1)
            delimiter = match_math.group(2)
            
            # Check the previous line
            if i > 0:
                prev_line = new_lines[-1]
                if prev_line.strip() != "":
                    # Previous line is NOT blank! This is the rendering bug!
                    print(f"  Line {i+1}: Found indented {delimiter} without preceding blank line.")
                    print(f"    Prev line: {repr(prev_line)}")
                    print(f"    Math line: {repr(line)}")
                    # Insert a blank line with the same indentation (or just a newline)
                    new_lines.append(f"{indent}\n")
                    modified = True
        
        new_lines.append(line)
        i += 1
        
    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.writelines(new_lines)
        print(f"  SUCCESS: Fixed preceding blank lines in {filepath}")
    else:
        print("  No issues found.")

for f in files:
    full_path = os.path.join(repo_dir, f)
    if os.path.exists(full_path):
        analyze_and_fix(full_path)
    else:
        print(f"File not found: {full_path}")
