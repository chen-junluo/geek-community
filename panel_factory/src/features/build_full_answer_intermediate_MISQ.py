# Artifact:    intermediate/full_answer_intermediate_MISQ
# Grain:       full_answer
# Merge Keys:  questionURL, answer_id
#
# Inputs:
#   - full_answer_intermediate.csv
#   - question_intermediate_MISQ.csv
#
# Output:      data/features/full_answer_intermediate_MISQ.csv
#   - Index: questionURL, answer_id, answer_source
#   - Core: (same as full_answer_intermediate)
#   - Derived: —
#
# Logic:
#   - Filter full_answer_intermediate to MISQ sample questions
#   - Inner join on questionURL with question_intermediate_MISQ
#   - Preserve all AI + human answers for MISQ questions

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["full_answer_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer"])
    question_misq = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])

    misq_urls = question_misq[["questionURL"]].drop_duplicates()
    full_answer_misq = full_answer.merge(misq_urls, on="questionURL", how="inner")

    full_answer_misq.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"full_answer_intermediate_MISQ 已保存: {OUTPUT_CSV}  shape={full_answer_misq.shape}")
    return full_answer_misq


if __name__ == "__main__":
    build()
