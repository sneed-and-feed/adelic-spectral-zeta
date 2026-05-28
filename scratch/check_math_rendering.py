import urllib.request
import json

test_cases = {
    "Bold paragraph + column 0 math block": r"""**1. For $B\omega$, since $B |1_0\rangle = B |1_1\rangle = \frac{1}{\sqrt{2}} |1\rangle$, we have:**

$$
B\omega = \frac{1}{2} ( |B 1_0\rangle \langle 1_1| + |B 1_1\rangle \langle 1_0| ) = \frac{1}{2} |1\rangle \langle 1|
$$""",
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
