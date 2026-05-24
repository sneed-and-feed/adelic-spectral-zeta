import os
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
    'via', 'Haar', 'density', 'continuity', 'lemma', 'proving', 'presence', 'potential', 'compact',
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
    'crossings', 'winding', 'rescaling', 'rescale', 'score', 'as', 'a', 'the', 'to', 'from', 'for',
    'since', 'so', 'at', 'be', 'we', 'its', 'has', 'have', 'not', 'but', 'it', 'this', 'that', 'they',
    'our', 'your', 'my', 'their', 'an', 'any', 'each', 'every', 'some', 'all', 'more', 'most', 'many',
    'few', 'only', 'first', 'second', 'third', 'last', 'next', 'also', 'even', 'just', 'then', 'now',
    'there', 'here', 'when', 'where', 'why', 'how', 'what', 'which', 'who', 'whom', 'whose', 'about',
    'above', 'after', 'against', 'along', 'among', 'around', 'before', 'behind', 'below', 'beneath',
    'beside', 'between', 'beyond', 'during', 'except', 'inside', 'into', 'near', 'outside', 'over',
    'through', 'under', 'until', 'up', 'upon', 'within', 'without', 'linear', 'linearly', 'scale',
    'scales', 'growth', 'grow', 'grows', 'constant', 'piecewise', 'continuous', 'real', 'complex',
    'imaginary', 'unitary', 'non-unitary', 'self-adjoint', 'deficiency', 'indices', 'limit',
    'infinite-dimensional', 'finite-dimensional', 'dimension', 'eigenvalue', 'eigenvalues',
    'eigenvector', 'eigenvectors', 'matrix', 'matrices', 'operator', 'operators', 'vector', 'vectors',
    'scalar', 'scalars', 'product', 'products', 'sum', 'sums', 'integral', 'integrals', 'derivative',
    'derivatives', 'differential', 'equations', 'analytic', 'meromorphic', 'entire', 'holomorphic',
    'pole', 'poles', 'residue', 'residues', 'zeros', 'critical', 'conjecture', 'theorem', 'proof',
    'corollary', 'proposition', 'definition', 'example', 'remark', 'note', 'appendix', 'chapter',
    'section', 'paragraph', 'exercise', 'problem', 'solution', 'question', 'answer', 'test',
    'verify', 'verification', 'simulation', 'simulations', 'experiment', 'experiments', 'run',
    'runs', 'running', 'plot', 'plots', 'graph', 'graphs', 'chart', 'charts', 'table', 'tables',
    'data', 'results', 'analysis', 'conclusion', 'future', 'work'
]

english_words_regex = rf'\s+(?:{"|".join(english_words)})\b'

def is_inside_text_command(subpart, start_pos):
    # Find all \text{...} in subpart
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

def smart_fix_line(line):
    # 1. Simple text replacements to resolve completed/unclosed forms first
    # Protect against multiple run accumulations (idempotent lookahead/lookbehinds)
    line = re.sub(r'(?<!\$)\$\\square(?!\$)', lambda m: r'$\square$', line)
    line = re.sub(r'(?<!\$)\$L-([Ff])unctions(?![\w\$])', lambda m: f'$L$-{m.group(1)}unctions', line)
    line = re.sub(r'(?<!\$)\$L-([Ff])unction(?![\w\$])', lambda m: f'$L$-{m.group(1)}unction', line)
    line = re.sub(r'(?<!\$)\$p-adic(?![\w\$])', lambda m: r'$p$-adic', line)
    line = re.sub(r'(?<!\$)\$(\d+)-adic(?![\w\$])', lambda m: f'${m.group(1)}$-adic', line)
    line = re.sub(r'(?<!\$)\$(\d+)-dimensional(?![\w\$])', lambda m: f'${m.group(1)}$-dimensional', line)
    line = re.sub(r'(?<!\$)\$([k-n])-th(?![\w\$])', lambda m: f'${m.group(1)}$-th', line)
    line = re.sub(r'(?<!\$)\$([a-zA-Z]+)-adic(?![\w\$])', lambda m: f'${m.group(1)}$-adic', line)
    line = re.sub(r'(?<!\$)\$([a-zA-Z]+)-function(?![\w\$])', lambda m: f'${m.group(1)}$-function', line)
    line = re.sub(r'(?<!\$)\$([a-zA-Z]+)-form(?![\w\$])', lambda m: f'${m.group(1)}$-form', line)
    line = re.sub(r'(?<!\$)\$([a-zA-Z]+)-invariant(?![\w\$])', lambda m: f'${m.group(1)}$-invariant', line)
    line = re.sub(r'(?<!\$)\$([a-zA-Z]+)-invariants(?![\w\$])', lambda m: f'${m.group(1)}$-invariants', line)
    
    # Groups like $GL(1), $GL(2), $GL(3), $GL(4), $GL(5), $GL(N), $GL(d), $GL(n)
    line = re.sub(r'(?<!\$)\$GL\((\d+|[a-zA-Z]+)\)(?![\w\$])', lambda m: f'$GL({m.group(1)})$', line)
    line = re.sub(r'(?<!\$)\$SL_2(?![\w\$])', lambda m: r'$SL_2$', line)
    line = re.sub(r'(?<!\$)\$SL_2\(\\mathbb\{([ZR])\}\)(?![\w\$])', lambda m: f'$SL_2(\\mathbb{{{m.group(1)}}})$', line)
    line = re.sub(r'(?<!\$)\$SL\(2\)(?![\w\$])', lambda m: r'$SL(2)$', line)
    line = re.sub(r'(?<!\$)\$PGL_2\(\\mathbb\{Q\}_p\)(?![\w\$])', lambda m: r'$PGL_2(\\mathbb{Q}_p)$', line)
    
    # QC$^\infty -> $QC^\infty$
    line = re.sub(r'QC\$\^\\infty', lambda m: r'$QC^\infty$', line)
    
    # Parse line into text tokens and unescaped dollars
    parts = []
    pos = 0
    n = len(line)
    while pos < n:
        if line[pos] == '$':
            is_escaped = False
            k = pos - 1
            while k >= 0 and line[k] == '\\':
                is_escaped = not is_escaped
                k -= 1
            if not is_escaped:
                parts.append(('dollar', '$'))
                pos += 1
                continue
        
        start = pos
        while pos < n:
            if line[pos] == '$':
                is_escaped = False
                k = pos - 1
                while k >= start and line[k] == '\\':
                    is_escaped = not is_escaped
                    k -= 1
                if not is_escaped:
                    break
            pos += 1
        parts.append(('text', line[start:pos]))
        
    state = "text"
    new_parts = []
    
    i = 0
    while i < len(parts):
        ptype, pval = parts[i]
        if ptype == 'dollar':
            if state == "text":
                state = "inline"
                new_parts.append('$')
            else:
                state = "text"
                new_parts.append('$')
            i += 1
        elif ptype == 'text':
            if state == "inline":
                match = None
                for m in re.finditer(english_words_regex, pval, re.IGNORECASE):
                    if not is_inside_text_command(pval, m.start()):
                        match = m
                        break
                if match:
                    math_portion = pval[:match.start()]
                    english_portion = pval[match.start():]
                    new_parts.append(math_portion + '$' + english_portion)
                    state = "text"
                else:
                    new_parts.append(pval)
            else:
                new_parts.append(pval)
            i += 1
            
    res = "".join(new_parts)
    if state == "inline":
        res += "$"
    return res

def fix_math_in_expression(expr):
    # Strip spaces
    expr = expr.strip()
    
    # Replace comparison operators
    expr = expr.replace('<=', r'\le')
    expr = expr.replace('>=', r'\ge')
    expr = expr.replace('<', r'\lt ')
    expr = expr.replace('>', r'\gt ')
    
    # Clean up double spaces
    expr = re.sub(r'\s+', ' ', expr)
    return expr.strip()

def process_text_part(text):
    # Split text block by display math blocks $$ ... $$
    display_parts = re.split(r'(\$\$[\s\S]*?\$\$)', text)
    
    for idx in range(len(display_parts)):
        part = display_parts[idx]
        if not part:
            continue
            
        if part.startswith('$$') and part.endswith('$$'):
            # Display math block
            expr = part[2:-2]
            fixed_expr = fix_math_in_expression(expr)
            display_parts[idx] = f"\n\n$$\n{fixed_expr}\n$$\n\n"
        else:
            # Normal text block, process line-by-line
            lines = part.split('\n')
            for l_idx in range(len(lines)):
                line = lines[l_idx]
                stripped_line = line.strip()
                if stripped_line.startswith('|') and stripped_line.endswith('|'):
                    # Table line: process column cells individually
                    cells = line.split('|')
                    for c_idx in range(1, len(cells) - 1):
                        cells[c_idx] = smart_fix_line(cells[c_idx])
                    lines[l_idx] = '|'.join(cells)
                else:
                    # Regular text line
                    lines[l_idx] = smart_fix_line(line)
            
            # Reconstruct the normal text block
            reconstructed_text = '\n'.join(lines)
            
            # Now split by inline math pattern to fix spacing and comparison operators
            inline_pattern = r'((?<!\$)\$(?!\$)[^$\n]+(?<!\$)\$(?!\$))'
            subparts = re.split(inline_pattern, reconstructed_text)
            for s_idx in range(len(subparts)):
                subpart = subparts[s_idx]
                if subpart.startswith('$') and subpart.endswith('$'):
                    expr = subpart[1:-1]
                    fixed_expr = fix_math_in_expression(expr)
                    subparts[s_idx] = f"${fixed_expr}$"
            
            display_parts[idx] = "".join(subparts)
            
    return "".join(display_parts)

def process_file_math(filepath):
    print(f"Fixing math in: {filepath}")
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
        
    # Split content by code blocks
    parts = re.split(r'(```[\s\S]*?```)', content)
    
    for i in range(len(parts)):
        part = parts[i]
        if part.startswith('```'):
            if part.startswith('```math'):
                # Convert ```math to $$ block math
                expr = part[7:-3].strip()
                fixed_expr = fix_math_in_expression(expr)
                parts[i] = f"\n\n$$\n{fixed_expr}\n$$\n\n"
            else:
                # Other code blocks (python, bash, etc.), leave untouched
                pass
        else:
            # Text part
            parts[i] = process_text_part(part)
            
    result = "".join(parts)
    
    # Post-process: clean up multiple consecutive blank lines
    result = re.sub(r'\n{3,}', '\n\n', result)
    
    # Save back
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(result)

def main():
    repo_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    md_files = []
    for root, dirs, files in os.walk(repo_dir):
        if '.git' in root or '.pytest_cache' in root or 'node_modules' in root:
            continue
        for file in files:
            if file.endswith('.md') and file != 'github_math_syntax_guide.md':
                md_files.append(os.path.join(root, file))
                
    for filepath in sorted(md_files):
        process_file_math(filepath)
        
    print("Fix completed successfully!")

if __name__ == '__main__':
    main()
