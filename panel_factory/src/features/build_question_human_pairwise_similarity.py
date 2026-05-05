# Artifact:  feature/question_human_pairwise_similarity
# 输入:      data/raw/cmn_base.csv, data/raw/cmn_content.csv, data/raw/question_ai_content.csv
# Grain:     question-level (questionURL)
# Merge key: questionURL
# 输出:      data/features/question_human_pairwise_similarity.csv
#
# 逻辑：
#   - treatment 组：对该 question 下所有 human answers 做 pairwise cosine similarity，取 mean。
#   - control 组：删掉第一个 human answer（按时间排序），对剩余 human answers 做 pairwise similarity mean。
#     （模拟 treatment 组中 AI 占据第一位后，后续 human answers 之间的相似度）
#   - 可用 human answers < 2 → human_pairwise_similarity_mean = np.nan

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


def _is_treatment(question_url: str, question_ai_content: pd.DataFrame) -> bool:
    """判断该 question 是否为 treatment（有 AI answer）。"""
    rows = question_ai_content[question_ai_content["questionURL"] == question_url]
    for col in ["preAI-content_full_text", "preAI-content_CN_text"]:
        if col in rows.columns:
            valid = rows[col].dropna()
            if len(valid) > 0 and str(valid.iloc[0]).strip():
                return True
    return False


# ── Per-question builder ──────────────────────────────────────────────────────

def build_question_pairwise(group: pd.DataFrame, question_ai_content: pd.DataFrame,
                            model) -> pd.Series:
    question_url = group.name

    # 所有 human answers，按时间排序（dateID 是 cumcount，0 = question 本身）
    human_answers = (
        group[(group["dateID"] != 0) & group["content_full_text"].notna()]
        .sort_values("dateID")
    )
    human_texts = human_answers["content_full_text"].str.strip().tolist()
    human_texts = [t for t in human_texts if t]  # 去掉空字符串

    is_treat = _is_treatment(question_url, question_ai_content)

    if is_treat:
        # treatment：所有 human answers 做 pairwise
        candidate_texts = human_texts
    else:
        # control：删掉第一个 human answer，剩余做 pairwise
        candidate_texts = human_texts[1:] if len(human_texts) >= 1 else []

    sim = _pairwise_mean_similarity(candidate_texts, model)

    return pd.Series({
        "questionURL": question_url,
        "group_type": "treatment" if is_treat else "control",
        "n_human_answers": len(human_texts),
        "n_human_answers_used": len(candidate_texts),
        "human_pairwise_similarity_mean": sim,
    })


# ── Main ──────────────────────────────────────────────────────────────────────

def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_base["date"] = pd.to_datetime(cmn_base["date"])
    unique_question_urls = cmn_base[
        (cmn_base["cmnID"] == 0) & (cmn_base["date"] > "2023-01-01")
    ]["questionURL"].unique()

    question_ai_content = pd.read_csv(os.path.join(raw_dir, "question_ai_content.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))
    cmn_content = cmn_content.merge(
        cmn_base[["questionURL", "cmnID", "date"]],
        on=["questionURL", "cmnID"], how="left"
    )
    cmn_content["date"] = pd.to_datetime(cmn_content["date"])
    cmn_content = cmn_content.sort_values(by="date")
    cmn_content["dateID"] = cmn_content.groupby("questionURL").cumcount()

    base = cmn_content[cmn_content["questionURL"].isin(unique_question_urls)].copy()

    model = _load_model()
    tqdm.pandas(desc="Computing pairwise similarity")

    feature = (
        base.groupby("questionURL")
        .progress_apply(lambda g: build_question_pairwise(g, question_ai_content, model))
        .reset_index(drop=True)
    )

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
