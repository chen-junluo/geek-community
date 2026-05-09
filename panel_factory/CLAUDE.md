# CLAUDE.md

- `panel_factory/` 是 shared data pipeline，不是 project-specific analysis space
- 核心职责：从 raw 中，稳定地重建 reusable intermediate、features、final panels
- 代码来源听从用户指示，可以用 `Archive/` 重建，也可以根据自然语言指令

---
## 1. Working rules

- Prioritize consistency with the current notebook pipeline before improving logic
- Treat existing intermediate artifact names as contracts during the first migration pass
- Preserve write/read CSV boundaries when they affect downstream behavior
- Do not rename columns, merge keys, or staged output files unless all downstream consumers are updated together
- Keep raw data read-only

---
## 2. 核心概念与架构

- 主要逻辑：`raw data` → `feature tables` → `final panels`
  - panel 的构建，不是把所有逻辑都堆在一个大表上反复改
  - 更合适的方式：在某个 `intermediate` base table 上，late merge 多个 compact features，最后形成 panel
- 内部文件架构：
  - `data/raw/`：原始数据，只读
  - `data/features/`：生成的 feature 表，以及部分重要 intermediate
  - `data/panels/`：最终 panel 数据
  - `src/features/`：feature 生成脚本
  - `src/panels/`：panel 聚合脚本
  - `src/utils/`：shared utilities，例如 `paths`、registry、I/O helpers
  - `documents/`：可选参考文档
    - 作用：减少重复阅读、节省 token、方便复查
    - 不是必须层，也不是 rule source
    - 规则与协作方式以 `CLAUDE.md` 为准
    - 如果 `documents/` 与 `CLAUDE.md` 不一致，应优先修正或忽略 `documents/`
    - 当前默认参考：`documents/features_registry.md`、`documents/pipeline_dependency_table.md`、`documents/naming_conventions.md`
    - 如需修改或沉淀，不仅要更新对应 `documents/`，也要在合适层级的 `CLAUDE.md` 中补充 reference
  - `notebooks/`：dashboard-style orchestration，供用户手动运行 pipeline，调用 `src/` 下的各类 Python 脚本
    - 不要默认把 notebooks 当作一次性实验文件
    - 不要在未经说明的情况下把 notebook 工作流改写成别的交互方式

---
## 3. 写新代码时的默认判断

- 如果要加的是 reusable variable，先判断它是否应该成为一个独立 feature table
- 如果某段逻辑只是某个 project 的临时分析需求，不要直接写进 `panel_factory/`
- 如果当前目标只是组装一个 panel，不要顺手把 feature generation 也塞进 panel builder
- 如果已有 intermediate 或 feature 已能支持当前任务，直接复用，不要重复造轮子
- 涉及 artifact 依赖关系时，优先参考 `documents/pipeline_dependency_table.md`
- 涉及 `feature` 是否已存在、是否应复用时，优先参考 `documents/features_registry.md`

---
---
## User-Specific Rules

<!-- 在此添加你的 panel_factory 特定规则 -->

---
## treatment contract

- `preAI` 是整个 `panel_factory` pipeline 的 canonical treatment variable。
- 语义：`preAI == 1` 表示该 `questionURL` 属于 treatment，即 human answers 之前存在 AI answer；`preAI == 0` 表示 control。

---
## data grain 层次与 index contract

### 三个核心 grain 层次

1. **Question Level**
   - Grain: `questionURL`
   - 定义：每个 question post 作为一个观测单位
   - Intermediate: `question_intermediate.csv`
   - 用途：question metadata、question text、question-level features
   - 禁止使用 `question_id`，唯一标识就是 `questionURL`

2. **Human Answer Level (Response Level)**
   - Grain: `questionURL × resp_id`
   - 定义：每个 human-authored answer 作为一个观测单位
   - Intermediate: `human_answer_intermediate.csv`
   - Index 构造：按 `questionURL + date + cmnID` chronological order 生成 `resp_id`
   - 特点：
     - 只包含 human answers，不包含 AI answers
     - `resp_id` 从 1 开始递增，表示该 question 下第几个 human answer
     - `cmnID != 0`（`cmnID == 0` 是 question 本身，不算 answer）
     - `cmnID` 不是 chronological order，不能直接用于 sequencing

3. **All Answer Level (Full Answer Level)**
   - Grain: `questionURL × answer_id`
   - 定义：包含 AI answer + human answers 的完整 answer universe
   - Intermediate: `full_answer_intermediate.csv`
   - Index 构造：
     - AI answer: `answer_id = 1`，`resp_id = NaN`，`answer_source = "AI_answer"`
     - Human answers: `answer_id = resp_id + has_ai_answer`，`answer_source = "human_answer"`
   - 特点：
     - 统一 `answer_text` 字段（AI 用 `ai_answer_text`，human 用 `human_answer_text`）
     - 必须强区分 AI answer 与 human answer，不要混用 `answer_id` 与 `resp_id`
     - 如果某个 question 有 AI answer，human answers 的 `answer_id` 会整体 +1

### Index 使用规则

- Question-level features: merge key 是 `questionURL`
- Human-answer-level features: merge key 是 `questionURL × resp_id`
- All-answer-level features: merge key 是 `questionURL × answer_id`
- 新 index 默认按 `dateID` / chronological order 构造
- `cmnID` 不是 chronological order，不能拿来做 sequencing
- MISQ sample rule
  - 严格沿用 `Archive/round2_parser_for_panel.ipynb` 的 sample definition。
  - 先在 question rows 上筛：`ask == 1` 且 `date >= 2023-01-01`。
  - 再按 `questionURL` 保留这些 questions 对应的 whole thread。
  - MISQ-specific intermediates / features / panels 必须只在这个 universe 内计算与 merge。
  - 默认不要直接覆盖通用 panel builder，优先新增 `*_MISQ` builders 明确语义。
  
- **default version rule**
  - 当前默认使用带 `_MISQ` 后缀的 intermediates 和 panels。
  - 所有新 feature、新 panel、新 project 默认基于 MISQ 版本构建。
  - 不带 `_MISQ` 后缀的旧版本文件保留在原位置，但不再作为 active reference。
  - 除非用户明确说明要做非 MISQ 项目，否则一律使用 MISQ 版本。
  - 目的：减少版本混淆，避免重复工作，统一 pipeline 入口。
  - 为什么要这样做
    - 做解耦。base table、feature engineering、panel assembly 是不同层。
    - 一个 `intermediate` 可以被多个 features 复用。
    - 一个 feature table 也可以被多个 panels 或多个 projects 复用。
    - 避免“每一步都 carry full table”的大表链式加工。
    - 减少 project-specific logic 混入 shared pipeline。
