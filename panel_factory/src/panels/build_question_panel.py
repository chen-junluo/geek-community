# Artifact:  panel/question_panel
# 输入:      data/features/question_intermediate.csv
#            data/features/question_ai_human_code_similarity.csv
#            data/features/question_human_pairwise_similarity.csv
#            data/features/question_content_jaccard_overlap.csv
#            data/features/question_accepted_answer_similarity.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/panels/question_panel.csv
#
# 职责：读取 question-level base intermediate，然后在保留 base 全部变量的前提下，late merge 其他 question-level features，输出 final question panel。
# 不在本文件里重新生成任何 feature。

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
    # ── 1. 读取 base intermediate ───────────────────────────────────────────────
    intermediate = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])
    print(f"question_intermediate(base): {intermediate.shape}")

    # ── 2. 读取 late-merge features ────────────────────────────────────────────
    feat_code_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["question_ai_human_code_similarity"])
    code_sim_cols = [
        "questionURL",
        "preAI",
        "human1_human2_code_similarity",
        "ai_human1_code_similarity",
        "ai_human2_code_similarity",
    ]
    code_sim_cols = [c for c in code_sim_cols if c in feat_code_similarity.columns]
    feat_code_similarity = feat_code_similarity[code_sim_cols].copy()

    feat_pairwise = pd.read_csv(ARTIFACT_PATHS["features"]["question_human_pairwise_similarity"])
    pairwise_cols = ["questionURL", "n_human_answers_used", "human_pairwise_similarity_mean"]
    pairwise_cols = [c for c in pairwise_cols if c in feat_pairwise.columns]
    feat_pairwise = feat_pairwise[pairwise_cols].copy()

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

    feat_accept_similarity = pd.read_csv(ARTIFACT_PATHS["features"]["question_accepted_answer_similarity"])
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

    # ── 3. Late merge ─────────────────────────────────────────────────────────
    panel = _late_merge_prefer_feature(intermediate, feat_code_similarity, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_pairwise, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_jaccard, ["questionURL"])
    panel = _late_merge_prefer_feature(panel, feat_accept_similarity, ["questionURL"])

    # ── 4. 输出 ───────────────────────────────────────────────────────────────
    out_path = ARTIFACT_PATHS["panels"]["question"]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    panel.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"question_panel 已保存: {out_path}  shape={panel.shape}")
    return panel


if __name__ == "__main__":
    build()
