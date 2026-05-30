# Llama Surgery Golfing Strategy & Resolution

## Open Question Resolution
**Decision:** The routing logit $z$ must be a **single learnable scalar per-head ($z_h$)**, not a per-token projection.

### Theoretical Justification
1. **Routing Absorption (Aquino-Michaels, 2026):** As demonstrated in *"Routing Absorption in Sparse Attention: Why Random Gates Are Hard to Beat"*, employing per-query token-level gating in end-to-end sparse attention results in severe co-adaptation. The massive Q/K/V parameter space will actively compensate for the mask imposed by a small gate network, absorbing the routing signal. Consequently, learned per-token gates perform no better than frozen random gates. A post-hoc or structurally decoupled approach is required to sidestep this parameter asymmetry.
2. **Structured Continuous Sparsification (Savarese et al., 2020):** In *"Growing Efficient Deep Networks by Structured Continuous Sparsification"*, the authors demonstrate that continuous relaxation of discrete structure optimization is highly effective when applied to structured components (e.g., layers, filters). A single scalar parameter per head allows the model to structurally prune/sparsify the entire attention head, rather than fighting against token-level statistical noise.
3. **Roadmap Consistency:** The V3 roadmap explicitly denotes the polarized routing depths as $d_h = \mathbb{1}[z > 0]$. The subscript $h$ confirms that this decision was mathematically intended to be made per-head, not per-token.

If we were to use a per-token router (akin to Mixture-of-Depths, Raposo et al. 2024, which works for general tokens but faces attention-specific absorption as noted by Aquino-Michaels), the dense pre-trained Llama model would simply exploit its existing Q/K/V manifolds to game the auxiliary loss, collapsing the topological structure.

---

## Implementation Roadmap for Llama Surgery

### 1. `MultiPrimeTopologyRouter`
The router must be stripped of any hidden-state linear projections. It will maintain a structured parameter set for the heads.

- **Learnable Parameter:** Define a single parameter tensor for the logits:
  ```python
  self.z = nn.Parameter(torch.full((num_heads,), -5.0)) # \mu_{init} = -5.0
  ```
- **Gumbel-Sigmoid Gating:** During the forward pass, sample Gumbel noise and apply the temperature $\tau(t)$:
  ```python
  g_h = torch.sigmoid((self.z + gumbel_noise) / tau)
  ```
  The resulting $g_h \in [0, 1]$ is a vector of size `(num_heads,)`.

### 2. `SurgicalLlamaAttention`
Modify the core attention computation to broadcast the per-head gate across the sequence length.

- **Attention Modification:** 
  ```python
  # g_h shape: (batch_size, num_heads, 1, 1) after unsqueezing
  # T_ij shape: (1, 1, seq_len, seq_len)
  scores = scores + g_h * alpha * T_ij
  ```
  At step 0, $\mathbb{E}[g_h] \approx 0$, meaning `scores` remains effectively identical to the pre-trained dense distribution, guaranteeing zero-shock insertion.

### 3. `SurgeryLossRamp` (Curriculum)
The auxiliary loss penalty applies directly to the scalar logits of each head, promoting sparsity smoothly.

- **Auxiliary Loss:**
  $$ \mathcal{L}_{aux}(t) = \lambda(t) \cdot \frac{1}{H \cdot |\mathcal{P}|} \sum_{h, p} (1 - g_h^{(p)}) $$
- **Annealing:** As temperature $\tau(t)$ decays from $1.0 \to 0.1$, the scalar parameters $z_h$ will naturally polarize, forcing the head to decide entirely between dense execution ($g_h \approx 0$) or sparse ultrametric execution ($g_h \approx 1$).

### 4. Hardware Extraction
Once training completes and the gates have polarized, the continuous framework is discarded. The routing depths are statically extracted as $d_h = \mathbb{1}[z_h > 0]$ and passed directly into the Triton block-sparse kernel for $O(N \log N)$ execution.
