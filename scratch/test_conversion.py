import sys
sys.path.insert(0, 'scratch')
from fix_github_math import convert_dollar_to_backtick_dollar

test1 = r'The operator $D_{\text{sym}}$ is defined on $\text{Dom}(D_{\text{sym}})$'
result1 = convert_dollar_to_backtick_dollar(test1)
print("Test 1:")
print(f"  IN:  {test1}")
print(f"  OUT: {result1}")
print()

test2 = r'coupling functional $\langle\xi, \cdot\rangle$ on $\text{Dom}(D_0)$. Because $\xi \notin \ell^2(\mathbb{Z})$'
result2 = convert_dollar_to_backtick_dollar(test2)
print("Test 2:")
print(f"  IN:  {test2}")
print(f"  OUT: {result2}")
print()

# Test that $$ is not touched
test3 = r'display: $$x^2$$'
result3 = convert_dollar_to_backtick_dollar(test3)
print("Test 3 ($$):")
print(f"  IN:  {test3}")
print(f"  OUT: {result3}")
print()

# Test inside fenced block
test4 = "```math\nx^2\n```"
result4 = convert_dollar_to_backtick_dollar(test4)
print("Test 4 (fenced):")
print(f"  IN:  {test4}")
print(f"  OUT: {result4}")
