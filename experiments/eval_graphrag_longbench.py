import os
import json
import argparse
import torch
from tqdm import tqdm
from datasets import load_dataset
from transformers import AutoModelForCausalLM, AutoTokenizer

# LlamaIndex Imports
from llama_index.core import Document, PropertyGraphIndex, Settings
from llama_index.llms.huggingface import HuggingFaceLLM
from llama_index.embeddings.huggingface import HuggingFaceEmbedding
from llama_index.core.indices.property_graph import SimpleLLMPathExtractor

def parse_args():
    parser = argparse.ArgumentParser()
    parser.add_argument('--dataset', type=str, default='qasper', help='LongBench dataset')
    parser.add_argument('--max_samples', type=int, default=5, help='Max samples to evaluate (Graph extraction is slow!)')
    parser.add_argument('--output_dir', type=str, default='results', help='Directory to save the predictions')
    parser.add_argument('--max_new_tokens', type=int, default=128, help='Max generated tokens')
    return parser.parse_args()

def main():
    args = parse_args()
    os.makedirs(args.output_dir, exist_ok=True)
    out_file = os.path.join(args.output_dir, f"graphrag_adelic_{args.dataset}.jsonl")
    
    print("Loading BAAI/bge-small-en-v1.5 embedding model for Graph dense search...")
    embed_model = HuggingFaceEmbedding(model_name="BAAI/bge-small-en-v1.5")
    Settings.embed_model = embed_model
    
    print("Loading Adèlic Llama 3.1 8B Model via HuggingFaceLLM...")
    llm = HuggingFaceLLM(
        model_name="sneedjak/AdelicLlama-3.1-8B-Instruct",
        tokenizer_name="sneedjak/AdelicLlama-3.1-8B-Instruct",
        context_window=8192,
        max_new_tokens=args.max_new_tokens,
        generate_kwargs={"temperature": 0.1, "do_sample": False},
        model_kwargs={"trust_remote_code": True, "torch_dtype": torch.bfloat16},
        tokenizer_kwargs={"trust_remote_code": True},
        device_map="auto",
    )
    Settings.llm = llm

    print(f"Loading LongBench dataset: {args.dataset}...")
    try:
        import urllib.request
        import zipfile
        url = "https://huggingface.co/datasets/THUDM/LongBench/resolve/main/data.zip"
        zip_path = "data.zip"
        local_file = f"data/{args.dataset}.jsonl"
        
        if not os.path.exists(local_file):
            print("Downloading THUDM/LongBench data.zip...")
            urllib.request.urlretrieve(url, zip_path)
            print("Extracting...")
            with zipfile.ZipFile(zip_path, 'r') as zip_ref:
                zip_ref.extractall(".")
                
        dataset = load_dataset('json', data_files=local_file, split='train')
    except Exception as e:
        print(f"Failed to load dataset: {e}")
        return

    if args.max_samples is not None:
        dataset = dataset.select(range(min(args.max_samples, len(dataset))))

    print(f"Starting GraphRAG evaluation on {len(dataset)} samples...")
    fout = open(out_file, 'w', encoding='utf-8')
    
    # Setup PropertyGraph Extractor
    # Note: Extracting paths from huge texts takes a long time.
    extractor = SimpleLLMPathExtractor(
        llm=llm,
        max_paths_per_chunk=10,
        num_workers=1
    )

    for item in tqdm(dataset):
        context = item['context']
        question = item['input']
        
        print(f"\n[GraphRAG] Building PropertyGraph for document ({len(context.split())} words)...")
        # For an 8B model, extracting an entire 10k token paper takes forever.
        # We wrap the context in a LlamaIndex Document
        doc = Document(text=context)
        
        # Build the Graph Index
        # This chunks the document, extracts nodes/edges with the LLM, and embeds them
        index = PropertyGraphIndex.from_documents(
            [doc],
            kg_extractors=[extractor],
            embed_model=embed_model,
            show_progress=True
        )
        
        # Create a query engine from the Graph Index
        query_engine = index.as_query_engine(
            include_text=True,  # Return the original text chunks alongside the graph paths
            similarity_top_k=3
        )
        
        print(f"\n[GraphRAG] Querying Graph: {question}")
        response = query_engine.query(question)
        
        ans = str(response).strip()
        print(f"Answer: {ans}")
        
        fout.write(json.dumps({
            "pred": ans,
            "answers": item["answers"],
            "all_classes": item.get("all_classes", None),
            "length": item.get("length", None)
        }) + '\n')
        fout.flush()

    fout.close()
    print("Evaluation Complete!")

if __name__ == '__main__':
    main()
