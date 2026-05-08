# Artifact:  intermediate/human_answer_MISQ
# 输入:      data/features/human_answer_intermediate.csv, data/features/question_intermediate_MISQ.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id
# 输出:      data/features/human_answer_intermediate_MISQ.csv
#
# 逻辑：把 human-response universe 收紧到 MISQ sample，只保留 MISQ questions 对应的 whole thread。

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["human_answer_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer"])
    question_misq = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])

    misq_urls = question_misq[["questionURL"]].drop_duplicates()
    human_answer_misq = human_answer.merge(misq_urls, on="questionURL", how="inner")

    human_answer_misq.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"human_answer_intermediate_MISQ 已保存: {OUTPUT_CSV}  shape={human_answer_misq.shape}")
    return human_answer_misq


if __name__ == "__main__":
    build()
