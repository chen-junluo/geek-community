# Artifact:    feature/question_llm_ground_truth_similarity_MISQ
# Grain:       question
# Merge Keys:  questionURL
#
# Inputs:
#   - question_intermediate_MISQ.csv
#   - full_answer_intermediate_MISQ.csv
#
# Output:      data/features/question_llm_ground_truth_similarity_MISQ.csv
#   - Index: questionURL
#   - Core: has_ai_answer, AISimWithGT__*, has_ground_truth__*, gt_error_reason__*
#   - Derived: prompt_version, gt_model_name__*
#
# Logic:
#   - 在 MISQ question universe 内，对固定三套模型预留 wide columns
#   - 支持只运行单个模型；未运行的模型列保持为空
#   - ground truth 通过 OpenRouter 调用 LLM，结果缓存到各自模型目录，命中 cache 时不重复调用 API
#   - 将每个模型的 ground truth 与 AI answer 做 semantic similarity，输出单个 wide feature table

import json
import logging
import os
import re
import time
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional

import numpy as np
import pandas as pd
from openai import OpenAI
from sentence_transformers import SentenceTransformer, util
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS


MODEL_SPECS = {
    "claude_opus_4_7": {
        "model_name": "anthropic/claude-opus-4.7",
        "cache_dir": ARTIFACT_PATHS["cache"]["question_ground_truth_claude_opus_4_7"],
    },
    "gpt_5_5": {
        "model_name": "openai/gpt-5.5",
        "cache_dir": ARTIFACT_PATHS["cache"]["question_ground_truth_gpt_5_5"],
    },
    "gemini_pro_preview": {
        "model_name": "google/gemini-2.5-pro-preview",
        "cache_dir": ARTIFACT_PATHS["cache"]["question_ground_truth_gemini_pro_preview"],
    },
}
MODEL_EXECUTION_ORDER = ["claude_opus_4_7", "gpt_5_5", "gemini_pro_preview"]
MODEL_NAME_TO_SLUG = {spec["model_name"]: slug for slug, spec in MODEL_SPECS.items()}

OPENROUTER_API_KEY = os.environ.get("OPENROUTER_API_KEY", "")
OPENROUTER_BASE_URL = os.environ.get("OPENROUTER_BASE_URL", "https://openrouter.ai/api/v1")
OPENROUTER_MODEL = os.environ.get("OPENROUTER_MODEL", "anthropic/claude-opus-4.7").strip()
OPENROUTER_MAX_WORKERS = min(int(os.environ.get("OPENROUTER_MAX_WORKERS", "2")), 2)
OPENROUTER_REQUEST_TIMEOUT = int(os.environ.get("OPENROUTER_REQUEST_TIMEOUT", "120"))
MAX_RETRIES = 3
RETRY_BACKOFF_SECONDS = [2, 4, 8]
MAX_TEXT_CHARS = 6000
PROMPT_VERSION = "v1_msq_ground_truth_reference_answer"
EMBEDDING_MODEL_NAME = "distiluse-base-multilingual-cased-v1"
OUTPUT_CSV = ARTIFACT_PATHS["features"]["question_llm_ground_truth_similarity_misq"]

for spec in MODEL_SPECS.values():
    os.makedirs(spec["cache_dir"], exist_ok=True)
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

GROUND_TRUTH_PROMPT = """你是一位技术问答社区中的资深 expert。你的任务不是聊天，也不是头脑风暴，而是为一个具体 technical question 写出 answer。

你的输出目标：
1. 回答必须直接回应 question 的核心 technical problem。
2. 回答必须给出最可能正确、最能解决这个technical问题的解决路径。
3. 如果存在多个可能方向，只保留你判断最主要、最 canonical、最能解决这个technical问题的那一个技术答案，不要并列罗列多种方案。
4. 优先给出 diagnosis、mechanism、key steps、code fix 或 configuration fix 中最关键的部分，但保持 concise。
5. 不要写思考过程，不要写推理说明，不要写“可能”“也许”“可以尝试以下几种方式”这类发散表述。
6. 不要写标题、编号、项目符号、免责声明、寒暄或总结。

请直接根据下面的 question，输出一条 concise、direct、best-effort、single-path 的 technical answer。

=== Question ===
{question_text}
"""


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


def _truncate_text(text: str, max_chars: int = MAX_TEXT_CHARS) -> str:
    if not isinstance(text, str) or not text.strip():
        return "(空文本)"
    text = text.strip()
    if len(text) <= max_chars:
        return text
    half = max_chars // 2
    return text[:half] + f"\n\n... [中间省略约{len(text) - max_chars}字] ...\n\n" + text[-half:]


def _extract_url_id(question_url: str) -> str:
    if not isinstance(question_url, str):
        return "unknown_question"
    match = re.search(r"(\d+)(?:/)?$", question_url.strip())
    return match.group(1) if match else "unknown_question"


def _normalize_model_slug(model_selector: str) -> str:
    selector = str(model_selector).strip()
    if selector in MODEL_SPECS:
        return selector
    if selector in MODEL_NAME_TO_SLUG:
        return MODEL_NAME_TO_SLUG[selector]
    raise ValueError(f"不支持的 OPENROUTER_MODEL: {model_selector}")


def _selected_model_slugs() -> list[str]:
    return [_normalize_model_slug(OPENROUTER_MODEL)]


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


def _save_cache(cache_dir: str, cache_key: str, data: dict) -> None:
    with open(_cache_path(cache_dir, cache_key), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def _build_client() -> OpenAI:
    return OpenAI(base_url=OPENROUTER_BASE_URL, api_key=OPENROUTER_API_KEY)


def _call_openrouter(question_text: str, model_name: str) -> tuple[Optional[str], Optional[str]]:
    if not OPENROUTER_API_KEY:
        return None, "缺少 OPENROUTER_API_KEY 环境变量"

    client = _build_client()
    prompt = GROUND_TRUTH_PROMPT.format(question_text=_truncate_text(question_text))
    last_error = None

    for attempt in range(MAX_RETRIES):
        try:
            response = client.chat.completions.create(
                model=model_name,
                messages=[{"role": "user", "content": prompt}],
                temperature=0.2,
                max_tokens=1200,
                timeout=OPENROUTER_REQUEST_TIMEOUT,
                extra_body={"reasoning": {"enabled": True}},
            )
            message = response.choices[0].message.content
            if isinstance(message, str) and message.strip():
                return message.strip(), None
            if isinstance(message, list):
                parts = [part.get("text", "") for part in message if isinstance(part, dict)]
                text = "\n".join([p for p in parts if p]).strip()
                if text:
                    return text, None
            last_error = "空响应"
        except Exception as e:
            last_error = str(e)[:300]
        if attempt < MAX_RETRIES - 1:
            time.sleep(RETRY_BACKOFF_SECONDS[min(attempt, len(RETRY_BACKOFF_SECONDS) - 1)])

    return None, f"重试{MAX_RETRIES}次后失败。最后错误: {last_error}"


def _generate_ground_truth_for_question(row: pd.Series, model_slug: str) -> dict:
    spec = MODEL_SPECS[model_slug]
    model_name = spec["model_name"]
    cache_dir = spec["cache_dir"]
    cache_key = _build_cache_key(row["questionURL"], model_slug)
    cached = _load_cache(cache_dir, cache_key)
    if cached is not None:
        return cached

    question_text = row.get("question_text")
    if pd.isna(question_text) or not str(question_text).strip():
        return {
            "questionURL": row["questionURL"],
            "cache_key": cache_key,
            "provider": "openrouter",
            "model_name": model_name,
            "prompt_version": PROMPT_VERSION,
            "generated_answer": None,
            "error_reason": "缺少 question_text",
            "api_call_timestamp": pd.Timestamp.utcnow().isoformat(),
        }

    generated_answer, error_reason = _call_openrouter(str(question_text), model_name)
    result = {
        "questionURL": row["questionURL"],
        "cache_key": cache_key,
        "provider": "openrouter",
        "model_name": model_name,
        "prompt_version": PROMPT_VERSION,
        "generated_answer": generated_answer,
        "error_reason": error_reason,
        "api_call_timestamp": pd.Timestamp.utcnow().isoformat(),
    }
    if generated_answer:
        _save_cache(cache_dir, cache_key, result)
    return result


def _build_ground_truth_frame(question: pd.DataFrame, model_slug: str) -> pd.DataFrame:
    question_rows = question[["questionURL", "question_text"]].drop_duplicates("questionURL")
    records = question_rows.to_dict("records")
    results = []

    with ThreadPoolExecutor(max_workers=OPENROUTER_MAX_WORKERS) as executor:
        future_to_question = {
            executor.submit(_generate_ground_truth_for_question, pd.Series(record), model_slug): record["questionURL"]
            for record in records
        }
        with tqdm(total=len(records), desc=f"Ground truth generation [{model_slug}]") as pbar:
            for future in as_completed(future_to_question):
                try:
                    results.append(future.result())
                except Exception as e:
                    spec = MODEL_SPECS[model_slug]
                    results.append({
                        "questionURL": future_to_question[future],
                        "cache_key": _build_cache_key(future_to_question[future], model_slug),
                        "provider": "openrouter",
                        "model_name": spec["model_name"],
                        "prompt_version": PROMPT_VERSION,
                        "generated_answer": None,
                        "error_reason": f"处理异常: {str(e)[:200]}",
                        "api_call_timestamp": pd.Timestamp.utcnow().isoformat(),
                    })
                pbar.update(1)

    gt_df = pd.DataFrame(results)
    if gt_df.empty:
        gt_df = pd.DataFrame(columns=[
            "questionURL", "cache_key", "provider", "model_name", "prompt_version",
            "generated_answer", "error_reason", "api_call_timestamp",
        ])
    return gt_df


def _initialize_output_columns(feature: pd.DataFrame) -> pd.DataFrame:
    for model_slug in MODEL_EXECUTION_ORDER:
        feature[f"AISimWithGT__{model_slug}"] = np.nan
        feature[f"has_ground_truth__{model_slug}"] = np.nan
        feature[f"gt_error_reason__{model_slug}"] = np.nan
        feature[f"gt_prompt_version__{model_slug}"] = np.nan
        feature[f"gt_model_name__{model_slug}"] = np.nan
    return feature


def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    base = question[["questionURL", "question_text"]].drop_duplicates("questionURL").copy()
    ai_answer = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "answer_text"]]
        .rename(columns={"answer_text": "ai_answer_text"})
        .drop_duplicates("questionURL")
    )
    feature = base.merge(ai_answer, on="questionURL", how="left")
    feature["has_ai_answer"] = (
        feature["ai_answer_text"].notna()
        & feature["ai_answer_text"].astype(str).str.strip().ne("")
    ).astype(int)
    feature = _initialize_output_columns(feature)

    similarity_model = _load_similarity_model()
    selected_model_slugs = _selected_model_slugs()
    logger.info(f"本次仅执行模型: {selected_model_slugs}，并发数: {OPENROUTER_MAX_WORKERS}")

    for model_slug in selected_model_slugs:
        gt_df = _build_ground_truth_frame(question, model_slug)
        gt_cols = gt_df[["questionURL", "generated_answer", "error_reason", "prompt_version", "model_name"]].rename(columns={
            "generated_answer": f"ground_truth_answer__{model_slug}",
            "error_reason": f"gt_error_reason_tmp__{model_slug}",
            "prompt_version": f"gt_prompt_version_tmp__{model_slug}",
            "model_name": f"gt_model_name_tmp__{model_slug}",
        })
        feature = feature.merge(gt_cols, on="questionURL", how="left")

        feature[f"gt_error_reason__{model_slug}"] = feature[f"gt_error_reason_tmp__{model_slug}"]
        feature[f"gt_prompt_version__{model_slug}"] = feature[f"gt_prompt_version_tmp__{model_slug}"]
        feature[f"gt_model_name__{model_slug}"] = feature[f"gt_model_name_tmp__{model_slug}"]
        feature = feature.drop(columns=[
            f"gt_error_reason_tmp__{model_slug}",
            f"gt_prompt_version_tmp__{model_slug}",
            f"gt_model_name_tmp__{model_slug}",
        ])

        has_gt_col = f"has_ground_truth__{model_slug}"
        sim_col = f"AISimWithGT__{model_slug}"
        gt_text_col = f"ground_truth_answer__{model_slug}"

        feature[has_gt_col] = (
            feature[gt_text_col].notna()
            & feature[gt_text_col].astype(str).str.strip().ne("")
        ).astype(int)

        valid = (
            feature["has_ai_answer"].eq(1)
            & feature[has_gt_col].eq(1)
            & feature["ai_answer_text"].astype(str).str.strip().ne("")
            & feature[gt_text_col].astype(str).str.strip().ne("")
        )
        if valid.any():
            tqdm.pandas(desc=f"Computing AI vs GT similarity [{model_slug}]")
            feature.loc[valid, sim_col] = feature.loc[valid].progress_apply(
                lambda row: compute_similarity(row["ai_answer_text"], row[gt_text_col], similarity_model),
                axis=1,
            )

    output_cols = ["questionURL", "has_ai_answer"]
    for model_slug in MODEL_EXECUTION_ORDER:
        output_cols.extend([
            f"AISimWithGT__{model_slug}",
            f"has_ground_truth__{model_slug}",
            f"gt_error_reason__{model_slug}",
            f"gt_prompt_version__{model_slug}",
            f"gt_model_name__{model_slug}",
        ])

    feature[output_cols].to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    logger.info(f"已保存: {OUTPUT_CSV}  shape={feature[output_cols].shape}")
    return feature[output_cols]


if __name__ == "__main__":
    build()
