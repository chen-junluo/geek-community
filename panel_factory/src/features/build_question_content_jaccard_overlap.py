# Artifact:  feature/question_content_jaccard_overlap
# 输入:      data/raw/cmn_base.csv, data/raw/cmn_content.csv, data/raw/question_ai_content.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_content_jaccard_overlap.csv
#
# 逻辑：对每个 question，用 token-set Jaccard overlap 计算六个变量：
#   - jaccard_h1_h2：第一个与第二个 human answer 的 content_full_text overlap
#   - jaccard_ai_h2：AI answer 与第二个 human answer 的 content_full_text overlap（仅 treatment，control 为 NaN）
#   - jaccard_ans1_ans2：treatment 用 AI vs human2，control 用 human1 vs human2
#   - jaccard_h1_h2_code：第一个与第二个 human answer 的 content_code_text overlap
#   - jaccard_ai_h2_code：AI answer 与第二个 human answer 的 content_code_text overlap（仅 treatment，control 为 NaN）
#   - jaccard_ans1_ans2_code：treatment 用 AI vs human2，control 用 human1 vs human2

import os
import re

import numpy as np
import pandas as pd
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS

# ── Config ──────────────────────────────────────────────────────────────────

OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_content_jaccard_overlap"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

STOPWORDS = {
    "a", "an", "and", "are", "as", "at", "be", "been", "but", "by", "for", "from",
    "had", "has", "have", "he", "her", "his", "i", "if", "in", "into", "is", "it",
    "its", "me", "my", "of", "on", "or", "our", "she", "so", "that", "the", "their",
    "them", "they", "this", "to", "was", "we", "were", "will", "with", "you", "your",
}
TOKEN_PATTERN = re.compile(r"[A-Za-z_][A-Za-z0-9_]*")


# ── Jaccard helpers ─────────────────────────────────────────────────────────

def _normalize_text(text) -> str:
    if pd.isna(text):
        return ""
    return str(text).strip().lower()


def _tokenize_to_set(text):
    normalized = _normalize_text(text)
    if not normalized:
        return set()
    tokens = TOKEN_PATTERN.findall(normalized)
    return {token for token in tokens if token not in STOPWORDS}


def compute_jaccard(text_a, text_b) -> float:
    if pd.isna(text_a) or pd.isna(text_b):
        return np.nan

    tokens_a = _tokenize_to_set(text_a)
    tokens_b = _tokenize_to_set(text_b)

    if not tokens_a or not tokens_b:
        return np.nan

    union = tokens_a | tokens_b
    if not union:
        return np.nan

    intersection = tokens_a & tokens_b
    return len(intersection) / len(union)


# ── Text extraction helpers ─────────────────────────────────────────────────

def _extract_ai_text(ai_rows: pd.DataFrame, ai_col: str, ai_fallback_col=None):
    ai_text = np.nan
    if ai_col in ai_rows.columns:
        valid = ai_rows[ai_col].dropna()
        if len(valid) > 0:
            ai_text = valid.iloc[0]
    if pd.isna(ai_text) and ai_fallback_col and ai_fallback_col in ai_rows.columns:
        valid = ai_rows[ai_fallback_col].dropna()
        if len(valid) > 0:
            ai_text = valid.iloc[0]
    return ai_text


def _extract_pair_texts(
    group: pd.DataFrame,
    question_ai_content: pd.DataFrame,
    human_col: str,
    ai_col: str,
    ai_fallback_col=None,
):
    question_url = group.name

    human_answers = (
        group[(group["dateID"] != 0) & group[human_col].notna()]
        .sort_values("dateID")
    )
    first_human_text = human_answers.iloc[0][human_col] if len(human_answers) >= 1 else np.nan
    second_human_text = human_answers.iloc[1][human_col] if len(human_answers) >= 2 else np.nan

    ai_rows = question_ai_content[question_ai_content["questionURL"] == question_url]
    ai_text = _extract_ai_text(ai_rows, ai_col, ai_fallback_col)

    return first_human_text, second_human_text, ai_text, len(human_answers)


def _build_overlap_triplet(h1_text, h2_text, ai_text, is_treatment: bool):
    h1_h2 = compute_jaccard(h1_text, h2_text)
    ai_h2 = np.nan
    if is_treatment:
        ai_h2 = compute_jaccard(ai_text, h2_text)
    ans1_ans2 = ai_h2 if is_treatment else h1_h2
    return h1_h2, ai_h2, ans1_ans2


# ── Per-question builder ────────────────────────────────────────────────────

def build_question_level_overlap(group: pd.DataFrame, question_ai_content: pd.DataFrame) -> pd.Series:
    question_url = group.name

    h1_full, h2_full, ai_full, n_human_answers = _extract_pair_texts(
        group,
        question_ai_content,
        human_col="content_full_text",
        ai_col="preAI-content_full_text",
        ai_fallback_col="preAI-content_CN_text",
    )
    h1_code, h2_code, ai_code, _ = _extract_pair_texts(
        group,
        question_ai_content,
        human_col="content_code_text",
        ai_col="preAI-content_code_text",
    )

    is_treatment = pd.notna(ai_full) and str(ai_full).strip() != ""

    jaccard_h1_h2, jaccard_ai_h2, jaccard_ans1_ans2 = _build_overlap_triplet(
        h1_full, h2_full, ai_full, is_treatment
    )
    jaccard_h1_h2_code, jaccard_ai_h2_code, jaccard_ans1_ans2_code = _build_overlap_triplet(
        h1_code, h2_code, ai_code, is_treatment
    )

    return pd.Series(
        {
            "questionURL": question_url,
            "group_type": "treatment" if is_treatment else "control",
            "n_human_answers": n_human_answers,
            "jaccard_h1_h2": jaccard_h1_h2,
            "jaccard_ai_h2": jaccard_ai_h2,
            "jaccard_ans1_ans2": jaccard_ans1_ans2,
            "jaccard_h1_h2_code": jaccard_h1_h2_code,
            "jaccard_ai_h2_code": jaccard_ai_h2_code,
            "jaccard_ans1_ans2_code": jaccard_ans1_ans2_code,
        }
    )


# ── Main ────────────────────────────────────────────────────────────────────

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

    tqdm.pandas(desc="Computing question-level Jaccard overlap")

    feature = (
        base.groupby("questionURL")
        .progress_apply(lambda g: build_question_level_overlap(g, question_ai_content))
        .reset_index(drop=True)
    )

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
