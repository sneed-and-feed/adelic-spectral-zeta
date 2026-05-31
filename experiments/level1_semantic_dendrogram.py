import torch
from transformers import AutoTokenizer, AutoModelForCausalLM
from llama_surgery import inject_surgery
import numpy as np
import matplotlib.pyplot as plt
from sklearn.decomposition import PCA
from sklearn.manifold import TSNE

# 1. Initialize a small base model & tokenizer
print("Loading model...")
model_name = "TinyLlama/TinyLlama-1.1B-intermediate-step-1431k-3T" # A small Llama model for quick demo
tokenizer = AutoTokenizer.from_pretrained(model_name)
model = AutoModelForCausalLM.from_pretrained(model_name, torch_dtype=torch.float16, device_map="cuda")

# 2. Inject V3 Differentiable Router Surgery
print("Injecting surgery...")
model = inject_surgery(model)

# 3. Create a diverse dataset (Math, French, Python)
documents = {
    "Math": [
        "Let X be a topological space. The homology groups H_n(X) are abelian groups.",
        "The proof relies on the Riemann hypothesis and analytic continuation of the zeta function.",
        "Consider the spectrum of the self-adjoint operator on the Hilbert space."
    ],
    "French": [
        "Bonjour le monde! La vie est belle quand on mange des croissants.",
        "C'est la vie. Les misérables est un roman classique.",
        "Je voudrais un café au lait s'il vous plaît."
    ],
    "Python": [
        "def fibonacci(n):\n    if n <= 1:\n        return n\n    return fibonacci(n-1) + fibonacci(n-2)",
        "import numpy as np\narray = np.zeros((10, 10))",
        "class Router(nn.Module):\n    def __init__(self):\n        super().__init__()"
    ]
}

print("Running forward passes and extracting route distributions...")
features = []
labels = []

# Freeze model to evaluate what the random/initial or continuous homotopy router clusters
model.eval()
with torch.no_grad():
    for category, docs in documents.items():
        for doc in docs:
            inputs = tokenizer(doc, return_tensors="pt").to("cuda")
            # Clear previous aux losses
            for layer in model.model.layers:
                layer.self_attn.router.aux_loss = 0.0
            
            outputs = model(**inputs, output_hidden_states=True)
            
            # Let's extract the semantic cluster probability from Layer 0 as an example
            # h: (1, seq_len, d_model)
            h_layer0 = outputs.hidden_states[0]
            # W_route: (d_model, num_branches)
            W_route = model.model.layers[0].self_attn.router.route_heads.weight
            
            # Compute logits: (seq_len, num_branches)
            logits = h_layer0[0] @ W_route.T
            probs = torch.softmax(logits, dim=-1)
            
            # Pool the probs for the whole document
            doc_probs = probs.mean(dim=0).cpu().numpy()
            features.append(doc_probs)
            labels.append(category)

features = np.array(features)

print("Performing PCA on routing distributions...")
pca = PCA(n_components=2)
reduced = pca.fit_transform(features)

colors = {"Math": "red", "French": "blue", "Python": "green"}

plt.figure(figsize=(8, 6))
for i, label in enumerate(labels):
    plt.scatter(reduced[i, 0], reduced[i, 1], color=colors[label], label=label if label not in plt.gca().get_legend_handles_labels()[1] else "")

plt.title("Semantic Dendrogram: Router Classifications")
plt.xlabel("PCA Component 1")
plt.ylabel("PCA Component 2")
plt.legend()
plt.savefig("figures/semantic_dendrogram.png")
print("Saved to figures/semantic_dendrogram.png")
