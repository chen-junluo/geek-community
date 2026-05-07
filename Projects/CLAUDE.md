# Projects-level rules
- 这个文件夹用于承接 downstream research projects，不是 shared pipeline 本体。
- 一个 data source、feature set 或 panel 可能服务多个 projects，所以 `Projects/` 与 `panel_factory/` 必须分离。
- 本文件只保留 `Projects/` 层的协作边界、任务路由与 document references。

---
## 1. Reference map
- project workspace 的默认目录结构与 stage conventions，参考 `Projects/Documents/project_workspace_structure.md`
- analysis script 的默认代码模板与 coding rules，参考 `Projects/Documents/analysis_script_template.md`
- analysis output conventions、result interpretation、failed-run handling 与 exploratory regression workflow，参考 `Projects/Documents/analysis_output_rules.md`
- 如后续需要沉淀新的 reusable rule，优先新增或更新 `Projects/Documents/*.md`，再由本文件建立稳定引用

---
## 2. Core boundaries
- `Projects/` 用于承接 downstream research projects，不是 shared pipeline 本体
- 项目分析代码不要与通用 pipeline 代码混淆
- 项目特定逻辑不要随意上移到 `panel_factory/`
- 写作材料、回归脚本、图表输出，应优先放在各自项目内部管理
- 如任务涉及 folder placement、stage layout、analysis/writeup/submission archive 的组织，参考 `Projects/Documents/project_workspace_structure.md`

---
## 3. Default workflow
- Claude 在 `Projects/` 下处理 analysis 任务时，默认按下面方式工作：
  - 读取现有 analysis script
  - 在现有文件基础上修改，或按需要新建 AI-friendly `.R` analysis script
  - 具体脚本模板与 coding rules，参考 `Projects/Documents/analysis_script_template.md`
  - 具体输出规则与 regression workflow，参考 `Projects/Documents/analysis_output_rules.md`
  - 运行对应分析
  - 读取保存到 `outputs/` 的结果
  - 在对话框中用简洁中文总结结果
  - 根据用户后续指示继续迭代现有文件，或新建新的分析文件
- 重点不是把代码写成展示型文档，而是让 analysis script：
  - AI 容易修改
  - 用户容易分块执行
  - 输出位置明确
  - 结果容易回读

---
## 4. Local override
- 如果某个 project、stage 或更低层级目录下存在自己的 `CLAUDE.md`，则该局部说明优先级更高
- 如用户在当前任务中给出更具体要求，以用户要求为准
