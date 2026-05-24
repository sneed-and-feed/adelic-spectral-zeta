import re

def main():
    filepath = "docs/unified_monograph.md"
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    print("$$ count:", content.count("$$"))
    print("$` count:", content.count("$`"))
    print("`$ count:", content.count("`$"))

    # Find single dollar signs that are not part of $$ or $` or `$
    # A single dollar sign must not have a $ or ` immediately before or after it.
    single_dollars = []
    for m in re.finditer(r"\$", content):
        start = m.start()
        # check left
        left_char = content[start-1] if start > 0 else ""
        # check right
        right_char = content[start+1] if start + 1 < len(content) else ""
        if left_char not in ("$", "`") and right_char not in ("$", "`"):
            single_dollars.append(start)

    print("Count of single $ (not part of $$ or $` or `$):", len(single_dollars))
    for pos in single_dollars:
        line_num = content[:pos].count("\n") + 1
        start_pos = max(0, pos - 50)
        end_pos = min(len(content), pos + 50)
        context = content[start_pos:end_pos].replace("\n", " ")
        print(f"Line {line_num} (char {pos}): ... {context} ...")

if __name__ == "__main__":
    main()
