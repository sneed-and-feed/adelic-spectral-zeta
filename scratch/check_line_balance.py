def main():
    filepath = "docs/unified_monograph.md"
    with open(filepath, "r", encoding="utf-8") as f:
        lines = f.readlines()

    in_display_math = False
    for idx, line in enumerate(lines):
        line_num = idx + 1
        stripped = line.strip()

        # Check if this is a display math block boundary
        if stripped == "$$":
            in_display_math = not in_display_math
            continue

        if in_display_math:
            # We are inside a display math block, don't parse inline math
            continue

        # Count inline math delimiters on this line
        # We need to count occurrences of $` and `$ and single $
        # Let's count backticked inline delimiters first
        backticked_count = line.count("$` ") + line.count(" $`") + line.count("$`` ") # check various spacings
        # To be precise, let's find all occurrences of $` and `$
        open_bt = line.count("$`")
        close_bt = line.count("`$")
        
        # If the backticked inline delimiters are unbalanced on the same line
        if open_bt != close_bt:
            print(f"Line {line_num}: Unbalanced backticked inline delimiters (open $`: {open_bt}, close `$ : {close_bt})")
            print(f"  Content: {repr(line)}")
            print("-" * 50)
            
        # Strip backticked math from the line to count simple $ signs
        # Replace $`...`$ with empty string
        # Let's use a regex to remove $`...`$
        import re
        line_no_bt = re.sub(r'\$`[\s\S]*?`\$', '', line)
        
        # Now count remaining dollar signs (which should be simple $...$ inline math)
        dollar_count = line_no_bt.count("$")
        
        # If the number of dollar signs is odd, they are unbalanced!
        if dollar_count % 2 != 0:
            print(f"Line {line_num}: Odd number of single dollar signs ({dollar_count})")
            print(f"  Content: {repr(line)}")
            print("-" * 50)

if __name__ == "__main__":
    main()
