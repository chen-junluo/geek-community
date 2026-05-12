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
- **Grain vs Intermediate 的区别**
  - **Grain**：从分析层面看的，即它属于哪个 level 的 panel
    - 四个核心 grain：`question`、`human_answer`、`full_answer`、`user_activity`
    - Grain 决定了 merge keys 和数据粒度
    - 例如：`human_answer` grain 的 merge keys 是 `questionURL × resp_id`
  - **Intermediate**：从数据生成角度看的，如果后续会被不断复用，那么它就是一个 Intermediate
    - Intermediate 是 base table，minimal processing
    - Feature 是 compact table，specific metrics
    - Panel 是 final table，late merge features onto intermediate
  - **命名规范**
    - Feature 文件名必须以 grain 开头：`{grain}_{feature_name}.csv`
    - Intermediate 文件名必须包含 `_intermediate` 后缀：`{grain}_intermediate.csv`
    - 列名也包含 grain prefix（除了 merge keys）
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
## Four principle when you are writing code
### 1. Think Before Coding
**Don't assume. Don't hide confusion. Surface tradeoffs.**
Before implementing:
- State your assumptions explicitly. If uncertain, ask.
- If multiple interpretations exist, present them - don't pick silently.
- If a simpler approach exists, say so. Push back when warranted.
- If something is unclear, stop. Name what's confusing. Ask.
### 2. Simplicity First
**Minimum code that solves the problem. Nothing speculative.**
- No features beyond what was asked.
- No abstractions for single-use code.
- No "flexibility" or "configurability" that wasn't requested.
- No error handling for impossible scenarios.
- If you write 200 lines and it could be 50, rewrite it.
Ask yourself: "Would a senior engineer say this is overcomplicated?" If yes, simplify.

### 3. Surgical Changes
**Touch only what you must. Clean up only your own mess.**
When editing existing code:
- Don't "improve" adjacent code, comments, or formatting.
- Don't refactor things that aren't broken.
- Match existing style, even if you'd do it differently.
- If you notice unrelated dead code, mention it - don't delete it.
When your changes create orphans:
- Remove imports/variables/functions that YOUR changes made unused.
- Don't remove pre-existing dead code unless asked.
The test: Every changed line should trace directly to the user's request.

### 4. Goal-Driven Execution
**Define success criteria. Loop until verified.**
Transform tasks into verifiable goals:
- "Add validation" → "Write tests for invalid inputs, then make them pass"
- "Fix the bug" → "Write a test that reproduces it, then make it pass"
- "Refactor X" → "Ensure tests pass before and after"
For multi-step tasks, state a brief plan:
```
1. [Step] → verify: [check]
2. [Step] → verify: [check]
3. [Step] → verify: [check]
```
Strong success criteria let you loop independently. Weak criteria ("make it work") require constant clarification.

---
## raw data 文件说明

- `data/raw/` 包含四个核心 CSV 文件，分别存储不同层面的数据
- **`cmn_base.csv`**
  - Grain: `questionURL × cmnID`
  - 内容：question + all answers 的 metadata（date、userURL、views、likes 等）
  - 筛选规则：`cmnID == 0` 为 question rows，`cmnID >= 1` 为 answer rows
  - 关键列：`questionURL`、`cmnID`、`date`、`userURL`、`views`、`focusNum`、`collectNum`、`netlikeNum`、`ask`、`answer`、`accept`
- **`cmn_content.csv`**
  - Grain: `questionURL × cmnID`
  - 内容：question + all answers 的文本内容
  - 筛选规则：`cmnID == 0` 为 question 原始文本，`cmnID >= 1` 为 answer 文本
  - 关键列：`questionURL`、`cmnID`、`content_full_text`、`content_withoutcode`、`content_code_text`、`content_CN_text`
- **`question_base.csv`**
  - Grain: `questionURL`
  - 内容：question-level metadata（tags、preAI indicator、ignoreAnsNum 等）
  - 关键列：`questionURL`、`tags`、`tagURL`、`preAI`、`ignoreAnsNum`、`crawldate`
- **`question_ai_content.csv`**
  - Grain: `questionURL`
  - 内容：question 下的 AI-generated answer 文本（如果存在）
  - 关键列：`questionURL`、`preAI-content_full_text`、`preAI-content_withoutcode`、`preAI-content_code_text`、`preAI-content_CN_text`
- **数据关系**
  - Question 原始文本：从 `cmn_content.csv` 筛选 `cmnID == 0`
  - AI answer 文本：从 `question_ai_content.csv` 读取 `preAI-content_full_text`
  - Human answer 文本：从 `cmn_content.csv` 筛选 `cmnID >= 1`
  - Question metadata：从 `cmn_base.csv` 筛选 `cmnID == 0`，merge `question_base.csv` 获取 tags 等额外信息
  
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
    - **Merge key 兼容性**：`human_answer_intermediate` 同时包含 `cmnID` 和 `resp_id` 两个 answer-level index
      - `resp_id`：canonical merge key，按 `questionURL` 内时间顺序从 1 递增，推荐用于新代码
      - `cmnID`：legacy merge key，来自 raw data，保留用于向后兼容
      - 两者都可用于 merge，但新 feature builders 应优先使用 `resp_id`
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
