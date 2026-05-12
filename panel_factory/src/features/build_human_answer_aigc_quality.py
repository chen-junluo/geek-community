# Artifact:    feature/human_answer_aigc_quality
# Grain:       human_answer
# Merge Keys:  questionURL, cmnID
#
# Inputs:
#   - human_answer_intermediate_MISQ.csv
#   - question_ai_content.csv
#   - data/.cache/AIGC_quality_index_comprehensive/*.json
#   - data/.cache/AIGC_quality_index_component_old/*.json
#   - data/.cache/AIGC_quality_index_component/*.json
#   - data/.cache/cmn2question_AIGC_sample_annotated.csv (optional)
#
# Output:      data/features/human_answer_aigc_quality.csv
#   - Index: questionURL, cmnID
#   - Core: ansID, quality, clarity, readability, accuracy, relevance, detail, quality_m2, clarity_m2, readability_m2, accuracy_m2, relevance_m2, detail_m2, experience_m2, insight_m2, innovative_m2, alternative_m2, storytelling_m2, quality_human
#   - Derived: file_name
#
# Logic:
#   - 按 `Archive/round2_parser_for_panel.ipynb` 的 `cmn2question_AIGC` construction 逻辑重建 answer universe
#   - `ansID` 使用 notebook contract：human answer 在 `preAI == 1` 时取 `cmnID + 1`，否则取 `cmnID`
#   - 从 `data/.cache/AIGC_quality_*/*.json` 读取 cached LLM responses
#   - 使用 notebook 中相同的 regex 规则解析 comprehensive / component scores
#   - 合并人工标注子样本中的 `quality_human`

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


def _build_human_answer_index() -> pd.DataFrame:
    human_answer_df = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    question_ai_content = pd.read_csv(QUESTION_AI_CONTENT_PATH)
    ai_questions = set(
        question_ai_content.loc[
            question_ai_content["preAI-content_full_text"].notna(),
            "questionURL",
        ]
    )

    aigc_index = human_answer_df[["questionURL", "cmnID"]].drop_duplicates().copy()
    aigc_index["preAI"] = aigc_index["questionURL"].isin(ai_questions).astype(int)
    aigc_index["ansID"] = np.where(aigc_index["preAI"] == 1, aigc_index["cmnID"] + 1, aigc_index["cmnID"])
    question_id = aigc_index["questionURL"].apply(_format_question_id)
    aigc_index["file_name"] = question_id + "_" + aigc_index["ansID"].astype(int).astype(str) + ".json"
    return aigc_index


def build() -> pd.DataFrame:
    print("Loading MISQ human-answer universe...")
    result = _build_human_answer_index()
    print(f"Human answer rows: {len(result)}")

    print("Loading cached comprehensive AIGC responses...")
    comprehensive = _read_cache_scores(COMPREHENSIVE_CACHE_DIR)
    comprehensive["quality"] = comprehensive["quality_score"].apply(
        lambda x: _extract_quality_with_patterns(x, COMPREHENSIVE_PATTERNS)
    )
    result = result.merge(
        comprehensive[["file_name", "quality"]],
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
    result = result.merge(
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
    result = result.merge(
        component_new[["file_name"] + list(COMPONENT_NEW_DIMENSIONS.values())],
        on="file_name",
        how="left",
    )

    if os.path.exists(ANNOTATION_PATH):
        print("Loading human annotation sample...")
        annotation = pd.read_csv(ANNOTATION_PATH)
        result = result.merge(annotation[["file_name", "quality_human"]], on="file_name", how="left")
    else:
        print("Human annotation sample not found, filling `quality_human` with NA")
        result["quality_human"] = np.nan

    result = result[
        [
            "questionURL",
            "cmnID",
            "ansID",
            "file_name",
            "quality",
            "clarity",
            "readability",
            "accuracy",
            "relevance",
            "detail",
            "quality_m2",
            "clarity_m2",
            "readability_m2",
            "accuracy_m2",
            "relevance_m2",
            "detail_m2",
            "experience_m2",
            "insight_m2",
            "innovative_m2",
            "alternative_m2",
            "storytelling_m2",
            "quality_human",
        ]
    ].copy()

    output_path = ARTIFACT_PATHS["features"]["human_answer_aigc_quality"]
    os.makedirs(os.path.dirname(output_path), exist_ok=True)
    result.to_csv(output_path, index=False, encoding="utf-8-sig")
    print(f"\nSaved to: {output_path}")
    print(f"Output shape: {result.shape}")
    print("\nDescriptive statistics:")
    print(result.describe())

    print("\nSample rows with quality scores:")
    sample = result[result["quality"].notna()].head(3)
    if len(sample) > 0:
        print(sample[["questionURL", "cmnID", "ansID", "quality", "quality_m2"]].to_string())

    return result


if __name__ == "__main__":
    build()
