# Artifact:    intermediate/question_intermediate
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - cmn_base.csv (cmnID==0)  # raw question metadata + asker-side reputation & badge fields
#   - cmn_content.csv  # raw question text
#   - question_base.csv  # raw question tags and ignoreAnsNum
#
# Output:      data/features/question_intermediate.csv
#   - Index: questionURL
#   - Core: title, userURL, date, tags, tagURL, views, focusNum, collectNum, preAI, crawldate, ignoreAnsNum, question_text
#   - Derived: carries asker-side `cmn_base` fields at `cmnID == 0`, including `accumRep`, `accumGold`, `accumSilver`, `accumCopper`
#
# Logic:
#   - 筛选 cmnID==0 的 question rows
#   - 保留 question row 自带的 asker-side reputation & badge fields
#   - 合并 question metadata, tags, text
#   - 生成 preAI treatment indicator
#   - 禁止使用 question_id

import os
import pandas as pd
import numpy as np

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["question"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    print("Loading raw data...")

    # Load cmn_base (questions only)
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_base["date"] = pd.to_datetime(cmn_base["date"]).dt.tz_localize(None)
    question_base_from_cmn = cmn_base[cmn_base["cmnID"] == 0].copy()

    # Load question_base (has tags, tagURL, ignoreAnsNum)
    question_base = pd.read_csv(os.path.join(raw_dir, "question_base.csv"))

    # Load cmn_content (for question text)
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))
    question_content = cmn_content[cmn_content["cmnID"] == 0][["questionURL", "content_full_text"]].copy()
    question_content = question_content.rename(columns={"content_full_text": "question_text"})

    print("Merging question data...")

    # Start with question_base_from_cmn
    question = question_base_from_cmn.copy()

    # Merge question_base to get tags, tagURL, ignoreAnsNum, preAI, crawldate
    question = question.merge(
        question_base[["questionURL", "tags", "tagURL", "ignoreAnsNum", "preAI", "crawldate"]],
        on="questionURL",
        how="left"
    )

    # Merge question text
    question = question.merge(question_content, on="questionURL", how="left")

    if "preAI" in question.columns:
        question["preAI"] = question["preAI"].fillna(0).astype(int)

    # Select only the columns we need for clean intermediate
    output_cols = [
        "questionURL",
        "title",
        "userURL",
        "date",
        "tags",
        "tagURL",
        "views",
        "focusNum",
        "collectNum",
        "preAI",
        "crawldate",
        "ignoreAnsNum",
        "question_text",
        "accumRep",
        "accumGold",
        "accumSilver",
        "accumCopper",
    ]

    # Check which columns exist
    existing_cols = [col for col in output_cols if col in question.columns]
    question = question[existing_cols]

    # Sort by date
    question = question.sort_values("date").reset_index(drop=True)

    # Save
    question.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"✓ question_intermediate saved: {OUTPUT_CSV}")
    print(f"  Shape: {question.shape}")
    print(f"  Date range: {question['date'].min()} to {question['date'].max()}")
    if "preAI" in question.columns:
        print(f"  preAI questions: {question['preAI'].sum()} ({question['preAI'].mean()*100:.1f}%)")

    return question


if __name__ == "__main__":
    build()
