# Artifact:  feature/question_accepted_answer_similarity
# 输入:      data/features/question_intermediate.csv, data/features/human_answer_intermediate.csv,
#            data/features/full_answer_intermediate.csv
# Grain:     question-level (questionURL)
# Merge keys: questionURL
# 输出:      data/features/question_accepted_answer_similarity.csv
#
# 逻辑：用 accepted human answer 作为 anchor，计算 AI answer 与 accepted anchor 的
#       full-text cosine similarity，列名固定为 AISimWithAccept。

import os

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_accepted_answer_similarity"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

MODEL_NAME = "distiluse-base-multilingual-cased-v1"


def _load_model():
    return SentenceTransformer(MODEL_NAME)


def compute_similarity(text_a, text_b, model) -> float:
    if pd.isna(text_a) or pd.isna(text_b):
        return np.nan
    text_a = str(text_a).strip()
    text_b = str(text_b).strip()
    if not text_a or not text_b:
        return np.nan
    embeddings = model.encode([text_a, text_b], convert_to_tensor=True)
    return util.cos_sim(embeddings[0], embeddings[1]).cpu().item()


def _join_resp_ids(values: pd.Series) -> str:
    ids = [str(int(v)) for v in values if pd.notna(v)]
    return "|".join(ids) if ids else np.nan


def build_anchor_lookup(human_answer: pd.DataFrame) -> pd.DataFrame:
    # 兼容两种列名：is_accepted_answer 或 accepted
    accept_col = "is_accepted_answer" if "is_accepted_answer" in human_answer.columns else "accepted"
    accepted = human_answer[human_answer[accept_col] == 1].copy()
    if accepted.empty:
        return pd.DataFrame(
            columns=[
                "questionURL",
                "has_accepted_answer",
                "n_accepted_answers",
                "anchor_selection_rule",
                "accepted_resp_id",
                "accepted_resp_ids",
                "accepted_anchor_text",
            ]
        )

    accepted = accepted.sort_values(["questionURL", "dateID", "date", "cmnID"], na_position="last")
    records = []
    for questionURL, group in accepted.groupby("questionURL"):
        group = group.copy()
        n_accepted_answers = len(group)
        if n_accepted_answers == 1:
            chosen = group.iloc[[0]]
            rule = "single_accept"
        else:
            max_metlikes = group["netlikeNum"].max() if "netlikeNum" in group.columns else group.get("metlikes", pd.Series([0])).max()
            metlikes_col = "netlikeNum" if "netlikeNum" in group.columns else "metlikes"
            chosen = group[group[metlikes_col] == max_metlikes].copy()
            if len(chosen) == 1:
                rule = "max_metlikes"
            else:
                chosen = chosen.sort_values(["dateID", "date", "cmnID"], na_position="last")
                rule = "concat_tied_max_metlikes"

        # 兼容两种文本列名
        text_col = "human_answer_text" if "human_answer_text" in chosen.columns else "textLengthCN"
        if text_col == "textLengthCN":
            # 如果没有 human_answer_text，需要从其他地方获取文本，这里暂时用空
            anchor_text = np.nan
        else:
            chosen_texts = chosen[text_col].dropna().astype(str).str.strip()
            chosen_texts = chosen_texts[chosen_texts != ""]
            anchor_text = "\n\n".join(chosen_texts.tolist()) if len(chosen_texts) > 0 else np.nan

        records.append(
            {
                "questionURL": questionURL,
                "has_accepted_answer": 1,
                "n_accepted_answers": n_accepted_answers,
                "anchor_selection_rule": rule,
                "accepted_resp_id": int(chosen.iloc[0]["resp_id"]) if len(chosen) == 1 else np.nan,
                "accepted_resp_ids": _join_resp_ids(chosen["resp_id"]),
                "accepted_anchor_text": anchor_text,
            }
        )
    return pd.DataFrame(records)


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer"])

    anchor_lookup = build_anchor_lookup(human_answer)
    ai_answer = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "answer_text"]]
        .rename(columns={"answer_text": "ai_answer_text"})
        .drop_duplicates("questionURL")
    )

    feature = question[["questionURL"]].copy()
    feature = feature.merge(ai_answer, on="questionURL", how="left")
    feature = feature.merge(anchor_lookup, on="questionURL", how="left")
    feature["has_ai_answer"] = feature["ai_answer_text"].notna().astype(int)
    feature["has_accepted_answer"] = feature["has_accepted_answer"].fillna(0).astype(int)

    feature["AISimWithAccept"] = np.nan
    valid = (
        feature["ai_answer_text"].notna()
        & feature["accepted_anchor_text"].notna()
        & feature["ai_answer_text"].astype(str).str.strip().ne("")
        & feature["accepted_anchor_text"].astype(str).str.strip().ne("")
    )

    model = _load_model()
    tqdm.pandas(desc="Computing AI vs accepted similarity")
    feature.loc[valid, "AISimWithAccept"] = feature.loc[valid].progress_apply(
        lambda row: compute_similarity(row["ai_answer_text"], row["accepted_anchor_text"], model),
        axis=1,
    )

    feature = feature[
        [
            "questionURL",
            "has_ai_answer",
            "has_accepted_answer",
            "n_accepted_answers",
            "anchor_selection_rule",
            "accepted_resp_id",
            "accepted_resp_ids",
            "AISimWithAccept",
        ]
    ]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_accepted_answer_similarity 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
