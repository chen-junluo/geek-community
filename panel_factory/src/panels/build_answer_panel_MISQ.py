# Artifact:    panel/answer_panel_MISQ
# Grain:       human_answer
# Merge Keys:  questionURL, resp_id
#
# Inputs:
#   - human_answer_intermediate_MISQ.csv
#   - human_answer_accepted_answer_similarity_MISQ.csv
#   - human_answer_accepted_answer_anchor_flag_MISQ.csv
#   - human_answer_llm_extension.csv
#   - human_answer_llm_deviation.csv
#   - human_answer_lexicon_based_answer_metrics.csv
#   - human_answer_aigc_quality.csv
#
# Output:      data/panels/answer_panel_MISQ.csv
#   - Index: questionURL, resp_id
#   - Core: (all columns from human_answer_intermediate_MISQ + merged features)
#   - Derived: —
#
# Logic:
#   - 读取 MISQ human-answer intermediate
#   - 在 MISQ universe 内 late merge answer-level features
#   - 对 `cmnID`-grain feature 使用 `questionURL, cmnID` merge
#   - 对 LLM metadata 列做 collision-safe rename，避免同名字段冲突
#   - 输出 MISQ final panel

import os
import pandas as pd

from utils.paths import ARTIFACT_PATHS


def _late_merge_prefer_feature(
    panel: pd.DataFrame,
    feature: pd.DataFrame,
    merge_keys: list[str],
) -> pd.DataFrame:
    overlap_cols = [
        col for col in feature.columns
        if col not in merge_keys and col in panel.columns
    ]
    if overlap_cols:
        feature = feature.drop(columns=overlap_cols)
    return panel.merge(feature, on=merge_keys, how="left")


def build() -> pd.DataFrame:
    intermediate = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    print(f"human_answer_intermediate_MISQ(base): {intermediate.shape}")

    feat_accept_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["answer_accepted_answer_similarity_misq"])
    accept_cols = [
        "questionURL",
        "resp_id",
        "n_accepted_answers",
        "anchor_selection_rule",
        "accepted_resp_id",
        "accepted_resp_ids",
        "SimWithAccept",
    ]
    accept_cols = [c for c in accept_cols if c in feat_accept_similarity.columns]
    feat_accept_similarity = feat_accept_similarity[accept_cols].copy()

    feat_accept_anchor_flag = pd.read_csv(ARTIFACT_PATHS["features"]["human_answer_accepted_answer_anchor_flag_misq"])
    anchor_flag_cols = ["questionURL", "resp_id", "is_accept_similarity_anchor"]
    anchor_flag_cols = [c for c in anchor_flag_cols if c in feat_accept_anchor_flag.columns]
    feat_accept_anchor_flag = feat_accept_anchor_flag[anchor_flag_cols].copy()

    feat_llm_extension = pd.read_csv(ARTIFACT_PATHS["features"]["answer_llm_extension"])
    llm_extension_cols = [
        "questionURL",
        "resp_id",
        "preAI",
        "anchor_source",
        "anchor_resp_id",
        "anchor_cmnID",
        "anchor_dateID",
        "comparison_target",
        "extension_score",
        "justification",
        "relationship_label",
        "prompt_version",
        "model_name",
        "error_reason",
    ]
    llm_extension_cols = [c for c in llm_extension_cols if c in feat_llm_extension.columns]
    feat_llm_extension = feat_llm_extension[llm_extension_cols].copy()
    feat_llm_extension = feat_llm_extension.rename(columns={
        "justification": "extension_justification",
        "relationship_label": "extension_relationship_label",
        "prompt_version": "extension_prompt_version",
        "model_name": "extension_model_name",
        "error_reason": "extension_error_reason",
    })

    feat_llm_deviation = pd.read_csv(ARTIFACT_PATHS["features"]["answer_llm_deviation"])
    llm_deviation_cols = [
        "questionURL",
        "resp_id",
        "preAI",
        "deviation_score",
        "justification",
        "relationship_label",
        "prompt_version",
        "model_name",
        "error_reason",
    ]
    llm_deviation_cols = [c for c in llm_deviation_cols if c in feat_llm_deviation.columns]
    feat_llm_deviation = feat_llm_deviation[llm_deviation_cols].copy()
    feat_llm_deviation = feat_llm_deviation.rename(columns={
        "justification": "deviation_justification",
        "relationship_label": "deviation_relationship_label",
        "prompt_version": "deviation_prompt_version",
        "model_name": "deviation_model_name",
        "error_reason": "deviation_error_reason",
    })

    feat_lexicon = pd.read_csv(ARTIFACT_PATHS["features"]["answer_lexicon_based_answer_metrics"])
    lexicon_cols = [
        "questionURL",
        "resp_id",
        "lexicon_personal_experience_binary",
        "lexicon_personal_experience_match_count",
        "lexicon_personal_experience_method",
        "lexicon_personal_experience_version",
        "lexicon_personal_experience_error_reason",
    ]
    lexicon_cols = [c for c in lexicon_cols if c in feat_lexicon.columns]
    feat_lexicon = feat_lexicon[lexicon_cols].copy()

    feat_human_aigc_quality = pd.read_csv(ARTIFACT_PATHS["features"]["human_answer_aigc_quality"])

    panel = _late_merge_prefer_feature(intermediate, feat_accept_similarity, ["questionURL", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_accept_anchor_flag, ["questionURL", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_llm_extension, ["questionURL", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_llm_deviation, ["questionURL", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_lexicon, ["questionURL", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_human_aigc_quality, ["questionURL", "cmnID"])
    if "preAI" in panel.columns:
        panel["preAI"] = panel["preAI"].fillna(0).astype(int)

    out_path = ARTIFACT_PATHS["panels"]["answer_misq"]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    panel.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"answer_panel_MISQ 已保存: {out_path}  shape={panel.shape}")
    return panel


if __name__ == "__main__":
    build()
