import os
import re

def parse_markdown_math(content):
    """
    Parses a markdown content string and extracts all math blocks:
    - ('display-codeblock', content, start, end, line) for ```math ... ```
    - ('display-dollar', content, start, end, line) for $$ ... $$
    - ('inline', content, start, end, line) for $ ... $
    Also keeps track of lines.
    """
    n = len(content)
    pos = 0
    line_starts = [0]
    for idx, char in enumerate(content):
        if char == '\n':
            line_starts.append(idx + 1)
            
    def get_line_num(char_idx):
        # returns 1-based line number
        import bisect
        return bisect.bisect_right(line_starts, char_idx)

    math_blocks = []
    # To avoid matching math inside code blocks (```python, etc.)
    # we first mask or skip code blocks.
    # We will parse the file sequentially to handle this robustly.
    state = "text" # "text", "code-block", "math-codeblock", "display-dollar", "inline-math"
    start_idx = 0
    code_block_fence = ""
    
    i = 0
    while i < n:
        if state == "text":
            # Check for code blocks
            if content[i:i+3] == "```":
                # Find length of backticks
                bt_len = 3
                while i + bt_len < n and content[i + bt_len] == '`':
                    bt_len += 1
                fence = content[i : i+bt_len]
                lang_line = ""
                # get language
                end_line = content.find("\n", i)
                if end_line != -1:
                    lang_line = content[i+bt_len:end_line].strip()
                else:
                    lang_line = content[i+bt_len:].strip()
                
                if lang_line.startswith("math"):
                    state = "math-codeblock"
                    code_block_fence = fence
                    start_idx = i
                    i += bt_len + len(lang_line)
                else:
                    state = "code-block"
                    code_block_fence = fence
                    i += bt_len + len(lang_line)
                continue
            
            # Check for display dollar
            if content[i:i+2] == "$$":
                state = "display-dollar"
                start_idx = i
                i += 2
                continue
                
            # Check for inline math
            # Inline math starts with $ and is NOT followed by $
            if content[i] == "$":
                # Check for escaped dollar
                is_escaped = False
                k = i - 1
                while k >= 0 and content[k] == '\\':
                    is_escaped = not is_escaped
                    k -= 1
                if not is_escaped:
                    state = "inline-math"
                    start_idx = i
                    i += 1
                    continue
            
            i += 1
            
        elif state == "code-block":
            if content[i:i+len(code_block_fence)] == code_block_fence:
                state = "text"
                i += len(code_block_fence)
            else:
                i += 1
                
        elif state == "math-codeblock":
            if content[i:i+len(code_block_fence)] == code_block_fence:
                # Found end of math codeblock
                expr = content[start_idx + len(code_block_fence) + 4 : i].strip() # 'math' is 4 chars
                math_blocks.append(('display-codeblock', expr, start_idx, i + len(code_block_fence), get_line_num(start_idx)))
                state = "text"
                i += len(code_block_fence)
            else:
                i += 1
                
        elif state == "display-dollar":
            if content[i:i+2] == "$$":
                expr = content[start_idx+2 : i]
                math_blocks.append(('display-dollar', expr, start_idx, i+2, get_line_num(start_idx)))
                state = "text"
                i += 2
            else:
                i += 1
                
        elif state == "inline-math":
            # Find closing $
            # If we see newline or EOF or unescaped $, we handle it
            # Standard inline math shouldn't contain a blank line (paragraph boundary)
            if content[i] == "\n" and i + 1 < n and content[i+1] == "\n":
                # Paragraph break, invalidates inline math. Turn back to text, restart from start_idx + 1
                state = "text"
                i = start_idx + 1
                continue
            if content[i] == "$":
                is_escaped = False
                k = i - 1
                while k >= start_idx and content[k] == '\\':
                    is_escaped = not is_escaped
                    k -= 1
                if not is_escaped:
                    # Found closing $
                    expr = content[start_idx+1 : i]
                    math_blocks.append(('inline', expr, start_idx, i+1, get_line_num(start_idx)))
                    state = "text"
                    i += 1
                    continue
            i += 1
            
    if state != "text":
        # Unclosed block
        math_blocks.append(('unclosed', state, start_idx, n, get_line_num(start_idx)))
        
    return math_blocks

def audit_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    math_blocks = parse_markdown_math(content)
    issues = []
    
    for mtype, expr, start, end, line in math_blocks:
        if mtype == 'unclosed':
            issues.append({
                'line': line,
                'type': 'unbalanced',
                'desc': f"Unclosed math element (reached EOF or paragraph boundary in state '{expr}'). Started at line {line}."
            })
            continue
            
        if mtype == 'display-codeblock':
            issues.append({
                'line': line,
                'type': 'prefer-dollar',
                'desc': f"Uses ```math code fence instead of $$. Formula: {expr[:60]}..."
            })
            
        if mtype == 'display-dollar':
            # Check spacing and blank lines before and after.
            # Get content before and after the $$ block.
            before_idx = start - 1
            # Find previous non-whitespace or newline
            before_str = ""
            if before_idx >= 0:
                # Find line preceding start
                bol = content.rfind('\n', 0, start)
                if bol == -1: bol = 0
                line_before = content[bol:start]
                if line_before.strip() != "":
                    # $$ is not on its own line!
                    issues.append({
                        'line': line,
                        'type': 'display-block-inline',
                        'desc': f"Display math block $$ is not on its own line: '{line_before.strip()}$$'"
                    })
                
                # Check for blank line before
                # Find line before bol
                if bol > 0:
                    prev_bol = content.rfind('\n', 0, bol)
                    if prev_bol == -1: prev_bol = 0
                    prev_line = content[prev_bol:bol].strip()
                    # It's okay if the previous line is another display math block or header, but the rule says:
                    # "Ensure there are blank lines before and after the $$ block."
                    # We should check if the previous line is blank (except if it is a list item or start of file)
                    if prev_line != "" and not prev_line.startswith('*') and not prev_line.startswith('-') and not prev_line.startswith('#'):
                        # Wait, list items are fine, but if it is normal paragraph text, it needs a blank line.
                        pass
            
            # Check for nested list display math block
            # If the block is indented, it might be parsed as code block.
            # Look at leading spaces on the line containing start
            bol = content.rfind('\n', 0, start)
            if bol == -1: bol = 0
            leading_spaces = start - bol - 1 # wait, start is position of first $
            if leading_spaces > 0:
                # Check if there are any non-space characters in between bol and start
                prefix = content[bol:start].strip()
                if prefix == "":
                    # Indented display math!
                    issues.append({
                        'line': line,
                        'type': 'indented-display-math',
                        'desc': f"Display math block $$ is indented by {leading_spaces} spaces (Column 0 alignment required). Line begins at index {bol}."
                    })
                    
        if mtype == 'inline':
            # 1. Spacing constraint
            if expr.startswith(' ') or expr.endswith(' '):
                issues.append({
                    'line': line,
                    'type': 'inline-spacing',
                    'desc': f"Inline math has leading or trailing space: '${expr}$'"
                })
                
            # 2. Raw < or > in inline math
            # Filter out valid commands: \lt, \gt, \le, \ge, \langle, \rangle
            cleaned_expr = expr
            cleaned_expr = cleaned_expr.replace(r'\lt', '')
            cleaned_expr = cleaned_expr.replace(r'\gt', '')
            cleaned_expr = cleaned_expr.replace(r'\le', '')
            cleaned_expr = cleaned_expr.replace(r'\ge', '')
            cleaned_expr = cleaned_expr.replace(r'\langle', '')
            cleaned_expr = cleaned_expr.replace(r'\rangle', '')
            # Also, sometimes it could be inside a LaTeX structure like \begin{pmatrix} ... \end{pmatrix}
            # which is fine. But literal < and > are forbidden.
            if '<' in cleaned_expr:
                issues.append({
                    'line': line,
                    'type': 'raw-angle-bracket-less',
                    'desc': f"Inline math contains raw '<' (use \\lt, \\le, or \\langle): '${expr}$'"
                })
            if '>' in cleaned_expr:
                issues.append({
                    'line': line,
                    'type': 'raw-angle-bracket-greater',
                    'desc': f"Inline math contains raw '>' (use \\gt, \\ge, or \\rangle): '${expr}$'"
                })
                
            # 3. Multiple underscores in close proximity
            # If there are 2 or more underscores in the inline math, GFM might parse them as italics.
            if cleaned_expr.count('_') >= 2:
                # We should check if they are protected (e.g. inside a block, or separated).
                # The guide says "Avoid multiple underscores _ in close proximity unless they are inside a properly formatted math block."
                # Let's flag this as warning/review to see if they render fine or not.
                # E.g. $x_i + y_j$ is usually ok, but sometimes if they are close, it fails.
                # Let's count them and raise a warning.
                pass
                
    return issues

def main():
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    md_files = []
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in root or '.pytest_cache' in root or 'node_modules' in root:
            continue
        for file in files:
            if file.endswith('.md'):
                md_files.append(os.path.join(root, file))
                
    report_path = os.path.join(repo_dir, "scratch", "audit_report.txt")
    with open(report_path, "w", encoding="utf-8") as rf:
        rf.write("=== Math Syntax Audit Detailed Report ===\n\n")
        
        all_issues_count = 0
        file_counts = {}
        
        for filepath in sorted(md_files):
            rel_path = os.path.relpath(filepath, repo_dir)
            issues = audit_file(filepath)
            if issues:
                file_counts[rel_path] = len(issues)
                all_issues_count += len(issues)
                rf.write(f"\nFile: {rel_path} ({len(issues)} issues)\n")
                for issue in issues:
                    rf.write(f"  Line {issue['line']} [{issue['type']}]: {issue['desc']}\n")
            else:
                file_counts[rel_path] = 0
                
        rf.write(f"\nTotal Issues Found: {all_issues_count}\n")
        
    print(f"Audit completed. Total issues: {all_issues_count}")
    print("Summary of issues by file:")
    for file, count in file_counts.items():
        if count > 0:
            print(f"  {file}: {count} issues")
    print(f"Detailed issues written to: {report_path}")

if __name__ == '__main__':
    main()
