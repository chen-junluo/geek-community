# Artifact:  intermediate/human_answer
# 输入:      data/raw/cmn_base.csv, data/raw/cmn_content.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id
# 输出:      data/features/human_answer_intermediate.csv
#
# 逻辑：标准化 human-answer universe。`cmnID == 0` 不算 answer，
#       `resp_id` 只给 human answers，且必须按 chronological order 构造。

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["human_answer"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])

    cmn_base["date"] = pd.to_datetime(cmn_base["date"], errors="coerce")

    answer_base = cmn_base[cmn_base["cmnID"] != 0].copy()
    answer_base = answer_base.merge(
        question[["questionURL", "preAI"]],
        on="questionURL",
        how="inner",
    )
    answer_base = answer_base.merge(
        cmn_content[["questionURL", "cmnID", "content_full_text", "content_code_text", "content_CN_text"]],
        on=["questionURL", "cmnID"],
        how="left",
    )
    # Ensure no old resp_id column exists
    if "resp_id" in answer_base.columns:
        answer_base = answer_base.drop(columns=["resp_id"])

    answer_base = answer_base.sort_values(
        ["questionURL", "date", "cmnID"],
        na_position="last",
    ).reset_index(drop=True)

    # Generate within-question local index (1, 2, 3... per questionURL)
    answer_base["resp_id"] = answer_base.groupby("questionURL").cumcount() + 1
    answer_base["is_accepted_answer"] = answer_base["accept"].fillna(0).astype(int)
    answer_base["human_answer_text"] = answer_base["content_full_text"]
    answer_base["dateID"] = answer_base["resp_id"]

    # Drop raw fields that have been standardized
    answer_base = answer_base.drop(columns=["accept"], errors="ignore")

    ordered_cols = [
        "questionURL",
        "resp_id",
        "cmnID",
        "dateID",
        "preAI",
        "date",
        "is_accepted_answer",
        "netlikeNum",
        "human_answer_text",
        "content_code_text",
        "content_CN_text",
    ]
    remaining_cols = [col for col in answer_base.columns if col not in ordered_cols]
    human_answer = answer_base[ordered_cols + remaining_cols]

    human_answer.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"human_answer_intermediate 已保存: {OUTPUT_CSV}  shape={human_answer.shape}")
    return human_answer


if __name__ == "__main__":
    build()
