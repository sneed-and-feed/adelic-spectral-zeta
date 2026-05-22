# Math Rendering Test

## Inline Math (backtick-dollar format)

Test 1 - Single subscript: $`D_{\text{sym}}`$

Test 2 - Multiple subscripts on one line: $`D_{\text{sym}}`$ is defined on $`\text{Dom}(D_{\text{sym}})`$

Test 3 - Many inline expressions: $`\langle\xi, \cdot\rangle`$ on $`\text{Dom}(D_0)`$. Because $`\xi \notin \ell^2(\mathbb{Z})`$, the vector $`\xi`$ is singular.

Test 4 - Complex expression: $`\sum_{n \neq 0} \frac{\|\xi_n\|^2}{\lambda_n^2} < \infty`$

Test 5 - Braces: $`\left\lbrace \frac{\xi_n}{\lambda_n} \right\rbrace`$

Test 6 - Greek and subscripts: $`\eta_{p, \Delta}(0)`$ as the phase of $`L_p(s, \Delta)^{-1}`$

## Display Math (fenced block)

```math
D_{\text{glob}} = D_0 - \frac{|\xi\rangle\langle\xi|}{1 + \langle\xi, (D_0 - z)^{-1}\xi\rangle}
```

## Table with Math

| Symbol | Description |
| :--- | :--- |
| $`D_{\text{glob}}`$ | Global Dirac operator |
| $`\xi_n = \mathcal{O}(\ln\|n\|)`$ | Coupling vector growth |
| $`\eta_{p, \Delta}(0)`$ | Non-Archimedean eta-invariant |
