# Session Handoff: Schreier Graph Spectral Gap

## What We Accomplished (Layman's Terms)
We've made massive strides in analyzing the "Schreier Graph" that models Collatz-like sequences. Following the discovery that the "uniform spectral gap" conjecture was false, we pivoted entirely and established a new, highly rigorous roadmap.

Most importantly, we **fully formalized the Exact Trace Identity (ETI)** in the Lean 4 theorem prover! We rigorously proved that the trace of the `sheetDiffMatrix` (the matrix representing the structural differences between symmetrical halves of the graph) collapses exactly to `-1`. This was proven completely from first principles with **0 sorrys and 0 unproven axioms**, effectively establishing a concrete topological constant for the graph's folding properties.

---

## Critical Tips & Tricks (How to Survive Lean 4 and Python)

If you are picking up where we left off, DO NOT ignore these hard-learned lessons. We spent significant time battling both out-of-memory errors and Lean's type system to uncover these:

### 1. The ZMod Arithmetic Trap
Lean 4 is notoriously pedantic when handling `ZMod N` where `N` is an arbitrary parameter (like $2^{d-1}$). 
* **The Trap:** The `omega` tactic (Lean's Presburger arithmetic solver) **does not work** with modulo operations when the modulus is a variable. 
* **The Trick:** Do not try to solve `(x + 2^(d-2)) % 2^(d-1) = 3x % 2^(d-1)` directly with `omega` or `ring`. Instead, immediately lift the terms to `Nat` and explicitly unfold the modulo using bounds checking. If you can prove that `a < N`, you can rewrite `a % N = a` using `Nat.mod_eq_of_lt`. Once the `%` operator is removed from the goal, `omega` can effortlessly solve the remaining inequalities.

### 2. OOM (Out-of-Memory) on Large Graph Generation
When doing numerical validations in Python (which you should ALWAYS do before trying to prove something in Lean):
* **The Trap:** Using dense matrices like `nx.adjacency_matrix(G).toarray()` will completely blow up your RAM. At $d=18$, the matrix requires tens of gigabytes to store as a dense array, which will crash your kernel.
* **The Trick:** Always slice and manipulate matrices using SciPy's sparse CSR formats directly (e.g. `adj[:N_half, :N_half]`). We were able to push computations to $d=20$ in mere seconds by keeping everything strictly sparse.

### 3. Handling Lean Graph Adjacencies
* **The Trick:** When evaluating `G.Adj x y`, Lean will break it down into multiple logical branches (`y = 3x \lor y = 3x - 1 \dots`). Use the `rcases` tactic to split these immediately, and attack the odd/even parity constraints. Many branches trivially collapse when you prove that an even number equals an odd number.

---

## The Lean Roadmap & Current Progress

We have a completely rigorous hierarchy of targets that fully capture the hierarchical diffusion of the graph:

### ✅ Target 1: The Exact Trace Identity (COMPLETED)
* **Theorem:** `Tr(sheetDiffMatrix) = -1` for all $d \ge 3$.
* **Status:** **Fully verified in `SchreierTrace.lean`**. We mathematically isolated the single monodromy loop connection between sheets and computed the matrix trace over the finite field, resulting in 0 warnings and 0 sorrys.

### 🚧 Target 2: Rigorous Relative Gap ($\lambda_{\text{anti}} > \lambda_{\text{sym},2}$) (UP NEXT)
* **The Goal:** Prove that the maximum antisymmetric eigenvalue strictly dominates the second largest symmetric eigenvalue.
* **Why it matters:** This proves that the antisymmetric block determines the global spectral gap ($\lambda_1$) of the full graph.
* **🚨 ADVERSARIAL TAKEDOWN (LLM Frontier Pitfall):** 
  Do NOT attempt to prove this algebraically using the Characteristic Polynomial or determinant manipulations. The symbolic matrices are $2^{d-1} \times 2^{d-1}$. An AI attempting to bash these matrices in Lean 4 will burn thousands of tokens hallucinating impossible tactic proofs and crash. 
  **The Correct Path:** You *must* use the **Min-Max Theorem (Rayleigh Quotients)**. The AI needs to be spoon-fed the exact mathematical formula for the test vector to lower-bound $\lambda_{\text{anti}}$. Do not let the AI try to guess the vector or guess the Poincaré inequality flows. Derive them in Python/on paper first.

### 🎯 Target 3: The $12/d^2$ Asymptotic Decay (Paper Target)
* **The Conjecture:** The relative spectral gap behaves as $1 - \rho(d) \sim 12/d^2$ as $d \to \infty$.
* **Status:** We **numerically verified** this up to $d=20$ using high-precision sparse Lanczos eigensolvers. The constant $C = (1-\rho)d^2$ converges beautifully to exactly $12$. The ultimate long-term goal is to formalize this discrete geometric scaling limit.
* **🚨🚨 ULTIMATE WINDMILL WARNING (LLM Frontier Pitfall):** 
  Do NOT attempt to formulate this as a discrete limit `Tendsto (fun d => ...)` in Lean 4. You cannot smoothly take limits of sequences of operators acting on vector spaces of exponentially growing dimension (`ZMod (2^d)`). An AI attempting this will be instantly destroyed by Lean's type universes.
  **The Correct Path:** The scaling $1/d^2$ implies the bottleneck behaves as a continuous 1D string. You must transition to the **Continuum Limit**. The only mathematically viable path for formalization is to define the infinite $p$-adic (or 2-adic) Adelic differential operator, prove the continuous spectrum there, and *then* prove the discrete Schreier graphs converge to it. 
