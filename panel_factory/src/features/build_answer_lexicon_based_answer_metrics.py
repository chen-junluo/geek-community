# Artifact:  feature/answer_lexicon_based_answer_metrics
# 输入:      data/features/human_answer_intermediate_MISQ.csv, data/features/full_answer_intermediate_MISQ.csv
# Grain:     human-answer-level (questionURL × resp_id)
# Merge keys: questionURL, resp_id
# 输出:      data/features/answer_lexicon_based_answer_metrics.csv
#
# 逻辑：在 MISQ human-response universe 内，用中文技术社区语境下的 rule-based lexicon
#       识别回答中的 personal experience 表达，先产出可扩展的 lexicon-based answer metrics。

import os
import re

import pandas as pd

from utils.paths import ARTIFACT_PATHS


OUTPUT_CSV = ARTIFACT_PATHS["features"]["answer_lexicon_based_answer_metrics"]
os.makedirs(os.path.dirname(OUTPUT_CSV), exist_ok=True)

METHOD = "lexicon_rule_based"
VERSION = "segmentfault_cn_v1"

DIRECT_PATTERNS = [
    r"我遇到过",
    r"我碰到过",
    r"我踩过",
    r"我踩坑",
    r"我试过",
    r"我试了",
    r"我用过",
    r"我用了",
    r"我之前",
    r"我当时",
    r"我这边",
    r"我自己(?:的)?经验",
    r"我项目里",
    r"我项目中",
    r"我在线上",
    r"我在生产",
    r"我本地复现",
    r"我复现过",
    r"我排查过",
    r"我处理过",
    r"我改成",
    r"我改成了",
    r"我后来",
    r"我最后",
    r"后来发现",
    r"最后发现",
    r"折腾了",
    r"踩坑",
    r"教训",
    r"经验是",
]

FIRST_PERSON_CONTEXT_PATTERNS = [
    r"我的(?:项目|服务|代码|场景|环境|机器|应用|系统|经验)",
    r"我在(?:项目|公司|线上|生产|本地|服务里|业务里|开发中|开发时)",
    r"我(?:测试下来|排查下来|实践下来|观察下来|处理下来)",
    r"我(?:发现|确认|定位到|复现了|解决了)",
]

EXCLUSION_PATTERNS = [
    r"建议你",
    r"你可以",
    r"一般来说",
    r"通常情况下",
    r"理论上",
]


_DIRECT_REGEXES = [re.compile(pattern) for pattern in DIRECT_PATTERNS]
_CONTEXT_REGEXES = [re.compile(pattern) for pattern in FIRST_PERSON_CONTEXT_PATTERNS]
_EXCLUSION_REGEXES = [re.compile(pattern) for pattern in EXCLUSION_PATTERNS]


def _normalize_text(text) -> str:
    if pd.isna(text):
        return ""
    text = str(text).strip().lower()
    text = re.sub(r"\s+", " ", text)
    return text


def _count_personal_experience_matches(text: str) -> int:
    direct_hits = sum(1 for regex in _DIRECT_REGEXES if regex.search(text))
    context_hits = sum(1 for regex in _CONTEXT_REGEXES if regex.search(text))
    return direct_hits + context_hits


def _looks_like_only_generic_advice(text: str, match_count: int) -> bool:
    if match_count == 0:
        return False
    has_exclusion = any(regex.search(text) for regex in _EXCLUSION_REGEXES)
    has_first_person = "我" in text
    return has_exclusion and not has_first_person


def _detect_personal_experience(text) -> tuple[int, int, str]:
    normalized = _normalize_text(text)
    if not normalized:
        return 0, 0, "empty_text"

    match_count = _count_personal_experience_matches(normalized)
    if _looks_like_only_generic_advice(normalized, match_count):
        return 0, 0, "generic_advice_only"

    return int(match_count > 0), match_count, ""


def build() -> pd.DataFrame:
    human_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["human_answer_misq"])
    full_answer = pd.read_csv(ARTIFACT_PATHS["intermediate"]["full_answer_misq"])

    # 从 full_answer 中提取 human answer 的文本
    human_text = (
        full_answer[full_answer["answer_source"] == "human_answer"]
        [["questionURL", "resp_id", "answer_text"]]
        .drop_duplicates(["questionURL", "resp_id"])
    )

    feature = human_answer[["questionURL", "resp_id", "cmnID"]].copy()
    feature = feature.merge(human_text, on=["questionURL", "resp_id"], how="left")
    feature = feature.rename(columns={"answer_text": "human_answer_text"})

    detected = feature["human_answer_text"].apply(_detect_personal_experience)
    feature[[
        "lexicon_personal_experience_binary",
        "lexicon_personal_experience_match_count",
        "lexicon_personal_experience_error_reason",
    ]] = pd.DataFrame(detected.tolist(), index=feature.index)

    feature["lexicon_personal_experience_method"] = METHOD
    feature["lexicon_personal_experience_version"] = VERSION

    feature = feature[[
        "questionURL",
        "resp_id",
        "cmnID",
        "lexicon_personal_experience_binary",
        "lexicon_personal_experience_match_count",
        "lexicon_personal_experience_method",
        "lexicon_personal_experience_version",
        "lexicon_personal_experience_error_reason",
    ]]

    feature.to_csv(OUTPUT_CSV, index=False, encoding="utf-8-sig")
    print(f"answer_lexicon_based_answer_metrics 已保存: {OUTPUT_CSV}  shape={feature.shape}")
    return feature


if __name__ == "__main__":
    build()
