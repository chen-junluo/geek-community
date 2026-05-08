# Artifact:  intermediate/full_answer
# 输入:      data/features/human_answer_intermediate.csv, data/raw/question_ai_content.csv, data/raw/cmn_content.csv
# Grain:     answer-level (questionURL × answer_id)
# Merge keys: questionURL, answer_id
# 输出:      data/features/full_answer_intermediate.csv
#
# 逻辑：标准化 all-answer universe。answer_id 覆盖 AI + human answers，
#       AI / human index 语义必须分开，AI row 的 resp_id 固定为空。

import os

import numpy as np
import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["full_answer"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def _extract_ai_text(ai_df: pd.DataFrame) -> pd.Series:
    if "preAI-content_full_text" in ai_df.columns:
        text = ai_df["preAI-content_full_text"]
    else:
        text = pd.Series(np.nan, index=ai_df.index)
    if "preAI-content_CN_text" in ai_df.columns:
        text = text.fillna(ai_df["preAI-content_CN_text"])
    return text


def _extract_ai_code_text(ai_df: pd.DataFrame) -> pd.Series:
    if "preAI-content_code_text" in ai_df.columns:
        return ai_df["preAI-content_code_text"]
    return pd.Series(np.nan, index=ai_df.index)



def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer"])
    question_ai_content = pd.read_csv(os.path.join(raw_dir, "question_ai_content.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))

    ai_rows = question[["questionURL"]].merge(
        question_ai_content,
        on="questionURL",
        how="left",
    )
    ai_rows["ai_answer_text"] = _extract_ai_text(ai_rows)
    ai_rows["ai_answer_code_text"] = _extract_ai_code_text(ai_rows)
    ai_rows = ai_rows[ai_rows["ai_answer_text"].notna()].copy()
    ai_rows["ai_answer_text"] = ai_rows["ai_answer_text"].astype(str).str.strip()
    ai_rows = ai_rows[ai_rows["ai_answer_text"] != ""].copy()
    ai_rows["answer_id"] = 1
    ai_rows["answer_source"] = "AI_answer"
    ai_rows["resp_id"] = np.nan
    ai_rows["human_answer_text"] = np.nan
    ai_rows["content_code_text"] = ai_rows["ai_answer_code_text"]
    ai_rows["answer_text"] = ai_rows["ai_answer_text"]
    ai_rows["is_accepted_answer"] = 0
    ai_rows["dateID"] = 0
    ai_rows["cmnID"] = np.nan

    human_rows = human_answer.copy()
    # Merge human answer text from cmn_content
    human_text = cmn_content[["questionURL", "cmnID", "content_full_text", "content_code_text"]].copy()
    human_rows = human_rows.merge(
        human_text,
        on=["questionURL", "cmnID"],
        how="left",
    )
    human_rows = human_rows.rename(columns={"content_full_text": "human_answer_text"})

    has_ai_map = ai_rows[["questionURL"]].drop_duplicates().assign(has_ai_answer=1)
    human_rows = human_rows.merge(has_ai_map, on="questionURL", how="left")
    human_rows["has_ai_answer"] = human_rows["has_ai_answer"].fillna(0).astype(int)
    human_rows["answer_id"] = human_rows["resp_id"] + human_rows["has_ai_answer"]
    human_rows["answer_source"] = "human_answer"
    human_rows["ai_answer_text"] = np.nan
    human_rows["ai_answer_code_text"] = np.nan
    human_rows["answer_text"] = human_rows["human_answer_text"]

    keep_cols = [
        "questionURL",
        "answer_id",
        "answer_source",
        "resp_id",
        "cmnID",
        "dateID",
        "date",
        "is_accepted_answer",
        "human_answer_text",
        "ai_answer_text",
        "ai_answer_code_text",
        "content_code_text",
        "answer_text",
        "netlikeNum",
    ]
    ai_rows = ai_rows[[col for col in keep_cols if col in ai_rows.columns]].copy()
    human_rows = human_rows[[col for col in keep_cols if col in human_rows.columns]].copy()

    full_answer = pd.concat([ai_rows, human_rows], ignore_index=True, sort=False)
    full_answer = full_answer.sort_values(
        ["questionURL", "answer_id", "dateID", "cmnID"],
        na_position="last",
    ).reset_index(drop=True)

    full_answer.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"full_answer_intermediate 已保存: {OUTPUT_CSV}  shape={full_answer.shape}")
    return full_answer


if __name__ == "__main__":
    build()
