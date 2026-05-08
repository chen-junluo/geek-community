# Artifact:  intermediate/full_answer_MISQ
# 输入:      data/features/full_answer_intermediate.csv, data/features/question_intermediate_MISQ.csv
# Grain:     answer-level (question_id × answer_id)
# Merge keys: question_id, answer_id
# 输出:      data/features/full_answer_intermediate_MISQ.csv
#
# 逻辑：把 full-answer universe 收紧到 MISQ sample，只保留 MISQ questions 对应的 AI + human rows。

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["full_answer_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer"])
    question_misq = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])

    misq_ids = question_misq[["question_id"]].drop_duplicates()
    full_answer_misq = full_answer.merge(misq_ids, on="question_id", how="inner")

    full_answer_misq.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"full_answer_intermediate_MISQ 已保存: {OUTPUT_CSV}  shape={full_answer_misq.shape}")
    return full_answer_misq


if __name__ == "__main__":
    build()
