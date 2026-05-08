# Artifact:  feature/answer_accepted_answer_similarity_MISQ
# 输入:      data/features/human_answer_intermediate_MISQ.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id
# 输出:      data/features/answer_accepted_answer_similarity_MISQ.csv
#
# 逻辑：在 MISQ universe 内，用 accepted human answer 作为 anchor，计算每个 human answer 与 anchor 的
#       full-text cosine similarity，列名固定为 SimWithAccept。

import os

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from features.build_question_accepted_answer_similarity import build_anchor_lookup
from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["answer_accepted_answer_similarity_misq"]
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
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    anchor_lookup = build_anchor_lookup(human_answer)

    feature = human_answer[["questionURL", "resp_id", "cmnID", "is_accepted_answer", "human_answer_text"]].copy()
    feature = feature.merge(anchor_lookup, on="questionURL", how="left")

    feature["SimWithAccept"] = np.nan
    valid = (
        feature["human_answer_text"].notna()
        & feature["accepted_anchor_text"].notna()
        & feature["human_answer_text"].astype(str).str.strip().ne("")
        & feature["accepted_anchor_text"].astype(str).str.strip().ne("")
    )

    model = _load_model()
    tqdm.pandas(desc="Computing human vs accepted similarity (MISQ)")
    feature.loc[valid, "SimWithAccept"] = feature.loc[valid].progress_apply(
        lambda row: compute_similarity(row["human_answer_text"], row["accepted_anchor_text"], model),
        axis=1,
    )

    feature = feature[
        [
            "questionURL",
            "resp_id",
            "cmnID",
            "is_accepted_answer",
            "n_accepted_answers",
            "anchor_selection_rule",
            "accepted_resp_id",
            "accepted_resp_ids",
            "SimWithAccept",
        ]
    ]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"answer_accepted_answer_similarity_MISQ 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
