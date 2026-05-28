"""
Test multiple problematic patterns via GitHub's Markdown API.
"""
import urllib.request
import json
import sys
import re

test_cases = {
    "Table with double vertical bar in math": r"""| Column 1 | Column 2 |
| --- | --- |
| Row 1 | $`\|\xi_n\|^2`$ |
| Row 2 | $`\Vert\xi_n\Vert^2`$ |"""
}

for name, md in test_cases.items():
    payload = json.dumps({
        "text": md,
        "mode": "gfm",
        "context": "sneed-and-feed/adelic-spectral-zeta"
    }).encode('utf-8')
    
    req = urllib.request.Request(
        'https://api.github.com/markdown',
        data=payload,
        headers={
            'Content-Type': 'application/json',
            'Accept': 'application/vnd.github+json',
            'User-Agent': 'Mozilla/5.0'
        }
    )
    
    try:
        resp = urllib.request.urlopen(req, timeout=30)
        html = resp.read().decode('utf-8')
        print(f"=== {name} ===")
        print(html.strip())
        print("================\n")
    except Exception as e:
        print(f"ERROR | {name}: {e}")

