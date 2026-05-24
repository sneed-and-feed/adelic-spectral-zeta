import json
from pathlib import Path

log_path = Path(r'C:\Users\x\.gemini\antigravity\brain\3f4766bf-0ca2-489a-a945-6a2ea942ab89\.system_generated\logs\transcript.jsonl')
if not log_path.exists():
    print(f"Log path does not exist: {log_path}")
    sys.exit(1)

with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
# Print details of lines from 1200 to 1278
for i in range(1200, 1278):
    if i >= len(lines):
        break
    try:
        data = json.loads(lines[i])
        print(f"Step {data.get('step_index')}: type={data.get('type')}, source={data.get('source')}, status={data.get('status')}")
        if data.get('type') == 'USER_INPUT':
            print(f"  User says: {data.get('content')}")
        elif data.get('type') == 'PLANNER_RESPONSE':
            content = data.get('content') or ""
            print(f"  Model says: {content[:200]}...")
    except Exception as e:
        print(f"  Error: {e}")
