def main():
    filepath = "docs/unified_monograph.md"
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
                print(f"Potential unclosed inline_simple starting at line {history[-1][1]}, col {history[-1][2]}:")
                snippet = content[start_pos:min(n, start_pos+200)].replace('\n', ' ')
                print(f"  Snippet: {snippet}")
                print("-" * 50)
                # Reset to text to continue parsing other potential errors
                state = "text"
                i += 1
                continue
            else:
                i += 1
                continue

    if state != "text":
        last = history[-1]
        print(f"EOF reached but state is still {state}, started at line {last[1]}, col {last[2]}")

if __name__ == "__main__":
    main()
