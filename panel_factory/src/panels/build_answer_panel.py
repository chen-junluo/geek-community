# Artifact:  panel/answer_panel
# 输入:      data/features/human_answer_intermediate.csv
#            data/features/answer_llm_deviation.csv
#            data/features/answer_accepted_answer_similarity.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id
# 输出:      data/panels/answer_panel.csv
#
# 职责：读取 human-answer base intermediate，然后在保留 base 全部变量的前提下，late merge 其他 answer-level features，输出 final answer panel。
# 当前 answer panel 明确面向 human-response universe，不混入 AI row。

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
    intermediate = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer"])
    print(f"human_answer_intermediate(base): {intermediate.shape}")

    # ── 2. 读取 late-merge feature ─────────────────────────────────────────────
    feat_deviation = pd.read_csv(ARTIFACT_PATHS["features"]["answer_llm_deviation"])

    dev_cols = ["questionURL", "resp_id", "preAI", "deviation_score",
                "justification", "relationship_label",
                "prompt_version", "model_name", "error_reason"]
    dev_cols = [c for c in dev_cols if c in feat_deviation.columns]
    feat_deviation = feat_deviation[dev_cols].copy()
    feat_deviation = feat_deviation.rename(columns={
        "justification": "deviation_justification",
        "relationship_label": "deviation_relationship_label",
        "prompt_version": "deviation_prompt_version",
        "model_name": "deviation_model_name",
        "error_reason": "deviation_error_reason",
    })

    panel = _late_merge_prefer_feature(intermediate, feat_deviation, ["questionURL", "resp_id"])
    if "preAI" in panel.columns:
        panel["preAI"] = panel["preAI"].fillna(0).astype(int)

    accept_path = ARTIFACT_PATHS["features"]["answer_accepted_answer_similarity"]
    if os.path.exists(accept_path):
        feat_accept_similarity = pd.read_csv(accept_path)
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
        panel = _late_merge_prefer_feature(panel, feat_accept_similarity, ["questionURL", "resp_id"])
    else:
        print(f"跳过 answer_accepted_answer_similarity，文件不存在: {accept_path}")

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
    panel = _late_merge_prefer_feature(panel, feat_lexicon, ["questionURL", "resp_id"])

    # ── 4. 输出 ───────────────────────────────────────────────────────────────
    out_path = ARTIFACT_PATHS["panels"]["answer"]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    panel.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"answer_panel 已保存: {out_path}  shape={panel.shape}")
    return panel


if __name__ == "__main__":
    build()
