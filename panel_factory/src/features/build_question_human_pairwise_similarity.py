# Artifact:  feature/question_human_pairwise_similarity
# 输入:      data/features/question_intermediate_MISQ.csv, data/features/human_answer_intermediate_MISQ.csv,
#            data/features/full_answer_intermediate_MISQ.csv
# Grain:     question-level (question_id)
# Merge keys: question_id, questionURL
# 输出:      data/features/question_human_pairwise_similarity.csv
#
# 逻辑：在 MISQ universe 内：
#   - 有 AI answer 时：对该 question 下所有 human answers 做 pairwise cosine similarity，取 mean。
#   - 无 AI answer 时：删掉第一个 human answer，对剩余 human answers 做 pairwise similarity mean。
#   - 可用 human answers < 2 → `human_pairwise_similarity_mean = np.nan`

import os
import itertools

import numpy as np
import pandas as pd
from tqdm import tqdm
from sentence_transformers import SentenceTransformer, util

from utils.paths import ARTIFACT_PATHS

# ── Config ───────────────────────────────────────────────────────────────────

OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_human_pairwise_similarity"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

MODEL_NAME = "distiluse-base-multilingual-cased-v1"


# ── Helpers ───────────────────────────────────────────────────────────────────

def _load_model():
    return SentenceTransformer(MODEL_NAME)


def _pairwise_mean_similarity(texts: list[str], model) -> float:
    """给定一组文本，计算所有 pair 的 cosine similarity 均值。texts 长度 < 2 返回 np.nan。"""
    if len(texts) < 2:
        return np.nan
    embeddings = model.encode(texts, convert_to_tensor=True)
    scores = []
    for i, j in itertools.combinations(range(len(texts)), 2):
        score = util.cos_sim(embeddings[i], embeddings[j]).cpu().item()
        scores.append(score)
    return float(np.mean(scores))


# ── Per-question builder ──────────────────────────────────────────────────────

def build_question_pairwise(
    group: pd.DataFrame,
    ai_lookup: pd.Series,
    model,
) -> pd.Series:
    question_id = group.name
    question_url = group["questionURL"].iloc[0]

    human_answers = group[group["content_full_text"].notna()].sort_values("dateID")
    human_texts = human_answers["content_full_text"].astype(str).str.strip().tolist()
    human_texts = [t for t in human_texts if t]

    ai_text = ai_lookup.get(question_id)
    is_treat = pd.notna(ai_text) and str(ai_text).strip() != ""

    if is_treat:
        candidate_texts = human_texts
    else:
        candidate_texts = human_texts[1:] if len(human_texts) >= 1 else []

    sim = _pairwise_mean_similarity(candidate_texts, model)

    return pd.Series({
        "question_id": question_id,
        "questionURL": question_url,
        "group_type": "treatment" if is_treat else "control",
        "n_human_answers": len(human_texts),
        "n_human_answers_used": len(candidate_texts),
        "human_pairwise_similarity_mean": sim,
    })


# ── Main ──────────────────────────────────────────────────────────────────────

def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    ai_lookup = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["question_id", "answer_text"]]
        .drop_duplicates("question_id")
        .set_index("question_id")["answer_text"]
    )

    model = _load_model()
    tqdm.pandas(desc="Computing pairwise similarity")

    feature = (
        human_answer.groupby("question_id")
        .progress_apply(lambda g: build_question_pairwise(g, ai_lookup, model))
        .reset_index(drop=True)
    )
    feature = question[["question_id", "questionURL"]].merge(
        feature,
        on=["question_id", "questionURL"],
        how="left",
    )

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
