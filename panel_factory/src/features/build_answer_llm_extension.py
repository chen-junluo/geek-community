# Artifact:  feature/answer_llm_extension
# 输入:      data/features/question_intermediate_MISQ.csv, data/features/human_answer_intermediate_MISQ.csv,
#            data/features/full_answer_intermediate_MISQ.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id
# 输出:      data/features/answer_llm_extension.csv
#
# 逻辑：在 MISQ human-response universe 内，对每个 human answer pair（earlier answer vs later answer），
#       用 DeepSeek 评估 later answer 在 earlier answer 基础上的 solution-path extension 程度（0-10）。
#       Treatment: earlier = AI answer；Control: earlier = 第一个 human answer。

import os
import re
import json
import time
import logging
from concurrent.futures import ThreadPoolExecutor, as_completed
from typing import Optional, Tuple, Dict

import numpy as np
import pandas as pd
import requests
from tqdm import tqdm

from utils.paths import ARTIFACT_PATHS

# ── Config ──────────────────────────────────────────────────────────────────

DEEPSEEK_API_KEY = os.environ.get("DEEPSEEK_API_KEY", "")
DEEPSEEK_API_URL = "https://api.deepseek.com/v1/chat/completions"
DEEPSEEK_MODEL = "deepseek-chat"
MAX_RETRIES = 3
RETRY_BACKOFF_SECONDS = [2, 4, 8]
REQUEST_TIMEOUT = 90
MAX_TEXT_CHARS = 4000
MAX_WORKERS = 20
PROMPT_VERSION = "v2_extension_score_0_10_rubric"

CACHE_DIR = ARTIFACT_PATHS["cache"]["llm_extension"]
OUTPUT_CSV = ARTIFACT_PATHS["features"]["answer_llm_extension"]

os.makedirs(CACHE_DIR, exist_ok=True)
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

logging.basicConfig(level=logging.INFO, format="%(asctime)s [%(levelname)s] %(message)s")
logger = logging.getLogger(__name__)

# ── Prompt ───────────────────────────────────────────────────────────────────

EVALUATION_PROMPT = """你是一位中文技术问答社区的内容关系评估专家。请根据同一个问题下的两个答案，评估 later answer 相对于 earlier answer 的"solution-path extension"（解决路径延展）程度。

核心定义：
"解决路径延展"指 later answer 是否主要沿着 earlier answer 的核心诊断、解释、方法或实现方案继续推进。它衡量的是两个答案之间的关系，不是 later answer 本身的质量、正确性、长度、礼貌程度或可读性。

请先识别 earlier answer 的核心解决路径，再判断 later answer 与它的关系。核心解决路径包括：主要原因判断、主要技术方案、关键操作步骤、排查方向、代码实现思路、工具或框架选择、以及对问题机制的解释。

评分标准如下：
- 0 分：later answer 与 earlier answer 的核心解决路径完全不同，或 later answer 基本没有回应 earlier answer 所涉及的解决方向；它主要提出另一种方法、另一种原因判断、另一套工具/框架、另一条排查路线，或只是无实质内容的回答。
- 1-3 分：later answer 与 earlier answer 只有很弱的路径重合。两者可能针对同一个 Question，但 later answer 的主要建议、原因解释或实现方法不同；相同之处主要停留在问题主题、术语或目标层面，而不是解决逻辑层面。
- 4-6 分：later answer 与 earlier answer 有中等程度的路径重合。later answer 保留 earlier answer 的部分核心方向，或接受其部分前提，但同时加入了新的主要方法、不同的排查重点、不同的实现方案，或把回答重心转向另一条较重要的路径。
- 7-9 分：later answer 与 earlier answer 高度沿用同一条核心解决路径，并在此基础上补充更具体的步骤、条件、代码细节、边界情况、原因解释、风险提醒、调试建议或例子；但它仍可能加入少量辅助性的新信息。
- 10 分：later answer 几乎完全是在 earlier answer 的同一核心解决路径上做进一步深化、细化或明确化，没有引入新的主要解决路径；它的主要贡献是把 earlier answer 说得更完整、更具体或更可执行。

判断时请遵守以下规则：
1. 必须结合 Question 理解两个答案是否在解决同一个具体问题。
2. 不要把答案质量当成评分对象。一个更正确或更详细的 later answer，如果走的是不同方案，也不应给高分。
3. 不要把文本相似度当成评分对象。措辞相似但核心方案不同，应给低分；措辞不同但核心路径一致，可以给高分。
4. 不要因为 later answer 更长就自动给高分。只有当新增内容服务于 earlier answer 的同一核心路径时，才提高分数。
5. 如果 later answer 同时包含延展和新方案，请根据其主要贡献给分：主要是延展则偏高，主要是新方案则偏低，二者接近则给 4-6 分。
6. 如果 earlier answer 或 later answer 内容过短、含糊或缺乏实质解决方案，请给较低分，并在 justification 中说明原因。
7. 请给出一个 0-10 的整数分数。
8. justification 必须是简单的一句中文说明，说明 later answer 是如何延展或偏离 earlier answer 的核心解决路径。
9. relationship_label 必须返回，且只能是 same_path、different_path、mixed 三者之一，不允许留空，不允许返回其他词。
10. 评分和 relationship_label 必须一致：0-3 分优先对应 different_path，4-6 分优先对应 mixed，7-10 分优先对应 same_path。如二者不一致，请以这个映射修正 relationship_label。
11. 只返回 JSON，不要输出任何额外文字，也不要使用 markdown 代码块。

=== Question ===
{question_text}

=== Earlier Answer ({anchor_source}) ===
{earlier_answer}

=== Later Answer ===
{later_answer}

=== 输出格式 ===
请仅返回如下 JSON：
{{
  "extension_score": <0到10的整数>,
  "justification": "<一句中文说明>",
  "relationship_label": "<same_path 或 different_path 或 mixed>"
}}"""


# ── Helpers ──────────────────────────────────────────────────────────────────

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


def _comparison_label(row: pd.Series) -> str:
    later_date_id = int(row["dateID"]) if pd.notna(row["dateID"]) else "na"
    if row["anchor_source"] == "AI_answer":
        return f"ai_vs_{later_date_id}"
    if pd.notna(row["anchor_dateID"]):
        return f"{int(row['anchor_dateID'])}_vs_{later_date_id}"
    return f"unknown_vs_{later_date_id}"


def _build_cache_key(row: pd.Series) -> str:
    return f"q_{_extract_url_id(row['questionURL'])}__{_comparison_label(row)}"


def _normalize_relationship_label(extension_score: Optional[int], relationship_label: Optional[str]) -> Optional[str]:
    allowed = {"same_path", "different_path", "mixed"}
    if relationship_label in allowed:
        return relationship_label
    if extension_score is None:
        return None
    if extension_score <= 3:
        return "different_path"
    if extension_score <= 6:
        return "mixed"
    return "same_path"


def _cache_path(cache_key: str) -> str:
    return os.path.join(CACHE_DIR, f"{cache_key}.json")


def _load_cache(cache_key: str) -> Optional[Dict]:
    path = _cache_path(cache_key)
    if not os.path.exists(path):
        return None
    try:
        with open(path, "r", encoding="utf-8") as f:
            data = json.load(f)
        if data.get("error_reason"):
            return None
        score = data.get("extension_score")
        try:
            score = int(score) if score is not None else None
        except Exception:
            score = None
        label = _normalize_relationship_label(score, data.get("relationship_label"))
        if "extension_score" in data and "justification" in data and label is not None:
            data["extension_score"] = score
            data["relationship_label"] = label
            return data
    except Exception:
        pass
    return None


def _save_cache(cache_key: str, data: dict):
    with open(_cache_path(cache_key), "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def _extract_json(raw: str) -> Tuple[Optional[Dict], Optional[str]]:
    text = raw.strip()
    if text.startswith("```"):
        lines = text.split("\n")[1:]
        if lines and lines[-1].strip().startswith("```"):
            lines = lines[:-1]
        text = "\n".join(lines).strip()
    try:
        return json.loads(text), None
    except json.JSONDecodeError:
        pass
    match = re.search(r"\{[\s\S]*\}", text)
    if match:
        try:
            return json.loads(match.group()), None
        except json.JSONDecodeError as e:
            return None, f"JSON解析错误: {e}"
    return None, f"未找到JSON对象 (长度={len(raw)})"


def _call_api(prompt: str) -> Tuple[Optional[str], Optional[str]]:
    if not DEEPSEEK_API_KEY:
        return None, "缺少 DEEPSEEK_API_KEY 环境变量"
    headers = {"Authorization": f"Bearer {DEEPSEEK_API_KEY}", "Content-Type": "application/json"}
    payload = {
        "model": DEEPSEEK_MODEL,
        "messages": [
            {"role": "system", "content": "你是一位中文技术问答关系评估专家。请始终仅返回有效JSON，不要使用markdown代码块，不要添加额外文字。"},
            {"role": "user", "content": prompt},
        ],
        "temperature": 0.1,
        "max_tokens": 600,
    }
    last_error = None
    for attempt in range(MAX_RETRIES):
        try:
            resp = requests.post(DEEPSEEK_API_URL, headers=headers, json=payload, timeout=REQUEST_TIMEOUT)
            if resp.status_code == 200:
                return resp.json()["choices"][0]["message"]["content"], None
            last_error = f"HTTP {resp.status_code}: {resp.text[:300]}"
        except requests.exceptions.Timeout:
            last_error = f"超时 ({REQUEST_TIMEOUT}秒)"
        except Exception as e:
            last_error = f"异常: {str(e)[:150]}"
        if attempt < MAX_RETRIES - 1:
            time.sleep(RETRY_BACKOFF_SECONDS[min(attempt, len(RETRY_BACKOFF_SECONDS) - 1)])
    return None, f"重试{MAX_RETRIES}次后失败。最后错误: {last_error}"


# ── Panel preparation ─────────────────────────────────────────────────────────

def prepare_eval_panel(
    question: pd.DataFrame,
    human_answer: pd.DataFrame,
    full_answer: pd.DataFrame,
) -> pd.DataFrame:
    question_rows = question[["questionURL", "question_text"]].drop_duplicates("questionURL")
    ai_rows = (
        full_answer[full_answer["answer_source"] == "AI_answer"]
        [["questionURL", "answer_text"]]
        .rename(columns={"answer_text": "ai_answer_text"})
        .drop_duplicates("questionURL")
    )
    first_human = (
        human_answer[human_answer["human_answer_text"].notna()]
        .sort_values(["questionURL", "dateID", "date", "cmnID"], na_position="last")
        .groupby("questionURL")
        .first()
        .reset_index()
        [["questionURL", "resp_id", "cmnID", "dateID", "human_answer_text"]]
        .rename(columns={
            "resp_id": "first_human_resp_id",
            "cmnID": "first_human_cmnID",
            "dateID": "first_human_dateID",
            "human_answer_text": "first_human_text",
        })
    )

    panel = (
        human_answer[human_answer["human_answer_text"].notna()].copy()
        .merge(question_rows, on="questionURL", how="left")
        .merge(ai_rows, on="questionURL", how="left")
        .merge(first_human, on="questionURL", how="left")
    )
    panel["is_treatment"] = panel["ai_answer_text"].notna().astype(int)
    panel["anchor_source"] = np.where(panel["is_treatment"] == 1, "AI_answer", "first_human_answer")
    panel["anchor_resp_id"] = np.where(panel["is_treatment"] == 1, np.nan, panel["first_human_resp_id"])
    panel["anchor_cmnID"] = np.where(panel["is_treatment"] == 1, np.nan, panel["first_human_cmnID"])
    panel["anchor_dateID"] = np.where(panel["is_treatment"] == 1, np.nan, panel["first_human_dateID"])
    panel["earlier_answer_text"] = np.where(
        panel["is_treatment"] == 1,
        panel["ai_answer_text"],
        panel["first_human_text"],
    )
    panel = panel.rename(columns={"human_answer_text": "later_answer_text"})

    t_mask = panel["is_treatment"] == 1
    c_mask = panel["is_treatment"] == 0
    panel = panel[(t_mask & panel["later_answer_text"].notna()) | (c_mask & panel["later_answer_text"].notna())].copy()
    panel = panel[(t_mask & panel["dateID"].notna()) | (c_mask & (panel["dateID"] > panel["first_human_dateID"]))].copy()

    panel["comparison_target"] = panel.apply(_comparison_label, axis=1)
    panel["question_text_for_llm"] = panel["question_text"].apply(_truncate_text)
    panel["earlier_answer_text_for_llm"] = panel["earlier_answer_text"].apply(_truncate_text)
    panel["later_answer_text_for_llm"] = panel["later_answer_text"].apply(_truncate_text)
    panel["cache_key"] = panel.apply(_build_cache_key, axis=1)

    return panel[[
        "questionURL", "resp_id", "comparison_target",
        "cmnID", "dateID", "date", "accept", "is_treatment",
        "anchor_source", "anchor_resp_id", "anchor_cmnID", "anchor_dateID",
        "question_text", "earlier_answer_text", "later_answer_text",
        "question_text_for_llm", "earlier_answer_text_for_llm", "later_answer_text_for_llm",
        "cache_key",
    ]].copy()


# ── Evaluation ────────────────────────────────────────────────────────────────

def evaluate_single_pair(row: pd.Series) -> dict:
    cache_key = row["cache_key"]
    cached = _load_cache(cache_key)
    if cached is not None:
        cached["cache_key"] = cache_key
        return cached

    for field, label in [("earlier_answer_text", "earlier answer"), ("later_answer_text", "later answer")]:
        if pd.isna(row[field]) or not str(row[field]).strip():
            return {"cache_key": cache_key, "extension_score": None, "justification": None,
                    "relationship_label": None, "error_reason": f"缺少 {label} 文本"}

    prompt = EVALUATION_PROMPT.format(
        question_text=row["question_text_for_llm"],
        anchor_source=row["anchor_source"],
        earlier_answer=row["earlier_answer_text_for_llm"],
        later_answer=row["later_answer_text_for_llm"],
    )
    raw_response, api_error = _call_api(prompt)
    if api_error:
        return {"cache_key": cache_key, "extension_score": None, "justification": None,
                "relationship_label": None, "error_reason": api_error}

    parsed, parse_error = _extract_json(raw_response)
    if parse_error:
        return {"cache_key": cache_key, "extension_score": None, "justification": None,
                "relationship_label": None, "error_reason": parse_error, "raw_response": raw_response}

    try:
        score = max(0, min(10, int(parsed.get("extension_score"))))
    except Exception:
        score = None

    label = _normalize_relationship_label(score, parsed.get("relationship_label"))
    if label is None:
        return {"cache_key": cache_key, "extension_score": score, "justification": parsed.get("justification"),
                "relationship_label": None, "error_reason": "relationship_label 缺失", "raw_response": raw_response}

    result = {"cache_key": cache_key, "extension_score": score, "justification": parsed.get("justification"),
              "relationship_label": label, "error_reason": None, "raw_response": raw_response,
              "prompt_version": PROMPT_VERSION, "model_name": DEEPSEEK_MODEL}
    _save_cache(cache_key, result)
    return result


def process_single_pair(row: pd.Series) -> dict:
    try:
        return evaluate_single_pair(row)
    except Exception as e:
        return {"cache_key": row["cache_key"], "extension_score": None, "justification": None,
                "relationship_label": None, "error_reason": f"处理异常: {str(e)[:150]}"}


# ── Main ──────────────────────────────────────────────────────────────────────

def build() -> pd.DataFrame:
    question = pd.read_csv(ARTIFACT_PATHS["intermediate"]["question_misq"])
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    eval_panel = prepare_eval_panel(question, human_answer, full_answer)
    logger.info(f"准备评估 {len(eval_panel)} 个 answer pairs，线程数: {MAX_WORKERS}")

    pair_records = eval_panel.to_dict("records")
    eval_results = []
    with ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_key = {executor.submit(process_single_pair, pd.Series(r)): r["cache_key"] for r in pair_records}
        with tqdm(total=len(pair_records), desc="LLM Extension Evaluation") as pbar:
            for future in as_completed(future_to_key):
                try:
                    eval_results.append(future.result())
                except Exception as e:
                    eval_results.append({"cache_key": future_to_key[future], "extension_score": None,
                                         "justification": None, "relationship_label": None,
                                         "error_reason": f"Future异常: {str(e)[:150]}"})
                pbar.update(1)

    result_df = pd.DataFrame(eval_results)
    output = eval_panel.merge(result_df, on="cache_key", how="left")

    feature_cols = ["questionURL", "resp_id", "cmnID", "dateID", "is_treatment", "anchor_source",
                    "anchor_resp_id", "anchor_cmnID", "anchor_dateID", "comparison_target",
                    "extension_score", "justification", "relationship_label",
                    "prompt_version", "model_name", "error_reason"]
    feature = output[feature_cols].copy()
    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    logger.info(f"已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
