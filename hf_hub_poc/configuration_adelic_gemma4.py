from transformers.models.gemma.configuration_gemma import GemmaConfig
import warnings

# Attempt to load Gemma4Config, fallback to GemmaConfig if not in transformers version
try:
    from transformers.models.gemma4.configuration_gemma4 import Gemma4Config as BaseConfig
except ImportError:
    try:
        from transformers import Gemma4Config as BaseConfig
    except ImportError:
        warnings.warn("Gemma4Config not found in transformers. Falling back to GemmaConfig for AdelicGemma4Config.")
        BaseConfig = GemmaConfig

class AdelicGemma4Config(BaseConfig):
    model_type = "gemma4" # or whatever the base config uses

    def __init__(
        self,
        adelic_soft_capacity=256,
        adelic_hard_capacity=1024,
        adelic_local_window=128,
        adelic_similarity_threshold=0.95,
        adelic_hologram_decay=0.9,
        **kwargs
    ):
        super().__init__(**kwargs)
        self.adelic_soft_capacity = adelic_soft_capacity
        self.adelic_hard_capacity = adelic_hard_capacity
        self.adelic_local_window = adelic_local_window
        self.adelic_similarity_threshold = adelic_similarity_threshold
        self.adelic_hologram_decay = adelic_hologram_decay
