import os
import re

def check_file(filepath):
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    n = len(content)
    i = 0
    state = "text"  # can be: text, display, inline_backtick, inline_simple
    start_pos = 0
    line = 1
    col = 1
    
    # Track position history for debugging
    history = []
    errors = []

    while i < n:
        char = content[i]
        
        # Keep track of line/col
        if char == '\n':
            line += 1
            col = 1
        else:
            col += 1

        # Check for state transitions
        if state == "text":
            if content[i:i+2] == "$$":
                state = "display"
                start_pos = i
                history.append((state, line, col, i))
                i += 2
                continue
            elif content[i:i+2] == "$`":
                state = "inline_backtick"
                start_pos = i
                history.append((state, line, col, i))
                i += 2
                continue
            elif char == "$":
                state = "inline_simple"
                start_pos = i
                history.append((state, line, col, i))
                i += 1
                continue
            else:
                i += 1
                continue

        elif state == "display":
            if content[i:i+2] == "$$":
                state = "text"
                i += 2
                continue
            else:
                i += 1
                continue

        elif state == "inline_backtick":
            if content[i:i+2] == "`$":
                state = "text"
                i += 2
                continue
            else:
                i += 1
                continue

        elif state == "inline_simple":
            if char == "$":
                # Found closing $
                state = "text"
                i += 1
                continue
            elif char == "\n" and (i - start_pos > 100 or "\n\n" in content[start_pos:i]):
                # If we encounter a paragraph break or it spans too long, it's likely an unclosed math block
                snippet = content[start_pos:min(n, start_pos+80)].replace('\n', ' ')
                errors.append((history[-1][1], history[-1][2], snippet))
                # Reset to text to continue parsing other potential errors
                state = "text"
                i += 1
                continue
            else:
                i += 1
                continue

    if state != "text":
        last = history[-1]
        errors.append((last[1], last[2], f"EOF reached while in {state}"))

    return errors

if __name__ == "__main__":
    docs = [
        "docs/collatz_gauge_geometry.md",
        "docs/commutator_rank_kernel_note.md",
        "docs/monograph/05_artin_l_functions_rigidity.md"
    ]
    for doc in docs:
        if os.path.exists(doc):
            print(f"=== Checking {doc} ===")
            errs = check_file(doc)
            if errs:
                for line, col, snip in errs:
                    print(f"  Line {line}, Col {col}: {snip}")
            else:
                print("  No issues found!")
        else:
            print(f"File not found: {doc}")
