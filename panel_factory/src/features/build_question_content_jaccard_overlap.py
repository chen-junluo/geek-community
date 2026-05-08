# Artifact:  feature/question_content_jaccard_overlap
# 输入:      data/features/question_intermediate_MISQ.csv, data/features/human_answer_intermediate_MISQ.csv,
#            data/features/full_answer_intermediate_MISQ.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_content_jaccard_overlap.csv
#
# 逻辑：在 MISQ universe 内，对每个 question，用 token-set Jaccard overlap 计算六个变量：
#   - jaccard_h1_h2：第一个与第二个 human answer 的 `content_full_text` overlap
#   - jaccard_ai_h2：AI answer 与第二个 human answer 的 `content_full_text` overlap（仅有 AI answer 时非空）
#   - jaccard_ans1_ans2：有 AI answer 时用 AI vs human2，否则用 human1 vs human2
#   - jaccard_h1_h2_code：第一个与第二个 human answer 的 `content_code_text` overlap
#   - jaccard_ai_h2_code：AI answer 与第二个 human answer 的 `content_code_text` overlap（仅有 AI answer 时非空）
#   - jaccard_ans1_ans2_code：有 AI answer 时用 AI vs human2，否则用 human1 vs human2

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

def _extract_pair_texts(
    group: pd.DataFrame,
    ai_text,
    human_col: str,
):
    human_answers = group[group[human_col].notna()].sort_values("dateID")
    first_human_text = human_answers.iloc[0][human_col] if len(human_answers) >= 1 else np.nan
    second_human_text = human_answers.iloc[1][human_col] if len(human_answers) >= 2 else np.nan
    return first_human_text, second_human_text, ai_text, len(human_answers)


def _build_overlap_triplet(h1_text, h2_text, ai_text, is_treatment: bool):
    h1_h2 = compute_jaccard(h1_text, h2_text)
    ai_h2 = np.nan
    if is_treatment:
        ai_h2 = compute_jaccard(ai_text, h2_text)
    ans1_ans2 = ai_h2 if is_treatment else h1_h2
    return h1_h2, ai_h2, ans1_ans2


# ── Per-question builder ────────────────────────────────────────────────────

def build_question_level_overlap(
    group: pd.DataFrame,
    ai_full_lookup: pd.Series,
    ai_code_lookup: pd.Series,
    preai_lookup: pd.Series,
) -> pd.Series:
    question_url = group.name

    ai_full = ai_full_lookup.get(question_url)
    ai_code = ai_code_lookup.get(question_url)
    preai = int(preai_lookup.get(question_url, 0))

    h1_full, h2_full, ai_full, n_human_answers = _extract_pair_texts(
        group,
        ai_full,
        human_col="content_full_text",
    )
    h1_code, h2_code, ai_code, _ = _extract_pair_texts(
        group,
        ai_code,
        human_col="content_code_text",
    )

    jaccard_h1_h2, jaccard_ai_h2, jaccard_ans1_ans2 = _build_overlap_triplet(
        h1_full, h2_full, ai_full, preai == 1
    )
    jaccard_h1_h2_code, jaccard_ai_h2_code, jaccard_ans1_ans2_code = _build_overlap_triplet(
        h1_code, h2_code, ai_code, preai == 1
    )

    return pd.Series(
        {
            "questionURL": question_url,
            "preAI": preai,
            "group_type": "treatment" if preai == 1 else "control",
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

def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    ai_full_lookup = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "answer_text"]]
        .drop_duplicates("questionURL")
        .set_index("questionURL")["answer_text"]
    )
    ai_code_lookup = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "content_code_text"]]
        .drop_duplicates("questionURL")
        .set_index("questionURL")["content_code_text"]
    )

    preai_lookup = question[["questionURL", "preAI"]].drop_duplicates("questionURL").set_index("questionURL")["preAI"]

    tqdm.pandas(desc="Computing question-level Jaccard overlap")

    feature = (
        human_answer.groupby("questionURL")
        .progress_apply(lambda g: build_question_level_overlap(g, ai_full_lookup, ai_code_lookup, preai_lookup))
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
