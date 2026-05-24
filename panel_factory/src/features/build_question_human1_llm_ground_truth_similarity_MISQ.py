# Artifact:    feature/question_human1_llm_ground_truth_similarity_MISQ
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv
#   - full_answer_intermediate_MISQ.csv
#
# Output:      data/features/question_human1_llm_ground_truth_similarity_MISQ.csv
#   - Index: questionURL
#   - Core: human1SimWithGT__*, has_ground_truth__*, gt_error_reason__*
#   - Derived: has_human1, human1_resp_id, human1_dateID, gt_provider__*, gt_prompt_version__*, gt_model_name__*
#
# Logic:
#   - 在 MISQ question universe 内，用 `resp_id` 选择第一个 human answer（human1）
#   - 只读取 `Opus` 与 `DeepSeek` 的现有 ground-truth cache，不做任何 model call
#   - 将每个模型的 ground truth 与 human1 做 semantic similarity，输出 single wide feature table

import json
import logging
import os
import re
from typing import Optional

import numpy as np
import pandas as pd
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS


MODEL_SPECS = {
    "claude_opus_4_7": {
        "provider": "custom_api_base",
        "model_name": "anthropic/claude-opus-4.7",
        "cache_dir": ARTIFACT_PATHS["cache"]["question_ground_truth_claude_opus_4_7"],
    },
    "deepseek_v4_pro": {
        "provider": "deepseek_official",
        "model_name": "deepseek-v4-pro",
        "cache_dir": ARTIFACT_PATHS["cache"]["question_ground_truth_deepseek_v4_pro"],
    },
}
MODEL_EXECUTION_ORDER = ["claude_opus_4_7", "deepseek_v4_pro"]
EMBEDDING_MODEL_NAME = "distiluse-base-multilingual-cased-v1"
OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_human1_llm_ground_truth_similarity_misq"]

for spec in MODEL_SPECS.values():
    os.makedirs(spec["cache_dir"], exist_ok=True)
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)


def _load_similarity_model() -> SentenceTransformer:
    return SentenceTransformer(EMBEDDING_MODEL_NAME)


def compute_similarity(text_a: str, text_b: str, model: SentenceTransformer) -> float:
    if pd.isna(text_a) or pd.isna(text_b):
        return np.nan
    text_a = str(text_a).strip()
    text_b = str(text_b).strip()
    if not text_a or not text_b:
        return np.nan
    embeddings = model.encode([text_a, text_b], convert_to_tensor=True)
    return util.cos_sim(embeddings[0], embeddings[1]).cpu().item()


def _extract_url_id(question_url: str) -> str:
    if not isinstance(question_url, str):
        return "unknown_question"
    match = re.search(r"(\d+)(?:/)?$", question_url.strip())
    return match.group(1) if match else "unknown_question"


def _build_cache_key(question_url: str, model_slug: str) -> str:
    return f"q_{_extract_url_id(question_url)}__gt__{model_slug}"


def _cache_path(cache_dir: str, cache_key: str) -> str:
    return os.path.join(cache_dir, f"{cache_key}.json")


def _load_cache(cache_dir: str, cache_key: str) -> Optional[dict]:
    path = _cache_path(cache_dir, cache_key)
    if not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        generated_answer = data.get("generated_answer")
        if isinstance(generated_answer, str) and generated_answer.strip():
            return data
    except Exception:
        return None
    return None


def _normalize_resp_id(series: pd.Series) -> pd.Series:
    return pd.to_numeric(series, errors="coerce")


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


def _build_ground_truth_frame(question: pd.DataFrame, model_slug: str) -> pd.DataFrame:
    spec = MODEL_SPECS[model_slug]
    records = []
    for question_url in question["questionURL"].drop_duplicates():
        cache_key = _build_cache_key(question_url, model_slug)
        cached = _load_cache(spec["cache_dir"], cache_key)
        if cached is None:
            records.append({
                "questionURL": question_url,
                "provider": spec["provider"],
                "model_name": spec["model_name"],
                "prompt_version": np.nan,
                "generated_answer": np.nan,
                "error_reason": "cache_miss",
            })
        else:
            records.append({
                "questionURL": question_url,
                "provider": cached.get("provider", spec["provider"]),
                "model_name": cached.get("model_name", spec["model_name"]),
                "prompt_version": cached.get("prompt_version"),
                "generated_answer": cached.get("generated_answer"),
                "error_reason": cached.get("error_reason"),
            })
    return pd.DataFrame(records)


def _initialize_output_columns(feature: pd.DataFrame) -> pd.DataFrame:
    for model_slug in MODEL_EXECUTION_ORDER:
        feature[f"human1SimWithGT__{model_slug}"] = np.nan
        feature[f"has_ground_truth__{model_slug}"] = np.nan
        feature[f"gt_error_reason__{model_slug}"] = np.nan
        feature[f"gt_provider__{model_slug}"] = np.nan
        feature[f"gt_prompt_version__{model_slug}"] = np.nan
        feature[f"gt_model_name__{model_slug}"] = np.nan
    return feature


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    feature = question[["questionURL"]].drop_duplicates().copy()
    feature = feature.merge(build_human1_lookup(full_answer), on="questionURL", how="left")
    feature["has_human1"] = feature["has_human1"].fillna(0).astype(int)
    feature = _initialize_output_columns(feature)

    similarity_model = _load_similarity_model()

    for model_slug in MODEL_EXECUTION_ORDER:
        gt_df = _build_ground_truth_frame(question, model_slug)
        gt_cols = gt_df[["questionURL", "provider", "generated_answer", "error_reason", "prompt_version", "model_name"]].rename(columns={
            "provider": f"gt_provider_tmp__{model_slug}",
            "generated_answer": f"ground_truth_answer__{model_slug}",
            "error_reason": f"gt_error_reason_tmp__{model_slug}",
            "prompt_version": f"gt_prompt_version_tmp__{model_slug}",
            "model_name": f"gt_model_name_tmp__{model_slug}",
        })
        feature = feature.merge(gt_cols, on="questionURL", how="left")

        gt_text_col = f"ground_truth_answer__{model_slug}"
        feature[f"gt_provider__{model_slug}"] = feature[f"gt_provider_tmp__{model_slug}"]
        feature[f"gt_error_reason__{model_slug}"] = feature[f"gt_error_reason_tmp__{model_slug}"]
        feature[f"gt_prompt_version__{model_slug}"] = feature[f"gt_prompt_version_tmp__{model_slug}"]
        feature[f"gt_model_name__{model_slug}"] = feature[f"gt_model_name_tmp__{model_slug}"]
        feature = feature.drop(columns=[
            f"gt_provider_tmp__{model_slug}",
            f"gt_error_reason_tmp__{model_slug}",
            f"gt_prompt_version_tmp__{model_slug}",
            f"gt_model_name_tmp__{model_slug}",
        ])

        has_gt_col = f"has_ground_truth__{model_slug}"
        sim_col = f"human1SimWithGT__{model_slug}"

        feature[has_gt_col] = (
            feature[gt_text_col].notna()
            & feature[gt_text_col].astype(str).str.strip().ne("")
        ).astype(int)

        valid = (
            feature["has_human1"].eq(1)
            & feature[has_gt_col].eq(1)
            & feature["human1_text"].astype(str).str.strip().ne("")
            & feature[gt_text_col].astype(str).str.strip().ne("")
        )
        if valid.any():
            tqdm.pandas(desc=f"Computing human1 vs GT similarity [{model_slug}]")
            feature.loc[valid, sim_col] = feature.loc[valid].progress_apply(
                lambda row: compute_similarity(row["human1_text"], row[gt_text_col], similarity_model),
                axis=1,
            )

        feature = feature.drop(columns=[gt_text_col])

    output_cols = ["questionURL", "has_human1", "human1_resp_id", "human1_dateID", "human1_selection_rule"]
    for model_slug in MODEL_EXECUTION_ORDER:
        output_cols.extend([
            f"human1SimWithGT__{model_slug}",
            f"has_ground_truth__{model_slug}",
            f"gt_error_reason__{model_slug}",
            f"gt_provider__{model_slug}",
            f"gt_prompt_version__{model_slug}",
            f"gt_model_name__{model_slug}",
        ])

    feature[output_cols].to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    logger.info(f"已保存: {OUTPUT_CSV}  shape={feature[output_cols].shape}")
    return feature[output_cols]


if __name__ == "__main__":
    build()
