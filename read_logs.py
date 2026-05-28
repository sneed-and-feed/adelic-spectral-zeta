import json

def print_transcript(path):
    print(f'--- Transcript: {path} ---')
    try:
        with open(path, 'r', encoding='utf-8') as f:
            lines = f.readlines()
        
        for line in lines[-30:]:
            data = json.loads(line)
            if data.get('type') in ['USER_INPUT', 'PLANNER_RESPONSE', 'MODEL_RESPONSE', 'SYSTEM_MESSAGE', 'TOOL_CALL', 'TOOL_RESPONSE']:
                content = data.get('content', '')
                if content:
                    print(f"[{data.get('type')}] {content[:1000]}")
                elif data.get('type') == 'TOOL_CALL':
                    print(f"[{data.get('type')}] {str(data)[:100]}")
    except Exception as e:
        print('Error:', e)

print_transcript(r'C:\Users\x\.gemini\antigravity\brain\424792a9-0cee-49ed-98ec-49eb81499eda\.system_generated\logs\transcript.jsonl')
print_transcript(r'C:\Users\x\.gemini\antigravity\brain\cb8601b2-e8e8-4929-8bd7-92ef07361f1b\.system_generated\logs\transcript.jsonl')
