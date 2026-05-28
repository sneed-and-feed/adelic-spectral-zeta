import os, glob

def process_script(path):
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    changed = False
    name = os.path.basename(path)

    if not content.startswith('"""') and not content.startswith("'''"):
        docstring = f'"""\nUtility script: {name}\n'
        if name.startswith('golf_'):
            docstring += 'Note: "golf" in this context refers to Lean proof golfing (shortening formal proofs).\n'
        docstring += '"""\n'
        content = docstring + content
        changed = True

    # Simple attempt to wrap module-level code in main.
    # If there's an 'if __name__ == '__main__':' it's fine.
    # Otherwise, if it has a lot of module level code without it, we might need manual fix.
    if changed:
        with open(path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed docstring in {path}')

for f in glob.glob('scripts/*.py'):
    process_script(f)
