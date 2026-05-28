import urllib.request
import sys

urls = [
    ('README', 'https://github.com/sneed-and-feed/adelic-spectral-zeta/blob/main/README.md'),
    ('Monograph', 'https://github.com/sneed-and-feed/adelic-spectral-zeta/blob/main/docs/unified_monograph.md'),
    ('Index Theorem', 'https://github.com/sneed-and-feed/adelic-spectral-zeta/blob/main/docs/geometric_index_theorem.md'),
    ('Appendix F Test', 'https://github.com/sneed-and-feed/adelic-spectral-zeta/blob/main/scratch/appendix_f_test.md'),
]

for name, url in urls:
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0 (Windows NT 10.0)'})
        resp = urllib.request.urlopen(req, timeout=30)
        html = resp.read().decode('utf-8', errors='replace')
        count = html.lower().count('unable to render')
        err_count = html.lower().count('math-render-error')
        sys.stdout.write(f'{name}: {len(html)} bytes, "unable to render": {count}, "math-render-error": {err_count}\n')
        sys.stdout.flush()
    except Exception as e:
        sys.stdout.write(f'{name}: ERROR - {e}\n')
        sys.stdout.flush()
