"""Canonical artifact path registry for geek-community panel_factory."""

import os

# panel_factory/data/ 的根目录（相对于 src/ 的上一级）
_BASE = os.path.join(os.path.dirname(__file__), "..", "..", "data")
_BASE = os.path.normpath(_BASE)

ARTIFACT_PATHS = {
    # raw-like source materials（只读）
    "raw": os.path.join(_BASE, "raw"),

    # panel assembly 的 base artifact role。
    # 当前 intermediate contract 指向 data/features/ 下的 full intermediate artifacts。
    "intermediate": {
        "question": os.path.join(_BASE, "features", "question_intermediate.csv"),
        "answer":   os.path.join(_BASE, "features", "answer_intermediate.csv"),
    },

    # compact feature tables。
    # 注意：某些 artifact 既可以登记在 features，也可以同时承担某个 panel 的 intermediate role。
    "features": {
        # answer-level LLM features
        "answer_llm_extension":         os.path.join(_BASE, "features", "answer_llm_extension.csv"),
        "answer_llm_deviation":         os.path.join(_BASE, "features", "answer_llm_deviation.csv"),
        # question-level similarity features
        "question_ai_human_similarity": os.path.join(_BASE, "features", "question_ai_human_similarity.csv"),
        "question_ai_human_code_similarity": os.path.join(_BASE, "features", "question_ai_human_code_similarity.csv"),
        "question_content_jaccard_overlap": os.path.join(_BASE, "features", "question_content_jaccard_overlap.csv"),
        # question-level human pairwise similarity（treatment: all humans; control: drop first human）
        "question_human_pairwise_similarity": os.path.join(_BASE, "features", "question_human_pairwise_similarity.csv"),
    },

    # final panels
    "panels": {
        "question": os.path.join(_BASE, "panels", "question_panel.csv"),
        "answer":   os.path.join(_BASE, "panels", "answer_panel.csv"),
    },

    # LLM call cache directories（与 data/ 平级，不纳入 artifact 管理，已加入 .gitignore）
    "cache": {
        "llm_extension": os.path.join(_BASE, "..", ".cache", "llm_extension"),
        "llm_deviation": os.path.join(_BASE, "..", ".cache", "llm_deviation"),
    },
}
