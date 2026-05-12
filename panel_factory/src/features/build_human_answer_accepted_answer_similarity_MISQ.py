# Artifact:    feature/human_answer_accepted_answer_similarity_MISQ
# Grain:       human_answer
# Merge Keys:  questionURL, resp_id
#
# Inputs:
#   - human_answer_intermediate_MISQ.csv
#   - full_answer_intermediate_MISQ.csv
# Output:      data/features/human_answer_accepted_answer_similarity_MISQ.csv
#   - Index: questionURL, resp_id
#   - Core: SimWithAccept
#   - Derived: —
#
# Logic:
#   - 为每个 question 选择 baseline answer (anchor)，计算每个 human answer 与 baseline 的 full-text cosine similarity
#   - 输出变量：`SimWithAccept`
#   - Baseline 选择规则（优先级从高到低）：
#     1. 如果有 accepted answer：
#        - 只有 1 个 → 选这个（rule = "single_accept"）
#        - 有多个 → 选 `netlikeNum` 最高的
#          - 唯一最高 → 选这个（rule = "max_netlikes_among_accepted"）
#          - 多个并列最高 → 按 `resp_id` 排序后拼接（rule = "concat_tied_accepted"）
#     2. 如果没有 accepted answer：
#        - 选 `netlikeNum` 最高的 human answer
#          - 唯一最高 → 选这个（rule = "max_netlike_no_accept"）
#          - 多个并列最高 → 按 `resp_id` 排序后拼接（rule = "concat_tied_netlike_no_accept"）
#     3. 如果完全没有 human answer → baseline = NaN（rule = NaN）

import os

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["human_answer_accepted_answer_similarity_misq"]
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
    # 按 questionURL 分组处理
    records = []
    for questionURL, group in human_answer.groupby("questionURL"):
        n_human_answers = len(group)

        # 先尝试找 accepted answers
        accepted = group[group["is_accepted_answer"] == 1]

        if len(accepted) > 0:
            # 有 accepted answer
            has_accepted = 1
            n_accepted = len(accepted)

            if n_accepted == 1:
                chosen = accepted.iloc[[0]]
                rule = "single_accept"
            else:
                # 多个 accepted，选 netlikeNum 最高的
                max_netlike = accepted["netlikeNum"].max()
                chosen = accepted[accepted["netlikeNum"] == max_netlike]
                if len(chosen) == 1:
                    rule = "max_netlike_among_accepted"
                else:
                    # 需要拼接，按 resp_id 排序（resp_id 已经是 chronological order）
                    chosen = chosen.sort_values("resp_id")
                    rule = "concat_tied_accepted"
        else:
            # 没有 accepted answer，选 netlikeNum 最高的
            has_accepted = 0
            n_accepted = 0

            max_netlike = group["netlikeNum"].max()
            chosen = group[group["netlikeNum"] == max_netlike]
            if len(chosen) == 1:
                rule = "max_netlike_no_accept"
            else:
                # 需要拼接，按 resp_id 排序
                chosen = chosen.sort_values("resp_id")
                rule = "concat_tied_netlike_no_accept"

        # 提取文本并拼接（如果需要）
        chosen_texts = chosen["human_answer_text"].dropna().astype(str).str.strip()
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
            "baseline_netlike": chosen["netlikeNum"].iloc[0] if len(chosen) > 0 else np.nan,
        })

    return pd.DataFrame(records)


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
            "n_human_answers",
            "baseline_netlike",
            "SimWithAccept",
        ]
    ]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"answer_accepted_answer_similarity_MISQ 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
