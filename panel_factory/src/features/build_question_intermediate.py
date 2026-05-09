# Artifact:  intermediate/question
# 输入:      data/raw/cmn_base.csv, data/raw/cmn_content.csv, data/raw/question_ai_content.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_intermediate.csv
#
# 逻辑：标准化 question universe，保留 question metadata + question text + canonical `preAI`，
#       供 question-level features / panels 复用。
#
# 补充列（相比旧版）：
#   - views, focusNum, collectNum (从 cmn_base)
#   - preAI (从 question_ai_content 推断)

import os

import pandas as pd
import numpy as np

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["question"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def _load_raw_tables(raw_dir: str):
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))
    question_ai_content = pd.read_csv(os.path.join(raw_dir, "question_ai_content.csv"), low_memory=False)

    cmn_base["date"] = pd.to_datetime(cmn_base["date"], errors="coerce")

    # Filter to questions only (cmnID == 0)
    question_base = (
        cmn_base[cmn_base["cmnID"] == 0]
        .copy()
        .sort_values(["date", "questionURL"], na_position="last")
        .reset_index(drop=True)
    )

    # Extract question text
    question_text = (
        cmn_content[cmn_content["cmnID"] == 0][["questionURL", "cmnID", "content_full_text"]]
        .drop_duplicates(["questionURL", "cmnID"])
        .rename(columns={"content_full_text": "question_text"})
    )

    # Infer preAI from question_ai_content
    ai_text = pd.Series(pd.NA, index=question_ai_content.index, dtype="object")
    if "preAI-content_full_text" in question_ai_content.columns:
        ai_text = question_ai_content["preAI-content_full_text"]
    if "preAI-content_CN_text" in question_ai_content.columns:
        ai_text = ai_text.fillna(question_ai_content["preAI-content_CN_text"])

    preai_lookup = question_ai_content[["questionURL"]].copy()
    preai_lookup["preAI"] = (
        ai_text.notna()
        & ai_text.astype(str).str.strip().ne("")
    ).astype(int)
    preai_lookup = preai_lookup.drop_duplicates("questionURL")

    return question_base, question_text, preai_lookup


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    question_base, question_text, preai_lookup = _load_raw_tables(raw_dir)

    # Merge question text
    question = question_base.merge(
        question_text,
        on=["questionURL", "cmnID"],
        how="left",
    )

    # Merge preAI indicator
    question = question.merge(preai_lookup, on="questionURL", how="left")
    question["preAI"] = question["preAI"].fillna(0).astype(int)

    # Select and order columns
    # Core columns
    core_cols = ["questionURL", "title", "question_text", "date", "preAI"]

    # Metadata columns
    metadata_cols = ["views", "focusNum", "collectNum", "ask"]

    # User columns
    user_cols = ["userURL", "userName", "accumRep", "accumGold", "accumSilver", "accumCopper"]

    # Formatting columns (from question itself, not AI)
    formatting_cols = ["imgNum", "brNum", "codeNum", "inlinecodeNum", "interlinecodeNum", "hrefNum"]

    # Other columns
    other_cols = ["location", "secdate", "seclocation", "answer", "hiddenanswer", "accept", "netlikeNum"]

    # Build ordered column list
    ordered_cols = core_cols + metadata_cols + user_cols + formatting_cols + other_cols

    # Add any remaining columns not in ordered list
    remaining_cols = [col for col in question.columns if col not in ordered_cols]
    question = question[ordered_cols + remaining_cols]

    # Drop cmnID (always 0 for questions)
    if "cmnID" in question.columns:
        question = question.drop(columns=["cmnID"])

    question.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_intermediate 已保存: {OUTPUT_CSV}  shape={question.shape}")
    print(f"  - date range: {question['date'].min()} to {question['date'].max()}")
    print(f"  - preAI questions: {question['preAI'].sum()} ({question['preAI'].mean()*100:.1f}%)")
    return question


if __name__ == "__main__":
    build()
