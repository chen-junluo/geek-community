# Artifact:  feature/question_ai_human_similarity
# 输入:      data/raw/cmn_base.csv, data/raw/cmn_content.csv, data/raw/question_ai_content.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_ai_human_similarity.csv
#
# 逻辑：对每个 question，用 sentence-transformers 计算三个 cosine similarity：
#   - human1_human2_similarity：第一个与第二个 human answer 之间（treatment + control 都算）
#   - ai_human1_similarity：AI answer 与第一个 human answer（仅 treatment，control 为 NaN）
#   - ai_human2_similarity：AI answer 与第二个 human answer（仅 treatment，control 为 NaN）

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

def build_question_level_similarity(group: pd.DataFrame, question_ai_content: pd.DataFrame,
                                    model) -> pd.Series:
    question_url = group.name

    human_answers = (
        group[(group["dateID"] != 0) & group["content_full_text"].notna()]
        .sort_values("dateID")
    )
    first_human_text = human_answers.iloc[0]["content_full_text"] if len(human_answers) >= 1 else np.nan
    second_human_text = human_answers.iloc[1]["content_full_text"] if len(human_answers) >= 2 else np.nan

    ai_rows = question_ai_content[question_ai_content["questionURL"] == question_url]
    ai_text = np.nan
    if "preAI-content_full_text" in ai_rows.columns:
        valid = ai_rows["preAI-content_full_text"].dropna()
        if len(valid) > 0:
            ai_text = valid.iloc[0]
    if pd.isna(ai_text) and "preAI-content_CN_text" in ai_rows.columns:
        valid = ai_rows["preAI-content_CN_text"].dropna()
        if len(valid) > 0:
            ai_text = valid.iloc[0]

    is_treatment = pd.notna(ai_text) and str(ai_text).strip() != ""

    result = {
        "questionURL": question_url,
        "group_type": "treatment" if is_treatment else "control",
        "n_human_answers": len(human_answers),
        "human1_human2_similarity": compute_similarity(first_human_text, second_human_text, model),
        "ai_human1_similarity": np.nan,
        "ai_human2_similarity": np.nan,
    }
    if is_treatment:
        result["ai_human1_similarity"] = compute_similarity(ai_text, first_human_text, model)
        result["ai_human2_similarity"] = compute_similarity(ai_text, second_human_text, model)

    return pd.Series(result)


# ── Main ──────────────────────────────────────────────────────────────────────

def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_base["date"] = pd.to_datetime(cmn_base["date"])
    unique_question_urls = cmn_base[(cmn_base["cmnID"] == 0) & (cmn_base["date"] > "2023-01-01")]["questionURL"].unique()

    question_ai_content = pd.read_csv(os.path.join(raw_dir, "question_ai_content.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))
    cmn_content = cmn_content.merge(
        cmn_base[["questionURL", "cmnID", "date", "accept"]],
        on=["questionURL", "cmnID"], how="left"
    )
    cmn_content["date"] = pd.to_datetime(cmn_content["date"])
    cmn_content = cmn_content.sort_values(by="date")
    cmn_content["dateID"] = cmn_content.groupby("questionURL").cumcount()

    base = cmn_content[cmn_content["questionURL"].isin(unique_question_urls)].copy()

    model = _load_model()
    tqdm.pandas(desc="Computing question-level similarity")

    feature = (
        base.groupby("questionURL")
        .progress_apply(lambda g: build_question_level_similarity(g, question_ai_content, model))
        .reset_index(drop=True)
    )

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
