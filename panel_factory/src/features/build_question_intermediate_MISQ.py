# Artifact:  intermediate/question_MISQ
# 输入:      data/features/question_intermediate.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_intermediate_MISQ.csv
#
# 逻辑：严格沿用 round2_parser_for_panel.ipynb 的 sample definition。
#       仅保留 question row 满足 ask == 1 且 date >= 2023-01-01 的 MISQ universe。

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["question_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

MISQ_CUTOFF = "2023-01-01"


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])
    question["date"] = pd.to_datetime(question["date"], errors="coerce")

    misq_question = question[
        (question["ask"] == 1)
        & (question["date"] >= MISQ_CUTOFF)
    ].copy()

    misq_question.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_intermediate_MISQ 已保存: {OUTPUT_CSV}  shape={misq_question.shape}")
    return misq_question


if __name__ == "__main__":
    build()
