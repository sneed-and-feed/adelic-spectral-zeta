import torch
from transformers import Trainer, TrainerCallback
from src.ultrametric_v3.surgery import SurgeryLossRamp

class TauAnnealingCallback(TrainerCallback):
    def __init__(self, initial_tau=1.0, min_tau=0.1, decay_steps=10000):
        self.initial_tau = initial_tau
        self.min_tau = min_tau
        self.decay_steps = decay_steps

    def on_step_begin(self, args, state, control, model, **kwargs):
        # Calculate tau (e.g., linear decay)
        progress = min(1.0, state.global_step / self.decay_steps)
        current_tau = self.initial_tau - progress * (self.initial_tau - self.min_tau)
        
        # Handle DDP / FSDP / DeepSpeed unwrapping safely
        unwrapped_model = model.module if hasattr(model, "module") else model
        
        # Inject the state into the config
        unwrapped_model.config.surgical_tau = current_tau

class SurgeryTrainer(Trainer):
    def __init__(self, *args, surgery_lambda_init=0.0, surgery_lambda_max=1.0, surgery_ramp_steps=1000, **kwargs):
        super().__init__(*args, **kwargs)
        self.loss_ramp = SurgeryLossRamp(
            lambda_init=surgery_lambda_init,
            lambda_max=surgery_lambda_max,
            ramp_steps=surgery_ramp_steps
        )

    def compute_loss(self, model, inputs, return_outputs=False, **kwargs):
        """
        How the loss is computed by Trainer. By default, all models return the loss in
        the first element.
        """
        unwrapped_model = model.module if hasattr(model, "module") else model

        # Standard forward pass
        # pass kwargs correctly to HF compute_loss if needed, but here we just pass **inputs
        # Some versions of transformers pass num_items_in_batch, etc.
        # But we must just pass inputs to model.
        outputs = model(**inputs)
        
        # We don't use .loss directly here, or if we do, we need to extract it
        if self.label_smoother is not None and "labels" in inputs:
            loss = self.label_smoother(outputs, inputs["labels"])
        else:
            # Save past state if it exists
            loss = outputs["loss"] if isinstance(outputs, dict) else outputs[0]

        from src.ultrametric_v3.surgery import MultiPrimeTopologyRouter
        
        # Process auxiliary losses directly from routers to survive gradient checkpointing
        tau = getattr(unwrapped_model.config, "surgical_tau", 1.0)
        aux_losses = []
        for module in unwrapped_model.modules():
            if isinstance(module, MultiPrimeTopologyRouter):
                g_h = module(tau)
                aux_losses.append((1.0 - g_h).mean())
        
        if aux_losses:
            # Compute total sparsity penalty
            total_sparsity_penalty = sum(aux_losses) / len(aux_losses)
            
            # Scale by lambda ramp
            lambda_t = self.loss_ramp.get_lambda(self.state.global_step)
            surgery_loss = lambda_t * total_sparsity_penalty
            
            loss = loss + surgery_loss

        return (loss, outputs) if return_outputs else loss
