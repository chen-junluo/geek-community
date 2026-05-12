# Artifact:    feature/question_aigc_quality
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv
#   - human_answer_intermediate_MISQ.csv
#   - question_ai_content.csv
#   - data/.cache/AIGC_quality_index_comprehensive/*.json
#   - data/.cache/AIGC_quality_index_component_old/*.json
#   - data/.cache/AIGC_quality_index_component/*.json
#   - data/.cache/cmn2question_AIGC_sample_annotated.csv (optional)
#
# Output:      data/features/question_aigc_quality.csv
#   - Index: questionURL
#   - Core: qualityAI, quality1Ans, quality2Ans, quality3Ans, quality1Resp, quality2Resp, quality3Resp, qualityAllResp, clarity1Ans, readability1Ans, accuracy1Ans, relevance1Ans, detail1Ans, experience1Ans, insight1Ans, innovative1Ans, alternative1Ans, storytelling1Ans
#   - Derived: roomForImprovement
#
# Logic:
#   - 按 `Archive/round2_parser_for_panel.ipynb` 精准复现 `cmn2question_AIGC` 与 `cmn2question_AIGC_quality`
#   - AI answer row: `ansID == 1` 且 `preAI == 1`
#   - human answer row: `ansID = cmnID + 1` when question has AI answer, else `ansID = cmnID`
#   - `quality1Ans/2Ans/3Ans` 按 `ansID` 聚合，`quality1Resp/2Resp/3Resp` 按 `cmnID` 聚合

import os
import re
import json

import numpy as np
import pandas as pd

from utils.paths import ARTIFACT_PATHS


DATA_BASE = os.path.join(os.path.dirname(__file__), "..", "..", "data")
CACHE_BASE = os.path.join(DATA_BASE, ".cache")
COMPREHENSIVE_CACHE_DIR = os.path.join(CACHE_BASE, "AIGC_quality_index_comprehensive")
COMPONENT_OLD_CACHE_DIR = os.path.join(CACHE_BASE, "AIGC_quality_index_component_old")
COMPONENT_CACHE_DIR = os.path.join(CACHE_BASE, "AIGC_quality_index_component")
ANNOTATION_PATH = os.path.join(CACHE_BASE, "cmn2question_AIGC_sample_annotated.csv")
QUESTION_AI_CONTENT_PATH = os.path.join(DATA_BASE, "raw", "question_ai_content.csv")

COMPREHENSIVE_PATTERNS = [
    r"Quality score: (\d+)",
    r"Rating: (\d+)",
    r"(\d+) out of",
    r"(\d+)/10",
    r"Step 3:[^\d]+(\d+)",
]

COMPONENT_NEW_DIMENSIONS = {
    "overall quality": "quality_m2",
    "clarity": "clarity_m2",
    "readability": "readability_m2",
    "accuracy": "accuracy_m2",
    "relevance": "relevance_m2",
    "level of detail": "detail_m2",
    "personal experiences": "experience_m2",
    "personal insights": "insight_m2",
    "innovative approaches": "innovative_m2",
    "alternative solutions": "alternative_m2",
    "engaging storytelling": "storytelling_m2",
}


def _format_question_id(question_url: str) -> str:
    match = re.search(r"/q/(\d+)", question_url)
    return match.group(1) if match else ""


def _extract_quality_with_patterns(text, patterns):
    if pd.isna(text) or not isinstance(text, str):
        return np.nan
    for pattern in patterns:
        match = re.search(pattern, text)
        if match:
            return int(match.group(1))
    return np.nan


def _extract_dimension_score(text, dimension, allow_na_zero=False):
    if pd.isna(text) or not isinstance(text, str):
        return np.nan
    pattern = rf"{dimension.capitalize()}: (\d+|N/A|NA)"
    match = re.search(pattern, text)
    if not match:
        return np.nan
    score = match.group(1)
    if score.isdigit():
        return int(score)
    return 0 if allow_na_zero else np.nan


def _read_cache_scores(cache_dir: str) -> pd.DataFrame:
    records = []
    for file_name in sorted(os.listdir(cache_dir)):
        if not file_name.endswith(".json"):
            continue
        file_path = os.path.join(cache_dir, file_name)
        with open(file_path, "r", encoding="utf-8") as f:
            payload = json.load(f)
        content = payload.get("choices", [{}])[0].get("message", {}).get("content")
        records.append({"file_name": file_name, "quality_score": content})
    return pd.DataFrame(records)


def _build_cmn2question_aigc() -> pd.DataFrame:
    question_df = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer_df = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    question_ai_content = pd.read_csv(QUESTION_AI_CONTENT_PATH)

    ai_rows = question_ai_content[
        question_ai_content["preAI-content_full_text"].notna()
    ][["questionURL", "title", "preAI-content_full_text"]].copy()
    ai_rows = ai_rows.rename(columns={"preAI-content_full_text": "content_full_text"})
    ai_rows["ansID"] = 1
    ai_rows["preAI"] = 1
    ai_rows["cmnID"] = pd.NA

    human_rows = human_answer_df[["questionURL", "cmnID", "human_answer_text"]].drop_duplicates().copy()
    human_rows = human_rows.rename(columns={"human_answer_text": "content_full_text"})
    human_rows = human_rows.merge(question_df[["questionURL", "title"]], on="questionURL", how="left")
    ai_questions = set(ai_rows["questionURL"])
    human_rows["preAI"] = human_rows["questionURL"].isin(ai_questions).astype(int)
    human_rows["ansID"] = np.where(human_rows["preAI"] == 1, human_rows["cmnID"] + 1, human_rows["cmnID"])

    cmn2question_aigc = pd.concat(
        [ai_rows[["questionURL", "title", "cmnID", "ansID", "preAI", "content_full_text"]],
         human_rows[["questionURL", "title", "cmnID", "ansID", "preAI", "content_full_text"]]],
        ignore_index=True,
        sort=False,
    )
    question_id = cmn2question_aigc["questionURL"].apply(_format_question_id)
    cmn2question_aigc["file_name"] = question_id + "_" + cmn2question_aigc["ansID"].astype(int).astype(str) + ".json"
    return cmn2question_aigc


def build() -> pd.DataFrame:
    print("Reconstructing notebook-style `cmn2question_AIGC`...")
    cmn2question_aigc = _build_cmn2question_aigc()

    print("Loading cached comprehensive AIGC responses...")
    comprehensive = _read_cache_scores(COMPREHENSIVE_CACHE_DIR)
    comprehensive["quality"] = comprehensive["quality_score"].apply(
        lambda x: _extract_quality_with_patterns(x, COMPREHENSIVE_PATTERNS)
    )
    cmn2question_aigc = cmn2question_aigc.merge(
        comprehensive[["file_name", "quality_score", "quality"]],
        on="file_name",
        how="left",
    )

    print("Loading cached old-component AIGC responses...")
    component_old = _read_cache_scores(COMPONENT_OLD_CACHE_DIR)
    for dimension in ["clarity", "readability", "accuracy", "relevance"]:
        component_old[dimension] = component_old["quality_score"].apply(
            lambda x, dim=dimension: _extract_dimension_score(x, dim, allow_na_zero=False)
        )
    component_old["detail"] = component_old["quality_score"].apply(
        lambda x: _extract_dimension_score(x, "level of detail", allow_na_zero=False)
    )
    cmn2question_aigc = cmn2question_aigc.merge(
        component_old[["file_name", "clarity", "readability", "accuracy", "relevance", "detail"]],
        on="file_name",
        how="left",
    )

    print("Loading cached new-component AIGC responses...")
    component_new = _read_cache_scores(COMPONENT_CACHE_DIR)
    for dimension, variable in COMPONENT_NEW_DIMENSIONS.items():
        component_new[variable] = component_new["quality_score"].apply(
            lambda x, dim=dimension: _extract_dimension_score(x, dim, allow_na_zero=True)
        )
    cmn2question_aigc = cmn2question_aigc.merge(
        component_new[["file_name"] + list(COMPONENT_NEW_DIMENSIONS.values())],
        on="file_name",
        how="left",
    )

    if os.path.exists(ANNOTATION_PATH):
        annotation = pd.read_csv(ANNOTATION_PATH)
        cmn2question_aigc = cmn2question_aigc.merge(
            annotation[["file_name", "quality_human"]],
            on="file_name",
            how="left",
        )

    def get_quality_ai(group):
        selected = group[(group["ansID"] == 1) & (group["preAI"] == 1)]
        return selected["quality"].iloc[0] if not selected.empty else np.nan

    def get_quality_ansid(group, ans_id):
        selected = group[group["ansID"] == ans_id]
        return selected["quality"].iloc[0] if not selected.empty else np.nan

    def get_quality_cmnid(group, cmn_id):
        selected = group[group["cmnID"] == cmn_id]
        return selected["quality"].iloc[0] if not selected.empty else np.nan

    def get_quality_all(group):
        selected = group[~group["cmnID"].isna()]
        return selected["quality"].mean() if not selected.empty else np.nan

    def get_component_ansid(group, component, ans_id):
        selected = group[group["ansID"] == ans_id]
        return selected[component].mean() if not selected.empty else np.nan

    print("Aggregating question-level AIGC quality...")
    result = cmn2question_aigc.groupby("questionURL").apply(
        lambda x: pd.Series({
            "qualityAI": get_quality_ai(x),
            "quality1Ans": get_quality_ansid(x, 1),
            "quality2Ans": get_quality_ansid(x, 2),
            "quality3Ans": get_quality_ansid(x, 3),
            "quality1Resp": get_quality_cmnid(x, 1),
            "quality2Resp": get_quality_cmnid(x, 2),
            "quality3Resp": get_quality_cmnid(x, 3),
            "qualityAllResp": get_quality_all(x),
            "clarity1Ans": get_component_ansid(x, "clarity_m2", 1),
            "readability1Ans": get_component_ansid(x, "readability_m2", 1),
            "accuracy1Ans": get_component_ansid(x, "accuracy_m2", 1),
            "relevance1Ans": get_component_ansid(x, "relevance_m2", 1),
            "detail1Ans": get_component_ansid(x, "detail_m2", 1),
            "experience1Ans": get_component_ansid(x, "experience_m2", 1),
            "insight1Ans": get_component_ansid(x, "insight_m2", 1),
            "innovative1Ans": get_component_ansid(x, "innovative_m2", 1),
            "alternative1Ans": get_component_ansid(x, "alternative_m2", 1),
            "storytelling1Ans": get_component_ansid(x, "storytelling_m2", 1),
        })
    ).reset_index()

    for col in ["qualityAI", "quality1Ans", "quality2Ans", "quality3Ans", "quality1Resp", "quality2Resp", "quality3Resp"]:
        result[col] = result[col].astype("Int64")
    result["qualityAllResp"] = result["qualityAllResp"].astype("Float64")
    result["roomForImprovement"] = 10 - result["quality1Ans"]

    output_path = ARTIFACT_PATHS["features"]["question_aigc_quality"]
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    result.to_csv(output_path, index=False, encoding="utf-8-sig")
    print(f"\nSaved to: {output_path}")
    print(f"Output shape: {result.shape}")
    print("\nDescriptive statistics:")
    print(result.describe())

    print("\nSample rows with quality scores:")
    sample = result[result["quality1Ans"].notna()].head(3)
    if len(sample) > 0:
        print(sample[["questionURL", "qualityAI", "quality1Ans", "quality1Resp", "roomForImprovement"]].to_string())

    return result


if __name__ == "__main__":
    build()
