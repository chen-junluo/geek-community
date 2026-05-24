# Artifact:    feature/human_answer_accepted_answer_anchor_flag_MISQ
# Grain:       human_answer
# Merge Keys:  questionURL, resp_id
#
# Inputs:
#   - human_answer_intermediate_MISQ.csv
# Output:      data/features/human_answer_accepted_answer_anchor_flag_MISQ.csv
#   - Index: questionURL, resp_id
#   - Core: is_accept_similarity_anchor
#   - Derived: —
#
# Logic:
#   - 为每个 question 复用 accepted-answer similarity 的同一套 baseline answer 选择规则
#   - 对每个 human answer 标记其是否属于该 baseline anchor set
#   - 若 anchor 由多个 answer 拼接形成，则这些 answer 的 `is_accept_similarity_anchor` 都记为 `1`
#   - Baseline 选择规则（优先级从高到低）：
#     1. 如果有 accepted answer：
#        - 只有 1 个 → 选这个（rule = "single_accept"）
#        - 有多个 → 选 `netlikeNum` 最高的
#          - 唯一最高 → 选这个（rule = "max_netlike_among_accepted"）
#          - 多个并列最高 → 按 `resp_id` 排序后拼接（rule = "concat_tied_accepted"）
#     2. 如果没有 accepted answer：
#        - 选 `netlikeNum` 最高的 human answer
#          - 唯一最高 → 选这个（rule = "max_netlike_no_accept"）
#          - 多个并列最高 → 按 `resp_id` 排序后拼接（rule = "concat_tied_netlike_no_accept"）
#     3. 如果完全没有 human answer → 不输出记录

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["human_answer_accepted_answer_anchor_flag_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build_anchor_membership(human_answer: pd.DataFrame) -> pd.DataFrame:
    records = []
    for questionURL, group in human_answer.groupby("questionURL"):
        accepted = group[group["accepted"] == 1]

        if len(accepted) > 0:
            if len(accepted) == 1:
                chosen = accepted.iloc[[0]]
            else:
                max_netlike = accepted["netlikeNum"].max()
                chosen = accepted[accepted["netlikeNum"] == max_netlike]
                if len(chosen) > 1:
                    chosen = chosen.sort_values("resp_id")
        else:
            max_netlike = group["netlikeNum"].max()
            chosen = group[group["netlikeNum"] == max_netlike]
            if len(chosen) > 1:
                chosen = chosen.sort_values("resp_id")

        for _, row in chosen.iterrows():
            records.append({
                "questionURL": questionURL,
                "resp_id": int(row["resp_id"]),
                "is_accept_similarity_anchor": 1,
            })

    return pd.DataFrame(records)


def build() -> pd.DataFrame:
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])

    anchor_membership = build_anchor_membership(human_answer)

    feature = human_answer[["questionURL", "resp_id"]].copy()
    feature = feature.merge(anchor_membership, on=["questionURL", "resp_id"], how="left")
    feature["is_accept_similarity_anchor"] = feature["is_accept_similarity_anchor"].fillna(0).astype(int)
    feature = feature[["questionURL", "resp_id", "is_accept_similarity_anchor"]]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"human_answer_accepted_answer_anchor_flag_MISQ 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
