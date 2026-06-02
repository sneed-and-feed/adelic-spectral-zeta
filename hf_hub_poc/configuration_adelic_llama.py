from transformers import LlamaConfig

class AdelicLlamaConfig(LlamaConfig):
    model_type = "adelic_llama"

    def __init__(
        self,
        adelic_soft_capacity: int = 256,
        adelic_hard_capacity: int = 1024,
        adelic_local_window: int = 128,
        adelic_similarity_threshold: float = 0.95,
        **kwargs,
    ):
        self.adelic_soft_capacity = adelic_soft_capacity
        self.adelic_hard_capacity = adelic_hard_capacity
        self.adelic_local_window = adelic_local_window
        self.adelic_similarity_threshold = adelic_similarity_threshold
        super().__init__(**kwargs)
