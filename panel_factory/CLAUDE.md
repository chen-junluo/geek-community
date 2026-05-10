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

<!-- 在此添加你的 Projects 层特定规则 -->

---
## pipeline consistency enforcement

- 强制同步规则：当新建/修任何`build_*.py` 文件的时候，必须同步更新三处：
  1. **修改 `build_*.py` 文件的 structured header**
  2. **更新 `documents/pipeline_dependency_table.md` 的 graph 和 table**
- Structured Header 强制要求

- 所有 `build_*.py` 文件必须包含 structured header
- Header 格式必须严格遵守 `documents/build_file_header_template.md` 规范
- 修改代码逻辑时，必须同步更新 header
- Header 中的信息必须与实际代码逻辑一致

---
## treatment contract

- `preAI` 是整个 `panel_factory` pipeline 的 canonical treatment variable。
- 语义：`preAI == 1` 表示该 `questionURL` 属于 treatment，即 human answers 之前存在 AI answer；`preAI == 0` 表示 control。

---
## data grain 层次与 merge index contract

- 四个核心 grain 层次
  - **Question grain**: intermediate `question_intermediate.csv`，merge key `questionURL`，用于 question metadata / text / aggregations
  - **Human Answer grain**: intermediate `human_answer_intermediate.csv`，merge key `questionURL × resp_id`，用于 human-authored answers（不包含 AI answers）
  - **Full Answer grain**: intermediate `full_answer_intermediate.csv`，merge key `questionURL × answer_id`，用于 AI answer + human answers 的完整 answer universe
  - **User Activity grain**: intermediate `all_activities_intermediate.csv`，merge key `userURL × date × activity_type`，用于 user-level activities（post question / answer / receive likes 等）
- Feature 层命名规范
  - 所有 feature 文件名必须以 grain 开头：`{grain}_{feature_name}.csv`
  - 列名也包含 grain prefix（除了 merge keys）
  - 例如：`question_content_metrics.csv` 中的列为 `question_textLength`、`question_imgNum`
- Intermediate 数量控制
  - 严格限制为 4 个 intermediates，不再新增
  - 所有衍生变量归入 `features/`
  - Panel 层通过 late merge 组装
  - 目的：做解耦，一个 intermediate 可被多个 features 复用，一个 feature table 可被多个 panels / projects 复用，避免”每一步都 carry full table”的大表链式加工，减少 project-specific logic 混入 shared pipeline

---
## MISQ rule
- MISQ sample rule
  - 严格沿用 `Archive/round2_parser_for_panel.ipynb` 的 sample definition
  - 先在 question rows 上筛：`ask == 1` 且 `date >= 2023-01-01`
  - 再按 `questionURL` 保留这些 questions 对应的 whole thread
  - MISQ-specific intermediates / features / panels 必须只在这个 universe 内计算与 merge
  - 默认不要直接覆盖通用 panel builder，优先新增 `*_MISQ` builders 明确语义
- Default version rule
  - 当前默认使用带 `_MISQ` 后缀的 intermediates 和 panels
  - 所有新 feature、新 panel、新 project 默认基于 MISQ 版本构建
  - 不带 `_MISQ` 后缀的旧版本文件保留在原位置，但不再作为 active reference
  - 除非用户明确说明要做非 MISQ 项目，否则一律使用 MISQ 版本
