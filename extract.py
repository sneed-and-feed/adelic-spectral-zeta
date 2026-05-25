import json

log_path = r'C:\Users\x\.gemini\antigravity\brain\ebfa942e-cc2c-459d-ab42-24e429b6274d\.system_generated\logs\transcript.jsonl'
out_path = r'C:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\battle_plan.txt'

with open(log_path, 'r', encoding='utf-8') as f, open(out_path, 'w', encoding='utf-8') as out:
    for line in f:
        if 'battle plan for' in line or 'reindexing trap' in line:
            try:
                data = json.loads(line)
                if data.get('type') == 'USER_INPUT':
                    out.write(data.get('content', ''))
                    out.write('\n' + '='*80 + '\n')
            except Exception as e:
                out.write(f'Error parsing line: {e}\n')
print('Script finished executing!')
