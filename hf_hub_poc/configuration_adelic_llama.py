from transformers import LlamaConfig

class AdelicLlamaConfig(LlamaConfig):
    model_type = "adelic_llama"

    def __init__(
        self,
        adelic_max_capacity: int = 512,
        adelic_local_window: int = 128,
        adelic_similarity_threshold: float = 0.95,
        **kwargs,
    ):
        self.adelic_max_capacity = adelic_max_capacity
        self.adelic_local_window = adelic_local_window
        self.adelic_similarity_threshold = adelic_similarity_threshold
        super().__init__(**kwargs)
