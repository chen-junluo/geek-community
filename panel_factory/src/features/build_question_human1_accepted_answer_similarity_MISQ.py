# Artifact:    feature/question_human1_accepted_answer_similarity_MISQ
# Grain:    question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv
#   - human_answer_intermediate_MISQ.csv
#   - full_answer_intermediate_MISQ.csv
#
# Output:      data/features/question_human1_accepted_answer_similarity_MISQ.csv
#   - Index: questionURL
#   - Core: human1SimWithAccept
#   - Derived: has_human1, human1_resp_id, human1_dateID, anchor-selection metadata
#
# Logic:
#   - 为每个 question 先用 `resp_id` 选择第一个 human answer（human1），再复用现有 accepted-anchor 规则
#   - accepted anchor 的选择逻辑与 `build_question_accepted_answer_similarity_MISQ.py` 保持一致
#   - 最终计算 `human1_text` 与 accepted anchor text 的 cosine similarity

import os

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_human1_accepted_answer_similarity_misq"]
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


def _normalize_resp_id(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce")


def build_anchor_lookup(human_answer: pd.DataFrame) -> pd.DataFrame:
    accept_col = "is_accepted_answer" if "is_accepted_answer" in human_answer.columns else "accepted"
    text_col = "human_answer_text" if "human_answer_text" in human_answer.columns else "textLengthCN"
    netlikes_col = "netlikeNum" if "netlikeNum" in human_answer.columns else "netlikes"

    records = []
    for questionURL, group in human_answer.groupby("questionURL"):
        n_human_answers = len(group)
        accepted = group[group[accept_col] == 1]

        if len(accepted) > 0:
            has_accepted = 1
            n_accepted = len(accepted)
            if n_accepted == 1:
                chosen = accepted.iloc[[0]]
                rule = "single_accept"
            else:
                max_netlike = accepted[netlikes_col].max()
                chosen = accepted[accepted[netlikes_col] == max_netlike]
                if len(chosen) == 1:
                    rule = "max_netlikes_among_accepted"
                else:
                    chosen = chosen.sort_values("resp_id_num")
                    rule = "concat_tied_accepted"
        else:
            has_accepted = 0
            n_accepted = 0
            max_netlike = group[netlikes_col].max()
            chosen = group[group[netlikes_col] == max_netlike]
            if len(chosen) == 1:
                rule = "max_netlike_no_accept"
            else:
                chosen = chosen.sort_values("resp_id_num")
                rule = "concat_tied_netlike_no_accept"

        if text_col == "textLengthCN":
            anchor_text = np.nan
        else:
            chosen_texts = chosen[text_col].dropna().astype(str).str.strip()
            chosen_texts = chosen_texts[chosen_texts != ""]
            anchor_text = "\n\n".join(chosen_texts.tolist()) if len(chosen_texts) > 0 else np.nan

        records.append({
            "questionURL": questionURL,
            "has_accepted_answer": has_accepted,
            "n_accepted_answers": n_accepted,
            "anchor_selection_rule": rule,
            "accepted_resp_id": int(chosen.iloc[0]["resp_id_num"]) if len(chosen) == 1 and pd.notna(chosen.iloc[0]["resp_id_num"]) else np.nan,
            "accepted_resp_ids": _join_resp_ids(chosen["resp_id_num"]),
            "accepted_anchor_text": anchor_text,
            "n_human_answers": n_human_answers,
            "baseline_netlike": chosen[netlikes_col].iloc[0] if len(chosen) > 0 else np.nan,
        })

    return pd.DataFrame(records)


def build_human1_lookup(full_answer: pd.DataFrame) -> pd.DataFrame:
    human_rows = full_answer[full_answer["answer_source"] == "human_answer"].copy()
    human_rows["resp_id_num"] = _normalize_resp_id(human_rows["resp_id"])
    human_rows = human_rows.sort_values(["questionURL", "resp_id_num"])
    human1 = human_rows.dropna(subset=["resp_id_num"]).drop_duplicates("questionURL", keep="first").copy()
    human1["has_human1"] = 1
    human1["human1_resp_id"] = human1["resp_id_num"].astype(int)
    human1["human1_dateID"] = human1["dateID"]
    human1["human1_selection_rule"] = "min_resp_id"
    human1["human1_text"] = human1["answer_text"]
    return human1[["questionURL", "has_human1", "human1_resp_id", "human1_dateID", "human1_selection_rule", "human1_text"]]


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    human_text = (
        full_answer[full_answer["answer_source"] == "human_answer"]
        [["questionURL", "resp_id", "answer_text"]]
        .rename(columns={"answer_text": "human_answer_text"})
        .drop_duplicates(["questionURL", "resp_id"])
    )
    human_answer_with_text = human_answer.merge(human_text, on=["questionURL", "resp_id"], how="left")
    human_answer_with_text["resp_id_num"] = _normalize_resp_id(human_answer_with_text["resp_id"])

    human1_lookup = build_human1_lookup(full_answer)
    anchor_lookup = build_anchor_lookup(human_answer_with_text)

    feature = question[["questionURL"]].drop_duplicates().copy()
    feature = feature.merge(human1_lookup, on="questionURL", how="left")
    feature = feature.merge(anchor_lookup, on="questionURL", how="left")
    feature["has_human1"] = feature["has_human1"].fillna(0).astype(int)
    feature["has_accepted_answer"] = feature["has_accepted_answer"].fillna(0).astype(int)

    feature["human1SimWithAccept"] = np.nan
    valid = (
        feature["human1_text"].notna()
        & feature["accepted_anchor_text"].notna()
        & feature["human1_text"].astype(str).str.strip().ne("")
        & feature["accepted_anchor_text"].astype(str).str.strip().ne("")
    )

    model = _load_model()
    tqdm.pandas(desc="Computing human1 vs accepted similarity (MISQ)")
    feature.loc[valid, "human1SimWithAccept"] = feature.loc[valid].progress_apply(
        lambda row: compute_similarity(row["human1_text"], row["accepted_anchor_text"], model),
        axis=1,
    )

    feature = feature[[
        "questionURL",
        "has_human1",
        "human1_resp_id",
        "human1_dateID",
        "human1_selection_rule",
        "has_accepted_answer",
        "n_accepted_answers",
        "anchor_selection_rule",
        "accepted_resp_id",
        "accepted_resp_ids",
        "n_human_answers",
        "baseline_netlike",
        "human1SimWithAccept",
    ]]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"question_human1_accepted_answer_similarity_MISQ 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
