# CLAUDE.md

- 这是一个科研项目 workspace，不是单一项目仓库。当前 workspace 主要包含三类内容：
  - `Archive/`：legacy materials。这里放旧 analysis scripts、旧 panel、旧 tables / figures、旧 writeup。主要用于参考，不应默认视为当前主流程。
  - `panel_factory/`：shared data pipeline。用于从 raw data 生成 features，再将 features 合并为 panels。
  - `Projects/`：downstream research spaces。项目分析、回归、写作等工作原则上应建立在 `panel_factory/` 产出的数据之上。


---
## 1. 项目文件夹和架构详细介绍

- `panel_factory/` 的核心概念
  - 主要的逻辑是读取 raw data -> 生成 feature tables -> 将 feature tables 合并为最终 panels。注意 panel 的构建，不是把所有逻辑都堆在一个大表上反复改。更合适的方式是：在某个 `intermediate` base table 上，late merge 多个 compact features，最后形成 panel。
  - 内部文件架构如下：
    - `data/raw/`：原始数据，只读
    - `data/features/`：生成的 feature 表，以及部分重要 intermediate
    - `data/panels/`：最终 panel 数据
    - `src/features/`：feature 生成脚本
    - `src/panels/`：panel 聚合脚本
    - `src/utils/`：shared utilities，例如 `paths`、registry、I/O helpers。
    - `documents/`：可选参考文档。作用是减少重复阅读、节省 token、方便复查。这里的内容不是必须层，也不是 rule source。规则与协作方式以 `CLAUDE.md` 为准；如果 `documents/` 与 `CLAUDE.md` 不一致，应优先修正或忽略 `documents/`。如果某些内容需要修改或沉淀，不仅要更新对应 `documents/`，也要在合适层级的 `CLAUDE.md` 中补充 reference，确保这些参考文档能被稳定引用。
    - `notebooks/`：用于 dashboard-style orchestration、供用户手动运行 pipeline，调用 `src/` 下的各类 Python 脚本。不要默认把 notebooks 当作一次性实验文件，也不要在未经说明的情况下把 notebook 工作流改写成别的交互方式。

- `projects/`
  - 这里存放具体研究项目。每个项目文件夹通常包括：项目说明、决策记录与待办、分阶段的 analysis、分阶段的 writeup
  - 这些项目文件夹是 `panel_factory/` 下游的研究工作区，不是共享数据处理框架本身。因此：
    - 项目分析代码不要与通用 pipeline 代码混淆
    - 项目特定逻辑不要随意上移到 `panel_factory/`
    - 写作材料、回归脚本、图表输出，应优先放在各自项目内部管理
  - `Projects/` 层的 analysis code writing rules、默认 script template 与 output conventions，统一由 `Projects/Documents/analysis_script_template.md` 承接；`Projects/CLAUDE.md` 负责建立引用，不再内嵌冗长模板。

- `archive/`
  - 这里是迁移前的旧架构内容和历史项目材料。
  - 用途：回溯旧逻辑、查找历史脚本或中间结果、对照迁移前后的处理方式
  - 默认规则：
    - `archive/` 不是当前主流程
    - 不要默认把 `archive/` 中的代码当作最新版本
    - 如需复用旧逻辑，应先与 `panel_factory/` 当前实现核对
  - 如任务涉及任何数字化转型、reconstruction、legacy workflow 拆解、迁移前逻辑梳理，立即参考 `Archive/CLAUDE.md`

---
## 2. 默认工作边界

除非用户明确要求，否则不要自动进行以下操作：
- 不要为了“更整洁”而重命名文件夹
- 不要自动重组 workspace 结构
- 不要随意改动 raw data
- 不要轻易修改 feature 名称、列名、merge keys、输出文件名
- 不要把 `archive/` 误当作当前生产代码
- 不要把项目内部分析逻辑直接混入 `panel_factory/`
- 不要未经说明就重写 notebook 驱动的工作方式

---
## 3. 任务定位规则

当用户提出任务时，先按下面的方式定位：
- 如果任务涉及 raw data、feature 生成、panel 构建、pipeline 工具函数，优先查看 `panel_factory/`
- 如果任务涉及回归、实证分析、表图输出、论文写作，优先查看 `projects/`
- 如果任务涉及历史版本、旧架构、迁移前逻辑，查看 `archive/`
- 如果任务涉及任何数字化转型、reconstruction、legacy workflow 拆解、迁移前逻辑梳理，除查看 `archive/` 外，还要优先遵守 `Archive/CLAUDE.md`

---

## 4. 局部说明优先

如果某个子文件夹下还有自己的 `CLAUDE.md`，则该局部文件夹内的说明优先级更高。
例如在 `panel_factory/` 内工作时，应同时遵守 `panel_factory/CLAUDE.md` 的要求。
- 协作风格
  - 中文简洁描述内容，technical terms 用 English。
  - 当结构不清晰时，先列 inventory，再提 reconstruction plan。
  - 优先尊重已有 artifact names、merge keys、output boundaries，再逐步优化。

---
## 5. 同步 upstream CLAUDE.md 更新

- 如果用户 fork 了这个 template 并想同步上游的 `CLAUDE.md` 更新，运行 `./scripts/sync-claude-md.sh`
- 工作原理：
  - 所有 `CLAUDE.md` 文件分为两部分：`## User-Specific Rules` marker 之前是 upstream 规则，之后是用户自定义规则
  - sync script 会从 upstream 拉取最新规则，替换 marker 之前的部分，保留 marker 之后的用户规则
- 使用步骤：
  ```bash
  # 首次设置（如果还没有 upstream remote）
  git remote add upstream https://github.com/chen-junluo/smart_research_folder_template.git

  # 同步更新
  ./scripts/sync-claude-md.sh

  # 检查变更
  git diff

  # 提交
  git add .
  git commit -m "Sync CLAUDE.md from upstream"
  ```
- 当用户要求同步 CLAUDE.md 或更新 upstream 规则时，直接运行这个 script

---
---
## User-Specific Rules

### Regression Reports
- 当用户要求输出回归表格时，使用 Regression Reports workflow
- 执行前必须读取 `Documents/Notes/regression_conventions.md` 和 `Documents/Notes/variable_mapping.md`
- 基于变量映射表进行文本替换，确保 Word 输出的表格使用可读的变量名
- Notes 格式：紧凑的 bullet points，包含 Sample、DV、IV 定义，不包含 controls/FE 细节
