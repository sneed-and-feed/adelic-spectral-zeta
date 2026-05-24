import os
import re
from pathlib import Path

def split_monograph():
    mono_path = Path("docs/unified_monograph.md")
    if not mono_path.exists():
        print("Error: unified_monograph.md not found.")
        return

    content = mono_path.read_text(encoding="utf-8")
    lines = content.splitlines()

    # Define the sections and their titles
    sections = [
        {"id": "01_abstract_and_introduction", "title": "Abstract & 1. Introduction and Architectural Design", "lines": []},
        {"id": "02_adelic_spectral_triple", "title": "2. The Adèlic Spectral Triple", "lines": []},
        {"id": "03_proof_of_axioms", "title": "3. Proof of the Spectral Triple Axioms", "lines": []},
        {"id": "04_higher_langlands_extensions", "title": "4. Higher Langlands Extensions & Rank-1 Universality", "lines": []},
        {"id": "05_artin_l_functions_rigidity", "title": "5. Artin L-Functions and Critical Line Rigidity", "lines": []},
        {"id": "06_quantum_physical_realization", "title": "6. Quantum Physical Realization & Many-Body Entanglement Sweeps", "lines": []},
        {"id": "07_arithmetic_statistics_subconvexity", "title": "7. Arithmetic Statistics and Subconvexity Bounds", "lines": []},
        {"id": "08_conclusion", "title": "8. Conclusion and Future Horizons", "lines": []},
        {"id": "09_appendices", "title": "Appendices", "lines": []}
    ]

    # Current section index
    current_sec = 0

    # Let's parse the lines and direct them to the appropriate section
    # The title of the paper is at the top. We will prepend it to Chapter 1.
    for i, line in enumerate(lines):
        # Detect headers to transition
        if line.startswith("## Abstract"):
            current_sec = 0
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 2. The Adèlic Spectral Triple"):
            current_sec = 1
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 3. Proof of the Spectral Triple Axioms"):
            current_sec = 2
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 4. Higher Langlands"):
            current_sec = 3
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 5. Artin L-Functions"):
            current_sec = 4
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 6. Quantum Physical"):
            current_sec = 5
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 7. Arithmetic Statistics"):
            current_sec = 6
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 8. Conclusion"):
            current_sec = 7
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## Appendices"):
            current_sec = 8
            sections[current_sec]["lines"].append(line)
        else:
            # Append line to current section
            sections[current_sec]["lines"].append(line)

    # Create target directory
    target_dir = Path("docs/monograph")
    target_dir.mkdir(parents=True, exist_ok=True)

    # Write each chapter
    for idx, sec in enumerate(sections):
        chapter_content = []
        # Prepend main title block for the monograph to Chapter 1
        if idx == 0:
            # We don't need to add anything extra, the title is already in the lines because it starts at the top
            pass
        else:
            # Add main title header for context
            chapter_content.append("# Adèlic Spectral Geometry, Quantum Criticality, and Automorphic L-Functions")
            chapter_content.append("### A Unification Monograph on the Spectral Realization of the Generalized Riemann Hypothesis")
            chapter_content.append("\n---\n")

        chapter_content.extend(sec["lines"])

        # Add navigation back to master document
        chapter_content.append("\n---\n")
        chapter_content.append(f"[← Back to Master Monograph Table of Contents](../unified_monograph.md)")

        chapter_file = target_dir / f"{sec['id']}.md"
        chapter_file.write_text("\n".join(chapter_content), encoding="utf-8")
        print(f"Wrote chapter: {chapter_file} ({len(sec['lines'])} lines)")

if __name__ == "__main__":
    split_monograph()
