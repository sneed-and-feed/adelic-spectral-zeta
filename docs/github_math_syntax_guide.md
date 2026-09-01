# Guide to Writing Math on GitHub (GFM) with KaTeX/MathJax

This guide documents the strict rules, edge cases, and best practices for writing complex mathematical equations, tables, and typography in GitHub-Flavored Markdown (GFM) to ensure 100% compliant KaTeX/MathJax rendering. These rules were learned through empirical trial and error with the GitHub Markdown API and CommonMark parsers.

---

## 1. Inline Math Delimiters (`$...$`)

### Spacing Constraints
Inline math delimiters (`$`) **must** be tightly coupled to their content. There should be **no spaces** between the delimiter and the math expression.
*   **Correct (Renders)**: `$x$` or `$\sigma \in [0.1, 0.9]$`
*   **Incorrect (Fails)**: `$ x$` or `$x $` or `$ \sigma \in [0.1, 0.9] $`

### Prohibition Against Backtick Math (`$` `...` `$`) and Mixed Delimiters
Never use backtick-enclosed math delimiters (`$` `code` `$`).
*   **The Problem**: Mixing backtick math with standard dollar math (`$...$`) triggers catastrophic GFM delimiter matching collisions. The parser matches an opening `$ ` from a backtick block with a closing `$` from a standard inline math block further down the document. This turns entire paragraphs, section headers, tables, and lists into single mangled math strings, producing widespread **"Unable to render expression."** errors and destroying document structure.
*   **Strict Rule**: Always use clean, standard `$expression$` for inline math and `$$\n...\n$$` for display math blocks. Never use backticks inside math delimiters.
    *   **Correct (Renders)**: `$H_0 = 70.93 \pm 0.70\text{ km s}^{-1}\text{Mpc}^{-1}$`
    *   **Incorrect (Fails / Mangling Hazard)**: `$ `H_0 = 70.93 \pm 0.70\text{ km s}^{-1}\text{Mpc}^{-1}` $`

### Hyphen-Attached Math Expressions (`$\text{low-}\ell$`, `$\text{high-}\ell$`, `$\text{small-}t$`)
In CommonMark / GFM, the regex detecting opening math delimiters `$math$` requires the dollar sign to be preceded by whitespace or recognized opening punctuation. A preceding hyphen (`-`) is treated as a word character, which prevents the parser from recognizing the dollar sign as an opening math delimiter.
*   **Incorrect (Fails to compile / shows raw text)**: `low-$\ell$`, `high-$\ell$`, `small-$t$`, `Low-$L$`, `Lyman-$\alpha$`, `low-$z$`
*   **Correct (Compiles cleanly in KaTeX)**: `$\text{low-}\ell$`, `$\text{high-}\ell$`, `$\text{small-}t$`, `$\text{Low-}L$`, `$\text{Lyman-}\alpha$`, `$\text{low-}z$` (or `low $\ell$`, `high $\ell$`)

### Character Mangling and Escaping
The GFM parser processes standard Markdown rules (like italics via `_` and HTML tags via `<` and `>`) **before** the math engine compiles. To prevent character mangling:
*   Avoid using raw `<` or `>` inside inline math. Instead, use `\lt`, `\gt`, `\le`, `\ge`.
*   Avoid multiple underscores `_` in close proximity unless they are inside a properly formatted math block.
*   For bra-ket notation, use `\langle` and `\rangle` instead of raw `<` and `>`.
    *   **Correct**: `$\langle 1_0, Bf \rangle$`
    *   **Incorrect**: `$<1_0, Bf>$`

---

## 2. Prohibition Against Wrapping Math in Markdown Italics

### The Problem
Wrapping a paragraph or caption containing inline math inside outer Markdown emphasis (`*...*` or `_..._`) causes severe parser corruption:
```markdown
<!-- INCORRECT: Parser inserts <em> inside math tags, breaking KaTeX -->
*Figure 1: Observed power $\mathcal{D}_\ell^{TT}$ on $S^3 / I^\ast$ with $\ell = 1..5$.*
```
*Why this fails*: The CommonMark tokenizer processes the outer asterisks/underscores first, pairing them across or within the math delimiters and injecting `<em>` or `<i>` tags into the formula string before KaTeX sees it.

### The Solution: Bold Prefixes and Clean Prose
Never wrap full captions, sentences, or paragraphs containing math in outer italics. Instead, use bold structural prefixes:
*   **Correct (Renders)**: `**Figure 1:** Observed power $\mathcal{D}_\ell^{TT}$ on $S^3 / I^\ast$ with $\ell = 1..5$.`
*   **Correct (Renders)**: `**Table 2:** Multiplicity spectrum of $\mathrm{SU}(2)$ representations.`
*   **Incorrect (Fails)**: `*Figure 1: Observed power $\mathcal{D}_\ell^{TT}$ on $S^3 / I^\ast$ with $\ell = 1..5$.*`

---

## 3. Escaping Math Asterisks (`\ast` vs `*`)

### The Problem
Using raw asterisks `*` inside math expressions (such as group duals, conjugates, or quotient spaces $I^*$, $S^3/I^*$, $f^*(x)$) collides with GFM emphasis parsing. When multiple math expressions containing `*` appear in the same paragraph, GFM interprets the asterisks as markdown italic/bold toggles.

### The Solution: Use `\ast` or `\star`
Always use `\ast` or `\star` inside LaTeX math mode:
*   **Correct (Renders)**: `$I^\ast$`, `$S^3 / I^\ast$`, `$\mathcal{H}^\ast$`, `$f^\ast(x)$`
*   **Incorrect (Collides)**: `$I^*$`, `$S^3 / I^*$`, `$\mathcal{H}^*$`, `$f^*(x)$`

---

## 4. KaTeX Font Formatting Restrictions (`\mathbf{...}`)

### The Problem: Operators & Relations Inside `\mathbf`
In KaTeX, `\mathbf{...}` is strictly an alphabet font modifier intended for alphanumeric characters (letters and numbers). Placing mathematical operators (`\pm`, `+`, `-`, `\times`), relation symbols (`=`), or entire equations inside `\mathbf{...}` causes KaTeX parser failure and renders **"Unable to render expression."**.

### The Solution: Bold Only Symbols
Apply `\mathbf` solely to the target vector, matrix, or variable symbol, keeping operators and values outside:
*   **Incorrect (Fails)**: `$\mathbf{S_8 = 0.776 \pm 0.014}$`
*   **Correct (Renders)**: `$\mathbf{S}_8 = 0.776 \pm 0.014$` or `$\mathbf{S_8} = 0.776 \pm 0.014$`
*   **Incorrect (Fails)**: `$\mathbf{H_0 = 73.24 \pm 0.82}$`
*   **Correct (Renders)**: `$\mathbf{H}_0 = 73.24 \pm 0.82$`
*   **If bolding entire equation in prose**: Wrap the dollar delimiters in Markdown bold: `**$S_8 = 0.776 \pm 0.014$**`.

---

## 5. Prohibition of `\text{--}` (En-Dashes) in Math Mode

### The Problem: LaTeX Ligature En-Dashes
In standard LaTeX documents, numerical ranges are frequently written with en-dash ligatures like `\text{--}` or `--` inside math mode (e.g. `$\approx 11\text{--}12\%$`, `$z_c \sim 3600\text{--}3800$`). KaTeX does not expand LaTeX font ligatures inside `\text{...}` and fails with a syntax error.

### The Solution: Hyphens in Math or En-Dashes in Markdown
*   **Inside Math Mode**: Use a single hyphen/minus `\text{-}` or `-`:
    *   **Correct (Renders)**: `$\approx 11\text{-}12\%$`, `$z_c \sim 3600\text{-}3800$`
*   **In Markdown Prose**: Split the range into two separate inline math expressions separated by Markdown en-dash (`--`):
    *   **Correct (Renders)**: `$\sim 11\%$--$12\%$`, `$z_c \sim 3600$--$3800$`
*   **Incorrect (Fails)**: `$\approx 11\text{--}12\%$`, `$z_c \sim 3600\text{--}3800$`

---

## 6. Table Pipe Delimiter Protection (`\lvert ... \rvert` vs `|...|`)

### The Problem
In Markdown tables, the pipe character `|` is the structural cell delimiter. If raw vertical bars `|` are used inside inline math (e.g. `$|x|$`, `$|C_i|$`, `$|\psi\rangle$`, `$\gcd(a, b) = 1 | c$`), GFM splits the cell at the pipe character **before** passing content to KaTeX, destroying the table layout.

### The Solution: Absolute Value & Conditioning Macros
Always use LaTeX delimiter macros inside table cells:
*   **Absolute values / Cardinality**: Use `\lvert ... \rvert` or `\vert ... \vert`.
    *   **Correct**: `$\lvert C_i \rvert = 120$`, `$\lvert q \rvert^2 = 1$`
    *   **Incorrect**: `$|C_i| = 120$`, `$|q|^2 = 1$`
*   **Norms**: Use `\lVert ... \rVert`.
    *   **Correct**: `$\lVert v \rVert \le 1$`
    *   **Incorrect**: `$||v|| \le 1$`
*   **Set Conditioning & Divisibility in Tables**: Use `\mid` or `\parallel`.
    *   **Correct**: `$\{x \in X \mid f(x) = 0\}$`, `$k \mid d$`
    *   **Incorrect**: `$\{x \in X | f(x) = 0\}$`, `$k | d$`

---

## 7. KaTeX Delimiter Matching Rules for Sets

### The Problem
Constructs using improper delimiter balancing (such as `\left\lbrace ... ;\middle\vert; ... \right\rbrace`) cause KaTeX syntax errors because `\middle` requires an exact delimiter symbol without attached punctuation.

### The Solution: Clean Set Notation
*   **Standard Set Notation (Preferred)**:
    ```latex
    \{ q \in \mathbb{H} \mid \lvert q \rvert^2 = 1 \}
    ```
*   **Scalable Delimiter Set Notation**:
    ```latex
    \left\lbrace q \in \mathbb{H} \;\middle|\; \lvert q \rvert^2 = 1 \right\rbrace
    ```
    or
    ```latex
    \left\lbrace q \in \mathbb{H} \;\middle\vert\; \lvert q \rvert^2 = 1 \right\rbrace
    ```

---

## 8. Display Math Blocks (`$$ ... $$`) & Column 0 Alignment

Display math must be written on its own lines with blank lines before and after:

```markdown
$$
E = mc^2
$$
```

### The List Item Rendering Conflict
If a Markdown list item contains **indented display math blocks**, GFM parses the indented lines as code blocks, preventing KaTeX compilation:

```markdown
<!-- INCORRECT: Indented $$ inside list item fails to compile -->
1. The physical radius is:
   $$
   R_c = \frac{c}{H_0 \sqrt{|\Omega_K|}}
   $$
```

### The Solution: Column 0 Alignment
Unindent the display math block completely to **Column 0**, preceded and followed by blank lines:

```markdown
<!-- CORRECT: Unindented $$ at Column 0 with blank lines -->
1. The physical radius is:

$$
R_c = \frac{c}{H_0 \sqrt{\lvert \Omega_K \rvert}}
$$

2. The injectivity radius is:

$$
r_{\mathrm{inj}} = \frac{\pi R_c}{10}
$$
```

### Post-Equation Text Indentation
Never indent prose lines following a display math block by $\ge 4$ spaces (e.g. `     where W = C^{-1}...`). CommonMark parses any line indented by 4 or more spaces following a blank line as an **indented code block**, which prints the prose and math as literal code text inside a gray box. Keep follow-up descriptions flush with the list indentation or at Column 0.

### Matrix Row Line Breaks (`\\` in `pmatrix` / `bmatrix`)
In GFM, placing a matrix with `\\` on a single line causes CommonMark to treat `\\` as an escaped backslash (`\`), stripping the row break and collapsing a $3 \times 3$ matrix into a single flat row vector.
Always format matrices across multiple lines in display math:

```markdown
<!-- CORRECT: Renders true 3x3 matrix on GitHub -->
$$
\mathbf{R} = \begin{pmatrix}
1.000 & 0.420 & -0.460 \\
0.420 & 1.000 & -0.660 \\
-0.460 & -0.660 & 1.000
\end{pmatrix}
$$
```

```markdown
> **Theorem 1.1 (Volume).**
> The volume of the quotient manifold is:
>
> $$
> \mathrm{Vol}(S^3 / I^\ast) = \frac{\pi^2 R_c^3}{60}.
> $$
>
> where $R_c$ is the curvature radius.
```

---

## 9. Matplotlib Text Formatting Best Practices (Publication Graphics)

Matplotlib's internal mathtext renderer (`mathtext.fontset = 'cm'`) is **not** a full LaTeX compiler. Raw LaTeX text macros will render as literal unparsed strings if LaTeX is not explicitly invoked via system binaries.

### Rules for Publication Figures:
1.  **Do NOT use `\textbf{...}` or `\textit{...}` in mathtext strings**:
    *   **Correct**: `ax.set_title('(a) CMB Multipole Modes', fontsize=11, fontweight='bold')`
    *   **Correct**: `ax.annotate('Emergence Mode', fontweight='bold', ...)`
    *   **Incorrect**: `ax.set_title(r'\textbf{(a) CMB Multipole Modes}')`
2.  **Use `$\mathbf{...}$` or `$\mathrm{...}$` inside math mode**:
    *   **Correct**: `$m_L^{\mathrm{SO}(3)} = 0$`
    *   **Incorrect**: `$m_L^{\text{SO}(3)} = 0$`
3.  **Literal `%` in Legends/Labels**:
    *   In matplotlib standard strings, write `%` directly, not `\%`.
    *   **Correct**: `label=r'Poincaré $S^3/I^\ast$ EDE (68% / 95% CL)'`
    *   **Incorrect**: `label=r'Poincaré $S^3/I^*\ast$ EDE (68\% / 95\% CL)'`
4.  **Vector Output & High-DPI Rendering**:
    *   Always export both vector PDF and 300+ DPI PNG:
    ```python
    plt.savefig('fig.pdf', bbox_inches='tight')
    plt.savefig('fig.png', dpi=300, bbox_inches='tight')
    ```

---

## 10. Automated Verification Checklist

Before publishing or committing GFM math papers:
- [x] **0 backtick math tokens**: Never use `$ `...` $` — use standard `$math$` and `$$\n...\n$$`.
- [x] **Inline math spacing**: All inline math `$...$` has no leading or trailing spaces.
- [x] **`\mathbf` syntax**: Bold only alphanumeric symbols (`$\mathbf{S}_8 = 0.776 \pm 0.014$`); no operators (`=`, `\pm`) inside `\mathbf{...}`.
- [x] **No `\text{--}` in math**: Use single hyphens `$\text{-}$` inside math or `--` in markdown prose.
- [x] **Hyphen-attached expressions**: Use `$\text{low-}\ell$` format, not `low-$\ell$`.
- [x] **Asterisk escaping**: All math asterisks use `\ast` (`$I^\ast$`).
- [x] **Table delimiters**: All table absolute values use `\lvert ... \rvert` or `\vert ... \vert` and conditioning/divisibility uses `\mid`.
- [x] **Captions**: All figure and table captions use bold prefixes (`**Figure N:** ...`).
- [x] **Display math alignment**: All display math blocks (`$$`) are unindented at Column 0 with blank lines before/after.
- [x] **Set delimiters**: All set delimiters use clean `\{ ... \mid ... \}` or `\left\lbrace ... \;\middle|\; ... \right\rbrace` syntax.
- [x] **Matplotlib figures**: Python figure scripts avoid raw `\textbf{...}` macros in non-LaTeX matplotlib text.
