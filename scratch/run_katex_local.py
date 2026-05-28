import subprocess
import os

def main():
    cwd = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\scratch"
    print("Installing katex locally in scratch folder...")
    # Run npm install katex locally in the scratch directory
    try:
        subprocess.run(["npm", "install", "--no-audit", "--no-fund", "katex"], cwd=cwd, check=True, shell=True)
        print("Installation successful!")
    except subprocess.CalledProcessError as e:
        print(f"Installation failed: {e}")
        return

    # Write a small test.js file
    js_content = """
const katex = require('katex');

const formulas = [
    // Original from README
    "\\\\mathfrak{D}_{\\\\text{glob}}(z) := \\\\mathfrak{D}_{\\\\text{ratio}}(z) \\\\mathfrak{D}_0(z) = \\\\prod_{n \\\\in \\\\mathbb{Z}, t_n^* \\\\neq 0} \\\\left( 1 - \\\\frac{z}{t_n^*} \\\\right) \\\\exp\\\\!\\\\left( \\\\frac{z}{t_n^*} \\\\right)",
    // With braced t_n^* group: {t_n}^*
    "\\\\mathfrak{D}_{\\\\text{glob}}(z) := \\\\mathfrak{D}_{\\\\text{ratio}}(z) \\\\mathfrak{D}_0(z) = \\\\prod_{n \\\\in \\\\mathbb{Z}, {t_n}^* \\\\neq 0} \\\\left( 1 - \\\\frac{z}{t_n^*} \\\\right) \\\\exp\\\\!\\\\left( \\\\frac{z}{t_n^*} \\\\right)",
    // With braced t_n^* entirely: {t_n^*}
    "\\\\mathfrak{D}_{\\\\text{glob}}(z) := \\\\mathfrak{D}_{\\\\text{ratio}}(z) \\\\mathfrak{D}_0(z) = \\\\prod_{n \\\\in \\\\mathbb{Z}, {t_n^*} \\\\neq 0} \\\\left( 1 - \\\\frac{z}{t_n^*} \\\\right) \\\\exp\\\\!\\\\left( \\\\frac{z}{t_n^*} \\\\right)",
    // With t_n{}^*
    "\\\\mathfrak{D}_{\\\\text{glob}}(z) := \\\\mathfrak{D}_{\\\\text{ratio}}(z) \\\\mathfrak{D}_0(z) = \\\\prod_{n \\\\in \\\\mathbb{Z}, t_n{}^* \\\\neq 0} \\\\left( 1 - \\\\frac{z}{t_n^*} \\\\right) \\\\exp\\\\!\\\\left( \\\\frac{z}{t_n^*} \\\\right)",
    // With t_{n}^*
    "\\\\mathfrak{D}_{\\\\text{glob}}(z) := \\\\mathfrak{D}_{\\\\text{ratio}}(z) \\\\mathfrak{D}_0(z) = \\\\prod_{n \\\\in \\\\mathbb{Z}, t_{n}^* \\\\neq 0} \\\\left( 1 - \\\\frac{z}{t_n^*} \\\\right) \\\\exp\\\\!\\\\left( \\\\frac{z}{t_n^*} \\\\right)",
    // Just the product parts
    "\\\\prod_{n \\\\in \\\\mathbb{Z}, t_n^* \\\\neq 0}",
    "\\\\prod_{n \\\\in \\\\mathbb{Z}, {t_n}^* \\\\neq 0}",
    "\\\\prod_{n \\\\in \\\\mathbb{Z}, {t_n^*} \\\\neq 0}",
    "\\\\prod_{n \\\\in \\\\mathbb{Z}, t_n{}^* \\\\neq 0}",
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
"""
    js_path = os.path.join(cwd, "test_katex.js")
    with open(js_path, "w", encoding="utf-8") as f:
        f.write(js_content)

    print("Running node test_katex.js...")
    try:
        res = subprocess.run(["node", "test_katex.js"], cwd=cwd, capture_output=True, text=True, check=True, shell=True)
        print(res.stdout)
    except subprocess.CalledProcessError as e:
        print(f"Execution failed: {e.stderr}")

if __name__ == '__main__':
    main()
