import glob

for f in glob.glob('scripts/*.py'):
    with open(f, 'r', encoding='utf-8') as file:
        lines = file.readlines()
    
    new_lines = []
    for line in lines:
        if 'sys.path.append' in line or 'sys.path.insert' in line:
            print(f"Removing {line.strip()} from {f}")
            continue
        new_lines.append(line)
        
    if len(new_lines) != len(lines):
        with open(f, 'w', encoding='utf-8') as file:
            file.writelines(new_lines)
