# Artifact:    intermediate/question_intermediate_MISQ
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate.csv
#
# Output:    data/features/question_intermediate_MISQ.csv
#   - Index: questionURL
#   - Core: title, date, tags, tagURL, views, focusNum, collectNum, preAI, crawldate, ignoreAnsNum, question_text
#   - Derived: —
#
# Logic:
#   - Filter MISQ sample: date >= 2023-01-01
#   - question_intermediate already contains only questions (no need to check ask==1)
#   - This is the canonical MISQ sample definition
#   - All other MISQ builders inherit this sample via questionURL join

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["question_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])

    # Convert date to datetime
    question["date"] = pd.to_datetime(question["date"], errors="coerce")

    # MISQ sample filter: date >= 2023-01-01
    # Note: question_intermediate only contains questions (no need to check ask==1)
    question_MISQ = question[
        question["date"] >= "2023-01-01"
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
