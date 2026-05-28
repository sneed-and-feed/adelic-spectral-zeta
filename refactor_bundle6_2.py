import os

def refactor_expander():
    path = 'experiments/expander_correlation.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    
    # insert docstring
    if not lines[0].startswith('"""'):
        lines.insert(0, '"""')
        lines.insert(1, 'Task: Expander Correlation Simulation')
        lines.insert(2, '=========================================')
        lines.insert(3, 'Simulates asymptotic frequency sweeps and quantitative power-law exponent fitting.')
        lines.insert(4, '"""')
        lines.insert(5, '')

    # find def get_primes
    new_lines = []
    skip = False
    added_import = False
    for line in lines:
        if line.startswith('def get_primes(n):'):
            skip = True
        if skip and line == '':
            skip = False
            continue
        if skip:
            continue
            
        if line.startswith('import sympy') and not added_import:
            new_lines.append('from adelic_spectral_zeta.primes import sieve_primes')
            added_import = True
            continue # replace sympy import
            
        if 'primes = get_primes(P_MAX)' in line:
            new_lines.append(line.replace('get_primes', 'sieve_primes'))
            continue
            
        new_lines.append(line)
        
    open(path, 'w', encoding='utf-8').write('\n'.join(new_lines))


def refactor_erdos():
    path = 'experiments/erdos_similarity_spectra.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    
    if not lines[0].startswith('"""'):
        lines.insert(0, '"""')
        lines.insert(1, 'Erdős Similarity via Adèlic Spectra')
        lines.insert(2, '=======================================')
        lines.insert(3, 'Confinement & Clustering Sweep.')
        lines.insert(4, '"""')
        lines.insert(5, '')

    new_lines = []
    for line in lines:
        if line.startswith('def run_experiment():'):
            new_lines.append('def main():')
            continue
        if 'run_experiment()' in line and not line.startswith('def '):
            new_lines.append(line.replace('run_experiment()', 'main()'))
            continue
        new_lines.append(line)
        
    open(path, 'w', encoding='utf-8').write('\n'.join(new_lines))


def refactor_qec():
    path = 'experiments/topological_qec.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    
    if not lines[0].startswith('"""'):
        lines.insert(0, '"""')
        lines.insert(1, 'Topological QEC')
        lines.insert(2, '=================')
        lines.insert(3, 'Thermal Noise Simulation.')
        lines.insert(4, '"""')
        lines.insert(5, '')

    new_lines = []
    skip = False
    for line in lines:
        if line.startswith('import sys'):
            skip = True
        if skip and line.startswith('sys.path.append'):
            skip = False
            continue
        if skip and line.startswith('import os'):
            continue
        if skip:
            continue
            
        if line.startswith('def run_monte_carlo():'):
            new_lines.append('def main():')
            continue
        if 'run_monte_carlo()' in line and not line.startswith('def '):
            new_lines.append(line.replace('run_monte_carlo()', 'main()'))
            continue
            
        if 'Break-Even (No QEC)' in line:
            new_lines.append(line.replace('Break-Even (No QEC)', 'Unprotected Qubit Baseline'))
            continue
            
        new_lines.append(line)
        
    open(path, 'w', encoding='utf-8').write('\n'.join(new_lines))

if __name__ == "__main__":
    refactor_expander()
    refactor_erdos()
    refactor_qec()
    print("Done refactoring batch 2 of Bundle 6")
