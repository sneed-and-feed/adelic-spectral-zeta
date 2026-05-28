import os
import re

replacements = {
    r'\bproves\b': 'suggests',
    r'\bProves\b': 'Suggests',
    r'\bPROVES\b': 'SUGGESTS',
    
    r'\bprove\b': 'suggest',
    r'\bProve\b': 'Suggest',
    r'\bPROVE\b': 'SUGGEST',
    
    r'\bproved\b': 'suggested',
    r'\bProved\b': 'Suggested',
    r'\bPROVED\b': 'SUGGESTED',
    
    r'\bproving\b': 'suggesting',
    r'\bProving\b': 'Suggesting',
    r'\bPROVING\b': 'SUGGESTING',
    
    r'\bproof\b': 'evidence',
    r'\bProof\b': 'Evidence',
    r'\bPROOF\b': 'EVIDENCE',
    
    r'\bverifies\b': 'checks',
    r'\bVerifies\b': 'Checks',
    r'\bVERIFIES\b': 'CHECKS',
    
    r'\bverify\b': 'test',
    r'\bVerify\b': 'Test',
    r'\bVERIFY\b': 'TEST',
    
    r'\bverified\b': 'tested',
    r'\bVerified\b': 'Tested',
    r'\bVERIFIED\b': 'TESTED',
    
    r'\bverifying\b': 'testing',
    r'\bVerifying\b': 'Testing',
    r'\bVERIFYING\b': 'TESTING',
    
    r'\bverification\b': 'exploration',
    r'\bVerification\b': 'Exploration',
    r'\bVERIFICATION\b': 'EXPLORATION',
}

def process_file(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    new_content = content
    for pattern, replacement in replacements.items():
        new_content = re.sub(pattern, replacement, new_content)
        
    if new_content != content:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(new_content)
        print(f"Updated {filepath}")

def main():
    base_dir = r"c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta"
    for root, dirs, files in os.walk(base_dir):
        # exclude hidden directories like .git
        dirs[:] = [d for d in dirs if not d.startswith('.')]
        for file in files:
            if file.endswith('.py'):
                process_file(os.path.join(root, file))

if __name__ == "__main__":
    main()
