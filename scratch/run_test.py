import os

lines = open('docs/unified_monograph.md', encoding='utf-8').readlines()
appendix_f = lines[1447:]
with open('scratch/appendix_f_test.md', 'w', encoding='utf-8') as f:
    f.writelines(appendix_f)
    
print(f"Wrote {len(appendix_f)} lines to scratch/appendix_f_test.md")
print(f"File exists: {os.path.exists('scratch/appendix_f_test.md')}")
