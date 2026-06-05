# Artifact:    feature/question_answer_timing_counts_MISQ
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv  # canonical MISQ question universe
#   - cmn_base.csv  # raw question + answer metadata
#
# Output:      data/features/question_answer_timing_counts_MISQ.csv
#   - Index: questionURL
#   - Core: question_post_date, first_answer_date, answer_count
#   - Derived: answerNum_afterQuestion_within1day, answerNum_afterQuestion_within2day, answerNum_afterQuestion_within3day, answerNum_afterQuestion_within7day, answerNum_afterQuestion_within14day, answerNum_afterFirstAnswer_within1day, answerNum_afterFirstAnswer_within2day, answerNum_afterFirstAnswer_within3day, answerNum_afterFirstAnswer_within7day, answerNum_afterFirstAnswer_within14day
#
# Logic:
#   - 先读取 `question_intermediate_MISQ.csv`，仅保留 MISQ sample 对应的 `questionURL`
#   - 再在 `cmn_base.csv` 中抽取这些 question 的 whole thread，按 `questionURL, date, cmnID` 排序建立 chronology
#   - `cmnID == 0` 仅用于提取 question post date；answer 顺序由排序后的 `dateID_temp` 决定，不用 `cmnID` 判定第几个 answer
#   - 对每个 MISQ question 统计以 question post date 为 anchor 的 1/2/3/7/14 天内 answer 数
#   - 对每个 MISQ question 统计以 first answer date 为 anchor 的 1/2/3/7/14 天内后续新增 answer 数（不含 first answer 自己）
#   - window 定义为 `answer_date <= anchor_date + X days`

import os

import pandas as pd

from utils.paths import ARTIFACT_PATHS

OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_answer_timing_counts_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

WINDOW_DAYS = [1, 2, 3, 7, 14]


def _count_answers_within_window(answer_dates: pd.Series, anchor_date: pd.Timestamp, days: int, *, include_anchor: bool) -> int:
    if pd.isna(anchor_date):
        return 0
    upper_bound = anchor_date + pd.Timedelta(days=days)
    if include_anchor:
        mask = (answer_dates >= anchor_date) & (answer_dates <= upper_bound)
    else:
        mask = (answer_dates > anchor_date) & (answer_dates <= upper_bound)
    return int(mask.sum())


def _build_question_row(question_url: str, group: pd.DataFrame) -> dict:
    question_rows = group[group["cmnID"] == 0]
    answer_rows = group[group["cmnID"] > 0].copy()

    if not answer_rows.empty:
        answer_rows = answer_rows.sort_values(["date", "cmnID"], na_position="last").reset_index(drop=True)
        answer_rows["dateID_temp"] = answer_rows.index + 1
        answer_dates = answer_rows["date"]
        first_answer_date = answer_rows.loc[answer_rows["dateID_temp"] == 1, "date"].iloc[0]
    else:
        answer_dates = pd.Series(dtype="datetime64[ns]")
        first_answer_date = pd.NaT

    question_post_date = question_rows["date"].iloc[0] if not question_rows.empty else pd.NaT

    row = {
        "questionURL": question_url,
        "question_post_date": question_post_date,
        "first_answer_date": first_answer_date,
        "answer_count": int(len(answer_rows)),
    }

    for days in WINDOW_DAYS:
        row[f"answerNum_afterQuestion_within{days}day"] = _count_answers_within_window(
            answer_dates,
            question_post_date,
            days,
            include_anchor=True,
        )
        row[f"answerNum_afterFirstAnswer_within{days}day"] = _count_answers_within_window(
            answer_dates,
            first_answer_date,
            days,
            include_anchor=False,
        )

    return row


def build() -> pd.DataFrame:
    question_misq = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    question_misq["date"] = pd.to_datetime(question_misq["date"], errors="coerce", utc=True).dt.tz_localize(None)
    misq_urls = question_misq[["questionURL"]].drop_duplicates()

    cmn_base = pd.read_csv(os.path.join(ARTIFACT_PATHS["raw"], "cmn_base.csv"), encoding="utf-8-sig")
    cmn_base["date"] = pd.to_datetime(cmn_base["date"], errors="coerce", utc=True).dt.tz_localize(None)

    thread_rows = cmn_base.loc[:, ["questionURL", "cmnID", "date"]].copy()
    thread_rows = thread_rows.merge(misq_urls, on="questionURL", how="inner")
    thread_rows = thread_rows.sort_values(["questionURL", "date", "cmnID"], na_position="last")

    records = [
        _build_question_row(question_url, group)
        for question_url, group in thread_rows.groupby("questionURL", sort=False)
    ]
    feature = pd.DataFrame(records)

    feature = misq_urls.merge(feature, on="questionURL", how="left")

    count_cols = [
        "answer_count",
        *[f"answerNum_afterQuestion_within{days}day" for days in WINDOW_DAYS],
        *[f"answerNum_afterFirstAnswer_within{days}day" for days in WINDOW_DAYS],
    ]
    feature[count_cols] = feature[count_cols].fillna(0).astype(int)

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")

    print("=== Descriptive statistics ===")
    print(feature[count_cols].agg(["min", "max", "mean"]).T)

    sample_cols = [
        "questionURL",
        "answer_count",
        "answerNum_afterQuestion_within7day",
        "answerNum_afterFirstAnswer_within7day",
        "question_post_date",
        "first_answer_date",
    ]
    sample = feature.loc[feature["answerNum_afterQuestion_within7day"] > 0, sample_cols].head(10)
    if not sample.empty:
        print("=== Sample rows (question-window hit > 0) ===")
        print(sample.to_string(index=False))

    return feature


if __name__ == "__main__":
    build()
