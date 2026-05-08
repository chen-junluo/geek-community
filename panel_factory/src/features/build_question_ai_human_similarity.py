# Artifact:  feature/question_ai_human_similarity
# 输入:      data/features/question_intermediate_MISQ.csv, data/features/human_answer_intermediate_MISQ.csv,
#            data/features/full_answer_intermediate_MISQ.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_ai_human_similarity.csv
#
# 逻辑：在 MISQ universe 内，对每个 question，用 sentence-transformers 计算三个 cosine similarity：
#   - human1_human2_similarity：第一个与第二个 human answer 之间
#   - ai_human1_similarity：AI answer 与第一个 human answer（仅有 AI answer 时非空）
#   - ai_human2_similarity：AI answer 与第二个 human answer（仅有 AI answer 时非空）

import os
import numpy as np
import pandas as pd
from tqdm import tqdm
from sentence_transformers import SentenceTransformer, util

from utils.paths import ARTIFACT_PATHS

# ── Config ──────────────────────────────────────────────────────────────────

OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_ai_human_similarity"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

MODEL_NAME = "distiluse-base-multilingual-cased-v1"


# ── Similarity helpers ────────────────────────────────────────────────────────

def _load_model():
    return SentenceTransformer(MODEL_NAME)


def compute_similarity(text_a, text_b, model) -> float:
    if pd.isna(text_a) or pd.isna(text_b):
        return np.nan
    text_a = str(text_a).strip()
    text_b = str(text_b).strip()
    if not text_a or not text_b:
        return np.nan
    embeddings = model.encode([text_a, text_b], convert_to_tensor=True)
    return util.cos_sim(embeddings[0], embeddings[1]).cpu().item()


# ── Per-question builder ──────────────────────────────────────────────────────

def build_question_level_similarity(
    group: pd.DataFrame,
    ai_lookup: pd.Series,
    preai_lookup: pd.Series,
    model,
) -> pd.Series:
    question_url = group.name

    human_answers = group[group["content_full_text"].notna()].sort_values("dateID")
    first_human_text = human_answers.iloc[0]["content_full_text"] if len(human_answers) >= 1 else np.nan
    second_human_text = human_answers.iloc[1]["content_full_text"] if len(human_answers) >= 2 else np.nan

    ai_text = ai_lookup.get(question_url)
    preai = int(preai_lookup.get(question_url, 0))

    result = {
        "questionURL": question_url,
        "preAI": preai,
        "group_type": "treatment" if preai == 1 else "control",
        "n_human_answers": len(human_answers),
        "human1_human2_similarity": compute_similarity(first_human_text, second_human_text, model),
        "ai_human1_similarity": np.nan,
        "ai_human2_similarity": np.nan,
    }
    if preai == 1:
        result["ai_human1_similarity"] = compute_similarity(ai_text, first_human_text, model)
        result["ai_human2_similarity"] = compute_similarity(ai_text, second_human_text, model)

    return pd.Series(result)


# ── Main ──────────────────────────────────────────────────────────────────────

def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    ai_lookup = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "answer_text"]]
        .drop_duplicates("questionURL")
        .set_index("questionURL")["answer_text"]
    )

    preai_lookup = question[["questionURL", "preAI"]].drop_duplicates("questionURL").set_index("questionURL")["preAI"]

    model = _load_model()
    tqdm.pandas(desc="Computing question-level similarity")

    feature = (
        human_answer.groupby("questionURL")
        .progress_apply(lambda g: build_question_level_similarity(g, ai_lookup, preai_lookup, model))
        .reset_index(drop=True)
    )
    feature = question[["questionURL"]].merge(
        feature,
        on="questionURL",
        how="left",
    )

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
