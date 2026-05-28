import ast
import glob
import sys
import os

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    with open(filepath, 'r', encoding='utf-8') as f:
        source = f.read()

    try:
        tree = ast.parse(source)
    except Exception as e:
        print(f"Error parsing {filepath}: {e}")
        return

    # Find the first node that is not import, functiondef, classdef, or docstring
    first_exec_line = -1
    for node in tree.body:
        if isinstance(node, (ast.Import, ast.ImportFrom, ast.FunctionDef, ast.ClassDef)):
            continue
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
            continue
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name) and node.targets[0].id == '__all__':
            continue
        
        first_exec_line = node.lineno - 1
        break

    if first_exec_line == -1:
        # Check if already has __main__ guard
        if 'if __name__ ==' in source or 'if __name__==' in source:
            return
        # If no exec line but also no main guard? Usually means it's just library file.
        return

    print(f"Wrapping {filepath} starting from line {first_exec_line + 1}")
    
    out_lines = lines[:first_exec_line]
    out_lines.append('def main() -> None:\n')
    
    for line in lines[first_exec_line:]:
        if line.strip() == '':
            out_lines.append(line)
        else:
            out_lines.append('    ' + line)
            
    out_lines.append('\nif __name__ == "__main__":\n    main()\n')
    
    with open(filepath, 'w', encoding='utf-8') as f:
        f.writelines(out_lines)

for filepath in glob.glob('scripts/*.py'):
    process_file(filepath)
