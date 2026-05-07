# Artifact:  panel/answer_panel_MISQ
# 输入:      data/features/human_answer_intermediate_MISQ.csv
#            data/features/answer_accepted_answer_similarity_MISQ.csv
# Grain:     human-answer-level (question_id × resp_id)
# Merge keys: question_id, resp_id
# 输出:      data/panels/answer_panel_MISQ.csv
#
# 职责：读取 MISQ human-answer intermediate，在 MISQ universe 内 late merge feature，输出 MISQ final panel。

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
        panel = panel.drop(columns=overlap_cols)
    return panel.merge(feature, on=merge_keys, how="left")


def build() -> pd.DataFrame:
    intermediate = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    print(f"human_answer_intermediate_MISQ(base): {intermediate.shape}")

    feat_accept_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["answer_accepted_answer_similarity_misq"])
    accept_cols = [
        "question_id",
        "resp_id",
        "n_accepted_answers",
        "anchor_selection_rule",
        "accepted_resp_id",
        "accepted_resp_ids",
        "SimWithAccept",
    ]
    accept_cols = [c for c in accept_cols if c in feat_accept_similarity.columns]
    feat_accept_similarity = feat_accept_similarity[accept_cols].copy()

    feat_llm_extension = pd.read_csv(ARTIFACT_PATHS["features"]["answer_llm_extension"])
    llm_extension_cols = [
        "question_id",
        "resp_id",
        "is_treatment",
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
        "question_id",
        "resp_id",
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
        "question_id",
        "resp_id",
        "lexicon_personal_experience_binary",
        "lexicon_personal_experience_match_count",
        "lexicon_personal_experience_method",
        "lexicon_personal_experience_version",
        "lexicon_personal_experience_error_reason",
    ]
    lexicon_cols = [c for c in lexicon_cols if c in feat_lexicon.columns]
    feat_lexicon = feat_lexicon[lexicon_cols].copy()

    panel = _late_merge_prefer_feature(intermediate, feat_accept_similarity, ["question_id", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_llm_extension, ["question_id", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_llm_deviation, ["question_id", "resp_id"])
    panel = _late_merge_prefer_feature(panel, feat_lexicon, ["question_id", "resp_id"])

    out_path = ARTIFACT_PATHS["panels"]["answer_misq"]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    panel.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"answer_panel_MISQ 已保存: {out_path}  shape={panel.shape}")
    return panel


if __name__ == "__main__":
    build()
