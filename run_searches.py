import subprocess

queries = [
    'all:"Quantum Many-Body Scars" AND all:"zero modes"',
    'all:"Eigenstate Thermalization Hypothesis" AND all:"Quantum Many-Body Scars"',
    'all:"entanglement entropy" AND all:"Quantum Many-Body Scars"'
]

for i, q in enumerate(queries):
    print(f"Running query: {q}")
    with open(f"arxiv_res_{i}.json", "w") as f:
        subprocess.run([
            "uv", "run", 
            r"C:\Users\x\.gemini\config\plugins\science\skills\literature_search_arxiv\scripts\search_arxiv.py", 
            "--query", q, 
            "--max_results", "5"
        ], stdout=f)
