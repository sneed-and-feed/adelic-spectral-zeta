with open("docs/unified_monograph.md", "r", encoding="utf-8") as f:
    lines = f.readlines()
for idx in range(940, 985):
    if idx < len(lines):
        print(f"{idx+1}: {repr(lines[idx])}")
