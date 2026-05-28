import glob
print("Total scripts:", len(glob.glob('scripts/*.py')))
for f in glob.glob('scripts/*.py'):
    with open(f, 'r', encoding='utf-8') as file:
        content = file.read()
        if 'if __name__' not in content:
            print(f)
