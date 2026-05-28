import urllib.request
import json

test_cases = [
    r"$`J`$",
    r"$`\sigma \in (-1/2, 3/2)`$",
    r"$`\xi_n`$",
    r"$`\text{Dom}(D_{\text{sym}})`$",
    r"$`\sum_{n \neq 0} \frac{|\xi_n|^2}{\lambda_n^2} < \infty`$",
    r"$`\xi_n = \mathcal{O}(\ln|n|)`$",
    r"$`\phi_z \in \ell^2(\mathbb{Z})`$",
    r"$`\lambda_n \sim n`$",
    r"$`\delta_n = \mathcal{O}(\ln^2|n|/|n|)`$",
    r"$`B = 0`$",
    r"$`b=0`$",
    r"$`\Lambda(z)`$",
    r"$`O(t^{1/4+\epsilon})`$",
    r"$`t^{1/3+\epsilon}`$"
]

for idx, md in enumerate(test_cases):
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
        print(f"CASE {idx}: {md}")
        print(html.strip())
        print("-" * 50)
    except Exception as e:
        print(f"CASE {idx} FAILED: {e}")
