with open("docs/unified_monograph.md", "r", encoding="utf-8") as f:
    lines = f.readlines()
line = lines[949] # 950 is index 949
print("Line length:", len(line))
print("Line content:", repr(line))
for idx, char in enumerate(line):
    if char == '$':
        print(f"Char at index {idx}: {repr(line[max(0, idx-5):min(len(line), idx+6)])}")
