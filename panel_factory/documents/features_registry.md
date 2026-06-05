---
## 1. feature registry
- 作用
  - 记录 `feature` artifacts 的最小注册信息，减少重复阅读与重复造轮子。
  - 这是参考文档，不是 rule source；规则仍以 `CLAUDE.md` 为准。
- 使用规则
  - 新增或重构 `feature` 时，优先检查这里是否已有可复用条目。
  - 如果 `feature` contract 发生变化，应同步更新本文件与相关 `CLAUDE.md` reference。

---
## 2. registry table
| feature_name | grain | merge_keys | built_by | output_path | notes |
| --- | --- | --- | --- | --- | --- |
| `question_content_metrics` | `question` | `questionURL` | `build_question_content_metrics.py` | `data/features/question_content_metrics.csv` | canonical question-side content feature built from `cmn_content.csv` question rows (`cmnID == 0`); outputs `question_*` metrics and separate `question_preAI_*` AI-side metrics |
| `human_answer_content_metrics` | `human_answer` | `questionURL`, `cmnID` | `build_human_answer_content_metrics.py` | `data/features/human_answer_content_metrics.csv` | canonical human-answer content feature; outputs raw content metric names (`textLength`, `codeLength`, etc.) with no extra builder-added prefix |
| `question_aggregation_from_answers` | `question` | `questionURL` | `build_question_aggregation_from_answers.py` | `data/features/question_aggregation_from_answers.csv` | question-level aggregation from human answers; consumes canonical `human_answer_content_metrics` and late-merges `question_content_metrics` for ask-side content fields |
| `question_llm_ground_truth_similarity_MISQ` | `question` | `questionURL` | `build_question_llm_ground_truth_similarity_MISQ.py` | `data/features/question_llm_ground_truth_similarity_MISQ.csv` | MISQ question-level GT similarity feature; current default runs `claude_opus_4_7` via custom API base `https://claude.tokencode.fun/v1`, caches per-model generated answers, and writes reserved wide columns for optional alternate models |
| `question_answer_timing_counts_MISQ` | `question` | `questionURL` | `build_question_answer_timing_counts_MISQ.py` | `data/features/question_answer_timing_counts_MISQ.csv` | MISQ question-level raw-thread timing counts from `cmn_base.csv`; first inherit the canonical MISQ question universe, then build chronological `dateID_temp` by sorting `date, cmnID`, count answers within 1/2/3/7/14 days of question post, and count post-first-answer answers within 1/2/3/7/14 days excluding the first answer itself |
| `human_answer_accepted_answer_anchor_flag_MISQ` | `human_answer` | `questionURL`, `resp_id` | `build_human_answer_accepted_answer_anchor_flag_MISQ.py` | `data/features/human_answer_accepted_answer_anchor_flag_MISQ.csv` | MISQ answer-level anchor-membership flag; reuses the exact accepted-answer similarity anchor selection logic and marks all selected anchors as `1`, including tied multi-anchor cases |
