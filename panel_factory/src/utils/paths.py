"""Canonical artifact path registry for geek-community panel_factory."""

import os

# panel_factory/data/ 的根目录（相对于 src/ 的上一级）
_BASE = os.path.join(os.path.dirname(__file__), "..", "..", "data")
_BASE = os.path.normpath(_BASE)

ARTIFACT_PATHS = {
    # raw-like source materials（只读）
    "raw": os.path.join(_BASE, "raw"),

    # standardized intermediates
    "intermediate": {
        "question": os.path.join(_BASE, "features", "question_intermediate.csv"),
        "human_answer": os.path.join(_BASE, "features", "human_answer_intermediate.csv"),
        "full_answer": os.path.join(_BASE, "features", "full_answer_intermediate.csv"),
        "question_misq": os.path.join(_BASE, "features", "question_intermediate_MISQ.csv"),
        "human_answer_misq": os.path.join(_BASE, "features", "human_answer_intermediate_MISQ.csv"),
        "full_answer_misq": os.path.join(_BASE, "features", "full_answer_intermediate_MISQ.csv"),
        # legacy alias，兼容旧 answer panel first-pass contract
        "answer": os.path.join(_BASE, "features", "human_answer_intermediate.csv"),
    },

    # compact feature tables。
    "features": {
        # answer-level LLM features
        "answer_llm_extension": os.path.join(_BASE, "features", "answer_llm_extension.csv"),
        "answer_llm_deviation": os.path.join(_BASE, "features", "answer_llm_deviation.csv"),
        "answer_accepted_answer_similarity": os.path.join(_BASE, "features", "answer_accepted_answer_similarity.csv"),
        "answer_accepted_answer_similarity_misq": os.path.join(_BASE, "features", "answer_accepted_answer_similarity_MISQ.csv"),
        "answer_lexicon_based_answer_metrics": os.path.join(_BASE, "features", "answer_lexicon_based_answer_metrics.csv"),
        # question-level similarity features
        "question_ai_human_similarity": os.path.join(_BASE, "features", "question_ai_human_similarity.csv"),
        "question_ai_human_code_similarity": os.path.join(_BASE, "features", "question_ai_human_code_similarity.csv"),
        "question_content_jaccard_overlap": os.path.join(_BASE, "features", "question_content_jaccard_overlap.csv"),
        "question_accepted_answer_similarity": os.path.join(_BASE, "features", "question_accepted_answer_similarity.csv"),
        "question_accepted_answer_similarity_misq": os.path.join(_BASE, "features", "question_accepted_answer_similarity_MISQ.csv"),
        # question-level human pairwise similarity（treatment: all humans; control: drop first human）
        "question_human_pairwise_similarity": os.path.join(_BASE, "features", "question_human_pairwise_similarity.csv"),
    },

    # final panels
    "panels": {
        "question": os.path.join(_BASE, "panels", "question_panel.csv"),
        "answer": os.path.join(_BASE, "panels", "answer_panel.csv"),
        "question_misq": os.path.join(_BASE, "panels", "question_panel_MISQ.csv"),
        "answer_misq": os.path.join(_BASE, "panels", "answer_panel_MISQ.csv"),
    },

    # LLM call cache directories（与 data/ 平级，不纳入 artifact 管理，已加入 .gitignore）
    "cache": {
        "llm_extension": os.path.join(_BASE, "..", ".cache", "llm_extension"),
        "llm_deviation": os.path.join(_BASE, "..", ".cache", "llm_deviation"),
    },
}
