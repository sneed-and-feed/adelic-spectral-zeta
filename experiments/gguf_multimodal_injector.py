import os
import sys
import time
import argparse
import ctypes
import numpy as np
import torch
import torch.nn as nn
from PIL import Image, ImageDraw
import requests

# Try to load HF_TOKEN from Google Colab secrets if available
try:
    from google.colab import userdata
    token = userdata.get('HF_TOKEN')
    if token:
        os.environ["HF_TOKEN"] = token
        print("[Injector] Loaded HF_TOKEN from Colab secrets.")
except Exception:
    pass

# ==============================================================================
# 1. Low-level Llama.cpp Ctypes Mocking / Loading
# ==============================================================================

HAS_LLAMA_CPP = False
try:
    import llama_cpp
    import llama_cpp.llama_cpp as ll_cpp
    HAS_LLAMA_CPP = True
    print("[Injector] llama-cpp-python loaded successfully.")
except ImportError:
    print("[Injector] llama-cpp-python not found. Falling back to HEADLESS MOCK mode.")

# Define mock types if llama_cpp is not available
if not HAS_LLAMA_CPP:
    # Creating a dummy namespace to prevent NameErrors
    class MockLlamaCpp:
        @staticmethod
        def llama_backend_init():
            print("[Mock C API] llama_backend_init()")

        @staticmethod
        def llama_backend_free():
            print("[Mock C API] llama_backend_free()")

        @staticmethod
        def llama_model_n_embd(model):
            return 3072  # Gemma-4-12B hidden size

        @staticmethod
        def llama_decode(ctx, batch):
            print(f"[Mock C API] llama_decode(ctx, batch) with n_tokens={batch.n_tokens}, is_embeddings={batch.embd is not None}")
            if batch.embd is not None:
                # Print sample embeddings shape/info
                print(f"  -> Decoded {batch.n_tokens} custom visual embeddings into KV cache.")
            else:
                sample_tokens = [batch.token[i] for i in range(min(5, batch.n_tokens))]
                print(f"  -> Decoded tokens: {sample_tokens} ... at positions: {[batch.pos[i] for i in range(min(5, batch.n_tokens))]}")
            return 0

        @staticmethod
        def llama_batch_init(n_tokens, embd, n_seq_max):
            class MockBatch:
                def __init__(self):
                    self.n_tokens = n_tokens
                    self.token = (ctypes.c_int32 * n_tokens)() if embd == 0 else None
                    self.embd = (ctypes.c_float * (n_tokens * embd))() if embd > 0 else None
                    self.pos = (ctypes.c_int32 * n_tokens)()
                    self.n_seq_id = (ctypes.c_int32 * n_tokens)()
                    self.logits = (ctypes.c_int8 * n_tokens)()
                    # seq_id is pointer to pointer. We represent it as pointer to array
                    self.seq_id = (ctypes.POINTER(ctypes.c_int32) * (n_tokens + 1))()
                    for i in range(n_tokens):
                        self.seq_id[i] = (ctypes.c_int32 * n_seq_max)()
                    self.seq_id[n_tokens] = None

            print(f"[Mock C API] llama_batch_init(n_tokens={n_tokens}, embd={embd}, n_seq_max={n_seq_max})")
            return MockBatch()

        @staticmethod
        def llama_batch_free(batch):
            print(f"[Mock C API] llama_batch_free()")

        @staticmethod
        def llama_get_logits_ith(ctx, i):
            # Return a pointer to a dummy vocab logits array of size 518000
            # We seed a mock response for GUI action generation (e.g. click at coordinates)
            vocab_size = 518000
            dummy_logits = (ctypes.c_float * vocab_size)()
            # Make some tokens highly probable
            # Let's mock a sequence of outputs like: 'CLICK', '(', '600', ',', '165', ')'
            # We'll just put high values at index 0 for simplicity, or random values
            for idx in range(vocab_size):
                dummy_logits[idx] = -10.0
            dummy_logits[100] = 10.0  # mock token
            return ctypes.pointer(dummy_logits)

    ll_cpp = MockLlamaCpp()

    class MockLlama:
        def __init__(self, model_path, vocab_only=False, **kwargs):
            self.model_path = model_path
            print(f"[Mock Llama] Loaded model {model_path} (vocab_only={vocab_only})")
            self.model = ctypes.c_void_p(12345)
            self.ctx = ctypes.c_void_p(67890)
            self._n_vocab = 518000

        def tokenize(self, text, add_bos=False, special=True):
            # Return some fake tokens
            text_str = text.decode("utf-8", errors="ignore")
            print(f"[Mock Tokenizer] Tokenize: '{text_str}'")
            if text == b"<|image|>":
                return [517766]
            elif text == b"<image|>":
                return [517770]
            elif text == b"<bos>":
                return [2]
            elif text == b"<eos>":
                return [1]
            elif text == b"<|turn>":
                return [106]
            elif text == b"<turn|>":
                return [216]
            # General fallback
            return [ord(c) + 1000 for c in text_str]

        def detokenize(self, tokens):
            # Return string back
            chars = []
            for t in tokens:
                if t == 517766:
                    chars.append("<|image|>")
                elif t == 517770:
                    chars.append("<image|>")
                elif t >= 1000:
                    chars.append(chr(t - 1000))
                else:
                    chars.append(f"[Tok {t}]")
            res_str = "".join(chars)
            return res_str.encode("utf-8")

        def n_vocab(self):
            return self._n_vocab

    llama_cpp = type('llama_cpp_dummy', (), {'Llama': MockLlama})()

# ==============================================================================
# 2. Vision Models (ViT and Vision Projection)
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


class MultimodalEncoder:
    def __init__(self, device: str, llm_dim: int):
        self.device = device
        self.llm_dim = llm_dim
        
        # Load ViT
        self.load_pretrained = (device == "cuda")
        if self.load_pretrained:
            try:
                from transformers import ViTImageProcessor, ViTModel
                print("[Vision] Loading pretrained google/vit-base-patch16-224...")
                self.vit_processor = ViTImageProcessor.from_pretrained("google/vit-base-patch16-224")
                self.vit_model = ViTModel.from_pretrained("google/vit-base-patch16-224")
                print("[Vision] Pretrained ViT loaded successfully.")
            except Exception as e:
                print(f"[Vision] Pretrained ViT load failed ({e}). Falling back to dummy.")
                self.load_pretrained = False

        if not self.load_pretrained:
            from transformers import ViTConfig, ViTImageProcessor, ViTModel
            print("[Vision] Using tiny randomly-initialized ViT for CPU/local mode.")
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
            
        self.vit_dim = self.vit_model.config.hidden_size
        self.projection = VisionProjection(vit_dim=self.vit_dim, llm_dim=self.llm_dim).to(self.device)
        self.projection.eval()
        
    def extract_and_project(self, image: Image.Image) -> np.ndarray:
        """Processes PIL image, extracts patch features, and projects to LLM hidden dim."""
        inputs = self.vit_processor(images=image, return_tensors="pt").to(self.device)
        with torch.no_grad():
            outputs = self.vit_model(**inputs)
            # Remove [CLS] token, leaving 196 patches
            features = outputs.last_hidden_state[:, 1:, :]  # (1, 196, vit_dim)
            projected = self.projection(features)           # (1, 196, llm_dim)
            
        return projected.squeeze(0).cpu().numpy()  # Return shape (196, llm_dim) as numpy float32 array

# ==============================================================================
# 3. Three-Stage Decoder Implementation
# ==============================================================================

def decode_tokens(ctx_ptr, token_ids, pos_start, seq_id=0, need_logits=False):
    """Decodes a list of token IDs at specified positions using llama_decode."""
    n_tokens = len(token_ids)
    if n_tokens == 0:
        return
        
    batch = ll_cpp.llama_batch_init(n_tokens, 0, 1)
    batch.n_tokens = n_tokens
    
    for i, tok in enumerate(token_ids):
        batch.token[i] = tok
        batch.pos[i] = pos_start + i
        batch.n_seq_id[i] = 1
        batch.seq_id[i][0] = seq_id
        # Enable logits ONLY for the last token in the batch if requested
        batch.logits[i] = 1 if (need_logits and i == n_tokens - 1) else 0
        
    res = ll_cpp.llama_decode(ctx_ptr, batch)
    ll_cpp.llama_batch_free(batch)
    
    if res != 0:
        raise RuntimeError(f"llama_decode failed with exit code {res}")


def decode_embeddings(ctx_ptr, embeddings, pos_start, seq_id=0):
    """Decodes a numpy array of custom embeddings at specified positions."""
    # embeddings is of shape (n_tokens, n_embd)
    n_tokens, n_embd = embeddings.shape
    embeddings_flat = embeddings.astype(np.float32).flatten()
    
    batch = ll_cpp.llama_batch_init(n_tokens, n_embd, 1)
    batch.n_tokens = n_tokens
    
    # Copy floats into batch.embd using ctypes memmove
    c_floats = (ctypes.c_float * len(embeddings_flat))(*embeddings_flat)
    ctypes.memmove(batch.embd, c_floats, ctypes.sizeof(c_floats))
    
    for i in range(n_tokens):
        batch.pos[i] = pos_start + i
        batch.n_seq_id[i] = 1
        batch.seq_id[i][0] = seq_id
        batch.logits[i] = 0  # Embeddings don't need logits
        
    res = ll_cpp.llama_decode(ctx_ptr, batch)
    ll_cpp.llama_batch_free(batch)
    
    if res != 0:
        raise RuntimeError(f"llama_decode (embeddings) failed with exit code {res}")


def sample_token(logits, temperature=0.7):
    """Simple temperature-based sampling from logits."""
    # Softmax with temperature
    if temperature == 0:
        return int(np.argmax(logits))
    logits = np.array(logits, dtype=np.float64)
    probs = np.exp(logits / temperature)
    probs /= np.sum(probs)
    return int(np.random.choice(len(logits), p=probs))

# ==============================================================================
# 4. Main Execution Loop
# ==============================================================================

def main():
    parser = argparse.ArgumentParser(description="GGUF Multimodal Injector (Path A)")
    parser.add_argument("--model_path", type=str, default=None, help="Path to your Gemma-4 GGUF file")
    parser.add_argument("--image_url", type=str, default="https://huggingface.co/datasets/huggingface/documentation-images/resolve/main/cats.png", help="URL or path to target image")
    parser.add_argument("--prompt", type=str, default="What is shown in this image?", help="Query prompt for the VLM")
    parser.add_argument("--mock", action="store_true", help="Force mock execution mode")
    parser.add_argument("--temp", type=float, default=0.7, help="Temperature for text sampling")
    parser.add_argument("--max_tokens", type=int, default=128, help="Max output tokens to generate")
    
    args = parser.parse_args()
    
    # Force mock mode if requested or if llama-cpp-python is missing
    global HAS_LLAMA_CPP, llama_cpp, ll_cpp
    if args.mock:
        HAS_LLAMA_CPP = False
        print("[Injector] Mock mode forced by user.")
        
    device = "cuda" if (torch.cuda.is_available() and not args.mock) else "cpu"
    print(f"[Injector] Running on device: {device}")
    
    # 1. Download or locate GGUF model
    model_path = args.model_path
    if not model_path and HAS_LLAMA_CPP:
        from huggingface_hub import hf_hub_download
        print("[Injector] No model path specified. Downloading Gemma-4-12B-patched GGUF (approx 23.8 GB) or Q6_K (approx 9.78 GB)...")
        # We prefer the Q6_K version to save bandwith/disk unless specified, but let's default to Q6_K since it's faster
        try:
            model_path = hf_hub_download(
                repo_id="sneedjak/Adelic-Gemma-4-12B-GGUF",
                filename="adelic-gemma4-12b-Q6_K.gguf"
            )
            print(f"[Injector] Download complete: {model_path}")
        except Exception as e:
            print(f"[Injector] Download failed: {e}. Switching to mock mode.")
            HAS_LLAMA_CPP = False
            model_path = "mock_model.gguf"
    elif not model_path:
        model_path = "mock_model.gguf"
        
    # 2. Initialize the Llama engine
    print(f"[Injector] Loading model into Llama engine...")
    if HAS_LLAMA_CPP:
        # Load high level class
        model = llama_cpp.Llama(
            model_path=model_path,
            n_ctx=2048,
            n_gpu_layers=-1 if device == "cuda" else 0, # Offload all to GPU if available
            verbose=True
        )
        model_ptr = model.model
        ctx_ptr = model.ctx
        n_embd = ll_cpp.llama_model_n_embd(model_ptr)
        vocab_size = model.n_vocab()
    else:
        # Initialize mock model
        model = llama_cpp.Llama(model_path=model_path)
        model_ptr = model.model
        ctx_ptr = model.ctx
        n_embd = ll_cpp.llama_model_n_embd(model_ptr)
        vocab_size = model.n_vocab()
        
    print(f"[Injector] Model hidden dimension (n_embd): {n_embd}")
    print(f"[Injector] Vocabulary size: {vocab_size}")
    
    # 3. Initialize Vision Stack
    vision_stack = MultimodalEncoder(device=device, llm_dim=n_embd)
    
    # 4. Fetch image
    print(f"[Injector] Fetching image from {args.image_url}...")
    try:
        if args.image_url.startswith("http"):
            image = Image.open(requests.get(args.image_url, stream=True).raw).convert("RGB")
        else:
            image = Image.open(args.image_url).convert("RGB")
        print("[Injector] Image loaded successfully.")
    except Exception as e:
        print(f"[Injector] Image load failed ({e}). Creating synthetic mock image.")
        image = Image.new("RGB", (224, 224), color=(50, 100, 150))
        draw = ImageDraw.Draw(image)
        draw.text((10, 100), "Mock Screen Grab", fill=(255, 255, 255))
        
    # 5. Extract visual features and project
    print("[Injector] Running Vision Encoder and Projection Layer...")
    visual_embeddings = vision_stack.extract_and_project(image)  # Shape (196, n_embd)
    print(f"[Injector] Visual embeddings projected successfully. Shape: {visual_embeddings.shape}")
    
    # 6. Retrieve special tokens dynamically
    # For Gemma 4:
    # image_token is '<|image|>' (ID: 517766 or 258880 depending on shard/HF mapping)
    # eoi_token is '<image|>' (ID: 517770 or 258882)
    # We retrieve them dynamically to prevent mismatches
    print("[Injector] Querying special tokens...")
    try:
        image_token_id = model.tokenize(b"<|image|>", add_bos=False, special=True)[0]
    except Exception:
        image_token_id = 517766
    try:
        eoi_token_id = model.tokenize(b"<image|>", add_bos=False, special=True)[0]
    except Exception:
        eoi_token_id = 517770
        
    print(f"  -> Detected <|image|> ID: {image_token_id}")
    print(f"  -> Detected <image|> EOI ID: {eoi_token_id}")
    
    # 7. Tokenize Prompt Segments
    # Prefix: "<start_of_turn>user\n"
    # Suffix: "\n{PROMPT}<end_of_turn>\n<start_of_turn>model\n"
    prefix_text = b"<bos><|turn>user\n"
    suffix_text = f"\n{args.prompt}<turn|>\n<|turn>model\n".encode("utf-8")
    
    print(f"[Injector] Tokenizing prompt prefix: '{prefix_text.decode()}'")
    prefix_ids = model.tokenize(prefix_text, add_bos=False, special=True)
    
    print(f"[Injector] Tokenizing prompt suffix: '{suffix_text.decode()}'")
    suffix_ids = model.tokenize(suffix_text, add_bos=False, special=True)
    
    # 8. Run Three-Stage Decoding
    print("\n===== [Stage 1: Decoding Prefix Text] =====")
    pos = 0
    decode_tokens(ctx_ptr, prefix_ids, pos_start=pos, seq_id=0, need_logits=False)
    pos += len(prefix_ids)
    print(f"  -> Prefix tokens decoded. Next position: {pos}")
    
    print("\n===== [Stage 2: Injecting Image Embeddings] =====")
    # Inject 196 visual embeddings at consecutive positions
    decode_embeddings(ctx_ptr, visual_embeddings, pos_start=pos, seq_id=0)
    pos += visual_embeddings.shape[0]
    
    # Decode EOI token immediately after the image embeddings to close the block
    decode_tokens(ctx_ptr, [eoi_token_id], pos_start=pos, seq_id=0, need_logits=False)
    pos += 1
    print(f"  -> Visual embeddings injected. Next position: {pos}")
    
    print("\n===== [Stage 3: Decoding Suffix Text] =====")
    # Decode suffix text, enabling logits for the final token so we can generate from it
    decode_tokens(ctx_ptr, suffix_ids, pos_start=pos, seq_id=0, need_logits=True)
    pos += len(suffix_ids)
    print(f"  -> Suffix tokens decoded. Next position: {pos}")
    
    # 9. Autoregressive Text Generation Loop
    print("\n===== [Generation Started] =====")
    generated_tokens = []
    
    try:
        eos_token_id = model.tokenize(b"<eos>", add_bos=False, special=True)[0]
    except Exception:
        eos_token_id = 1
    try:
        eot_token_id = model.tokenize(b"<turn|>", add_bos=False, special=True)[0]
    except Exception:
        eot_token_id = 216
        
    for step in range(args.max_tokens):
        # Retrieve logits pointer
        logits_ptr = ll_cpp.llama_get_logits_ith(ctx_ptr, 0)
        
        # Safe logits cast
        if not HAS_LLAMA_CPP:
            # Mock generating a sample action response
            mock_action_seq = ["[Mock] Action: CLICK on Search Bar at (600, 165).", "\nReason: Found search query target."]
            if step < len(mock_action_seq):
                text = mock_action_seq[step]
            else:
                text = ""
                break
            print(text, end="", flush=True)
            time.sleep(0.3)
            continue
            
        # Convert logits pointer to numpy array
        logits = np.ctypeslib.as_array(logits_ptr, shape=(vocab_size,))
        
        # Sample next token
        next_token = sample_token(logits, temperature=args.temp)
        
        if next_token == eos_token_id or next_token == eot_token_id:
            print(" [EOS/EOT detected]", flush=True)
            break
            
        generated_tokens.append(next_token)
        
        # Decode and print generated text
        token_text = model.detokenize([next_token]).decode("utf-8", errors="ignore")
        print(token_text, end="", flush=True)
        
        # Decode next token to advance context for next step
        decode_tokens(ctx_ptr, [next_token], pos_start=pos, seq_id=0, need_logits=True)
        pos += 1
        
    print("\n===== [Generation Completed] =====\n")
    
    # Cleanup memory
    if HAS_LLAMA_CPP:
        # High-level model class in llama-cpp-python is cleaned up by garbage collection or manually
        del model
        
    print("[Injector] Completed successfully.")


if __name__ == "__main__":
    main()
