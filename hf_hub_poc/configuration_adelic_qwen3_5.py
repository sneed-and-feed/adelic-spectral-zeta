from transformers.models.qwen3_5.configuration_qwen3_5 import Qwen3_5Config

class AdelicQwen3_5Config(Qwen3_5Config):
    model_type = "adelic_qwen3_5"

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

    def get_text_config(self, decoder=False):
        """
        Hotfix for Hugging Face transformers main branch bug:
        GenerationConfig.from_model_config incorrectly assumes get_text_config() returns an object 
        with a to_dict() method. If the base class returns a dict, it crashes.
        """
        return self
