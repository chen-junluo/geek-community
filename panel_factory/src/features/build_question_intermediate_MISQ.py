# Artifact:  intermediate/question_MISQ
# 输入:      data/features/question_intermediate.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_intermediate_MISQ.csv
#
# 逻辑：筛选 MISQ sample questions (ask == 1 & date >= 2023-01-01)
#       这是唯一实现 MISQ 筛选逻辑的地方，其他 MISQ builders 通过 questionURL join 继承

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["question_MISQ"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])

    # Convert date to datetime
    question["date"] = pd.to_datetime(question["date"], errors="coerce")

    # MISQ sample filter: ask == 1 & date >= 2023-01-01
    question_MISQ = question[
        (question["ask"] == 1) &
        (question["date"] >= "2023-01-01")
    ].copy()

    # Reset index
    question_MISQ = question_MISQ.reset_index(drop=True)

    question_MISQ.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_intermediate_MISQ 已保存: {OUTPUT_CSV}  shape={question_MISQ.shape}")
    print(f"  - Full universe: {len(question)} questions")
    print(f"  - MISQ sample: {len(question_MISQ)} questions ({len(question_MISQ)/len(question)*100:.1f}%)")
    print(f"  - Date range: {question_MISQ['date'].min()} to {question_MISQ['date'].max()}")
    return question_MISQ


if __name__ == "__main__":
    build()
