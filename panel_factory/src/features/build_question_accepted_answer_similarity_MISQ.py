# Artifact:  feature/question_accepted_answer_similarity_MISQ
# 输入:      data/features/question_intermediate_MISQ.csv, data/features/human_answer_intermediate_MISQ.csv,
#            data/features/full_answer_intermediate_MISQ.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_accepted_answer_similarity_MISQ.csv
#
# 逻辑：在 MISQ universe 内，用 accepted human answer 作为 anchor，计算 AI answer 与 accepted anchor 的
#       full-text cosine similarity，列名固定为 AISimWithAccept。

import os

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from features.build_question_accepted_answer_similarity import build_anchor_lookup
from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_accepted_answer_similarity_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

MODEL_NAME = "distiluse-base-multilingual-cased-v1"


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


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    # 从 full_answer 中提取 human answer 的文本，merge 到 human_answer
    human_text = (
        full_answer[full_answer["answer_source"] == "human_answer"]
        [["questionURL", "resp_id", "answer_text"]]
        .rename(columns={"answer_text": "human_answer_text"})
        .drop_duplicates(["questionURL", "resp_id"])
    )
    human_answer_with_text = human_answer.merge(human_text, on=["questionURL", "resp_id"], how="left")

    anchor_lookup = build_anchor_lookup(human_answer_with_text)
    ai_answer = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "answer_text"]]
        .rename(columns={"answer_text": "ai_answer_text"})
        .drop_duplicates("questionURL")
    )

    feature = question[["questionURL"]].copy()
    feature = feature.merge(ai_answer, on="questionURL", how="left")
    feature = feature.merge(anchor_lookup, on="questionURL", how="left")
    feature["has_ai_answer"] = feature["ai_answer_text"].notna().astype(int)
    feature["has_accepted_answer"] = feature["has_accepted_answer"].fillna(0).astype(int)

    feature["AISimWithAccept"] = np.nan
    valid = (
        feature["ai_answer_text"].notna()
        & feature["accepted_anchor_text"].notna()
        & feature["ai_answer_text"].astype(str).str.strip().ne("")
        & feature["accepted_anchor_text"].astype(str).str.strip().ne("")
    )

    model = _load_model()
    tqdm.pandas(desc="Computing AI vs accepted similarity (MISQ)")
    feature.loc[valid, "AISimWithAccept"] = feature.loc[valid].progress_apply(
        lambda row: compute_similarity(row["ai_answer_text"], row["accepted_anchor_text"], model),
        axis=1,
    )

    feature = feature[
        [
            "questionURL",
            "has_ai_answer",
            "has_accepted_answer",
            "n_accepted_answers",
            "anchor_selection_rule",
            "accepted_resp_id",
            "accepted_resp_ids",
            "AISimWithAccept",
        ]
    ]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_accepted_answer_similarity_MISQ 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
