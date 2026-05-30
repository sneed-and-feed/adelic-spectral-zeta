"""
Ultrametric AI — Dynamic Topology Router (PyTorch)

Maps continuous token embeddings into discrete Bruhat-Tits tree branches
via per-head factorized Gumbel-Softmax routing. Each attention head routes
independently, enabling different heads to attend to different hierarchical
sub-structures of the fractal tree.

Includes auxiliary load-balancing loss to prevent routing collapse
(Switch Transformer, Fedus et al. 2021).
"""

import torch
import torch.nn as nn
import torch.nn.functional as F
import math
from typing import Optional, Tuple


class DynamicTopologyRouter(nn.Module):
    """
    Multi-Head Dynamic Topology Router.

    Projects token embeddings into per-head recursive p-adic tree paths.
    Each head gets its own routing decision at every level of the Bruhat-Tits
    tree, producing a genuinely nested hierarchical mask — not a flat partition.

    Args:
        embed_dim: token embedding dimension
        seq_len: maximum sequence length (determines tree depth)
        num_heads: number of independent routing heads
        p: tree arity (2 = binary Bruhat-Tits tree)
        tau: Gumbel-Softmax temperature (higher = softer routing)
        hard: if True, use straight-through estimator for discrete routing
    """

    def __init__(
        self,
        embed_dim: int,
        seq_len: int,
        num_heads: int = 1,
        p: int = 2,
        tau: float = 1.0,
        hard: bool = True,
    ):
        super().__init__()
        self.embed_dim = embed_dim
        self.num_heads = num_heads
        self.p = p
        self.tau = tau
        self.hard = hard
        self.levels = int(math.ceil(math.log(max(seq_len, 2), p)))

        # Per-head routing: shared backbone, per-head projection heads
        self.backbone = nn.Linear(embed_dim, embed_dim)
        self.route_heads = nn.Linear(embed_dim, num_heads * self.levels * p)

    def forward(
        self, x: torch.Tensor, tau_override: Optional[float] = None
    ) -> Tuple[torch.Tensor, torch.Tensor]:
        """
        Args:
            x: (batch, seq_len, embed_dim) token embeddings
            tau_override: optional temperature override for annealing schedules

        Returns:
            assignments: (batch, num_heads, seq_len, levels, p) routing weights
            load_balance_loss: scalar auxiliary loss for training stability
        """
        batch_size, seq_len, _ = x.shape
        tau = tau_override if tau_override is not None else self.tau

        # Shared feature extraction → per-head routing logits
        h = F.gelu(self.backbone(x))  # (batch, seq_len, embed_dim)
        logits = self.route_heads(h)  # (batch, seq_len, num_heads * levels * p)
        logits = logits.view(batch_size, seq_len, self.num_heads, self.levels, self.p)
        logits = logits.permute(0, 2, 1, 3, 4)  # (batch, heads, seq_len, levels, p)

        if self.training:
            # Flatten for gumbel_softmax, then reshape back
            flat = logits.reshape(-1, self.p)
            sampled = F.gumbel_softmax(flat, tau=tau, hard=self.hard, dim=-1)
            assignments = sampled.view_as(logits)
        else:
            # Deterministic argmax at inference
            indices = logits.argmax(dim=-1)
            assignments = F.one_hot(indices, num_classes=self.p).float()

        load_balance_loss = self.compute_load_balance_loss(assignments)
        return assignments, load_balance_loss

    @staticmethod
    def compute_load_balance_loss(assignments: torch.Tensor) -> torch.Tensor:
        """
        Switch Transformer-style load balancing loss.

        Penalizes routing imbalance to prevent all tokens collapsing to one
        branch. Loss is minimized when tokens are uniformly distributed
        across branches at every level.

        L_balance = p * sum_i(f_i * P_i) per level, averaged over heads/batch.

        Args:
            assignments: (batch, num_heads, seq_len, levels, p) routing weights
        Returns:
            loss: scalar tensor
        """
        p = assignments.shape[-1]
        # f_i: fraction of tokens routed to each branch (hard counts)
        f = (assignments.detach() > 0.5).float().mean(dim=2)  # (B, H, L, p)
        # P_i: mean routing probability to each branch (soft, differentiable)
        P = assignments.mean(dim=2)  # (B, H, L, p)
        # Dot product per level, scale by p so uniform distribution → loss = 1
        loss = (f * P).sum(dim=-1).mean() * p
        return loss

    @staticmethod
    def get_tau_schedule(
        step: int,
        warmup_steps: int = 2000,
        tau_start: float = 2.0,
        tau_end: float = 0.1,
    ) -> float:
        """
        Cosine temperature annealing: soft routing → hard routing over training.

        Args:
            step: current training step
            warmup_steps: total annealing steps
            tau_start: initial temperature (soft)
            tau_end: final temperature (hard)
        Returns:
            tau: current temperature value
        """
        if step >= warmup_steps:
            return tau_end
        progress = step / warmup_steps
        return tau_end + 0.5 * (tau_start - tau_end) * (1 + math.cos(math.pi * progress))

class MultiPrimeTopologyRouter(nn.Module):
    """
    Wraps multiple DynamicTopologyRouter instances for multi-prime (True Adelic) routing.
    Divides the attention heads into equal-sized groups, assigning a different
    prime arity to each group.
    """
    def __init__(
        self,
        embed_dim: int,
        seq_len: int,
        num_heads: int,
        prime_arities: list[int],
        tau: float = 1.0,
        hard: bool = True,
    ):
        super().__init__()
        self.prime_arities = prime_arities
        self.num_groups = len(prime_arities)
        
        assert num_heads % self.num_groups == 0, f"num_heads ({num_heads}) must be divisible by number of prime arities ({self.num_groups})"
        self.heads_per_group = num_heads // self.num_groups
        
        self.routers = nn.ModuleList([
            DynamicTopologyRouter(
                embed_dim=embed_dim,
                seq_len=seq_len,
                num_heads=self.heads_per_group,
                p=p,
                tau=tau,
                hard=hard,
            ) for p in prime_arities
        ])

    def forward(
        self, x: torch.Tensor, tau_override: Optional[float] = None
    ) -> Tuple[list[torch.Tensor], torch.Tensor]:
        """
        Returns:
            assignments: list of routing weights for each prime group
            total_loss: scalar auxiliary loss
        """
        assignments = []
        total_loss = 0.0
        for router in self.routers:
            assn, loss = router(x, tau_override=tau_override)
            assignments.append(assn)
            total_loss = total_loss + loss
        return assignments, total_loss



# ============================================================================
# Ultrametric Mask Utilities
# ============================================================================


def get_dynamic_ultrametric_mask(
    assignments: torch.Tensor, p: int = 2, max_dist: Optional[int] = None, local_window: int = 0
) -> torch.Tensor:
    """
    Generates a dynamic ultrametric mask from learned routing assignments.

    Two tokens attend to each other if their expected p-adic distance
    (height of lowest common ancestor in the Bruhat-Tits tree) ≤ max_dist.

    Supports both shared routing (4D input) and per-head routing (5D input).

    Args:
        assignments: (batch, seq_len, levels, p) shared routing, OR
                     (batch, heads, seq_len, levels, p) per-head routing
        p: tree arity
        max_dist: maximum p-adic distance for attention. Default: levels // 2

    Returns:
        mask: (batch, seq_len, seq_len) or (batch, heads, seq_len, seq_len)
    """
    if assignments.dim() == 5:
        B, H, S, L, P = assignments.shape
        a_flat = assignments.reshape(B * H, S, L, P)
        mask_flat = _compute_distance_mask(a_flat, L, max_dist, local_window)
        return mask_flat.view(B, H, S, S)
    else:
        B, S, L, P = assignments.shape
        return _compute_distance_mask(assignments, L, max_dist, local_window)


def _compute_distance_mask(
    assignments: torch.Tensor, levels: int, max_dist: Optional[int], local_window: int = 0
) -> torch.Tensor:
    """
    Core p-adic distance mask computation via reversed cumulative product.

    The expected p-adic distance between tokens i and j is:
        d(i,j) = levels - sum_{l=0}^{levels-1} prod_{m=l}^{levels-1} M[i,j,m]
    where M[i,j,l] is the probability that tokens i,j share branch l.
    """
    # Compute expected distance iteratively to save memory (avoids B*S*S*L tensor)
    # Expected distance = levels - sum_{l=0}^{levels-1} prod_{m=l}^{levels-1} M[i,j,m]
    # We compute this by iterating from l = levels-1 down to 0
    B, S, L, P = assignments.shape
    sum_P = torch.zeros(B, S, S, device=assignments.device, dtype=assignments.dtype)
    current_P = torch.ones(B, S, S, device=assignments.device, dtype=assignments.dtype)
    
    for l in reversed(range(L)):
        # Probability tokens i, j agree at level l
        # M_l shape: (B, S, S)
        A_l = assignments[:, :, l, :]
        M_l = torch.bmm(A_l, A_l.transpose(-1, -2))
        
        current_P = current_P * M_l
        sum_P = sum_P + current_P

    expected_dist = levels - sum_P

    if max_dist is None:
        max_dist = max(levels // 2, 1)

    # Straight-Through Estimator: hard mask forward, soft gradient backward
    temperature = 0.5
    soft_mask = torch.sigmoid((max_dist - expected_dist) / temperature)
    hard_mask = (expected_dist <= max_dist).float()
    
    if local_window > 0:
        S = expected_dist.shape[-1]
        idx = torch.arange(S, device=expected_dist.device)
        band = (torch.abs(idx.unsqueeze(0) - idx.unsqueeze(1)) <= local_window).float()
        hard_mask = torch.clamp(hard_mask + band, max=1.0)
        
    mask = hard_mask.detach() - soft_mask.detach() + soft_mask
    return mask


def get_ultrametric_mask(seq_len: int, p: int = 2) -> torch.Tensor:
    """
    Generates a static boolean mask for ultrametric (p-adic) attention.

    In a standard dense transformer, every token attends to every other token.
    In an ultrametric Bruhat-Tits topology, tokens are leaves on a tree.
    Tokens only strongly attend to tokens that share a deep common ancestor.

    This function generates a block-sparse mask where the density decreases
    as the p-adic distance increases, dropping connections that are
    topologically "far".

    Args:
        seq_len: sequence length
        p: tree arity (default: 2 for binary tree)
    Returns:
        mask: (seq_len, seq_len) boolean tensor
    """
    levels = int(math.ceil(math.log(max(seq_len, 2), p)))
    pad_len = p**levels

    mask = torch.zeros((pad_len, pad_len), dtype=torch.bool)
    for level in range(levels):
        block_size = p**level
        for i in range(0, pad_len, block_size):
            mask[i : i + block_size, i : i + block_size] = True

    return mask[:seq_len, :seq_len]


def compute_p_adic_distance(i: int, j: int, p: int = 2) -> int:
    """
    Computes the p-adic distance between two token indices.
    Corresponds to the height of their lowest common ancestor in a p-ary tree.
    """
    if i == j:
        return 0
    diff = i ^ j
    return int(math.floor(math.log(diff, p))) + 1
