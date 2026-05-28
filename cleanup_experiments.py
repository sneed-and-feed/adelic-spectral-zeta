import os
import glob

def cleanup_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    lines = content.splitlines()
    if not lines:
        return

    modified = False

    # 1. Remove sys.path hack
    new_lines = []
    for line in lines:
        if 'sys.path.append' in line and '__file__' in line:
            modified = True
            continue
        new_lines.append(line)
    lines = new_lines

    # 2. Add module docstring if missing
    if not lines[0].startswith('"""') and not lines[0].startswith("'''"):
        lines.insert(0, '"""')
        lines.insert(1, f"Adelic Spectral Zeta: {os.path.basename(filepath)}")
        lines.insert(2, '"""')
        lines.insert(3, '')
        modified = True

    # 3. Fix bare excepts
    for i, line in enumerate(lines):
        if 'except:' in line:
            lines[i] = line.replace('except:', 'except Exception:')
            modified = True

    if modified:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write('\n'.join(lines) + '\n')
        print(f"Cleaned up {filepath}")

if __name__ == "__main__":
    exp_files = glob.glob('experiments/*.py')
    for f in exp_files:
        cleanup_file(f)
