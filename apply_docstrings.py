import os

files_to_process = [
    'formalization/Formalization/CollatzRelMatrix.lean',
    'formalization/Formalization/SchreierSpectral.lean',
    'formalization/Formalization/SchreierConnectivity.lean',
    'formalization/Formalization/MathlibSpectral.lean'
]

for file_path in files_to_process:
    if not os.path.exists(file_path):
        print(f"Not found: {file_path}")
        continue
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    modified = False

    # Add header if missing
    if not content.strip().startswith('/-!'):
        import_lines = []
        rest_lines = []
        lines = content.split('\n')
        for i, line in enumerate(lines):
            if line.startswith('import '):
                import_lines.append(line)
            else:
                rest_lines = lines[i:]
                break
        
        header = "\n/-!\n# " + os.path.basename(file_path).split('.')[0] + "\n\nCore formalization for the Collatz Spectral Theorem.\n-/\n\n"
        content = '\n'.join(import_lines) + header + '\n'.join(rest_lines)
        modified = True

    # Add lint if missing
    if '#lint' not in content:
        content += "\n#lint\n"
        modified = True

    if modified:
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Updated {file_path}")

print("Docstring and linting pass completed.")
