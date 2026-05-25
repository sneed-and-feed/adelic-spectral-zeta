import json
import os

log_path = r'C:\Users\x\.gemini\antigravity\brain\ebfa942e-cc2c-459d-ab42-24e429b6274d\.system_generated\logs\transcript.jsonl'
out_path = r'C:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\model_msgs.txt'

msgs = []
with open(log_path, 'r', encoding='utf-8') as f:
    for line in f:
        try:
            data = json.loads(line)
            if data.get('source') == 'MODEL' and data.get('content'):
                content = data.get('content')
                if '<EPHEMERAL_MESSAGE>' not in content:
                    msgs.append(content)
        except:
            pass

with open(out_path, 'w', encoding='utf-8') as out:
    for m in msgs[-10:]:
        out.write('='*80 + '\n')
        out.write(m + '\n')
print('Extracted!')
