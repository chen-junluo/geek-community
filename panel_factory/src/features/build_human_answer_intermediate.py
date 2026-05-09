# Artifact:  intermediate/human_answer
# 输入:      data/raw/cmn_base.csv, data/raw/cmn_content.csv, question_intermediate.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id (或 questionURL, cmnID)
# 输出:      data/features/human_answer_intermediate.csv
#
# 逻辑：标准化 human-answer universe。`cmnID == 0` 不算 answer，
#       `resp_id` 只给 human answers，且必须按 chronological order 构造。
#
# 补充列（相比旧版）：
#   - metlikes (coalesce netlikeNum)
#   - accumRep, accumGold, accumSilver, accumCopper (user badges)
#   - content_code_text, content_CN_text (text extracts)
#   - 确保 resp_id 按 (date, cmnID) chronological order

import os

import pandas as pd
import numpy as np

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["human_answer"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])

    cmn_base["date"] = pd.to_datetime(cmn_base["date"], errors="coerce")

    # Filter to answers only (cmnID != 0)
    answer_base = cmn_base[cmn_base["cmnID"] != 0].copy()

    # Merge question preAI
    answer_base = answer_base.merge(
        question[["questionURL", "preAI"]],
        on="questionURL",
        how="inner",
        suffixes=("", "_question")
    )

    # Merge answer text content
    answer_base = answer_base.merge(
        cmn_content[["questionURL", "cmnID", "content_full_text", "content_code_text", "content_CN_text"]],
        on=["questionURL", "cmnID"],
        how="left",
    )

    # Ensure no old resp_id column exists
    if "resp_id" in answer_base.columns:
        answer_base = answer_base.drop(columns=["resp_id"])

    # Sort by questionURL, then date, then cmnID (chronological order)
    answer_base = answer_base.sort_values(
        ["questionURL", "date", "cmnID"],
        na_position="last",
    ).reset_index(drop=True)

    # Generate resp_id (within-question chronological index: 1, 2, 3...)
    answer_base["resp_id"] = answer_base.groupby("questionURL").cumcount() + 1

    # Standardize column names
    answer_base["is_accepted_answer"] = answer_base["accept"].fillna(0).astype(int)
    answer_base["metlikes"] = answer_base["netlikeNum"].fillna(0)  # coalesce netlikeNum
    answer_base["human_answer_text"] = answer_base["content_full_text"]
    answer_base["dateID"] = answer_base["resp_id"]  # dateID = resp_id for compatibility

    # Drop raw fields that have been standardized
    answer_base = answer_base.drop(columns=["accept"], errors="ignore")

    # Select and order columns
    # Core columns
    core_cols = ["questionURL", "resp_id", "cmnID", "dateID", "date"]

    # Answer metadata
    answer_cols = ["is_accepted_answer", "metlikes", "answer", "hiddenanswer"]

    # Text content
    text_cols = ["human_answer_text", "content_code_text", "content_CN_text"]

    # User info
    user_cols = ["userURL", "userName", "accumRep", "accumGold", "accumSilver", "accumCopper"]

    # Formatting
    formatting_cols = ["imgNum", "brNum", "codeNum", "inlinecodeNum", "interlinecodeNum", "hrefNum"]

    # Other
    other_cols = ["preAI", "location", "secdate", "seclocation", "netlikeNum"]

    # Build ordered column list
    ordered_cols = core_cols + answer_cols + text_cols + user_cols + formatting_cols + other_cols

    # Add any remaining columns
    remaining_cols = [col for col in answer_base.columns if col not in ordered_cols]
    human_answer = answer_base[ordered_cols + remaining_cols]

    # Validation: check chronological order
    _validate_chronological_order(human_answer)

    human_answer.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"human_answer_intermediate 已保存: {OUTPUT_CSV}  shape={human_answer.shape}")
    print(f"  - resp_id range: {human_answer['resp_id'].min()} to {human_answer['resp_id'].max()}")
    print(f"  - date range: {human_answer['date'].min()} to {human_answer['date'].max()}")
    print(f"  - accepted answers: {human_answer['is_accepted_answer'].sum()}")
    return human_answer


def _validate_chronological_order(df):
    """Validate that resp_id follows chronological order within each question."""
    violations = []

    for questionURL, group in df.groupby("questionURL"):
        group = group.sort_values("resp_id")

        # Check if dates are monotonically increasing
        dates = pd.to_datetime(group["date"])
        if not dates.is_monotonic_increasing:
            violations.append(questionURL)

    if violations:
        print(f"  ⚠ Warning: {len(violations)} questions have non-chronological resp_id")
        print(f"    Sample violations: {violations[:5]}")
    else:
        print(f"  ✓ Chronological order validated")


if __name__ == "__main__":
    build()
