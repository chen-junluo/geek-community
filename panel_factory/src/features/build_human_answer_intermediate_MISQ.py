# Artifact:    intermediate/human_answer_intermediate_MISQ
# Grain:       human_answer
# Merge Keys:  questionURL, resp_id
#
# Inputs:
#   - human_answer_intermediate.csv
#   - question_intermediate_MISQ.csv
#
# Output:      data/features/human_answer_intermediate_MISQ.csv
#   - Index: questionURL, resp_id
#   - Core: (same as human_answer_intermediate)
#   - Derived: —
#
# Logic:
#   - 读取 human_answer_intermediate
#   - 通过 questionURL join question_intermediate_MISQ
#   - 保留 MISQ sample 的 human answers

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["human_answer_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer"], low_memory=False)
    question_misq = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"], low_memory=False)

    misq_urls = question_misq[["questionURL"]].drop_duplicates()
    human_answer_misq = human_answer.merge(misq_urls, on="questionURL", how="inner")

    # 生成 resp_id：within-question 的局部序号，按时间排序
    if "resp_id" not in human_answer_misq.columns:
        human_answer_misq["date"] = pd.to_datetime(human_answer_misq["date"], errors="coerce")
        human_answer_misq = human_answer_misq.sort_values(["questionURL", "date", "cmnID"])
        human_answer_misq["resp_id"] = human_answer_misq.groupby("questionURL").cumcount() + 1

    # 生成 answer_id：within-question 的局部序号，考虑 AI answer
    if "answer_id" not in human_answer_misq.columns:
        # 检查每个 question 是否有 AI answer
        has_ai = question_misq[["questionURL", "preAI"]].copy() if "preAI" in question_misq.columns else None
        if has_ai is not None:
            human_answer_misq = human_answer_misq.merge(
                has_ai.rename(columns={"preAI": "has_ai_answer"}),
                on="questionURL",
                how="left"
            )
            human_answer_misq["has_ai_answer"] = human_answer_misq["has_ai_answer"].fillna(0).astype(int)
            # 如果有 AI answer，human answers 的 answer_id 从 2 开始；否则从 1 开始
            human_answer_misq["answer_id"] = human_answer_misq["resp_id"] + human_answer_misq["has_ai_answer"]
        else:
            # 如果没有 preAI 信息，默认 answer_id = resp_id
            human_answer_misq["answer_id"] = human_answer_misq["resp_id"]

    human_answer_misq.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"human_answer_intermediate_MISQ 已保存: {OUTPUT_CSV}  shape={human_answer_misq.shape}")
    return human_answer_misq


if __name__ == "__main__":
    build()
