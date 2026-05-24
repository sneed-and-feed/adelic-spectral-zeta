import re

def process_file(filepath):
    print(f"Processing: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()

    # We will tokenize the content to avoid modifying code blocks
    # Code blocks start with ``` and end with ```
    parts = re.split(r'(```[\s\S]*?```)', content)
    
    for i in range(len(parts)):
        # If it's a code block, skip it
        if parts[i].startswith('```'):
            continue
            
        # Parse display math blocks $$ ... $$ to protect them
        # We will split by $$
        subparts = re.split(r'(\$\{[\s\S]*?\}|\$\$[\s\S]*?\$\$)', parts[i])
        for j in range(len(subparts)):
            if subparts[j].startswith('$$'):
                # This is display math. We fix t_n^* / t_k^* subscripts here
                eq = subparts[j]
                # Replace t_n^* and t_k^* with braces: {t_n}^* and {t_k}^*
                # (but avoid double wrapping)
                eq = re.sub(r'(?<!\{)t_n\^\*', r'{t_n}^*', eq)
                eq = re.sub(r'(?<!\{)t_k\^\*', r'{t_k}^*', eq)
                subparts[j] = eq
                continue
            
            # Now, for standard text, we find inline math $ ... $
            # We want to match $...$ but NOT $$
            # Let's use a character-by-character scan for inline math blocks
            text = subparts[j]
            new_text = []
            k = 0
            n = len(text)
            while k < n:
                if text[k] == '$':
                    # Check if it is $$
                    if k + 1 < n and text[k+1] == '$':
                        new_text.append('$$')
                        k += 2
                        continue
                    
                    # Check if it's already protected: $`...`$
                    if k + 1 < n and text[k+1] == '`':
                        # Find the closing `$
                        # Wait, let's scan forward to find `$`
                        match_end = text.find('`$', k + 2)
                        if match_end != -1:
                            # Already protected, keep it as is
                            # But apply the t_n^* / t_k^* replacement inside
                            math_content = text[k+2:match_end]
                            math_content = re.sub(r'(?<!\{)t_n\^\*', r'{t_n}^*', math_content)
                            math_content = re.sub(r'(?<!\{)t_k\^\*', r'{t_k}^*', math_content)
                            new_text.append(f"$`{math_content}`$")
                            k = match_end + 2
                            continue
                    
                    # Otherwise, find the closing $
                    # The closing $ must be on the same line, or we look for the next $
                    # GFM inline math cannot span empty lines
                    end_idx = -1
                    for scan in range(k + 1, n):
                        if text[scan] == '\n' and (scan + 1 < n and text[scan+1] == '\n'):
                            # Encountered blank line, abort inline math matching
                            break
                        if text[scan] == '$':
                            # Found potential closing $
                            # Ensure it's not escaped
                            if text[scan-1] != '\\':
                                end_idx = scan
                                break
                    
                    if end_idx != -1:
                        math_content = text[k+1:end_idx]
                        # Apply the t_n^* / t_k^* replacement inside
                        math_content = re.sub(r'(?<!\{)t_n\^\*', r'{t_n}^*', math_content)
                        math_content = re.sub(r'(?<!\{)t_k\^\*', r'{t_k}^*', math_content)
                        
                        # Decide if we need to wrap it in backticks.
                        # We wrap if it contains: _, *, \, {, }
                        needs_wrap = any(char in math_content for char in ['_', '*', '\\', '{', '}'])
                        if needs_wrap:
                            new_text.append(f"$`{math_content}`$")
                        else:
                            new_text.append(f"${math_content}$")
                        k = end_idx + 1
                    else:
                        new_text.append('$')
                        k += 1
                else:
                    new_text.append(text[k])
                    k += 1
            
            subparts[j] = "".join(new_text)
            
        parts[i] = "".join(subparts)
        
    new_content = "".join(parts)
    
    # Save the file
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(new_content)
    print("Done!")

if __name__ == '__main__':
    process_file("docs/unified_monograph.md")
    process_file("docs/geometric_index_theorem.md")
