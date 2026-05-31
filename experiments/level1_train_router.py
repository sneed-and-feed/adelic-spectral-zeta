import sys
sys.modules['triton'] = None

import torch
from transformers import AutoTokenizer, AutoModelForCausalLM, TrainingArguments
from llama_surgery import inject_surgery
from llama_surgery.surgery_trainer import SurgeryTrainer, TauAnnealingCallback
from datasets import Dataset
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA

# 1. Initialize
print("Loading TinyLlama and injecting surgery...")
model_name = "TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T"
tokenizer = AutoTokenizer.from_pretrained(model_name)
tokenizer.pad_token = tokenizer.eos_token

model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype=torch.float16, device_map="cuda")
model = inject_surgery(model)

# 2. Dataset
documents = {
    "Math": [
        "Let X be a topological space. The homology groups H_n(X) are abelian groups.",
        "The proof relies on the Riemann hypothesis and analytic continuation of the zeta function.",
        "Consider the spectrum of the self-adjoint operator on the Hilbert space.",
        "Differential geometry studies smooth manifolds equipped with Riemannian metrics."
    ],
    "French": [
        "Bonjour le monde! La vie est belle quand on mange des croissants.",
        "C'est la vie. Les misérables est un roman classique.",
        "Je voudrais un café au lait s'il vous plaît.",
        "Paris est la capitale de la France, célèbre pour la Tour Eiffel."
    ],
    "Python": [
        "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
        "import numpy as np\narray = np.zeros((10, 10))",
        "class Router(nn.Module):\n    def __init__(self):\n        super().__init__()",
        "for i in range(10):\n    print(f'Iteration {i}')"
    ]
}

texts = []
labels = []
for k, v in documents.items():
    for doc in v:
        texts.append(doc)
        labels.append(k)

# Duplicate the dataset to simulate a few training epochs
texts = texts * 5
labels = labels * 5

encodings = tokenizer(texts, truncation=True, padding=True, max_length=64)
dataset = Dataset.from_dict({
    'input_ids': encodings['input_ids'],
    'attention_mask': encodings['attention_mask'],
    'labels': encodings['input_ids'] 
})

# Freeze all parameters EXCEPT the router heads
for name, param in model.named_parameters():
    if "router" not in name:
        param.requires_grad = False
    else:
        param.requires_grad = True

print("Training the router heads...")
training_args = TrainingArguments(
    output_dir="./surgery_results",
    num_train_epochs=5,
    per_device_train_batch_size=4,
    learning_rate=1e-2, # High learning rate to quickly separate clusters
    logging_steps=5,
    report_to="none"
)

trainer = SurgeryTrainer(
    model=model,
    args=training_args,
    train_dataset=dataset,
    surgery_lambda_max=0.01
)
trainer.add_callback(TauAnnealingCallback(initial_tau=1.0, min_tau=0.1, decay_steps=50))

trainer.train()

# 3. Evaluate and Plot
print("Extracting trained routing distributions...")
model.eval()
features = []
eval_labels = []

unique_texts = []
unique_labels = []
for k, v in documents.items():
    for doc in v:
        unique_texts.append(doc)
        unique_labels.append(k)

with torch.no_grad():
    for doc, label in zip(unique_texts, unique_labels):
        inputs = tokenizer(doc, return_tensors="pt").to("cuda")
        outputs = model(**inputs, output_hidden_states=True)
        
        h_layer0 = outputs.hidden_states[0]
        W_route = model.model.layers[0].self_attn.router.route_heads.weight
        
        tau = getattr(model.config, "surgical_tau", 1.0)
        logits = h_layer0[0] @ W_route.T
        probs = torch.softmax(logits / tau, dim=-1)
        doc_probs = probs.mean(dim=0).cpu().numpy()
        
        features.append(doc_probs)
        eval_labels.append(label)

features = np.array(features)
pca = PCA(n_components=2)
reduced = pca.fit_transform(features)

colors = {"Math": "red", "French": "blue", "Python": "green"}
plt.figure(figsize=(8, 6))
for i, label in enumerate(eval_labels):
    plt.scatter(reduced[i, 0], reduced[i, 1], color=colors[label], label=label if label not in plt.gca().get_legend_handles_labels()[1] else "")

plt.title("Semantic Dendrogram: Trained Router")
plt.xlabel("PCA Component 1")
plt.ylabel("PCA Component 2")
plt.legend()
plt.savefig("figures/trained_semantic_dendrogram.png")
print("Saved to figures/trained_semantic_dendrogram.png")
