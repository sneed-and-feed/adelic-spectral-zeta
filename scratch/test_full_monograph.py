"""
Test the full monograph sections via GitHub's Markdown API to find any remaining issues.
Breaks the document into chunks and checks each one.
"""
import urllib.request
import json
import sys
import re
import time
from pathlib import Path


def strip_blockquote(line):
    s = line
    while s.lstrip().startswith('>'):
        s = s.lstrip()[1:]
        if s.startswith(' '):
            s = s[1:]
    return s


def extract_inline_math_lines(text):
    """Find all lines with inline $`...`$ math."""
    lines = text.split('\n')
    result = []
    in_fenced = False
    
    for i, line in enumerate(lines, 1):
        content = strip_blockquote(line).strip()
        if content.startswith('```'):
            in_fenced = not in_fenced
            continue
        if in_fenced:
            continue
        if '$`' in line:
            result.append((i, line))
    
    return result


def test_via_api(markdown_text, label=""):
    """Send markdown to GitHub API and check for errors."""
    payload = json.dumps({
        "text": markdown_text,
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
        
        math_count = html.count('math-renderer')
        error_count = html.count('math-render-error')
        em_count = html.count('<em>')
        
        return {
            'ok': error_count == 0,
            'math_count': math_count,
            'error_count': error_count,
            'em_count': em_count,
            'html_len': len(html),
        }
    except Exception as e:
        return {'ok': False, 'error': str(e)}


def main():
    filepath = Path('docs/unified_monograph.md')
    text = filepath.read_text(encoding='utf-8')
    
    # Get all lines with inline math
    math_lines = extract_inline_math_lines(text)
    print(f"Found {len(math_lines)} lines with inline math in {filepath.name}")
    
    # Test in batches of 20 lines
    batch_size = 20
    total_errors = 0
    total_tested = 0
    
    for batch_start in range(0, len(math_lines), batch_size):
        batch = math_lines[batch_start:batch_start + batch_size]
        batch_text = '\n\n'.join(line for _, line in batch)
        
        result = test_via_api(batch_text, f"batch {batch_start//batch_size + 1}")
        total_tested += len(batch)
        
        if result.get('error'):
            print(f"  Batch {batch_start//batch_size + 1}: API ERROR - {result['error']}")
            break
        
        if not result['ok']:
            total_errors += result['error_count']
            print(f"  Batch {batch_start//batch_size + 1} (lines {batch[0][0]}-{batch[-1][0]}): {result['error_count']} ERRORS")
            # Print individual failing lines
            for lineno, line in batch:
                individual = test_via_api(line)
                if individual.get('error_count', 0) > 0 or individual.get('em_count', 0) > 0:
                    print(f"    FAIL L{lineno}: {line[:100]}")
                time.sleep(0.1)
        else:
            status = f"OK ({result['math_count']} math)"
            if result['em_count'] > 0:
                status += f" WARNING: {result['em_count']} <em> tags"
            line_range = f"L{batch[0][0]}-{batch[-1][0]}"
            print(f"  Batch {batch_start//batch_size + 1} ({line_range}): {status}")
        
        time.sleep(0.2)  # Rate limiting
    
    print(f"\nTotal: {total_tested} lines tested, {total_errors} rendering errors")


if __name__ == '__main__':
    main()
