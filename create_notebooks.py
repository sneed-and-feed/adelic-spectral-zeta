import json
import os

def py_to_ipynb(py_file, ipynb_file):
    with open(py_file, 'r', encoding='utf-8') as f:
        code = f.read()
    
    nb = {
        'cells': [
            {
                'cell_type': 'code',
                'execution_count': None,
                'metadata': {},
                'outputs': [],
                'source': ['!pip install --upgrade jax jaxlib\n']
            },
            {
                'cell_type': 'code',
                'execution_count': None,
                'metadata': {},
                'outputs': [],
                'source': [line + '\n' for line in code.split('\n')]
            }
        ],
        'metadata': {
            'accelerator': 'TPU',
            'kernelspec': {'display_name': 'Python 3', 'name': 'python3'}
        },
        'nbformat': 4,
        'nbformat_minor': 0
    }
    with open(ipynb_file, 'w', encoding='utf-8') as f:
        json.dump(nb, f, indent=2)

py_to_ipynb('experiments/colab_tpu_adelic_annealer.py', 'experiments/colab_tpu_adelic_annealer.ipynb')
py_to_ipynb('experiments/colab_tpu_coherent_qec.py', 'experiments/colab_tpu_coherent_qec.ipynb')
print('Notebooks created!')
