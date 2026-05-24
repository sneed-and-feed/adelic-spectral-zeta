import json
from pathlib import Path
import re

log_path = Path(r'C:\Users\x\.gemini\antigravity\brain\3f4766bf-0ca2-489a-a945-6a2ea942ab89\.system_generated\logs\transcript.jsonl')
if not log_path.exists():
    print(f"Log path does not exist: {log_path}")
    sys.exit(1)

with open(log_path, 'r', encoding='utf-8') as f:
    lines = f.readlines()

print(f"Total lines: {len(lines)}")
keywords = ['bughunting', 'innovation', 'rendering error', 'mathjax', 'unable to render']

for i, line in enumerate(lines):
    try:
        data = json.loads(line)
        content = data.get('content') or ""
        # Check if content has any of the keywords
        matched = [kw for kw in keywords if kw.lower() in content.lower()]
        if matched:
            print(f"Line {i} (Step {data.get('step_index')}): matched {matched}")
            # print surrounding lines if it is USER_INPUT or PLANNER_RESPONSE
            if data.get('type') in ('USER_INPUT', 'PLANNER_RESPONSE'):
                print(f"  Type: {data.get('type')}")
                print(f"  Content: {content[:300]}...\n")
    except Exception as e:
        pass
