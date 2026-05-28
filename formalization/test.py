import subprocess
import sys
result = subprocess.run(['lake', 'env', 'lean', 'fix_charpoly.lean'], capture_output=True, text=True)
if result.returncode != 0:
    print(result.stderr)
    sys.exit(1)
print('SUCCESS')
