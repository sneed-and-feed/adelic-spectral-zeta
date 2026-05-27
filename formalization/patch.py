import re

with open(r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\CollatzRelMatrix.lean', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix 1: collatzDirMatrix_tau_invariant
old_tau_inv = """theorem collatzDirMatrix_tau_invariant (n : ℕ) (hn : n ≥ 1) (x y : ZMod (2^n)) :
    collatzDirMatrix n (tauDir n x) (tauDir n y) = collatzDirMatrix n x y := by
  simp only [collatzDirMatrix]
  have h1 : 3 * tauDir n x = tauDir n (3 * x) := three_mul_tauDir n hn x
  have h2 : 3 * tauDir n x - 1 = tauDir n (3 * x - 1) := three_mul_tauDir_sub n hn x
  simp only [h1, h2]
  have h3 : tauDir n y = tauDir n (3 * x) ↔ y = 3 * x := by
    simp [tauDir]
  have h4 : tauDir n y = tauDir n (3 * x - 1) ↔ y = 3 * x - 1 := by
    simp [tauDir]
  rw [h3, h4]"""

new_tau_inv = """theorem collatzDirMatrix_tau_invariant (n : ℕ) (hn : n ≥ 1) (x y : ZMod (2^n)) :
    collatzDirMatrix n (tauDir n x) (tauDir n y) = collatzDirMatrix n x y := by
  simp only [collatzDirMatrix]
  have h1 : 3 * tauDir n x = tauDir n (3 * x) := three_mul_tauDir n hn x
  have h2 : 3 * tauDir n x - 1 = tauDir n (3 * x - 1) := three_mul_tauDir_sub n hn x
  simp only [h1, h2]
  have h3 : tauDir n y = tauDir n (3 * x) ↔ y = 3 * x := by
    dsimp [tauDir]; constructor <;> intro h
    · exact add_right_cancel h
    · rw [h]
  have h4 : tauDir n y = tauDir n (3 * x - 1) ↔ y = 3 * x - 1 := by
    dsimp [tauDir]; constructor <;> intro h
    · exact add_right_cancel h
    · rw [h]
  simp only [h3, h4]"""
content = content.replace(old_tau_inv, new_tau_inv)

# Fix 2: D'_tau_sym_offdiag
old_offdiag = """  have h_double : (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) + ((2^(n-1) : ℕ) : ZMod (2^n)) = liftDir u := by
    have : ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      push_cast
      have h_exp : (2 : ℕ) * 2^(n-1) = 2^n := by
        have : n = (n-1) + 1 := by omega
        rw [this, pow_succ]; ring
      have : ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^(n-1) : ℕ) : ZMod (2^n)) = ((2^(n-1) + 2^(n-1) : ℕ) : ZMod (2^n)) := by
        push_cast; ring
      rw [this, show 2^(n-1) + 2^(n-1) = 2^n from h_exp, ZMod.natCast_self]
    rw [add_assoc, this, add_zero]"""

new_offdiag = """  have h_double : (liftDir u + ((2^(n-1) : ℕ) : ZMod (2^n))) + ((2^(n-1) : ℕ) : ZMod (2^n)) = liftDir u := by
    have : ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^(n-1) : ℕ) : ZMod (2^n)) = 0 := by
      have h_exp : 2 * 2^(n-1) = 2^n := by
        rw [←pow_one 2, ←pow_add, add_comm, Nat.sub_add_cancel (by omega : n ≥ 1)]
      have : ((2^(n-1) : ℕ) : ZMod (2^n)) + ((2^(n-1) : ℕ) : ZMod (2^n)) = (((2^(n-1) + 2^(n-1) : ℕ) : ZMod (2^n))) := by
        push_cast; ring
      have h_calc : 2^(n-1) + 2^(n-1) = 2 * 2^(n-1) := by ring
      rw [this, h_calc, h_exp, ZMod.natCast_self]
    rw [add_assoc, this, add_zero]"""
content = content.replace(old_offdiag, new_offdiag)

# Fix 3: D'_block_diag
old_block_diag = """theorem D'_block_diag {n : ℕ} (hn : n ≥ 2) :
    conjBlockInv (d := n + 1) * D'_matrix hn * conjBlock (d := n + 1) =
    D'_block_diag_target hn := by
  sorry"""

new_block_diag = """theorem D'_block_diag {n : ℕ} (hn : n ≥ 2) :
    conjBlockInv (d := n) * D'_matrix hn * conjBlock (d := n) =
    D'_block_diag_target hn := by
  sorry"""
content = content.replace(old_block_diag, new_block_diag)

with open(r'c:\Users\x\.gemini\antigravity\scratch\adelic_spectral_zeta\formalization\Formalization\CollatzRelMatrix.lean', 'w', encoding='utf-8') as f:
    f.write(content)

print("File patched.")
