with open('scratch/audit_report.txt', 'r', encoding='utf-8') as f:
    content = f.read()

lines = content.split('\n')
print("=== Matches ===")
for i, line in enumerate(lines):
    if 'unclosed' in line.lower():
        print(f"Line {i}: {line}")
