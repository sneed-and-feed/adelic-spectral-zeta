# Guide to Writing Math on GitHub (GFM) with KaTeX/MathJax

This guide documents the strict rules and edge cases for writing complex mathematical equations in GitHub-Flavored Markdown (GFM) to ensure they render correctly. These rules were learned through empirical trial and error with the GitHub Markdown API.

---

## 1. Inline Math Delimiters (`$...$`)

### Spacing Constraints
Inline math delimiters (`$`) **must** be tightly coupled to their content. There should be **no spaces** between the delimiter and the math expression.
*   **Correct (Renders)**: `$x$` or `$\sigma \in [0.1, 0.9]$`
*   **Incorrect (Fails)**: `$ x$` or `$x $` or `$ \sigma \in [0.1, 0.9] $`

### Character Mangling and Escaping
The GFM parser processes standard Markdown rules (like italics via `_` and HTML tags via `<` and `>`) **before** the math engine compiles. To prevent character mangling:
*   Avoid using raw `<` or `>` inside inline math. Instead, use `\lt`, `\gt`, `\le`, `\ge`.
*   Avoid multiple underscores `_` in close proximity unless they are inside a properly formatted math block.
*   For bra-ket notation, use `\langle` and `\rangle` instead of raw `<` and `>`.
    *   **Correct**: `$\langle 1_0, Bf \rangle$`
    *   **Incorrect**: `$<1_0, Bf>$`

---

## 2. Display Math Blocks (`$$ ... $$`)

Display math should be written on its own lines:
```markdown
$$
E = mc^2
$$
```

*   Ensure there are blank lines before and after the `$$` block.
*   Do not put spaces between the `$$` delimiters and the math if they are on the same line, e.g. `$$E = mc^2$$` is acceptable but `$$ E = mc^2 $$` is prone to parsing errors. Keeping them on separate lines is always preferred.

---

## 3. The List Item Rendering Conflict (Critical Edge Case)

### The Problem
If a Markdown list item (ordered or unordered) contains **inline math** in its header, and contains a **nested/indented display math block** (either `$$` or ```` ```math ````), the display math will **fail to render**, showing up instead as a raw text block or code box.
```markdown
*   **Example of what FAILS**:
    1. For $B\omega$, since ... we have:
       ```math
       B\omega = \frac{1}{2} |1\rangle \langle 1|
       ```
```
*Why this happens*: GFM parses the indentation as a standard code block first, preventing the math compiler from identifying and rendering the equation.

### The Solution: Bold Pseudo-Lists
To display lists with equations:
1.  Replace standard lists (`1.`, `2.`, etc.) with **bold pseudo-lists** (`- **1. ...**`).
2.  Align the display math block (`$$`) at **Column 0** (unindented).
3.  Add blank lines around the display block.

#### Correct Pattern:
```markdown
- **1. For $B\omega$, since $B |1_0\rangle = B |1_1\rangle = \frac{1}{\sqrt{2}} |1\rangle$, we have:**

$$
B\omega = \frac{1}{2} ( |B 1_0\rangle \langle 1_1| + |B 1_1\rangle \langle 1_0| ) = \frac{1}{2} |1\rangle \langle 1|
$$

- **2. For $\omega B$, the adjoint action maps...**
```

This formatting ensures the list header renders beautifully, and the math blocks are parsed at root level by the math engine without indentation conflicts.

---

## 4. Balancing Delimiters

A single unclosed `$` will cause the GFM parser to treat subsequent text (often up to the next paragraph or the end of the file) as inline math, resulting in corrupted formatting.
*   Always audit files for unmatched dollar signs.
*   Use automated parsing tools (like `scratch/check_all_docs_unbalanced.py`) to verify that the math parser state returns to `text` at the end of every line/paragraph.
