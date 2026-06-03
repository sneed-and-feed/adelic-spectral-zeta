from transformers.models.qwen2.configuration_qwen2 import Qwen2Config

class AdelicQwenConfig(Qwen2Config):
    model_type = "adelic_qwen"

    def __init__(
        self,
        adelic_soft_capacity=256,
        adelic_hard_capacity=1024,
        adelic_local_window=128,
        adelic_similarity_threshold=0.95,
        adelic_hologram_decay=0.9,
        **kwargs,
    ):
        self.adelic_soft_capacity = adelic_soft_capacity
        self.adelic_hard_capacity = adelic_hard_capacity
        self.adelic_local_window = adelic_local_window
        self.adelic_similarity_threshold = adelic_similarity_threshold
        self.adelic_hologram_decay = adelic_hologram_decay
        super().__init__(**kwargs)
