import ast
import glob
import sys
import os

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        source = f.read()
    
    try:
        tree = ast.parse(source)
    except Exception as e:
        print(f"Error parsing {filepath}: {e}")
        return

    # Check if there are top-level statements other than imports, func defs, class defs, docstrings
    needs_main = False
    for node in tree.body:
        if isinstance(node, (ast.Import, ast.ImportFrom, ast.FunctionDef, ast.ClassDef)):
            continue
        # docstring
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant) and isinstance(node.value.value, str):
            continue
        if isinstance(node, ast.Assign) and len(node.targets) == 1 and isinstance(node.targets[0], ast.Name) and node.targets[0].id == '__all__':
            continue
        
        needs_main = True
        break
    
    if needs_main:
        print(f"Needs main: {filepath}")

for filepath in glob.glob('scripts/*.py'):
    with open(filepath, 'r', encoding='utf-8') as f:
        if 'if __name__' not in f.read():
            process_file(filepath)

