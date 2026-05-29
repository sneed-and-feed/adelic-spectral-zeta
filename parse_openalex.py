import json, sys, glob

for filename in glob.glob('C:/Users/x/.gemini/antigravity/brain/3ec68051-c463-4e9a-acd6-79b59ccd6854/scratch/*.json'):
    print(f"\n--- {filename} ---")
    try:
        with open(filename, encoding='utf-16') as f:
            content = f.read()
            if not content.strip():
                continue
            data = json.loads(content).get('results', [])
            for item in data:
                title = item.get('display_name', '')
                if not title: continue
                title_lower = title.lower()
                if 'collatz' in title_lower or 'ihara' in title_lower or 'transfer' in title_lower or 'zeta' in title_lower:
                    print("ID:", item.get('id'))
                    print("Title:", title)
    except Exception as e:
        print("Error:", e)
