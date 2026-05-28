import ast
import glob

def refactor_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        source = f.read()

    if 'if __name__ == "__main__":' in source or 'if __name__ == "__main__":' in source.replace("'", '"'):
        return

    try:
        tree = ast.parse(source)
    except SyntaxError:
        print(f"Syntax error in {filepath}")
        return

    lines = source.splitlines()

    main_start_line = None
    for node in tree.body:
        if isinstance(node, (ast.Import, ast.ImportFrom, ast.FunctionDef, ast.AsyncFunctionDef, ast.ClassDef)):
            continue
        if isinstance(node, ast.Expr) and isinstance(node.value, ast.Constant):
            continue
        
        main_start_line = node.lineno - 1
        break

    if main_start_line is None:
        return

    # Back up past empty lines
    while main_start_line > 0 and lines[main_start_line-1].strip() == '':
        main_start_line -= 1

    final_lines = lines[:main_start_line]
    final_lines.append('')
    final_lines.append('def main():')
    
    for line in lines[main_start_line:]:
        if line.strip() == '':
            final_lines.append('')
        else:
            final_lines.append('    ' + line)

    final_lines.append('')
    final_lines.append('if __name__ == "__main__":')
    final_lines.append('    main()')

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write('\n'.join(final_lines) + '\n')
    
    print(f"Wrapped {filepath} in main()")

def main():
    exp_files = glob.glob('experiments/*.py')
    for f in exp_files:
        refactor_file(f)

if __name__ == "__main__":
    main()
