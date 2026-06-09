# Artifact:    intermediate/full_answer_intermediate
# Grain:       full_answer
# Merge Keys:  questionURL, answer_id
#
# Inputs:
#   - question_ai_content.csv  # AI answer text
#   - human_answer_intermediate.csv  # human answers
#
# Output:      data/features/full_answer_intermediate.csv
#   - Index: questionURL, answer_id, answer_source
#   - Core: resp_id, cmnID, dateID, date, is_accepted_answer, netlikeNum, answer_text, content_code_text
#   - Derived: —
#
# Logic:
#   - Combine AI answers (answer_id=1) and human answers (answer_id=resp_id+has_ai_answer)
#   - Unify answer_text field: AI uses ai_answer_text, human uses human_answer_text
#   - Add answer_source field: 'AI_answer' or 'human_answer'
#   - Preserve resp_id for human answers, set NaN for AI answers

import os
import pandas as pd
import numpy as np

from utils.paths import ARTIFACT_PATHS

OUTPUT_CSV = ARTIFACT_PATHS["intermediate"]["full_answer"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)


def _extract_ai_text(ai_df: pd.DataFrame) -> pd.Series:
    """提取 AI answer text，优先使用 full_text，fallback 到 CN_text"""
    if "preAI-content_full_text" in ai_df.columns:
        text = ai_df["preAI-content_full_text"]
    else:
        text = pd.Series(np.nan, index=ai_df.index)
    if "preAI-content_CN_text" in ai_df.columns:
        text = text.fillna(ai_df["preAI-content_CN_text"])
    return text


def _extract_ai_code_text(ai_df: pd.DataFrame) -> pd.Series:
    """提取 AI answer code text"""
    if "preAI-content_code_text" in ai_df.columns:
        return ai_df["preAI-content_code_text"]
    return pd.Series(np.nan, index=ai_df.index)


def build(raw_dir: str = ARTIFACT_PATHS["raw"]) -> pd.DataFrame:
    # 读取输入文件
    ai_content = pd.read_csv(os.path.join(raw_dir, "question_ai_content.csv"))
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer"])

    # ========== 处理 AI answers ==========
    ai_rows = ai_content.copy()
    ai_rows["answer_text"] = _extract_ai_text(ai_rows)
    ai_rows["content_code_text"] = _extract_ai_code_text(ai_rows)

    # 清理和过滤
    ai_rows["answer_text"] = ai_rows["answer_text"].astype("string").str.strip()
    ai_rows = ai_rows[ai_rows["answer_text"].notna() & ai_rows["answer_text"].ne("")].copy()

    # 添加标识字段
    ai_rows["answer_source"] = "AI_answer"
    ai_rows["resp_id"] = np.nan
    ai_rows["cmnID"] = np.nan
    ai_rows["dateID"] = 0  # AI answer 排在最前
    ai_rows["date"] = pd.NaT
    ai_rows["is_accepted_answer"] = 0
    ai_rows["netlikeNum"] = np.nan

    # 选择需要的列
    ai_cols = [
        "questionURL",
        "answer_source",
        "resp_id",
        "cmnID",
        "dateID",
        "date",
        "is_accepted_answer",
        "answer_text",
        "content_code_text",
        "netlikeNum",
    ]
    ai_rows = ai_rows[[col for col in ai_cols if col in ai_rows.columns]].copy()

    # ====== 处理 human answers ======
    human_rows = human_answer.copy()
    human_rows["answer_source"] = "human_answer"

    # 重命名列以统一
    if "human_answer_text" in human_rows.columns:
        human_rows = human_rows.rename(columns={"human_answer_text": "answer_text"})

    # 选择需要的列
    human_cols = [
        "questionURL",
        "answer_source",
        "resp_id",
        "cmnID",
        "dateID",
        "date",
        "is_accepted_answer",
        "answer_text",
        "content_code_text",
        "netlikeNum",
    ]
    human_rows = human_rows[[col for col in human_cols if col in human_rows.columns]].copy()

    # ======= 合并 AI + human answers ==========
    full_answer = pd.concat([ai_rows, human_rows], ignore_index=True, sort=False)

    # 按 questionURL + dateID 排序（AI answer dateID=0，排在最前）
    full_answer = full_answer.sort_values(
        ["questionURL", "dateID", "cmnID"],
        na_position="last",
    ).reset_index(drop=True)

    # 生成 answer_id：每个 questionURL 内从 1 开始递增
    full_answer["answer_id"] = full_answer.groupby("questionURL").cumcount() + 1

    # 保存
    full_answer.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"✓ full_answer_intermediate 已保存: {OUTPUT_CSV}")
    print(f"  Shape: {full_answer.shape}")
    print(f"  AI answers: {(full_answer['answer_source'] == 'AI_answer').sum()}")
    print(f"  Human answers: {(full_answer['answer_source'] == 'human_answer').sum()}")

    return full_answer


if __name__ == "__main__":
    build()
