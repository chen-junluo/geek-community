# Artifact:  panel/question_panel_MISQ
# 输入:      data/features/question_intermediate_MISQ.csv
#            data/features/question_accepted_answer_similarity_MISQ.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/panels/question_panel_MISQ.csv
#
# 职责：读取 MISQ question intermediate，在 MISQ universe 内 late merge feature，输出 MISQ final panel。

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
    intermediate = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    print(f"question_intermediate_MISQ(base): {intermediate.shape}")

    feat_accept_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["question_accepted_answer_similarity_misq"])
    accept_cols = [
        "questionURL",
        "has_ai_answer",
        "has_accepted_answer",
        "n_accepted_answers",
        "anchor_selection_rule",
        "accepted_resp_id",
        "accepted_resp_ids",
        "AISimWithAccept",
    ]
    accept_cols = [c for c in accept_cols if c in feat_accept_similarity.columns]
    feat_accept_similarity = feat_accept_similarity[accept_cols].copy()

    feat_ai_human_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["question_ai_human_similarity"])
    ai_human_cols = [
        "questionURL",
        "group_type",
        "n_human_answers",
        "human1_human2_similarity",
        "ai_human1_similarity",
        "ai_human2_similarity",
    ]
    ai_human_cols = [c for c in ai_human_cols if c in feat_ai_human_similarity.columns]
    feat_ai_human_similarity = feat_ai_human_similarity[ai_human_cols].copy()

    feat_ai_human_code_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["question_ai_human_code_similarity"])
    ai_human_code_cols = [
        "questionURL",
        "human1_human2_code_similarity",
        "ai_human1_code_similarity",
        "ai_human2_code_similarity",
    ]
    ai_human_code_cols = [c for c in ai_human_code_cols if c in feat_ai_human_code_similarity.columns]
    feat_ai_human_code_similarity = feat_ai_human_code_similarity[ai_human_code_cols].copy()

    feat_jaccard = pd.read_csv(ARTIFACT_PATHS["features"]["question_content_jaccard_overlap"])
    jaccard_cols = [
        "questionURL",
        "jaccard_h1_h2",
        "jaccard_ai_h2",
        "jaccard_ans1_ans2",
        "jaccard_h1_h2_code",
        "jaccard_ai_h2_code",
        "jaccard_ans1_ans2_code",
    ]
    jaccard_cols = [c for c in jaccard_cols if c in feat_jaccard.columns]
    feat_jaccard = feat_jaccard[jaccard_cols].copy()

    feat_pairwise = pd.read_csv(ARTIFACT_PATHS["features"]["question_human_pairwise_similarity"])
    pairwise_cols = [
        "questionURL",
        "n_human_answers_used",
        "human_pairwise_similarity_mean",
    ]
    pairwise_cols = [c for c in pairwise_cols if c in feat_pairwise.columns]
    feat_pairwise = feat_pairwise[pairwise_cols].copy()

    panel = _late_merge_prefer_feature(intermediate, feat_accept_similarity, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_ai_human_similarity, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_ai_human_code_similarity, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_jaccard, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_pairwise, ["questionURL"])

    out_path = ARTIFACT_PATHS["panels"]["question_misq"]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    panel.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"question_panel_MISQ 已保存: {out_path}  shape={panel.shape}")
    return panel


if __name__ == "__main__":
    build()
