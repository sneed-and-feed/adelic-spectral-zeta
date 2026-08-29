# Guide to Writing Math on GitHub (GFM) with KaTeX/MathJax

This guide documents the strict rules, edge cases, and best practices for writing complex mathematical equations, tables, and typography in GitHub-Flavored Markdown (GFM) to ensure 100% compliant KaTeX/MathJax rendering. These rules were learned through empirical trial and error with the GitHub Markdown API and CommonMark parsers.

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

## 4. Table Pipe Delimiter Protection (`\lvert ... \rvert` vs `|...|`)

### The Problem
In Markdown tables, the pipe character `|` is the structural cell delimiter. If raw vertical bars `|` are used inside inline math (e.g. `$|x|$`, `$|C_i|$`, `$|\psi\rangle$`), GFM splits the cell at the pipe character **before** passing content to KaTeX, destroying the table layout.

### The Solution: Absolute Value Macros
Always use LaTeX delimiter macros inside table cells:
*   **Absolute values / Cardinality**: Use `\lvert ... \rvert` or `\vert ... \vert`.
    *   **Correct**: `$\lvert C_i \rvert = 120$`, `$\lvert q \rvert^2 = 1$`
    *   **Incorrect**: `$|C_i| = 120$`, `$|q|^2 = 1$`
*   **Norms**: Use `\lVert ... \rVert`.
    *   **Correct**: `$\lVert v \rVert \le 1$`
    *   **Incorrect**: `$||v|| \le 1$`
*   **Set Conditioning in Tables**: Use `\mid`.
    *   **Correct**: `$\{x \in X \mid f(x) = 0\}$`

---

## 5. KaTeX Delimiter Matching Rules for Sets

### The Problem
Constructs using improper delimiter balancing (such as `\left\{ ... ;\middle\vert; ... \right\}`) cause KaTeX syntax errors because `\middle` requires an exact delimiter symbol without attached punctuation.

### The Solution: Clean Set Notation
*   **Standard Set Notation (Preferred)**:
    ```latex
    \{ q \in \mathbb{H} \mid \lvert q \rvert^2 = 1 \}
    ```
*   **Scalable Delimiter Set Notation**:
    ```latex
    \left\{ q \in \mathbb{H} \;\middle|\; \lvert q \rvert^2 = 1 \right\}
    ```
    or
    ```latex
    \left\{ q \in \mathbb{H} \;\middle\vert\; \lvert q \rvert^2 = 1 \right\}
    ```

---

## 6. Display Math Blocks (`$$ ... $$`) & Column 0 Alignment

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

### Set-Builder Delimiters
In KaTeX / MathJax on GitHub, never use `\left\{ ... \;\middle|\; ... \right\}` or `;\middle|;` for set definitions. Instead, use standard LaTeX set notation with `\{ ... \mid ... \}` or `\{ ... : ... \}`:

```markdown
<!-- CORRECT: Universal, never fails in KaTeX or GFM -->
$$
S^3 = \{ q \in \mathbb{H} \mid \lvert q \rvert^2 = 1 \}
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

## 7. Matplotlib Text Formatting Best Practices (Publication Graphics)

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

## 8. Automated Verification Checklist

Before publishing or committing GFM math papers:
- [x] All inline math `$...$` has no leading/trailing spaces.
- [x] All math asterisks use `\ast` (`$I^\ast$`).
- [x] All table absolute values use `\lvert ... \rvert` or `\vert ... \vert`.
- [x] All figure and table captions use bold prefixes (`**Figure N:** ...`).
- [x] All display math blocks (`$$`) are unindented at Column 0 with blank lines before/after.
- [x] All set delimiters use clean `\{ ... \mid ... \}` or `\left\{ ... \;\middle|\; ... \right\}` syntax.
- [x] Python figure scripts avoid raw `\textbf{...}` macros in non-LaTeX matplotlib text.
