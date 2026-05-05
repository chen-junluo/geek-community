# Artifact:  panel/answer_panel
# 输入:      data/features/answer_llm_extension.csv  (base intermediate / special intermediate)
#            data/features/answer_llm_deviation.csv
# Grain:     answer-level (questionURL × cmnID)
# Merge keys: questionURL, cmnID
# 输出:      data/panels/answer_panel.csv
#
# 职责：读取 answer-level base intermediate，然后在保留 base 全部变量的前提下，late merge 其他 answer-level features，输出 final answer panel。
# 当前 first-pass pipeline 中，answer_llm_extension 同时承担 feature 与 intermediate 两种 role。
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
    intermediate = pd.read_csv(ARTIFACT_PATHS["intermediate"]["answer"])
    print(f"answer_intermediate(base): {intermediate.shape}")

    # ── 2. 读取 late-merge feature ─────────────────────────────────────────────
    feat_deviation = pd.read_csv(ARTIFACT_PATHS["features"]["answer_llm_deviation"])

    # deviation feature
    dev_cols = ["questionURL", "cmnID", "deviation_score",
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

    # ── 3. Late merge ─────────────────────────────────────────────────────────
    panel = _late_merge_prefer_feature(intermediate, feat_deviation, ["questionURL", "cmnID"])

    # ── 4. 输出 ───────────────────────────────────────────────────────────────
    out_path = ARTIFACT_PATHS["panels"]["answer"]
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    panel.to_csv(out_path, index=False, encoding="utf-8-sig")
    print(f"answer_panel 已保存: {out_path}  shape={panel.shape}")
    return panel


if __name__ == "__main__":
    build()
