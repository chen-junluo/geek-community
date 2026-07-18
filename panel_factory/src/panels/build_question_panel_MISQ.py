# Artifact:    panel/question_panel_MISQ
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv
#   - question_content_metrics.csv
#   - question_aigc_quality.csv
#   - question_ai_human_similarity.csv
#   - question_ai_human_code_similarity.csv
#   - question_content_jaccard_overlap.csv
#   - question_human_pairwise_similarity.csv
#   - question_human1_accepted_answer_similarity_MISQ.csv
#   - question_llm_ground_truth_similarity_MISQ.csv
#   - question_human1_llm_ground_truth_similarity_MISQ.csv
#   - question_human2_llm_ground_truth_similarity_MISQ.csv
#   - question_aggregation_from_answers.csv
#   - user_activity_experience.csv
#
# Output:      data/panels/question_panel_MISQ.csv
#   - Index: questionURL
#   - Core: (all columns from question_intermediate_MISQ + merged features)
#   - Derived: user activity experience columns merged by `questionURL × userURL_ask`; archived answer-aligned `*Ans` variables derived after all feature merges
#
# Logic:
#   - 读取 question_intermediate_MISQ 作为 base
#   - Late merge 所有 question-level features，包括新增的 `human1` similarity features
#   - 基于 `questionURL × userURL_ask` merge question asker 的 `user_activity_experience`（仅 `cmnID == 0`）
#   - 对 overlap 列优先保留 feature 版本，但 `title`、`preAI` 等 canonical base columns 保留 intermediate 版本
#   - 在全部 feature merge 完成后，按 archived contract 生成 answer-aligned derived variables

import os
from typing import Optional

import numpy as np
import pandas as pd

from utils.paths import ARTIFACT_PATHS

OUTPUT_CSV = ARTIFACT_PATHS["panels"]["question_misq"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

CANONICAL_BASE_COLUMNS = {
    "title",
    "preAI",
}

COMMENT_FIELDS = [
    "nComment", "nCommentAsker", "nCommentResponder", "nCommentOthers",
    "nAt", "nAtAsker", "nAtResponder", "nAtOthers", "nFollowup", "nAddKnow",
]
ANSWER_SUM_FIELDS = [
    "codeLength", "textLength", "textLengthCN", "accepted", "netlikeNum",
    "hiddenanswer", "answer", "interlinecodeNum", "aNum",
]
EXPERT_SUM_FIELDS = [
    "masterTop5pct", "masterTop10pct", "masterTop15pct", "masterTop20pct",
    "seniorTop5pct", "seniorTop10pct", "seniorTop15pct", "seniorTop20pct",
    "looseTop5pct", "looseTop10pct", "looseTop15pct", "looseTop20pct",
    "strictTop5pct", "strictTop10pct", "strictTop15pct", "strictTop20pct",
    "preferdiscussTop5pct", "preferdiscussTop10pct", "preferdiscussTop15pct", "preferdiscussTop20pct",
]
EXPERIENCE_SINGLE_FIELDS = [
    "askBefore", "resBefore", "acceptedBefore", "acceptBefore", "commentBefore",
    "netlikeBefore", "badgeBefore", "ratioAcceptAsk", "ratioCommentBadge",
]
VARS_FIELDS = COMMENT_FIELDS + ANSWER_SUM_FIELDS + EXPERT_SUM_FIELDS + EXPERIENCE_SINGLE_FIELDS


def _late_merge_prefer_feature(
    panel: pd.DataFrame,
    feature: pd.DataFrame,
    merge_keys: list[str],
) -> pd.DataFrame:
    overlap_cols = [
        col for col in feature.columns
        if col not in merge_keys and col in panel.columns and col not in CANONICAL_BASE_COLUMNS
    ]
    feature_cols_to_drop = [
        col for col in feature.columns
        if col not in merge_keys and col in CANONICAL_BASE_COLUMNS
    ]
    if overlap_cols: # 以panel为准，丢弃feature中的overlap_cols
        feature = feature.drop(columns=overlap_cols)
    if feature_cols_to_drop:
        feature = feature.drop(columns=feature_cols_to_drop)
    return panel.merge(feature, on=merge_keys, how="left")


def _load_feature(feature_key: str) -> Optional[pd.DataFrame]:
    fpath = ARTIFACT_PATHS["features"].get(feature_key)
    if not fpath or not os.path.exists(fpath):
        print(f"Warning: {feature_key} not found, skipping")
        return None
    print(f"Merging {feature_key}...")
    return pd.read_csv(fpath)


def _merge_question_asker_experience(panel: pd.DataFrame) -> pd.DataFrame:
    experience = _load_feature("user_activity_experience")
    if experience is None:
        return panel

    if "userURL" not in panel.columns:
        print("Warning: base panel missing userURL, skipping user activity experience merge")
        return panel

    panel = panel.drop(columns=["userURL_ask"], errors="ignore")

    experience = experience.loc[experience["cmnID"] == 0].copy()
    experience = experience.rename(columns={"userURL": "userURL_ask"})
    experience = experience.drop(columns=["cmnID", "title"], errors="ignore")

    panel = panel.rename(columns={"userURL": "userURL_ask"})
    panel = panel.merge(
        experience,
        on=["questionURL", "userURL_ask"],
        how="left",
        suffixes=["", "_right"],
    )
    return panel


def _ensure_column(panel: pd.DataFrame, target: str, source: str) -> pd.DataFrame:
    if target not in panel.columns and source in panel.columns:
        panel[target] = panel[source]
    return panel


def _add_archived_answer_aligned_variables(panel: pd.DataFrame) -> pd.DataFrame:
    panel = panel.copy()

    panel = _ensure_column(panel, "preAI-codeLength", "question_preAI_codeLength")
    panel = _ensure_column(panel, "preAI-textLengthCN", "question_preAI_textLengthCN")
    panel = _ensure_column(panel, "preAI-textLength", "question_preAI_textLength")

    five_minutes = pd.Timedelta(minutes=5)
    hours = float(five_minutes.total_seconds() / 3600)

    for field in VARS_FIELDS:
        first_col = f"{field}_1Resp"
        second_col = f"{field}_2Resp"
        if first_col in panel.columns and second_col in panel.columns:
            panel[f"{field}_2Ans"] = panel[first_col].where(panel["preAI"] == 1, panel[second_col])

    panel["wait1Ans_original"] = panel["wait1Resp_original"].where(panel["preAI"] != 1, hours)
    panel["wait2Ans_original"] = panel["wait1Resp_original"].where(panel["preAI"] == 1, panel["wait2Resp_original"])
    panel["wait3Ans_original"] = panel["wait2Resp_original"].where(panel["preAI"] == 1, panel["wait3Resp_original"])

    panel["wait1Resp"] = panel["wait1Resp_original"]
    panel["wait2Resp"] = panel["wait2Resp_original"]
    panel["wait3Resp"] = panel["wait3Resp_original"]

    panel["wait1Ans"] = panel["wait1Resp"].where(panel["preAI"] != 1, hours)
    panel["wait2Ans"] = panel["wait1Resp"].where(panel["preAI"] == 1, panel["wait2Resp"])
    panel["wait3Ans"] = panel["wait2Resp"].where(panel["preAI"] == 1, panel["wait3Resp"])
    panel["deltawait2Ans_original"] = panel["wait1Resp_original"].where(panel["preAI"] == 1, panel["wait2Resp_original"] - panel["wait1Resp_original"])
    panel["deltawait3Ans_original"] = panel["wait2Resp_original"].where(panel["preAI"] == 1, panel["wait3Resp_original"] - panel["wait2Resp_original"])
    panel["deltawait2Ans"] = panel["wait1Resp"].where(panel["preAI"] == 1, panel["wait2Resp"] - panel["wait1Resp"])
    panel["deltawait3Ans"] = panel["wait2Resp"].where(panel["preAI"] == 1, panel["wait3Resp"] - panel["wait2Resp"])

    panel["deltawait2Resp_original"] = panel["wait2Resp_original"] - panel["wait1Resp_original"]
    panel["deltawait3Resp_original"] = panel["wait3Resp_original"] - panel["wait2Resp_original"]

    panel["acceptedBefore1Ans"] = panel["acceptedBefore_1Resp"].where(panel["preAI"] != 1, np.nan)
    panel["acceptedBefore2Ans"] = panel["acceptedBefore_2Resp"].where(panel["preAI"] != 1, panel["acceptedBefore_1Resp"])

    panel["accepted1Ans"] = panel["accepted_1Resp"].where(panel["preAI"] != 1, 0)
    panel["accepted1Ans"] = panel["accepted1Ans"].fillna(0)
    panel["accepted2Ans"] = panel["accepted_2Resp"].where(panel["preAI"] != 1, panel["accepted_1Resp"])
    panel["accepted2Ans"] = panel["accepted2Ans"].fillna(0)

    panel["badgeBefore1Ans"] = panel["badgeBefore_1Resp"].where(panel["preAI"] != 1, np.nan)
    panel["badgeBefore2Ans"] = panel["badgeBefore_2Resp"].where(panel["preAI"] != 1, panel["badgeBefore_1Resp"])
    panel["accumGold1Ans"] = panel["accumGold_1Resp"].where(panel["preAI"] != 1, np.nan)
    panel["accumSilver1Ans"] = panel["accumSilver_1Resp"].where(panel["preAI"] != 1, np.nan)
    panel["accumCopper1Ans"] = panel["accumCopper_1Resp"].where(panel["preAI"] != 1, np.nan)

    panel["codeLength1Ans"] = panel["codeLength_1Resp"].where(panel["preAI"] != 1, panel["preAI-codeLength"])
    panel["textLengthCN1Ans"] = panel["textLengthCN_1Resp"].where(panel["preAI"] != 1, panel["preAI-textLengthCN"])
    panel["textLength1Ans"] = panel["textLength_1Resp"].where(panel["preAI"] != 1, panel["preAI-textLength"])

    panel["netlikeNum_gt1Ans"] = panel["netlikeNum_gt1Resp"].where(panel["preAI"] != 1, panel["netlikeNum_sumResp"])
    panel["accepted_gt1Ans"] = panel["accepted_gt1Resp"].where(panel["preAI"] != 1, panel["accepted_sumResp"])
    panel["nolikeRespNum_gt1Ans"] = panel["nolikeRespNum_gt1Resp"].where(panel["preAI"] != 1, panel["nolikeRespNum_sumResp"])
    panel["1likeRespNum_gt1Ans"] = panel["1likeRespNum_gt1Resp"].where(panel["preAI"] != 1, panel["1likeRespNum_sumResp"])

    return panel


def build():
    print("Loading base...")
    base = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    print(f"Base: {base.shape}")

    feature_keys = [
        "question_content_metrics",
        "question_aigc_quality",
        "question_ai_human_similarity",
        "question_ai_human_code_similarity",
        "question_content_jaccard_overlap",
        "question_human_pairwise_similarity",
        "question_accepted_answer_similarity_misq",
        "question_human1_accepted_answer_similarity_misq",
        "question_llm_ground_truth_similarity_misq",
        "question_human1_llm_ground_truth_similarity_misq",
        "question_human2_llm_ground_truth_similarity_misq",
        "question_aggregation_from_answers",
    ]

    for key in feature_keys:
        feat = _load_feature(key)
        if feat is None:
            continue
        base = _late_merge_prefer_feature(base, feat, ["questionURL"])
        print(f"  Shape: {base.shape}")

    base = _merge_question_asker_experience(base)
    print(f"After merging user_activity_experience: {base.shape}")

    base = _add_archived_answer_aligned_variables(base)
    print(f"After deriving archived answer-aligned variables: {base.shape}")

    base.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"Saved: {OUTPUT_CSV}")
    print(f"Shape: {base.shape}")
    return base


if __name__ == "__main__":
    build()
