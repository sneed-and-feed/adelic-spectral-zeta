"""p-adic metric representation of amino acid sequences mapping biochemical properties to p-adic valuations."""

import numpy as np
from Bio.PDB import MMCIFParser, Superimposer
from Bio.SeqUtils import seq1
import gzip
from typing import Tuple

# Amino Acid Biochemical Properties Mapping
# Categories based on standard biochemical definitions
HYDROPHOBIC = {'A', 'V', 'I', 'L', 'M', 'F', 'Y', 'W'}
POLAR = {'S', 'T', 'N', 'Q', 'C', 'G', 'P'}
POSITIVE = {'R', 'K', 'H'}
NEGATIVE = {'D', 'E'}
SMALL = {'G', 'A', 'S', 'P', 'C', 'T', 'D', 'N', 'V'}
LARGE = {'F', 'Y', 'W', 'M', 'R', 'K', 'H', 'E', 'Q', 'L', 'I'}

def get_properties(aa: str) -> Tuple[bool, bool, bool]:
    """Returns a tuple of booleans (is_hydrophobic, is_charged, is_large)"""
    is_hydro = aa in HYDROPHOBIC
    is_charged = aa in POSITIVE or aa in NEGATIVE
    is_large = aa in LARGE
    return is_hydro, is_charged, is_large

def p_adic_valuation(aa1: str, aa2: str) -> Tuple[int, int, int]:
    """
    Computes the p-adic valuation (v2, v3, v5) between two amino acids.
    We assign biochemical properties to specific prime places:
    v2 (p=2): Hydrophobicity preservation (1 if same, 0 if different)
    v3 (p=3): Charge preservation (1 if same, 0 if different)
    v5 (p=5): Size preservation (1 if same, 0 if different)
    """
    if aa1 == aa2:
        return 1, 1, 1
        
    p1 = get_properties(aa1)
    p2 = get_properties(aa2)
    
    v2 = 1 if p1[0] == p2[0] else 0
    v3 = 1 if p1[1] == p2[1] else 0
    v5 = 1 if p1[2] == p2[2] else 0
    
    return v2, v3, v5

def sequence_p_adic_distance(seq1: str, seq2: str, p: int) -> float:
    """
    Computes the sequence-level p-adic distance.
    Valuation of sequence = sum of per-residue valuations.
    Distance = p^(-v_seq)
    """
    length = min(len(seq1), len(seq2))
    if length == 0:
        return float('inf')
        
    v_seq = 0
    for i in range(length):
        v2, v3, v5 = p_adic_valuation(seq1[i], seq2[i])
        if p == 2:
            v_seq += v2
        elif p == 3:
            v_seq += v3
        elif p == 5:
            v_seq += v5
            
    # Normalize valuation by length to prevent underflow
    normalized_v = v_seq / length
    return p ** (-normalized_v)

def parse_mmcif_sequence(filepath: str, chain_id: str = 'A') -> str:
    """Extracts the sequence from an mmCIF file."""
    parser = MMCIFParser(QUIET=True)
    if filepath.endswith('.gz'):
        with gzip.open(filepath, 'rt') as f:
            structure = parser.get_structure('struct', f)
    else:
        structure = parser.get_structure('struct', filepath)
        
    for model in structure:
        for chain in model:
            if chain.id == chain_id:
                seq = ""
                for residue in chain:
                    if residue.id[0] == ' ':
                        resname = residue.resname
                        if len(resname) == 3:
                            seq += seq1(resname)
                return seq
    return ""

from Bio import Align

def calculate_3d_rmsd(file1: str, file2: str, chain_id1: str = 'A', chain_id2: str = 'A') -> float:
    """Calculates the physical 3D RMSD between the CA atoms of two mmCIF structures using sequence alignment."""
    parser = MMCIFParser(QUIET=True)
    
    def get_structure(path):
        if path.endswith('.gz'):
            with gzip.open(path, 'rt') as f:
                return parser.get_structure('struct', f)
        return parser.get_structure('struct', path)

    s1 = get_structure(file1)
    s2 = get_structure(file2)
    
    chain1 = s1[0][chain_id1]
    chain2 = s2[0][chain_id2]
    
    def seq1_code(resname):
        from Bio.SeqUtils import seq1
        return seq1(resname)
        
    seq1 = "".join([seq1_code(res.resname) for res in chain1 if res.id[0] == ' ' and len(res.resname) == 3])
    seq2 = "".join([seq1_code(res.resname) for res in chain2 if res.id[0] == ' ' and len(res.resname) == 3])
        
    aligner = Align.PairwiseAligner()
    aligner.mode = 'global'
    alignments = aligner.align(seq1, seq2)
    alignment = alignments[0]
    
    # Get corresponding residues
    ca_atoms1 = []
    ca_atoms2 = []
    
    res_list1 = [res for res in chain1 if res.id[0] == ' ' and len(res.resname) == 3]
    res_list2 = [res for res in chain2 if res.id[0] == ' ' and len(res.resname) == 3]
    
    for (start1, end1), (start2, end2) in zip(alignment.aligned[0], alignment.aligned[1]):
        for idx1, idx2 in zip(range(start1, end1), range(start2, end2)):
            if 'CA' in res_list1[idx1] and 'CA' in res_list2[idx2]:
                ca_atoms1.append(res_list1[idx1]['CA'])
                ca_atoms2.append(res_list2[idx2]['CA'])
            
    if not ca_atoms1:
        return float('inf')

    super_imposer = Superimposer()
    super_imposer.set_atoms(ca_atoms1, ca_atoms2)
    
    return super_imposer.rms
