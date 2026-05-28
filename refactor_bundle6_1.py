import os

def refactor_gue():
    path = 'experiments/gue_pair_correlation.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('import matplotlib.pyplot'):
            import_idx = i
            break
    lines.insert(import_idx + 1, 'from adelic_spectral_zeta.primes import SMALL_PRIMES')
    lines.insert(import_idx + 2, '')
    lines.insert(import_idx + 3, 'def main():')

    for i in range(import_idx + 4, len(lines)):
        lines[i] = '    ' + lines[i]

    new_lines = []
    skip = False
    for line in lines:
        if 'primes = [' in line:
            new_lines.append('    primes = SMALL_PRIMES')
            skip = True
            continue
        if skip:
            if '151]' in line:
                skip = False
            continue
        new_lines.append(line)

    new_lines.extend(['', 'if __name__ == "__main__":', '    main()'])
    open(path, 'w', encoding='utf-8').write('\n'.join(new_lines))

def refactor_chern():
    path = 'experiments/chern_simons_statistics.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('from collections import defaultdict'):
            import_idx = i
            break
    lines.insert(import_idx + 1, 'from adelic_spectral_zeta.primes import sieve_primes')

    new_lines = []
    skip = False
    for line in lines:
        if 'def sieve(n):' in line:
            skip = True
        if skip and 'return np.where(is_prime)[0]' in line:
            skip = False
            continue
        if skip:
            continue
        if 'primes = sieve(P_MAX)' in line:
            new_lines.append(line.replace('sieve(', 'sieve_primes('))
            continue
        new_lines.append(line)
    
    lines = new_lines
    import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('print("=" * 70)'):
            import_idx = i
            break
    lines.insert(import_idx, 'def main():')
    for i in range(import_idx + 1, len(lines)):
        lines[i] = '    ' + lines[i]

    lines.extend(['', 'if __name__ == "__main__":', '    main()'])
    open(path, 'w', encoding='utf-8').write('\n'.join(lines))

def refactor_ept():
    path = 'experiments/entanglement_phase_transition.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    main_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('results = '):
            main_idx = i
            break

    lines.insert(main_idx, 'def main():')
    for i in range(main_idx + 1, len(lines)):
        lines[i] = '    ' + lines[i]

    for i in range(len(lines)):
        if 'except:' in lines[i]:
            lines[i] = lines[i].replace('except:', 'except Exception:')

    lines.extend(['', 'if __name__ == "__main__":', '    main()'])
    open(path, 'w', encoding='utf-8').write('\n'.join(lines))

def refactor_ees():
    path = 'experiments/entanglement_entropy_scan.py'
    lines = open(path, 'r', encoding='utf-8').read().splitlines()
    import_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('import mpmath'):
            import_idx = i
            break
    lines.insert(import_idx + 1, 'from adelic_spectral_zeta.primes import sieve_primes')

    new_lines = []
    skip = False
    for line in lines:
        if 'def sieve(n):' in line:
            skip = True
        if skip and 'return np.where(is_prime)[0]' in line:
            skip = False
            continue
        if skip:
            continue
        if 'primes = sieve(P_MAX)' in line:
            new_lines.append(line.replace('sieve(', 'sieve_primes('))
            continue
        new_lines.append(line)
    lines = new_lines

    main_idx = 0
    for i, line in enumerate(lines):
        if line.startswith('print("=" * 70)'):
            main_idx = i
            break
    lines.insert(main_idx, 'def main():')
    for i in range(main_idx + 1, len(lines)):
        lines[i] = '    ' + lines[i]

    for i in range(len(lines)):
        if 'except:' in lines[i]:
            lines[i] = lines[i].replace('except:', 'except Exception:')

    lines.extend(['', 'if __name__ == "__main__":', '    main()'])
    open(path, 'w', encoding='utf-8').write('\n'.join(lines))

if __name__ == "__main__":
    refactor_gue()
    refactor_chern()
    refactor_ept()
    refactor_ees()
    print("Done refactoring batch 1 of Bundle 6")
