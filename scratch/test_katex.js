
const katex = require('katex');

const formulas = [
    // Original from README
    "\\mathfrak{D}_{\\text{glob}}(z) := \\mathfrak{D}_{\\text{ratio}}(z) \\mathfrak{D}_0(z) = \\prod_{n \\in \\mathbb{Z}, t_n^* \\neq 0} \\left( 1 - \\frac{z}{t_n^*} \\right) \\exp\\!\\left( \\frac{z}{t_n^*} \\right)",
    // With braced t_n^* group: {t_n}^*
    "\\mathfrak{D}_{\\text{glob}}(z) := \\mathfrak{D}_{\\text{ratio}}(z) \\mathfrak{D}_0(z) = \\prod_{n \\in \\mathbb{Z}, {t_n}^* \\neq 0} \\left( 1 - \\frac{z}{t_n^*} \\right) \\exp\\!\\left( \\frac{z}{t_n^*} \\right)",
    // With braced t_n^* entirely: {t_n^*}
    "\\mathfrak{D}_{\\text{glob}}(z) := \\mathfrak{D}_{\\text{ratio}}(z) \\mathfrak{D}_0(z) = \\prod_{n \\in \\mathbb{Z}, {t_n^*} \\neq 0} \\left( 1 - \\frac{z}{t_n^*} \\right) \\exp\\!\\left( \\frac{z}{t_n^*} \\right)",
    // With t_n{}^*
    "\\mathfrak{D}_{\\text{glob}}(z) := \\mathfrak{D}_{\\text{ratio}}(z) \\mathfrak{D}_0(z) = \\prod_{n \\in \\mathbb{Z}, t_n{}^* \\neq 0} \\left( 1 - \\frac{z}{t_n^*} \\right) \\exp\\!\\left( \\frac{z}{t_n^*} \\right)",
    // With t_{n}^*
    "\\mathfrak{D}_{\\text{glob}}(z) := \\mathfrak{D}_{\\text{ratio}}(z) \\mathfrak{D}_0(z) = \\prod_{n \\in \\mathbb{Z}, t_{n}^* \\neq 0} \\left( 1 - \\frac{z}{t_n^*} \\right) \\exp\\!\\left( \\frac{z}{t_n^*} \\right)",
    // Just the product parts
    "\\prod_{n \\in \\mathbb{Z}, t_n^* \\neq 0}",
    "\\prod_{n \\in \\mathbb{Z}, {t_n}^* \\neq 0}",
    "\\prod_{n \\in \\mathbb{Z}, {t_n^*} \\neq 0}",
    "\\prod_{n \\in \\mathbb{Z}, t_n{}^* \\neq 0}",
];

formulas.forEach((f, idx) => {
    console.log(`Testing formula #${idx + 1}: ${f}`);
    try {
        katex.renderToString(f);
        console.log("Result: SUCCESS");
    } catch (err) {
        console.log("Result: ERROR - " + err.message);
    }
    console.log("-".repeat(50));
});
