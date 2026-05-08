# Artifact:  feature/question_accepted_answer_similarity_MISQ
# 输入:      data/features/question_intermediate_MISQ.csv, data/features/human_answer_intermediate_MISQ.csv,
#            data/features/full_answer_intermediate_MISQ.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_accepted_answer_similarity_MISQ.csv
#
# 逻辑：
# - 为每个 question 选择 baseline answer (anchor)，计算 AI answer 与 baseline 的 full-text cosine similarity
# - 输出变量：`AISimWithAccept`
#
# Baseline 选择规则（优先级从高到低）：
# 1. 如果有 accepted answer：
#    - 只有 1 个 → 选这个（rule = "single_accept"）
#    - 有多个 → 选 `netlikeNum` 最高的
#      - 唯一最高 → 选这个（rule = "max_metlikes_among_accepted"）
#      - 多个并列最高 → 按 `resp_id` 排序后拼接（rule = "concat_tied_accepted"）
# 2. 如果没有 accepted answer：
#    - 选 `netlikeNum` 最高的 human answer
#      - 唯一最高 → 选这个（rule = "max_netlike_no_accept"）
#      - 多个并列最高 → 按 `resp_id` 排序后拼接（rule = "concat_tied_netlike_no_accept"）
# 3. 如果完全没有 human answer → baseline = NaN（rule = NaN）
#
# 注：`resp_id` 是按 chronological order 生成的，拼接时保证时间顺序

import os

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

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


def _join_resp_ids(values: pd.Series) -> str:
    ids = [str(int(v)) for v in values if pd.notna(v)]
    return "|".join(ids) if ids else np.nan


def build_anchor_lookup(human_answer: pd.DataFrame) -> pd.DataFrame:
    """
    为每个 question 选择 baseline answer (anchor)。

    优先级：
    1. 如果有 accepted answer，按现有逻辑选择
    2. 如果没有 accepted answer，选 netlikeNum 最高的 human answer
    3. 如果完全没有 human answer，baseline = NaN
    """
    # 兼容两种列名
    accept_col = "is_accepted_answer" if "is_accepted_answer" in human_answer.columns else "accepted"
    text_col = "human_answer_text" if "human_answer_text" in human_answer.columns else "textLengthCN"
    metlikes_col = "netlikeNum" if "netlikeNum" in human_answer.columns else "metlikes"

    # 按 questionURL 分组处理
    records = []
    for questionURL, group in human_answer.groupby("questionURL"):
        n_human_answers = len(group)

        # 先尝试找 accepted answers
        accepted = group[group[accept_col] == 1]

        if len(accepted) > 0:
            # 有 accepted answer
            has_accepted = 1
            n_accepted = len(accepted)

            if n_accepted == 1:
                chosen = accepted.iloc[[0]]
                rule = "single_accept"
            else:
                # 多个 accepted，选 netlikeNum 最高的
                max_netlike = accepted[metlikes_col].max()
                chosen = accepted[accepted[metlikes_col] == max_netlike]
                if len(chosen) == 1:
                    rule = "max_metlikes_among_accepted"
                else:
                    # 需要拼接，按 resp_id 排序（resp_id 已经是 chronological order）
                    chosen = chosen.sort_values("resp_id")
                    rule = "concat_tied_accepted"
        else:
            # 没有 accepted answer，选 netlikeNum 最高的
            has_accepted = 0
            n_accepted = 0

            max_netlike = group[metlikes_col].max()
            chosen = group[group[metlikes_col] == max_netlike]
            if len(chosen) == 1:
                rule = "max_netlike_no_accept"
            else:
                # 需要拼接，按 resp_id 排序
                chosen = chosen.sort_values("resp_id")
                rule = "concat_tied_netlike_no_accept"

        # 提取文本并拼接（如果需要）
        if text_col == "textLengthCN":
            anchor_text = np.nan
        else:
            chosen_texts = chosen[text_col].dropna().astype(str).str.strip()
            chosen_texts = chosen_texts[chosen_texts != ""]
            anchor_text = "\n\n".join(chosen_texts.tolist()) if len(chosen_texts) > 0 else np.nan

        # 记录结果
        records.append({
            "questionURL": questionURL,
            "has_accepted_answer": has_accepted,
            "n_accepted_answers": n_accepted,
            "anchor_selection_rule": rule,
            "accepted_resp_id": int(chosen.iloc[0]["resp_id"]) if len(chosen) == 1 else np.nan,
            "accepted_resp_ids": _join_resp_ids(chosen["resp_id"]),
            "accepted_anchor_text": anchor_text,
            "n_human_answers": n_human_answers,
            "baseline_netlike": chosen[metlikes_col].iloc[0] if len(chosen) > 0 else np.nan,
        })

    return pd.DataFrame(records)


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
            "n_human_answers",
            "baseline_netlike",
            "AISimWithAccept",
        ]
    ]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_accepted_answer_similarity_MISQ 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
