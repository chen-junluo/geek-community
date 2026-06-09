# Artifact:    feature/question_aggregation_from_answers
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate.csv
#   - human_answer_intermediate.csv
#   - human_answer_content_metrics.csv
#   - question_content_metrics.csv
#   - user_activity_experience.csv
#
# Output:      data/features/question_aggregation_from_answers.csv
#   - Index: questionURL
#   - Core: wait1Resp_original, wait2Resp_original, wait3Resp_original, waitAccepted_original, waitAvgAllResp_original, askTime_original, askTime, hourofday, dayofweek, monthofyear, isHoliday, isLieu, hiddenanswer_que, answer_que, accepted_que, views_que, focusNum_que, collectNum_que, codeLength_1Resp, textLengthCN_1Resp, acceptedBefore_sumResp, answer_que_within7day, log_answer_que_within7day, deltaPostLastansAvg, deltawaitMedian
#   - Derived: good1Resp, good2Resp, bestgt1Resp, bestallResp, like-threshold counts, markdown-threshold counts, acceptedBefore-stratified counts and netlike summaries, tag-window context
#
# Logic:
#   - 恢复 `Archive/round2_parser_for_panel.ipynb` cells 62-65, 58 的 canonical question aggregation contract
#   - answer-side: 以 `human_answer_intermediate` + `human_answer_content_metrics` + `user_activity_experience` 在 `questionURL, cmnID` 对齐后聚合
#   - question-side: 以 `question_intermediate` 提供 ask-side metadata，再 late merge `question_content_metrics` 提供 canonical ask-side content metrics
#   - 对关键 canonical columns 做 fail-fast contract check，不允许 silent fallback 到全 `NaN`

import os
import time
import pandas as pd
import numpy as np
import chinese_calendar

from utils.paths import ARTIFACT_PATHS

OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_aggregation_from_answers"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

QUESTION_INTERMEDIATE = ARTIFACT_PATHS["intermediate"]["question"]
HUMAN_ANSWER_INTERMEDIATE = ARTIFACT_PATHS["intermediate"]["human_answer"]
HUMAN_ANSWER_CONTENT_METRICS = ARTIFACT_PATHS["features"]["human_answer_content_metrics"]
QUESTION_CONTENT_METRICS = ARTIFACT_PATHS["features"]["question_content_metrics"]
USER_ACTIVITY_EXPERIENCE = ARTIFACT_PATHS["features"]["user_activity_experience"]

LIKES_THRESHOLDS = [1, 3, 5, 7, 10]
MARKDOWN_THRESHOLDS = [0, 1, 2, 3, 4, 5]
TIME_WINDOWS_ALL = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 14, 30, 60, 150]
TIME_WINDOWS_DELTA = [1, 8, 10, 30, 60, 150]
COMMENT_FIELDS = [
    "nComment",
    "nCommentAsker",
    "nCommentResponder",
    "nCommentOthers",
    "nAt",
    "nAtAsker",
    "nAtResponder",
    "nAtOthers",
    "nFollowup",
    "nAddKnow",
]
GEEK_FIELDS = [
    "imgNum",
    "inlinecodeNum",
    "interlinecodeNum",
    "boldNum",
    "italicNum",
    "liNum",
    "aNum",
    "blockquoteNum",
    "hrNum",
    "tableNum",
]
PLACEBO_ASK_FIELDS = [
    "placebo_a",
    "placebo_d",
    "placebo_p",
    "placebo_c",
    "placebo_u",
    "placebo_y",
    "placebo_i",
    "placebo_l",
    "placebo_s",
    "placebo_f",
    "placebo_b",
    "placebo_x",
    "placebo_h",
    "placebo_k",
    "placebo_z",
    "placebo_q",
    "placebo_vd",
    "placebo_vn",
    "placebo_vx",
    "placebo_ad",
    "placebo_an",
    "placebo_format",
]
ANSWER_SUM_FIELDS = [
    "codeLength",
    "textLength",
    "textLengthCN",
    "accepted",
    "netlikeNum",
    "hiddenanswer",
    "answer",
    "interlinecodeNum",
    "aNum",
    "liNum",
    "commentOthersBefore",
]
EXPERT_SUM_FIELDS = [
    "acceptedBefore",
    "masterTop5pct",
    "masterTop10pct",
    "masterTop15pct",
    "masterTop20pct",
    "seniorTop5pct",
    "seniorTop10pct",
    "seniorTop15pct",
    "seniorTop20pct",
    "looseTop5pct",
    "looseTop10pct",
    "looseTop15pct",
    "looseTop20pct",
    "strictTop5pct",
    "strictTop10pct",
    "strictTop15pct",
    "strictTop20pct",
    "preferdiscussTop5pct",
    "preferdiscussTop10pct",
    "preferdiscussTop15pct",
    "preferdiscussTop20pct",
]
EXPERIENCE_SINGLE_FIELDS = [
    "accumRep",
    "accumGold",
    "accumSilver",
    "accumCopper",
    "askBefore",
    "resBefore",
    "acceptedBefore",
    "acceptBefore",
    "commentBefore",
    "netlikeBefore",
    "badgeBefore",
    "ratioAcceptAsk",
    "ratioCommentBadge",
]
ASK_SUM_FIELDS = [
    "codeLength",
    "textLength",
    "textLengthCN",
    "accept",
    "netlikeNum",
    "ulNum",
    "olNum",
    "brNum",
    "codeNum",
    "interlinecodeNum",
    "aNum",
] + COMMENT_FIELDS + EXPERIENCE_SINGLE_FIELDS
FIRST_SECOND_ACCEPTED_FIELDS = ANSWER_SUM_FIELDS + COMMENT_FIELDS + EXPERT_SUM_FIELDS + EXPERIENCE_SINGLE_FIELDS
AFTER_AND_SUM_FIELDS = ANSWER_SUM_FIELDS + COMMENT_FIELDS + EXPERT_SUM_FIELDS
ACCEPTED_RANGES = [
    (0, float("inf")),
    (245.542471, float("inf")),
    (0, 5),
    (6, 55),
    (56, 290),
    (291, 1500),
    (0, 100),
    (101, 200),
    (201, 300),
    (301, 400),
    (401, 500),
    (501, 600),
    (601, 700),
    (701, 800),
    (801, 900),
    (901, 1000),
    (1001, 1100),
    (1101, 1200),
    (1201, 1300),
    (1301, 1400),
    (1401, float("inf")),
]


def _accepted_range_label(lower: float, upper: float) -> str:
    upper_label = "inf" if np.isinf(upper) else str(int(upper))
    lower_label = str(int(lower)) if float(lower).is_integer() else str(lower)
    return f"accepted{lower_label}-{upper_label}"


def _format_seconds(seconds: float) -> str:
    seconds = max(float(seconds), 0.0)
    minutes, sec = divmod(int(seconds), 60)
    hours, minutes = divmod(minutes, 60)
    if hours > 0:
        return f"{hours}h {minutes}m {sec}s"
    if minutes > 0:
        return f"{minutes}m {sec}s"
    return f"{sec}s"


def _progress_iter(items, label: str, report_every: int = 500):
    total = len(items)
    start = time.time()
    print(f"{label}: 0/{total}")
    for idx, item in enumerate(items, start=1):
        yield item
        if idx % report_every == 0 or idx == total:
            elapsed = time.time() - start
            rate = idx / elapsed if elapsed > 0 else 0
            remaining = (total - idx) / rate if rate > 0 else float("inf")
            pct = idx / total * 100 if total else 100
            eta_text = _format_seconds(remaining) if np.isfinite(remaining) else "unknown"
            print(f"{label}: {idx}/{total} ({pct:.1f}%), elapsed={_format_seconds(elapsed)}, eta={eta_text}")


def _to_datetime_naive(series: pd.Series) -> pd.Series:
    parsed = pd.to_datetime(series, errors="coerce")
    if getattr(parsed.dt, "tz", None) is not None:
        parsed = parsed.dt.tz_localize(None)
    return parsed


def _check_dependencies() -> None:
    for path in [
        QUESTION_INTERMEDIATE,
        HUMAN_ANSWER_INTERMEDIATE,
        HUMAN_ANSWER_CONTENT_METRICS,
        QUESTION_CONTENT_METRICS,
        USER_ACTIVITY_EXPERIENCE,
    ]:
        if not os.path.exists(path):
            raise FileNotFoundError(path)


def _load_base_tables() -> tuple[pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame, pd.DataFrame]:
    questions = pd.read_csv(QUESTION_INTERMEDIATE)
    answers = pd.read_csv(HUMAN_ANSWER_INTERMEDIATE)
    answer_content = pd.read_csv(HUMAN_ANSWER_CONTENT_METRICS)
    question_content = pd.read_csv(QUESTION_CONTENT_METRICS)
    experience = pd.read_csv(USER_ACTIVITY_EXPERIENCE)

    questions["date"] = _to_datetime_naive(questions["date"])
    answers["date"] = _to_datetime_naive(answers["date"])
    if "date" in experience.columns:
        experience["date"] = _to_datetime_naive(experience["date"])

    return questions, answers, answer_content, question_content, experience


def _require_columns(df: pd.DataFrame, required_columns: list[str], table_name: str) -> None:
    missing = [col for col in required_columns if col not in df.columns]
    if missing:
        raise ValueError(f"{table_name} missing required columns: {missing}")


def _rename_content_metrics(content: pd.DataFrame) -> pd.DataFrame:
    rename_map = {
        "textLength": "textLength",
        "textLengthCN": "textLengthCN",
        "codeLength": "codeLength",
        "imgNum": "imgNum",
        "brNum": "brNum",
        "codeNum": "codeNum",
        "inlinecodeNum": "inlinecodeNum",
        "interlinecodeNum": "interlinecodeNum",
        "hrefNum": "hrefNum",
        "aNum": "aNum",
        "boldNum": "boldNum",
        "italicNum": "italicNum",
        "ulNum": "ulNum",
        "olNum": "olNum",
        "liNum": "liNum",
        "blockquoteNum": "blockquoteNum",
        "hrNum": "hrNum",
        "tableNum": "tableNum",
    }
    _require_columns(content, list(rename_map.keys()), "human_answer_content_metrics")
    return content.rename(columns=rename_map)


def _prepare_question_level_table(questions: pd.DataFrame, question_content: pd.DataFrame) -> pd.DataFrame:
    required_question_content = [
        "questionURL",
        "question_codeLength",
        "question_textLength",
        "question_textLengthCN",
        "question_brNum",
        "question_codeNum",
        "question_interlinecodeNum",
        "question_aNum",
        "question_hrefNum",
        "question_ulNum",
        "question_olNum",
    ]
    _require_columns(question_content, required_question_content, "question_content_metrics")
    question_content = question_content.drop_duplicates(subset=["questionURL"])
    return questions.merge(question_content, on="questionURL", how="left")


def _extract_experience_columns(experience: pd.DataFrame) -> pd.DataFrame:
    keep = ["questionURL", "cmnID"]
    for col in experience.columns:
        if col.startswith("user_activity_"):
            keep.append(col)
    exp = experience[keep].copy()
    exp = exp.rename(columns={col: col.replace("user_activity_", "") for col in exp.columns if col.startswith("user_activity_")})
    exp = exp.drop_duplicates(subset=["questionURL", "cmnID"])
    return exp


def _ensure_columns(df: pd.DataFrame, columns: list[str], fill_value=np.nan) -> pd.DataFrame:
    for col in columns:
        if col not in df.columns:
            df[col] = fill_value
    return df


def _prepare_answer_level_table(
    questions: pd.DataFrame,
    answers: pd.DataFrame,
    content: pd.DataFrame,
    experience: pd.DataFrame,
) -> pd.DataFrame:
    content = _rename_content_metrics(content)
    experience = _extract_experience_columns(experience)

    ask = questions[["questionURL", "date"]].rename(columns={"date": "askTime"})
    df = answers.merge(ask, on="questionURL", how="left")
    df = df.merge(content, on=["questionURL", "cmnID"], how="left")
    df = df.merge(experience, on=["questionURL", "cmnID"], how="left")
    df = _ensure_columns(df, ASK_SUM_FIELDS + FIRST_SECOND_ACCEPTED_FIELDS + AFTER_AND_SUM_FIELDS + GEEK_FIELDS)

    fill_zero = [col for col in COMMENT_FIELDS if col in df.columns]
    if fill_zero:
        df[fill_zero] = df[fill_zero].fillna(0)

    df["accepted"] = df["is_accepted_answer"].fillna(0).astype(int)
    df["answer"] = 1
    df["hiddenanswer"] = df.get("hiddenanswer", 0)
    df["waitTime"] = (df["date"] - df["askTime"]).dt.total_seconds() / 3600
    df = df.sort_values(["questionURL", "date", "cmnID"]).reset_index(drop=True)
    return df


def _is_holiday(date: pd.Timestamp) -> float:
    if pd.notnull(date) and isinstance(date, pd.Timestamp):
        return float(chinese_calendar.is_holiday(date))
    return np.nan


def _is_in_lieu(date: pd.Timestamp) -> float:
    if pd.notnull(date) and isinstance(date, pd.Timestamp):
        return float(chinese_calendar.is_in_lieu(date))
    return np.nan


def _generate_wait_metrics(group: pd.DataFrame) -> dict:
    result = {
        "wait1Resp_original": np.nan,
        "wait2Resp_original": np.nan,
        "wait3Resp_original": np.nan,
        "waitAccepted_original": np.nan,
        "cmnidAccepted_original": np.nan,
        "waitAvgAllResp_original": np.nan,
    }
    ordered = group.sort_values(["date", "cmnID"])
    answer_dates = ordered["date"].tolist()
    ask_time = ordered["askTime"].iloc[0]

    if len(answer_dates) > 0:
        result["wait1Resp_original"] = (answer_dates[0] - ask_time).total_seconds() / 3600
        result["waitAvgAllResp_original"] = np.mean([(dt - ask_time).total_seconds() / 3600 for dt in answer_dates])
    if len(answer_dates) > 1:
        result["wait2Resp_original"] = (answer_dates[1] - ask_time).total_seconds() / 3600
    if len(answer_dates) > 2:
        result["wait3Resp_original"] = (answer_dates[2] - ask_time).total_seconds() / 3600

    accepted_rows = ordered[ordered["accepted"] == 1]
    if not accepted_rows.empty:
        accepted_row = accepted_rows.iloc[0]
        result["waitAccepted_original"] = (accepted_row["date"] - ask_time).total_seconds() / 3600
        result["cmnidAccepted_original"] = accepted_row["cmnID"]

    return result


def _generate_time_fields(questions: pd.DataFrame) -> pd.DataFrame:
    out = questions[["questionURL", "date"]].copy()
    out["askTime_original"] = out["date"]
    out["askTime"] = out["date"].dt.date
    out["hourofday"] = out["date"].dt.hour
    out["dayofweek"] = out["date"].dt.dayofweek
    out["monthofyear"] = out["date"].dt.month
    out["isHoliday"] = out["date"].apply(_is_holiday)
    out["isLieu"] = out["date"].apply(_is_in_lieu)
    return out.drop(columns=["date"])


def _generate_geek_ask(question_row: pd.Series) -> dict:
    result = {"userURL_ask": question_row.get("userURL", np.nan)}
    question_field_map = {
        "imgNum": "question_imgNum",
        "inlinecodeNum": "question_inlinecodeNum",
        "interlinecodeNum": "question_interlinecodeNum",
        "boldNum": "question_boldNum",
        "italicNum": "question_italicNum",
        "liNum": "question_liNum",
        "aNum": "question_aNum",
        "blockquoteNum": "question_blockquoteNum",
        "hrNum": "question_hrNum",
        "tableNum": "question_tableNum",
    }
    good_count = 0
    for field in GEEK_FIELDS:
        value = pd.to_numeric(question_row.get(question_field_map[field], np.nan), errors="coerce")
        result[f"{field}_ask"] = value
        good_count += 1 if pd.notna(value) and value > 0 else 0
    result["geekAsk"] = good_count
    for field in PLACEBO_ASK_FIELDS:
        result[f"{field}_ask"] = pd.to_numeric(question_row.get(field, np.nan), errors="coerce")
    return result


def _generate_other_ask(question_row: pd.Series) -> dict:
    out = {}
    question_field_map = {
        "codeLength": "codeLength",
        "textLength": "textLength",
        "textLengthCN": "textLengthCN",
        "accept": "accept",
        "netlikeNum": "netlikeNum",
        "ulNum": "ulNum",
        "olNum": "olNum",
        "brNum": "brNum",
        "codeNum": "codeNum",
        "interlinecodeNum": "interlinecodeNum",
        "aNum": "aNum",
    }
    for field in ASK_SUM_FIELDS:
        source_field = question_field_map.get(field, field)
        out[f"{field}_ask"] = pd.to_numeric(question_row.get(source_field, np.nan), errors="coerce")
    return out


def _generate_positional_answer_metrics(group: pd.DataFrame, position: int, suffix: str) -> dict:
    result = {f"{field}_{suffix}": np.nan for field in FIRST_SECOND_ACCEPTED_FIELDS}
    result[f"good{1 if suffix == '1Resp' else 2 if suffix == '2Resp' else 1}Resp"] = np.nan
    if len(group) < position:
        return result

    row = group.iloc[position - 1]
    for field in FIRST_SECOND_ACCEPTED_FIELDS:
        result[f"{field}_{suffix}"] = pd.to_numeric(row.get(field, np.nan), errors="coerce")

    good_value = group.iloc[[position - 1]][[field for field in GEEK_FIELDS if field in group.columns]].gt(0).sum(axis=1).iloc[0]
    if suffix == "1Resp":
        result["good1Resp"] = good_value
    elif suffix == "2Resp":
        result["good2Resp"] = good_value
    return result


def _generate_after_resp(group: pd.DataFrame) -> dict:
    result = {f"{field}_gt1Resp": np.nan for field in AFTER_AND_SUM_FIELDS}
    result["bestgt1Resp"] = np.nan
    for threshold in LIKES_THRESHOLDS:
        result[f"{threshold}likeRespNum_gt1Resp"] = np.nan
    result["neglikeRespNum_gt1Resp"] = np.nan
    result["nolikeRespNum_gt1Resp"] = np.nan
    for threshold in MARKDOWN_THRESHOLDS:
        result[f"{threshold}mdRespNum_gt1Resp"] = np.nan

    if len(group) <= 1:
        return result

    df = group.iloc[1:].copy()
    sums = df[AFTER_AND_SUM_FIELDS].sum(numeric_only=True)
    result.update({f"{field}_gt1Resp": sums.get(field, np.nan) for field in AFTER_AND_SUM_FIELDS})
    markdown_score = df[[field for field in GEEK_FIELDS if field in df.columns]].gt(0).sum(axis=1)
    result["bestgt1Resp"] = markdown_score.max() if len(markdown_score) else np.nan
    for threshold in LIKES_THRESHOLDS:
        result[f"{threshold}likeRespNum_gt1Resp"] = (df["netlikeNum"] >= threshold).sum()
    for threshold in MARKDOWN_THRESHOLDS:
        result[f"{threshold}mdRespNum_gt1Resp"] = (markdown_score >= threshold).sum()
    result["neglikeRespNum_gt1Resp"] = (df["netlikeNum"] < 0).sum()
    result["nolikeRespNum_gt1Resp"] = (df["netlikeNum"] == 0).sum()
    return result


def _generate_sum_resp(group: pd.DataFrame, question_row: pd.Series) -> dict:
    result = {f"{field}_sumResp": np.nan for field in AFTER_AND_SUM_FIELDS}
    result["bestallResp"] = np.nan
    result["netlikeAvg_sumResp"] = np.nan
    result["rookieRespNum_sumResp"] = np.nan
    result["ageAvg_sumResp"] = np.nan
    for threshold in LIKES_THRESHOLDS:
        result[f"{threshold}likeRespNum_sumResp"] = np.nan
    result["neglikeRespNum_sumResp"] = np.nan
    result["nolikeRespNum_sumResp"] = np.nan
    for threshold in MARKDOWN_THRESHOLDS:
        result[f"{threshold}mdRespNum_sumResp"] = np.nan
    for lower, upper in ACCEPTED_RANGES:
        label = _accepted_range_label(lower, upper)
        result[f"{label}_sumResp"] = np.nan
        result[f"netlikeSum_{label}_sumResp"] = np.nan
        result[f"netlikeAvg_{label}_sumResp"] = np.nan

    sum_res_df = group.copy()
    ask_time = question_row["date"]
    ai_status = question_row.get("preAI", 0)
    base_time = ask_time + pd.Timedelta(minutes=5)

    if not sum_res_df.empty:
        sums = sum_res_df[AFTER_AND_SUM_FIELDS].sum(numeric_only=True)
        result.update({f"{field}_sumResp": sums.get(field, np.nan) for field in AFTER_AND_SUM_FIELDS})
        markdown_score = sum_res_df[[field for field in GEEK_FIELDS if field in sum_res_df.columns]].gt(0).sum(axis=1)
        result["bestallResp"] = markdown_score.max() if len(markdown_score) else np.nan
        result["netlikeAvg_sumResp"] = sum_res_df["netlikeNum"].mean()
        result["rookieRespNum_sumResp"] = (sum_res_df["age"] <= 30).sum() if "age" in sum_res_df.columns else np.nan
        result["ageAvg_sumResp"] = sum_res_df["age"].mean() if "age" in sum_res_df.columns else np.nan
        for threshold in LIKES_THRESHOLDS:
            result[f"{threshold}likeRespNum_sumResp"] = (sum_res_df["netlikeNum"] >= threshold).sum()
        for threshold in MARKDOWN_THRESHOLDS:
            result[f"{threshold}mdRespNum_sumResp"] = (markdown_score >= threshold).sum()
        result["neglikeRespNum_sumResp"] = (sum_res_df["netlikeNum"] < 0).sum()
        result["nolikeRespNum_sumResp"] = (sum_res_df["netlikeNum"] == 0).sum()

        for lower, upper in ACCEPTED_RANGES:
            label = _accepted_range_label(lower, upper)
            mask = sum_res_df["acceptedBefore"] >= lower
            if not np.isinf(upper):
                mask = mask & (sum_res_df["acceptedBefore"] <= upper)
            result[f"{label}_sumResp"] = mask.sum()
            selected = sum_res_df.loc[mask, "netlikeNum"]
            result[f"netlikeSum_{label}_sumResp"] = selected.sum()
            result[f"netlikeAvg_{label}_sumResp"] = selected.mean()

        result["netlike_betterThanAI_sumResp"] = sum_res_df.loc[sum_res_df["acceptedBefore"] >= 245.542471, "netlikeNum"].mean()
        result["netlike_accepted0-inf_sumResp"] = sum_res_df.loc[sum_res_df["acceptedBefore"] >= 0, "netlikeNum"].mean()
        result["netlike_accepted0-100_sumResp"] = sum_res_df.loc[(sum_res_df["acceptedBefore"] >= 0) & (sum_res_df["acceptedBefore"] <= 100), "netlikeNum"].mean()

    for days in TIME_WINDOWS_ALL:
        within = sum_res_df[(sum_res_df["date"] > ask_time) & (sum_res_df["date"] <= ask_time + pd.Timedelta(days=days))]
        result[f"answer_que_within{days}day"] = int(within["answer"].sum()) if not within.empty else 0
        result[f"log_answer_que_within{days}day"] = np.log1p(result[f"answer_que_within{days}day"] + 1)

    result["deltaPostLastansAvg"] = np.nan
    result["delta1AnsLastansAvg"] = np.nan
    result["delta24Avg_within1day"] = np.nan
    result["deltawaitMedian"] = np.nan
    result["deltawaitMean"] = np.nan
    result["deltawaitMedian_after1Ans"] = np.nan
    result["deltawaitMean_after1Ans"] = np.nan
    result["TEST_delta"] = np.nan

    answer_num = len(sum_res_df) + (1 if ai_status == 1 else 0)
    if answer_num >= 1:
        if ai_status == 1 and len(sum_res_df) == 0:
            last_resp_time = base_time
        else:
            last_resp_time = sum_res_df["date"].max()
        result["deltaPostLastansAvg"] = (last_resp_time - ask_time).total_seconds() / 3600 / answer_num

        resp_date_list = sum_res_df["date"].tolist()
        ans_date_list = resp_date_list + ([base_time] if ai_status == 1 else [])
        ans_date_list.sort()
        ans_deltawait_list = [
            (ans_date_list[i] - (ask_time if i == 0 else ans_date_list[i - 1])).total_seconds() / 3600
            for i in range(len(ans_date_list))
        ]
        result["deltawaitMedian"] = np.median(ans_deltawait_list)
        result["deltawaitMean"] = np.mean(ans_deltawait_list)

    if answer_num >= 2:
        first_ans_time = ans_date_list[0]
        delta_time_after1ans = (last_resp_time - first_ans_time).total_seconds() / 3600
        result["delta1AnsLastansAvg"] = delta_time_after1ans / (answer_num - 1)
        ans_deltawait_after1 = ans_deltawait_list[1:]
        result["deltawaitMedian_after1Ans"] = np.median(ans_deltawait_after1)
        result["deltawaitMean_after1Ans"] = np.mean(ans_deltawait_after1)
        result["TEST_delta"] = result["delta1AnsLastansAvg"] - result["deltawaitMean_after1Ans"]

    answer_num_within_days = {}
    for days in TIME_WINDOWS_DELTA:
        answer_num_within_days[days] = result[f"answer_que_within{days}day"] + (1 if ai_status == 1 else 0)

    if answer_num_within_days[1] != 0:
        result["delta24Avg_within1day"] = 24 / answer_num_within_days[1]

    if answer_num >= 2:
        for days in TIME_WINDOWS_DELTA:
            result[f"deltaPostLastansAvg_within{days}day"] = np.nan
            result[f"delta1AnsLastansAvg_within{days}day"] = np.nan
            answer_num_within_day = answer_num_within_days[days]
            if answer_num_within_day != 0:
                within = sum_res_df[(sum_res_df["date"] > ask_time) & (sum_res_df["date"] <= ask_time + pd.Timedelta(days=days))]
                if within.empty and ai_status != 1:
                    continue
                last_resp_in_day_time = within["date"].max() if not within.empty else base_time
                delta_post_lastans_day = (last_resp_in_day_time - ask_time).total_seconds() / 3600
                result[f"deltaPostLastansAvg_within{days}day"] = delta_post_lastans_day / answer_num_within_day
                if (answer_num_within_day - 1) != 0:
                    delta_adjusted = (last_resp_in_day_time - first_ans_time).total_seconds() / 3600
                    result[f"delta1AnsLastansAvg_within{days}day"] = delta_adjusted / (answer_num_within_day - 1)

    return result


def _generate_accepted_resp(group: pd.DataFrame) -> dict:
    result = {f"{field}_acceptedResp": np.nan for field in FIRST_SECOND_ACCEPTED_FIELDS}
    result["goodacceptedResp"] = np.nan
    accepted_rows = group[group["accepted"] == 1]
    if len(accepted_rows) != 1:
        return result

    row = accepted_rows.iloc[0]
    for field in FIRST_SECOND_ACCEPTED_FIELDS:
        result[f"{field}_acceptedResp"] = pd.to_numeric(row.get(field, np.nan), errors="coerce")
    markdown_score = accepted_rows[[field for field in GEEK_FIELDS if field in accepted_rows.columns]].gt(0).sum(axis=1).iloc[0]
    result["goodacceptedResp"] = markdown_score
    return result


def _build_question_level_core(question_rows: pd.DataFrame, answers_augmented: pd.DataFrame) -> pd.DataFrame:
    question_results = []
    questions_indexed = question_rows.set_index("questionURL", drop=False)
    grouped_items = list(answers_augmented.groupby("questionURL", sort=False))
    for question_url, answer_group in _progress_iter(grouped_items, "Core aggregation", report_every=500):
        question_row = questions_indexed.loc[question_url]
        answer_group = answer_group.sort_values(["date", "cmnID"]).reset_index(drop=True)
        result = {"questionURL": question_url}
        result.update(_generate_wait_metrics(answer_group))
        result.update(_generate_geek_ask(question_row))
        result.update(_generate_other_ask(question_row))
        result.update(_generate_positional_answer_metrics(answer_group, 1, "1Resp"))
        result.update(_generate_positional_answer_metrics(answer_group, 2, "2Resp"))
        result.update(_generate_after_resp(answer_group))
        result.update(_generate_sum_resp(answer_group, question_row))
        result.update(_generate_accepted_resp(answer_group))
        question_results.append(result)
    return pd.DataFrame(question_results)


def _build_question_que_sums(questions: pd.DataFrame, answers_augmented: pd.DataFrame) -> pd.DataFrame:
    sum_fields = ["hiddenanswer", "answer", "accepted", "views", "focusNum", "collectNum"]
    question_rows = questions[["questionURL", "views", "focusNum", "collectNum"]].copy()
    question_rows["hiddenanswer"] = 0
    question_rows["answer"] = 0
    question_rows["accepted"] = 0
    answer_rows = answers_augmented[["questionURL", "hiddenanswer", "answer", "accepted"]].copy()
    answer_rows["views"] = 0
    answer_rows["focusNum"] = 0
    answer_rows["collectNum"] = 0
    cmn2question = pd.concat([question_rows[["questionURL"] + sum_fields], answer_rows[["questionURL"] + sum_fields]], ignore_index=True)
    sums = cmn2question.groupby("questionURL")[sum_fields].sum().add_suffix("_que")
    return sums.reset_index()


def _build_tag_level_context(questions: pd.DataFrame, answers_augmented: pd.DataFrame) -> pd.DataFrame:
    ask = questions[["questionURL", "date", "tagURL"]].copy()
    ask["cmnTime"] = ask["date"].dt.normalize()

    answer_counts = answers_augmented.groupby("questionURL").apply(
        lambda group: pd.Series({"answerNum_within7day": (group["date"] <= group["askTime"].iloc[0] + pd.Timedelta(days=7)).sum()})
    ).reset_index()

    full = ask.merge(answer_counts, on="questionURL", how="left")
    full["answerNum_within7day"] = full["answerNum_within7day"].fillna(0)

    rows = []
    full_records = list(full.to_dict("records"))
    for row in _progress_iter(full_records, "Tag context", report_every=500):
        end_date = row["cmnTime"]
        tag = row["tagURL"]
        result = {"questionURL": row["questionURL"]}
        for days in [30, 7, 1]:
            mask = (
                (full["cmnTime"] < end_date)
                & (full["cmnTime"] >= end_date - pd.Timedelta(days=days))
                & (full["tagURL"] == tag)
            )
            ask_sum = mask.sum()
            answer_sum = full.loc[mask, "answerNum_within7day"].sum()
            result[f"answerNum_sameTag_b{days}"] = answer_sum
            result[f"askNum_sameTag_b{days}"] = ask_sum
            result[f"avgAnswerNum_sameTag_b{days}"] = answer_sum / ask_sum if ask_sum != 0 else 0

        recent_mask = (
            (full["cmnTime"] < end_date)
            & (full["cmnTime"] >= end_date - pd.Timedelta(days=7))
            & (full["tagURL"] == tag)
        )
        filtered = full.loc[recent_mask, "answerNum_within7day"]
        for i in range(15):
            result[f"n{i}"] = (filtered == i).sum()
        rows.append(result)
    return pd.DataFrame(rows)


def build() -> pd.DataFrame:
    print("=" * 80)
    print("Building question_aggregation_from_answers feature")
    print("=" * 80)

    _check_dependencies()
    questions, answers, answer_content, question_content, experience = _load_base_tables()
    question_rows = _prepare_question_level_table(questions.copy(), question_content)
    answers_augmented = _prepare_answer_level_table(question_rows, answers, answer_content, experience)

    print(f"Questions: {len(question_rows):,}")
    print(f"Answers: {len(answers_augmented):,}")

    core = _build_question_level_core(question_rows, answers_augmented)
    time_fields = _generate_time_fields(question_rows)
    que_sums = _build_question_que_sums(question_rows, answers_augmented)
    tag_context = _build_tag_level_context(question_rows, answers_augmented)

    result = question_rows[["questionURL"]].merge(time_fields, on="questionURL", how="left")
    result = result.merge(que_sums, on="questionURL", how="left")
    result = result.merge(core, on="questionURL", how="left")
    result = result.merge(tag_context, on="questionURL", how="left")

    result.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"Saved {len(result):,} rows × {len(result.columns)} columns to {OUTPUT_CSV}")
    return result

    _check_dependencies()
    questions, answers, answer_content, question_content, experience = _load_base_tables()
    question_rows = _prepare_question_level_table(questions.copy(), question_content)
    answers_augmented = _prepare_answer_level_table(question_rows, answers, answer_content, experience)

    print(f"Questions: {len(question_rows):,}")
    print(f"Answers: {len(answers_augmented):,}")

    core = _build_question_level_core(question_rows, answers_augmented)
    time_fields = _generate_time_fields(question_rows)
    que_sums = _build_question_que_sums(question_rows, answers_augmented)
    tag_context = _build_tag_level_context(question_rows, answers_augmented)

    result = question_rows[["questionURL"]].merge(time_fields, on="questionURL", how="left")
    result = result.merge(que_sums, on="questionURL", how="left")
    result = result.merge(core, on="questionURL", how="left")
    result = result.merge(tag_context, on="questionURL", how="left")

    result.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"Saved {len(result):,} rows × {len(result.columns)} columns to {OUTPUT_CSV}")
    return result


if __name__ == "__main__":
    build()
