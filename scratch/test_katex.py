import subprocess
import json

def test_formula(formula):
    # Run npx --yes katex to render the formula
    cmd = ["npx", "--yes", "katex", "-e", formula]
    try:
        res = subprocess.run(cmd, capture_output=True, text=True, check=True, shell=True)
        return {"status": "success", "output": res.stdout}
    except subprocess.CalledProcessError as e:
        return {"status": "error", "error": e.stderr.strip() or e.stdout.strip()}

def main():
    formulas = [
        # Original from README
        r"\mathfrak{D}_{\text{glob}}(z) := \mathfrak{D}_{\text{ratio}}(z) \mathfrak{D}_0(z) = \prod_{n \in \mathbb{Z}, t_n^* \neq 0} \left( 1 - \frac{z}{t_n^*} \right) \exp\!\left( \frac{z}{t_n^*} \right)",
        # With braced t_n^*
        r"\mathfrak{D}_{\text{glob}}(z) := \mathfrak{D}_{\text{ratio}}(z) \mathfrak{D}_0(z) = \prod_{n \in \mathbb{Z}, {t_n}^* \neq 0} \left( 1 - \frac{z}{t_n^*} \right) \exp\!\left( \frac{z}{t_n^*} \right)",
        # With t_{n}^*
        r"\mathfrak{D}_{\text{glob}}(z) := \mathfrak{D}_{\text{ratio}}(z) \mathfrak{D}_0(z) = \prod_{n \in \mathbb{Z}, t_{n}^* \neq 0} \left( 1 - \frac{z}{t_{n}^*} \right) \exp\!\left( \frac{z}{t_{n}^*} \right)",
        # With t_{n^*}
        r"\mathfrak{D}_{\text{glob}}(z) := \mathfrak{D}_{\text{ratio}}(z) \mathfrak{D}_0(z) = \prod_{n \in \mathbb{Z}, t_{n^*} \neq 0} \left( 1 - \frac{z}{t_{n^*}} \right) \exp\!\left( \frac{z}{t_{n^*}} \right)",
        # Braced entire t_n^* in subscript
        r"\mathfrak{D}_{\text{glob}}(z) := \mathfrak{D}_{\text{ratio}}(z) \mathfrak{D}_0(z) = \prod_{n \in \mathbb{Z}, {t_n^*} \neq 0} \left( 1 - \frac{z}{t_n^*} \right) \exp\!\left( \frac{z}{t_n^*} \right)",
        # Just the subscript term
        r"\prod_{n \in \mathbb{Z}, t_n^* \neq 0}",
        r"\prod_{n \in \mathbb{Z}, {t_n}^* \neq 0}",
        r"\prod_{n \in \mathbb{Z}, {t_n^*} \neq 0}",
        r"\prod_{n \in \mathbb{Z}, t_{n}^* \neq 0}",
    ]
    
    for f in formulas:
        print(f"Testing: {f}")
        res = test_formula(f)
        print(f"Result: {res['status']}")
        if res['status'] == 'error':
            print(f"Error: {res['error']}")
        print("-" * 60)

if __name__ == '__main__':
    main()
