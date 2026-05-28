import re

def main():
    filepath = "docs/unified_monograph.md"
    with open(filepath, "r", encoding="utf-8") as f:
        content = f.read()

    # Search for occurrences of $L$-function or $L$
    # let's look for $L$-
    matches = re.finditer(r"\$L\-", content)
    for m in matches:
        start = m.start()
        line = content[:start].count("\n") + 1
        print(f"Line {line}: {content[max(0, start-20):min(len(content), start+30)]}")

if __name__ == "__main__":
    main()
