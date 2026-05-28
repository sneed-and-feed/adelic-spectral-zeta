import glob

for f in glob.glob('scripts/*.py'):
    with open(f, 'rb') as file:
        content = file.read()
    
    new_content = content.replace(b'\xef\xbb\xbf', b'')
    if new_content != content:
        print(f"Removed BOM from {f}")
        with open(f, 'wb') as file:
            file.write(new_content)
