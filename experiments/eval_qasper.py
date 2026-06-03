import json
import re
import string
from collections import Counter

def normalize_answer(s):
    """Lower text and remove punctuation, articles and extra whitespace."""
    def remove_articles(text):
        return re.sub(r'\b(a|an|the)\b', ' ', text)
    def white_space_fix(text):
        return ' '.join(text.split())
    def remove_punc(text):
        exclude = set(string.punctuation)
        return ''.join(ch for ch in text if ch not in exclude)
    def lower(text):
        return text.lower()
    return white_space_fix(remove_articles(remove_punc(lower(s))))

def f1_score(prediction, ground_truth):
    prediction_tokens = normalize_answer(prediction).split()
    ground_truth_tokens = normalize_answer(ground_truth).split()
    common = Counter(prediction_tokens) & Counter(ground_truth_tokens)
    num_same = sum(common.values())
    if num_same == 0:
        return 0
    precision = 1.0 * num_same / len(prediction_tokens)
    recall = 1.0 * num_same / len(ground_truth_tokens)
    f1 = (2 * precision * recall) / (precision + recall)
    return f1

def score_qasper(pred, answers):
    # Qasper can have multiple valid answers; we take the max F1
    return max([f1_score(pred, ans) for ans in answers])

def main():
    try:
        with open("results/graphrag_adelic_qasper.jsonl", "r") as f:
            lines = f.readlines()
    except FileNotFoundError:
        print("Could not find results/graphrag_adelic_qasper.jsonl")
        return

    total_f1 = 0
    for line in lines:
        data = json.loads(line)
        pred = data["pred"]
        answers = data["answers"]
        score = score_qasper(pred, answers)
        total_f1 += score
        print(f"Pred: {pred[:50]}... | Score: {score*100:.2f}%")
        
    avg_f1 = total_f1 / len(lines)
    print(f"\nTotal Average F1 Score: {avg_f1 * 100:.2f}%")

if __name__ == "__main__":
    main()
