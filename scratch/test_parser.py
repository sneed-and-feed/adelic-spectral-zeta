import re

english_words = [
    'with', 'spanned', 'by', 'vectors', 'is', 'formulated', 'as', 'a', 'singular', 'perturbation',
    'the', 'global', 'operator', 'yielding', 'entire', 'function', 'of', 'order', 'whose', 'zeros',
    'are', 'precisely', 'satisfying', 'uniquely', 'determined', 'breaks', 'breaking', 'causes',
    'causing', 'fractional', 'violates', 'integrality', 'making', 'rigid', 'topological', 'requirement',
    'off', 'critical', 'line', 'shifts', 'shifted', 'drift', 'deforms', 'system', 'symmetry', 'so',
    'for', 'since', 'meaning', 'to', 'from', 'where', 'and', 'or', 'in', 'does', 'require', 'onto',
    'span', 'individual', 'parameters', 'sufficient', 'match', 'spectral', 'average', 'subspace',
    'overlap', 'shown', 'below', 'fact', 'illustrating', 'plots', 'saved', 'gives', 'nested',
    'inside', 'higher-rank', 'hypothesis', 'antenna', 'allowing', 'almost', 'identically', 'sometimes',
    'better', 'than', 'bypassing', 'need', 'resolve', 'approximate', 'approximation', 'bound',
    'symmetric-power', 'lifts', 'cuspidal', 'automorphic', 'Galois', 'icosahedral', 'attempting',
    'shielding', 'local', 'cycle', 'fluctuations', 'ramified', 'primes', 'exact', 'trace', 'invariant',
    'quantum', 'physical', 'tight-binding', 'condensed', 'matter', 'fermions', 'hopping', 'Bruhat-Tits',
    'trees', 'coupled', '1D', 'Archimedean', 'clock', 'wire', 'showing', 'correspond', 'points',
    'distinct', 'entropy', 'spikes', 'stable', 'detectors', 'Coulomb-like', 'interactions', 'unconditional',
    'resolution', 'all', 'exponentially', 'decaying', 'geometric', 'sequences', 'lifting', 'copy',
    'relation', 'adèlic', 'product', 'space', 'construct', 'Cantor', 'filters', 'obstruct', 'sequence',
    'translations', 'modulo', 'driving', 'Schrödinger', 'ground-state', 'energy', 'strictly', 'positive',
    'preserving', 'gap', 'transition', 'avoidance', 'Lebesgue', 'measure', 'closed', 'unconditionally',
    'via', 'Haar', 'density', 'continuity', 'lemma', 'suggesting', 'presence', 'potential', 'compact',
    'filter', 'converges', 'sufficiently', 'small', 'non-zero', 'scales', 'Fubini', 'integration',
    'exceptional', 'set', 'could', 'leak', 'projection', '2-dimensional', 'zero', 'measure-theoretic',
    'constructed', 'removing', 'countable', 'union', 'point', 'sets', 'leveraging', 'scale-invariance',
    'representation', 'character', 'cusp', 'form', 'unperturbed', 'diagonal', 'Fourier-like',
    'scale-invariant', 'basis', 'unitary', 'shift', 'locally', 'constant', 'compactly', 'supported',
    'functions', 'codimension', 'phase', 'normalized', 'deficiency', 'isometry', 'compressed',
    'specific', 'choice', 'matches', 'regularized', 'resolvent', 'guarantees', 'gauge-covariant',
    'connection', 'covariant', 'coprime', 'joint', 'embedding', 'orthonormal', 'descend', 'regularize',
    'curse', 'dimensionality', 'Hadamard', 'weak', 'Schatten', 'reflecting', 'smooth', 'subalgebra',
    'isomorphic', 'Schwartz', 'sequences', 'generator', 'bounded', 'derivation', 'iterate', 'regularity',
    'digamma', 'Mellin-Barnes', 'transform', 'charge', 'conjugate', 'conjugation', 'double', 'commutator',
    'trace-class', 'flat', 'trivial', 'background', 'Sato-Tate', 'orthogonality', 'bijection', 'crossing',
    'crossings', 'winding', 'rescaling', 'rescale', 'score'
]

english_words_regex = rf'\s+(?:{"|".join(english_words)})\b'

def is_inside_text_command(subpart, start_pos):
    # Find all \text{...} in subpart
    # We can track brace nesting
    # Simple check: find all occurrences of \text{
    for m in re.finditer(r'\\text\{', subpart):
        cmd_start = m.start()
        # Find matching closing brace
        brace_count = 1
        idx = m.end()
        while idx < len(subpart) and brace_count > 0:
            if subpart[idx] == '{':
                brace_count += 1
            elif subpart[idx] == '}':
                brace_count -= 1
            idx += 1
        if cmd_start <= start_pos < idx:
            return True
    return False

def smart_fix_paragraph(paragraph):
    # Split by dollar signs
    # re.split(r'(\$(?!\$))', paragraph) splits by single $ but protects $$
    # Let's write a simple parser
    parts = []
    pos = 0
    n = len(paragraph)
    while pos < n:
        if paragraph[pos:pos+2] == '$$':
            parts.append(('display', '$$'))
            pos += 2
        elif paragraph[pos] == '$':
            parts.append(('dollar', '$'))
            pos += 1
        else:
            # Match until next $ or $$
            start = pos
            while pos < n and paragraph[pos] != '$':
                pos += 1
            parts.append(('text', paragraph[start:pos]))
            
    # Now parts is a list of ('display', '$$'), ('dollar', '$'), ('text', content)
    # We reconstruct, keeping track of state
    state = "text" # "text", "inline", "display"
    new_parts = []
    
    i = 0
    while i < len(parts):
        ptype, pval = parts[i]
        if ptype == 'display':
            if state == "text":
                state = "display"
                new_parts.append('$$')
            elif state == "display":
                state = "text"
                new_parts.append('$$')
            else:
                # If display delimiter occurs inside inline math, it's malformed. Let's just output it.
                new_parts.append('$$')
            i += 1
        elif ptype == 'dollar':
            if state == "text":
                state = "inline"
                new_parts.append('$')
            elif state == "inline":
                state = "text"
                new_parts.append('$')
            else:
                new_parts.append('$')
            i += 1
        elif ptype == 'text':
            if state == "inline":
                # This text is inside inline math.
                # Check if it has any unclosed English words!
                # We search for the first English word in this subpart
                match = None
                for m in re.finditer(english_words_regex, pval, re.IGNORECASE):
                    if not is_inside_text_command(pval, m.start()):
                        match = m
                        break
                if match:
                    # Found an English word!
                    # Split this subpart into math and text.
                    math_portion = pval[:match.start()]
                    english_portion = pval[match.start():]
                    # We close the inline math, output the English portion,
                    # and since state was inline, it becomes text!
                    new_parts.append(math_portion + '$' + english_portion)
                    state = "text"
                    # But wait! What if the next token is a dollar sign?
                    # Since state is now text, the next dollar sign will open a new inline math block!
                    # E.g. $D_{sym} ... with ... $g_\pm ...$ -> $D_{sym}$ with $g_\pm$
                else:
                    new_parts.append(pval)
            else:
                new_parts.append(pval)
            i += 1
            
    # If we reach the end and state is still inline, we close it
    res = "".join(new_parts)
    if state == "inline":
        res += "$"
    return res

# Test cases
test1 = "We define a symmetric restricted operator $D_{\\text{sym}} = D_0\\bigr\\vert _{\\text{Ker}(\\langle\\xi,\\cdot\\rangle)} with deficiency indices exactly $(1,1), spanned by deficiency vectors $g_\\pm = (D_0 \\mp i\\mathbb{I})^{-1}\\xi \\in \\ell^2(\\mathbb{Z}). The global operator $D_{\\text{glob}} is formulated as a singular rank-1 perturbation:"
print("Test 1 Input:\n", test1)
print("Test 1 Fixed:\n", smart_fix_paragraph(test1))
print()

test2 = "We establish the unconditional resolution of the Erdős Similarity Conjecture (1974) for all exponentially decaying geometric sequences $S = \\{\\alpha q^{-n}\\}_{n=1}^\\infty$ ($q \\ge 2$, $\\alpha \\neq 0$)."
print("Test 2 Input:\n", test2)
print("Test 2 Fixed:\n", smart_fix_paragraph(test2))
