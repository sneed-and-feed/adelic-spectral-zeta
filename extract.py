import re

def parse(infile, outfile):
    with open(infile, 'rb') as f:
        b = f.read()
    text = b.decode('utf-16', errors='ignore')
    if '{' not in text:
        text = b.decode('utf-8', errors='ignore')
    
    with open(outfile, 'w', encoding='utf-8') as f:
        m = re.search(r'"display_name":\s*"([^"]+)"', text)
        if m: f.write("Title: " + m.group(1) + "\n")
        
        m_abs = re.search(r'"abstract_inverted_index":\s*(\{.*?\})\s*,\s*"', text, re.DOTALL)
        if m_abs:
            import json
            try:
                inv = json.loads(m_abs.group(1))
                words = {}
                for word, positions in inv.items():
                    for pos in positions: words[pos] = word
                abstract = ' '.join(words.get(i, '?') for i in range(max(words.keys())+1))
                f.write("Abstract: " + abstract + "\n")
            except Exception as e:
                pass
        else:
            f.write("No abstract.\n")

parse('C:/Users/x/.gemini/antigravity/brain/3ec68051-c463-4e9a-acd6-79b59ccd6854/scratch/work2.json', 'C:/Users/x/.gemini/antigravity/brain/3ec68051-c463-4e9a-acd6-79b59ccd6854/scratch/pyout2.txt')
