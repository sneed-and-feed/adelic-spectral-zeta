import re
import os

def convert_text_part(text):
    # First, convert display math blocks: $$ ... $$ to ```math ... ```
    # Match non-overlapping $$ blocks
    # We strip the contents so that it fits nicely inside the ```math ... ``` codeblock
    text = re.sub(r'\$\$([\s\S]*?)\$\$', lambda m: f"```math\n{m.group(1).strip()}\n```", text)
    
    # Now parse inline math character-by-character
    result = []
    k = 0
    n = len(text)
    while k < n:
        # Check for \$ (escaped dollar sign)
        if text[k] == '\\' and k + 1 < n and text[k+1] == '$':
            result.append('\\$')
            k += 2
            continue
        
        if text[k] == '$':
            # Check if it's already a backticked inline block:
            # It could start with $` or $`` or $```
            if k + 1 < n and text[k+1] == '`':
                # Find how many backticks
                bt_count = 0
                while k + 1 + bt_count < n and text[k + 1 + bt_count] == '`':
                    bt_count += 1
                
                # Find the closing sequence: bt_count backticks followed by $
                closing_seq = '`' * bt_count + '$'
                match_end = text.find(closing_seq, k + 1 + bt_count)
                if match_end != -1:
                    # It is already backticked! Extract math content
                    math_content = text[k + 1 + bt_count : match_end].strip()
                    # Rewrite as clean single-backtick inline math: $`math_content`$
                    result.append(f"$`{math_content}`$")
                    k = match_end + len(closing_seq)
                    continue
            
            # Otherwise, this is a standard $ delimiter.
            # Scan forward for the closing $ on the same line/paragraph
            # GFM inline math does not cross paragraph boundary (\n\n)
            end_idx = -1
            for scan in range(k + 1, n):
                # If we see \$ (escaped dollar), skip the dollar so we don't treat it as closing
                if text[scan] == '\\' and scan + 1 < n and text[scan+1] == '$':
                    continue
                if text[scan] == '\n' and scan + 1 < n and text[scan+1] == '\n':
                    # Paragraph break, stop scanning
                    break
                if text[scan] == '$':
                    # Check if it's not escaped
                    if text[scan-1] != '\\':
                        end_idx = scan
                        break
            
            if end_idx != -1:
                math_content = text[k+1:end_idx].strip()
                # Convert standard $math$ to $`math`$
                result.append(f"$`{math_content}`$")
                k = end_idx + 1
            else:
                # Unmatched $, keep it
                result.append('$')
                k += 1
        else:
            result.append(text[k])
            k += 1
            
    return "".join(result)

def convert_file(filepath):
    print(f"Converting: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # We want to tokenize the content to avoid modifying code blocks
    # Code blocks start with ``` and end with ```
    parts = re.split(r'(```[\s\S]*?```)', content)
    
    modified = False
    for i in range(len(parts)):
        # If it's a code block, check if it's a ```math block that needs cleanup
        # otherwise skip other code blocks (python, bash, mermaid, etc.)
        if parts[i].startswith('```'):
            if parts[i].startswith('```math'):
                # We can normalize ```math blocks to be trimmed
                inner = parts[i][7:-3].strip()
                new_block = f"```math\n{inner}\n```"
                if parts[i] != new_block:
                    parts[i] = new_block
                    modified = True
            continue
            
        new_part = convert_text_part(parts[i])
        if parts[i] != new_part:
            parts[i] = new_part
            modified = True
            
    if modified:
        new_content = "".join(parts)
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Saved successfully: {filepath}")
    else:
        print(f"No changes made to: {filepath}")

def main():
    files = [
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\README.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\unified_monograph.md",
        r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\docs\geometric_index_theorem.md"
    ]
    for filepath in files:
        if os.path.exists(filepath):
            convert_file(filepath)
        else:
            print(f"File not found: {filepath}")

if __name__ == '__main__':
    main()
