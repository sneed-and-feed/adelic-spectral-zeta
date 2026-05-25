import os
import shutil
from pathlib import Path

def split_monograph():
    mono_path = Path("docs/unified_monograph.md")
    if not mono_path.exists():
        print("Error: unified_monograph.md not found.")
        return

    content = mono_path.read_text(encoding="utf-8")
    lines = content.splitlines()

    # Define the 10 sections and their metadata
    sections = [
        {"id": "01_abstract_and_introduction", "lines": []},
        {"id": "02_adelic_spectral_triple", "lines": []},
        {"id": "03_proof_of_axioms", "lines": []},
        {"id": "04_higher_langlands_extensions", "lines": []},
        {"id": "05_artin_l_functions_rigidity", "lines": []},
        {"id": "06_quantum_physical_realization", "lines": []},
        {"id": "07_arithmetic_statistics_subconvexity", "lines": []},
        {"id": "08_numerical_verification_simulations", "lines": []},
        {"id": "09_conclusion", "lines": []},
        {"id": "10_appendices", "lines": []}
    ]

    current_sec = 0

    for i, line in enumerate(lines):
        # Detect headers to transition
        if line.startswith("## Abstract"):
            current_sec = 0
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 2. The Adèlic Spectral Triple"):
            current_sec = 1
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 3. Evidence of the Spectral Triple Axioms"):
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
        elif line.startswith("### 7.4 Numerical Exploration"):
            # Split point: transition to Chapter 8
            current_sec = 7
            sections[current_sec]["lines"].append("## 8. Numerical Exploration & Many-Body Simulations")
            sections[current_sec]["lines"].append("")
            sections[current_sec]["lines"].append(line)
        elif line.startswith("## 8. Conclusion"):
            current_sec = 8
            # Rename Section 8 to Section 9
            renamed_line = line.replace("## 8. Conclusion", "## 9. Conclusion")
            sections[current_sec]["lines"].append(renamed_line)
        elif line.startswith("## Appendices"):
            current_sec = 9
            sections[current_sec]["lines"].append(line)
        else:
            sections[current_sec]["lines"].append(line)

    # Recreate monograph directory to avoid stray files
    target_dir = Path("docs/monograph")
    if target_dir.exists():
        shutil.rmtree(target_dir)
    target_dir.mkdir(parents=True, exist_ok=True)

    # Write each chapter
    for idx, sec in enumerate(sections):
        chapter_content = []
        if idx == 0:
            # Chapter 1 starts with the title blocks directly from lines 1-5 of unified_monograph.md
            pass
        else:
            # Prepend standard monograph headers
            chapter_content.append("# Adèlic Spectral Geometry, Quantum Criticality, and Automorphic L-Functions")
            chapter_content.append("### A Unification Monograph on the Spectral Realization of the Generalized Riemann Hypothesis")
            chapter_content.append("\n---\n")

        chapter_content.extend(sec["lines"])

        # Add navigation back to the Table of Contents index
        chapter_content.append("\n---\n")
        chapter_content.append("[← Back to Master Monograph Table of Contents](../unified_monograph.md)")

        chapter_file = target_dir / f"{sec['id']}.md"
        chapter_file.write_text("\n".join(chapter_content), encoding="utf-8")
        print(f"Wrote chapter: {chapter_file} ({len(sec['lines'])} lines)")

if __name__ == "__main__":
    split_monograph()
