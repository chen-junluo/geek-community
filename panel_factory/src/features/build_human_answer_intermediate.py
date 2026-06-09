# Artifact:    intermediate/human_answer_intermediate
# Grain:       human_answer
# Merge Keys:  questionURL, resp_id
#
# Inputs:
#   - cmn_base.csv (cmnID>0, answer==1)  # raw human answer metadata
#   - cmn_content.csv  # raw human answer text
#
# Output:      data/features/human_answer_intermediate.csv
#   - Index: questionURL, resp_id
#   - Core: cmnID, date, userURL, accepted, netlikeNum, dateID, human_answer_text, content_code_text, content_CN_text
#   - Derived: —
#
# Logic:
#   - 筛选 cmnID>0 且 answer==1 的 human answers
#   - 按 questionURL, date, cmnID 排序
#   - 生成 resp_id: 每个 question 内从 1 开始递增
#   - 提取 human_answer_text, content_code_text, content_CN_text
#   - 使用 netlikeNum

import os
import pandas as pd
import numpy as np

from utils.paths import ARTIFACT_PATHS

OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["human_answer"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    # 读取 raw data
    cmn_base = pd.read_csv(os.path.join(raw_dir, "cmn_base.csv"))
    cmn_content = pd.read_csv(os.path.join(raw_dir, "cmn_content.csv"))

    # 转换 date 为 datetime
    cmn_base["date"] = pd.to_datetime(cmn_base["date"], errors="coerce")

    # 筛选：cmnID > 0 且 answer == 1
    human_answers = cmn_base[
        (cmn_base["cmnID"] > 0) &
     (cmn_base["answer"] == 1)
    ].copy()

    # 按 questionURL, date, cmnID 排序（chronological order）
    human_answers = human_answers.sort_values(
        ["questionURL", "date", "cmnID"],
        na_position="last"
    ).reset_index(drop=True)

    # 生成 resp_id：在每个 questionURL 内从 1 开始递增
    human_answers["resp_id"] = human_answers.groupby("questionURL").cumcount() + 1

    # 生成 dateID = resp_id
    human_answers["dateID"] = human_answers["resp_id"]

    # Merge cmn_content 提取 text fields
    human_answers = human_answers.merge(
        cmn_content[["questionURL", "cmnID", "content_full_text", "content_code_text", "content_CN_text"]],
        on=["questionURL", "cmnID"],
        how="left"
    )

    # 标准化列名
    human_answers["human_answer_text"] = human_answers["content_full_text"]
    human_answers["is_accepted_answer"] = human_answers["accept"].fillna(0).astype(int)

    # 选择输出列（按要求的顺序）
    output_cols = [
        # Index
        "resp_id", "dateID", "questionURL", "cmnID",
        # Metadata
        "date", "userURL", "userName",
        # Text
      "human_answer_text", "content_code_text", "content_CN_text",
        # Acceptance
        "is_accepted_answer", "netlikeNum",
        # User badges
        "accumRep", "accumGold", "accumSilver", "accumCopper"
    ]

    human_answer_intermediate = human_answers[output_cols]

    # 保存
    human_answer_intermediate.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")

    # 报告统计
    print(f"✓ human_answer_intermediate 已保存: {OUTPUT_CSV}")
    print(f"  - Shape: {human_answer_intermediate.shape}")
    print(f"  - resp_id range: {human_answer_intermediate['resp_id'].min()} to {human_answer_intermediate['resp_id'].max()}")
    print(f"  - Unique questions: {human_answer_intermediate['questionURL'].nunique()}")
    print(f"  - Date range: {human_answer_intermediate['date'].min()} to {human_answer_intermediate['date'].max()}")
    print(f"  - Accepted answers: {human_answer_intermediate['is_accepted_answer'].sum()}")
    print(f"  - netlikeNum stats: min={human_answer_intermediate['netlikeNum'].min()}, max={human_answer_intermediate['netlikeNum'].max()}, mean={human_answer_intermediate['netlikeNum'].mean():.2f}")

    return human_answer_intermediate


if __name__ == "__main__":
    build()
