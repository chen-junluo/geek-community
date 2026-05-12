# Artifact:    feature/question_ai_human_code_similarity
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv
#   - human_answer_intermediate_MISQ.csv
#   - full_answer_intermediate_MISQ.csv
#
# Output:      data/features/question_ai_human_code_similarity.csv
#   - Index: questionURL
#   - Core: human1_human2_code_similarity, ai_human1_code_similarity, ai_human2_code_similarity
#   - Derived: —
#
# Logic:
#   - 在 MISQ universe 内，对每个 question，用 sentence-transformers 计算三个 code cosine similarity
#   - human1_human2_code_similarity：第一个与第二个 human answer 的 `content_code_text` 之间
#   - ai_human1_code_similarity：AI answer 与第一个 human answer 的 `content_code_text`
#   - ai_human2_code_similarity：AI answer 与第二个 human answer 的 `content_code_text`

import os
import numpy as np
import pandas as pd
from tqdm import tqdm
from sentence_transformers import SentenceTransformer, util

from utils.paths import ARTIFACT_PATHS

# ── Config ──────────────────────────────────────────────────────────────────

OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_ai_human_code_similarity"]
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
    question_url = group["questionURL"].iloc[0]

    human_answers = group[group["content_code_text"].notna()].sort_values("dateID")
    first_human_text = human_answers.iloc[0]["content_code_text"] if len(human_answers) >= 1 else np.nan
    second_human_text = human_answers.iloc[1]["content_code_text"] if len(human_answers) >= 2 else np.nan

    ai_text = ai_lookup.get(question_url)
    preai = int(preai_lookup.get(question_url, 0))

    result = {
        "questionURL": question_url,
        "preAI": preai,
        "group_type": "treatment" if preai == 1 else "control",
        "n_human_answers": len(human_answers),
        "human1_human2_code_similarity": compute_similarity(first_human_text, second_human_text, model),
        "ai_human1_code_similarity": np.nan,
        "ai_human2_code_similarity": np.nan,
    }
    if preai == 1:
        result["ai_human1_code_similarity"] = compute_similarity(ai_text, first_human_text, model)
        result["ai_human2_code_similarity"] = compute_similarity(ai_text, second_human_text, model)

    return pd.Series(result)


# ── Main ──────────────────────────────────────────────────────────────────────

def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    ai_lookup = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "content_code_text"]]
        .drop_duplicates("questionURL")
        .set_index("questionURL")["content_code_text"]
    )

    preai_lookup = question[["questionURL", "preAI"]].drop_duplicates("questionURL").set_index("questionURL")["preAI"]

    model = _load_model()
    tqdm.pandas(desc="Computing question-level code similarity")

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
