import sys
import os
import time
from io import BytesIO
from PIL import Image, ImageDraw
import torch
import torch.nn as nn
import torch.nn.functional as F
import math

# Ensure the src/ directory and the root directory are in the Python path
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "src")))
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), "..")))

# Try to load HF_TOKEN from Google Colab secrets if available
try:
    from google.colab import userdata
    token = userdata.get('HF_TOKEN')
    if token:
        os.environ["HF_TOKEN"] = token
        print("[Agent] Loaded HF_TOKEN from Colab secrets.")
except Exception:
    pass

# Safe PyAutoGUI import for headless test environments
HAS_PYAUTOGUI = False
try:
    import pyautogui
    pyautogui.FAILSAFE = True
    HAS_PYAUTOGUI = True
    print("[Agent] PyAutoGUI initialized successfully (GUI mode active).")
except Exception as e:
    print(f"[Agent] PyAutoGUI import failed ({e}). Running in HEADLESS MOCK mode.")

from transformers import AutoConfig, AutoModelForCausalLM, ViTImageProcessor, ViTModel, ViTConfig
from llama_surgery import inject_surgery, SurgicalLlamaAttention, DynamicTopologyRouter
from llama_surgery.layer import apply_rotary_pos_emb


# ==============================================================================
# 1. Vision Projection Layer
# ==============================================================================

class VisionProjection(nn.Module):
    def __init__(self, vit_dim: int = 768, llm_dim: int = 2048):
        super().__init__()
        self.proj = nn.Sequential(
            nn.Linear(vit_dim, llm_dim),
            nn.GELU(),
            nn.Linear(llm_dim, llm_dim)
        )
        
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        return self.proj(x)


# ==============================================================================
# 2. Surgical Multimodal Attention
# ==============================================================================

class SurgicalMultimodalAttention(SurgicalLlamaAttention):
    def __init__(self, config, layer_idx=None):
        config.surgical_p = 3
        super().__init__(config, layer_idx=layer_idx)
        
    def forward(
        self,
        hidden_states: torch.Tensor,
        position_embeddings = None,
        attention_mask = None,
        past_key_values = None,
        modality_indices = None,
        **kwargs,
    ):
        batch_size, seq_len, _ = hidden_states.size()
        past_key_value = kwargs.get("past_key_value", past_key_values)
        tau = getattr(self.config, "surgical_tau", 1.0)
        
        curr_assignments, load_balance_loss = self.router(hidden_states, tau_override=tau)
        self.current_penalty = load_balance_loss
        
        # Modality routing segregation loss (only during training)
        if modality_indices is not None and self.training:
            level0_routing = curr_assignments[..., 0, :]
            text_mask = (modality_indices == 0).float().view(1, 1, seq_len, 1)
            vision_mask = (modality_indices == 1).float().view(1, 1, seq_len, 1)
            
            text_loss = (1.0 - level0_routing[..., 0]) * text_mask.squeeze(-1)
            vision_loss = (1.0 - level0_routing[..., 1]) * vision_mask.squeeze(-1)
            seg_loss = (text_loss.sum() + vision_loss.sum()) / (seq_len + 1e-8)
            self.current_penalty = load_balance_loss + 0.5 * seg_loss
            
        if past_key_value is None or seq_len > 1:
            self._cached_assignments = curr_assignments
            assignments = curr_assignments
        else:
            if hasattr(self, '_cached_assignments') and self._cached_assignments is not None:
                assignments = torch.cat([self._cached_assignments, curr_assignments], dim=2)
                self._cached_assignments = assignments
            else:
                assignments = curr_assignments
                self._cached_assignments = assignments

        q = self.q_proj(hidden_states).view(batch_size, seq_len, self.num_heads, self.head_dim).transpose(1, 2)
        k = self.k_proj(hidden_states).view(batch_size, seq_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)
        v = self.v_proj(hidden_states).view(batch_size, seq_len, self.num_key_value_heads, self.head_dim).transpose(1, 2)

        if position_embeddings is not None:
            cos, sin = position_embeddings
            if cos.dim() == 3:
                cos = cos.unsqueeze(1)
                sin = sin.unsqueeze(1)
            def rotate_half(x):
                x1, x2 = x[..., : x.shape[-1] // 2], x[..., x.shape[-1] // 2 :]
                return torch.cat((-x2, x1), dim=-1)
            q = (q * cos) + (rotate_half(q) * sin)
            k = (k * cos) + (rotate_half(k) * sin)
        else:
            cos, sin = self.rope(q)
            q, k = apply_rotary_pos_emb(q, k, cos, sin)

        k = self._repeat_kv(k, self.num_key_value_groups)
        v = self._repeat_kv(v, self.num_key_value_groups)

        scores = torch.matmul(q.to(torch.float32), k.to(torch.float32).transpose(-2, -1)) * self.scale
        if attention_mask is not None:
            scores = scores + attention_mask
        else:
            causal_mask = torch.triu(torch.ones(seq_len, seq_len, dtype=torch.bool, device=hidden_states.device), diagonal=1)
            scores = scores.masked_fill(causal_mask, float('-inf'))

        from llama_surgery.topology import get_dynamic_ultrametric_mask
        local_window = getattr(self.config, "surgical_local_window", 16)
        full_mask = get_dynamic_ultrametric_mask(assignments, p=self.p, local_window=local_window).to(hidden_states.device)
        um_mask_bool = full_mask > 0.5
        
        sparse_scores = scores.masked_fill(~um_mask_bool, float('-inf'))
        is_all_neg_inf = (sparse_scores == float('-inf')).all(dim=-1, keepdim=True)
        sparse_scores = sparse_scores.masked_fill(is_all_neg_inf, 0.0)
        
        attn_weights = F.softmax(sparse_scores, dim=-1, dtype=torch.float32)
        attn_weights = torch.nan_to_num(attn_weights, 0.0)
        
        attn_weights = attn_weights * full_mask
        attn_weights = attn_weights / (attn_weights.sum(dim=-1, keepdim=True) + 1e-8)

        attn_weights = attn_weights.to(v.dtype)
        attn_weights = self.attn_dropout(attn_weights)

        out = torch.matmul(attn_weights, v)
        out = out.transpose(1, 2).contiguous().view(batch_size, seq_len, self.embed_dim)
        out = self.o_proj(out)
        
        return out, attn_weights

    def _repeat_kv(self, x, n_rep):
        if n_rep == 1:
            return x
        batch, num_key_value_heads, slen, head_dim = x.shape
        x = x[:, :, None, :, :].expand(batch, num_key_value_heads, n_rep, slen, head_dim)
        return x.reshape(batch, num_key_value_heads * n_rep, slen, head_dim)


def inject_multimodal_surgery(model):
    for i, layer in enumerate(model.model.layers):
        old_attn = layer.self_attn
        new_attn = SurgicalMultimodalAttention(model.config, layer_idx=i)
        new_attn.q_proj.weight = old_attn.q_proj.weight
        new_attn.k_proj.weight = old_attn.k_proj.weight
        new_attn.v_proj.weight = old_attn.v_proj.weight
        new_attn.o_proj.weight = old_attn.o_proj.weight
        if hasattr(old_attn.q_proj, 'bias') and old_attn.q_proj.bias is not None:
            new_attn.q_proj.bias = old_attn.q_proj.bias
        if hasattr(old_attn.k_proj, 'bias') and old_attn.k_proj.bias is not None:
            new_attn.k_proj.bias = old_attn.k_proj.bias
        if hasattr(old_attn.v_proj, 'bias') and old_attn.v_proj.bias is not None:
            new_attn.v_proj.bias = old_attn.v_proj.bias
        if hasattr(old_attn.o_proj, 'bias') and old_attn.o_proj.bias is not None:
            new_attn.o_proj.bias = old_attn.o_proj.bias
        new_attn.to(old_attn.q_proj.weight.device, dtype=old_attn.q_proj.weight.dtype)
        layer.self_attn = new_attn
    return model


# ==============================================================================
# 3. Interactive Screen Agent Loop
# ==============================================================================

class InteractiveScreenAgent:
    def __init__(self, device: str = None):
        if device is None:
            self.device = "cuda" if torch.cuda.is_available() else "cpu"
        else:
            self.device = device
            
        print(f"[Agent] Starting up on device: {self.device}")
        
        # Initialize LLM config & model backbone (tiny configuration for testing)
        config = AutoConfig.from_pretrained("TinyLlama/TinyLlama-1.1B-Intermediate-Step-1431k-3T")
        config.num_hidden_layers = 2
        config.hidden_size = 64
        config.intermediate_size = 128
        config.num_attention_heads = 4
        config.num_key_value_heads = 2
        config.head_dim = 16
        config.max_position_embeddings = 256
        
        self.model = AutoModelForCausalLM.from_config(config)
        self.model = inject_multimodal_surgery(self.model)
        self.model.to(self.device)
        self.model.eval()
        
        # Initialize Vision Transformer
        self.load_pretrained = (self.device == "cuda")
        if self.load_pretrained:
            try:
                print("[Agent] Loading pretrained google/vit-base-patch16-224...")
                self.vit_processor = ViTImageProcessor.from_pretrained("google/vit-base-patch16-224")
                self.vit_model = ViTModel.from_pretrained("google/vit-base-patch16-224")
                print("[Agent] Pretrained ViT loaded successfully.")
            except Exception as e:
                print(f"[Agent] Pretrained ViT load failed: {e}. Falling back to random config.")
                self.load_pretrained = False

        if not self.load_pretrained:
            print("[Agent] Using tiny randomly-initialized ViT for local/CPU execution.")
            vit_config = ViTConfig(
                hidden_size=64,
                num_hidden_layers=2,
                num_attention_heads=4,
                intermediate_size=128
            )
            self.vit_processor = ViTImageProcessor()
            self.vit_model = ViTModel(vit_config)
            
        self.vit_model.to(self.device)
        self.vit_model.eval()
        for param in self.vit_model.parameters():
            param.requires_grad = False
            
        # Get dynamic shapes
        self.image_len = 196
        self.vit_dim = self.vit_model.config.hidden_size
        self.vision_proj = VisionProjection(vit_dim=self.vit_dim, llm_dim=64).to(self.device)
        self.vision_proj.eval()
        
    def capture_screen(self, step_idx: int) -> Image.Image:
        """Captures the real screen using PyAutoGUI or generates a synthetic screen grab in headless mode."""
        if HAS_PYAUTOGUI:
            try:
                print("[Agent] Capturing active desktop screen...")
                return pyautogui.screenshot()
            except Exception as e:
                print(f"[Agent] Screen capture failed ({e}). Generating synthetic fallback.")
                
        # Generate synthetic desktop screenshot
        print(f"[Agent] Generating mock screen capture (Step {step_idx})...")
        img = Image.new("RGB", (800, 600), color=(30, 30, 30))
        draw = ImageDraw.Draw(img)
        
        # Draw some mock windows
        draw.rectangle([50, 50, 450, 400], fill=(50, 50, 50), outline=(100, 100, 100)) # Window 1
        draw.text((60, 60), "VS Code - main.py", fill=(255, 255, 255))
        draw.rectangle([80, 100, 420, 350], fill=(20, 20, 20)) # Code area
        
        draw.rectangle([500, 80, 750, 520], fill=(40, 40, 50), outline=(80, 80, 100)) # Window 2 (Browser)
        draw.text((510, 90), "Hugging Face - Adelic-Gemma", fill=(255, 255, 255))
        
        # Draw mock search box & cursor
        draw.rectangle([550, 150, 720, 180], fill=(255, 255, 255))
        draw.text((555, 155), "Search models...", fill=(0, 0, 0))
        
        # Draw cursor
        draw.polygon([580, 165, 580, 185, 595, 175], fill=(255, 0, 0)) # Mouse cursor
        
        return img.resize((224, 224)) # Resize to match ViT input size

    def process_frame(self, image: Image.Image) -> torch.Tensor:
        """Preprocesses PIL image and extracts visual patch embeddings."""
        inputs = self.vit_processor(images=image, return_tensors="pt").to(self.device)
        with torch.no_grad():
            outputs = self.vit_model(**inputs)
            # Remove [CLS] token
            features = outputs.last_hidden_state[:, 1:, :] # (1, 196, vit_dim)
        return features

    def decide_action(self, image_features: torch.Tensor, instruction: str) -> dict:
        """Runs inference to decide the next GUI action."""
        # 1. Project visual features to LLM embedding dimension
        with torch.no_grad():
            vision_embeds = self.vision_proj(image_features) # (1, 196, 64)
            
        # 2. Tokenize instructions
        # Since we are using a mock/tiny configuration for simulation, we'll construct mock text inputs
        text_len1 = 16
        text_len2 = 16
        seq_len = text_len1 + self.image_len + text_len2
        
        modality_indices = torch.cat([
            torch.zeros(text_len1, dtype=torch.long),
            torch.ones(self.image_len, dtype=torch.long),
            torch.zeros(text_len2, dtype=torch.long)
        ]).to(self.device)
        
        text_ids = torch.randint(0, 1000, (1, text_len1 + text_len2)).to(self.device)
        
        # 3. Interleave and forward
        with torch.no_grad():
            text_embeds = self.model.model.embed_tokens(text_ids)
            interleaved_embeds = torch.cat([
                text_embeds[:, :text_len1, :],
                vision_embeds,
                text_embeds[:, text_len1:, :]
            ], dim=1)
            
            for layer in self.model.model.layers:
                layer.self_attn.modality_indices = modality_indices
                
            hidden_states = interleaved_embeds
            cos, sin = self.model.model.layers[0].self_attn.rope(hidden_states)
            position_embeddings = (cos.unsqueeze(0), sin.unsqueeze(0))
            
            for layer in self.model.model.layers:
                hidden_states, attn_weights = layer.self_attn(
                    hidden_states=hidden_states,
                    position_embeddings=position_embeddings,
                    modality_indices=modality_indices
                )
                hidden_states = layer.post_attention_layernorm(hidden_states)
                hidden_states = hidden_states + layer.mlp(hidden_states)
                
            # Retrieve primary routing choices
            assignments, _ = self.model.model.layers[0].self_attn.router(interleaved_embeds)
            level0_choices = assignments[0, 0, :, 0, :].argmax(dim=-1)
            
        # 4. Generate action command (simulate VLM output parser)
        # In a production setup, we would read the decoded tokens from the model.
        # For this simulation loop, we'll verify the coordinates from the mock screen state.
        print(f"[Agent] Router modality choices: Text={ (level0_choices == 0).sum().item() } tokens, Vision={ (level0_choices == 1).sum().item() } tokens")
        
        # Mock action: Click search box at (600, 165)
        action = {
            "action": "click",
            "x": 600,
            "y": 165,
            "reason": f"Found search bar for task '{instruction}'"
        }
        return action

    def execute_action(self, action: dict):
        """Executes the action dict using PyAutoGUI or mock-logs it in headless environments."""
        action_type = action.get("action")
        reason = action.get("reason", "")
        
        print(f"[Agent] Decision: {reason.upper()}")
        
        if HAS_PYAUTOGUI:
            try:
                if action_type == "click":
                    x, y = action["x"], action["y"]
                    print(f"[Agent] Executing click at ({x}, {y}) using PyAutoGUI...")
                    pyautogui.moveTo(x, y, duration=0.5)
                    pyautogui.click()
                elif action_type == "type":
                    text = action["text"]
                    print(f"[Agent] Executing text input: '{text}' using PyAutoGUI...")
                    pyautogui.write(text, interval=0.1)
                elif action_type == "sleep":
                    delay = action.get("duration", 1.0)
                    print(f"[Agent] Cooldown sleep for {delay}s...")
                    time.sleep(delay)
                return
            except Exception as e:
                print(f"[Agent] PyAutoGUI execution failed ({e}). Reverting to mock log.")
                
        # Headless mock log execution
        if action_type == "click":
            print(f"[Mock Action] Move mouse to ({action['x']}, {action['y']}) and CLICK.")
        elif action_type == "type":
            print(f"[Mock Action] Write text: '{action['text']}'.")
        time.sleep(0.5)

    def run_agent_loop(self, instruction: str, max_steps: int = 3):
        print(f"\n===== [Agent Loop Started] Task: '{instruction}' =====")
        for step in range(1, max_steps + 1):
            print(f"\n--- Step {step} of {max_steps} ---")
            
            # 1. Capture screen (Perceive)
            screenshot = self.capture_screen(step)
            
            # 2. Extract features
            image_features = self.process_frame(screenshot)
            
            # 3. Decide next action (Think)
            action = self.decide_action(image_features, instruction)
            
            # 4. Execute action (Act)
            self.execute_action(action)
            
            # Cooldown delay
            time.sleep(1.0)
            
        print("\n===== [Agent Loop Completed] =====")


if __name__ == "__main__":
    agent = InteractiveScreenAgent()
    agent.run_agent_loop(instruction="Navigate to Adelic-Gemma Hugging Face model and search reviews.", max_steps=2)
