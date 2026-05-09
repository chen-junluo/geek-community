# CLAUDE.md

- 不要重复实现前序步骤已经完成的处理逻辑
  - 如果当前变量的生成需要依赖 raw-like source、某些 intermediate 或 feature，而这些 intermediate 或 feature 已经可以由 `src/` 下现有脚本生成，则默认优先复用已有产物
  - 当前脚本应直接使用这些已有的 intermediate 或 feature 作为输入，不要在本文件中重复生成相同产物
- 每次交付时：
  - 默认要求每个代码文件内部是完整的、`self-consistent` 的
  - 不要出现注释描述、实际逻辑、命名含义彼此不一致的情况
- 对代码注释的处理：
  - 不要删除中英夹杂的现有注释
  - 这类注释通常包含 `context`、研究过程信息或 `domain knowledge`
  - 如果代码改动改变了这些注释的含义，应更新内容，而不是直接删掉
- 我看重 canonical source clarity
  - 优先复用上游有的变量，避免重复 alias，避免 downstream 误读和缺失值污染

---
## 1. `src/` 的核心结构

- `features/`：生成 compact feature tables
- `panels/`：把 features late merge 到某个 intermediate 上，生成 final panel
- `utils/`：shared utilities

---
## 2. Panel 构建原则

- 不要在一个 full panel 上一路追加很多变量，再输出更大的 intermediate
- 优先保持 `intermediate`、`features`、`panel` 三层解耦
- panel builder 的职责应尽量收敛到：读取 intermediate、merge features、写出 panel

---
## 3. 命名与 artifact naming

- `src/` 下的文件命名、artifact naming、变量命名，统一参考 `../documents/naming_conventions.md`
- 本文件不再重复内嵌 `build_xxx_intermediate.py`、`build_xxx.py`、`build_xxx_panel.py` 等命名细则
- 如需新增或修正 naming rule，应先更新 `../documents/naming_conventions.md`，再视需要调整本文件或上层 `CLAUDE.md` 的 reference

---
## 4. 每个 `build_*.py` 文件顶部默认应有简短 bullets

- 本文件生成什么 artifact
- 关键输入是什么
- grain 是什么
- merge keys 是什么
- 修改代码文件时：
  - 如果改动影响了现有注释，尤其是文件顶部注释，必须同步更新对应注释
  - 保持 `code`、`comment`、`variable naming` 三者一致，不要在同一文件内留下局部不一致状态

---
## 5. 写新代码时的默认判断

- 不要在 panel script 里重复生成已经可以独立生成的 feature
- 不要为了加一个变量，就在 full panel 上一路 mutate 出更多中间表
- 新变量如果能作为 compact feature 独立存在，就优先写成 feature builder
- panel builder 的职责应尽量收敛到：读取某个 intermediate，merge 所需 features，输出 final panel
- 对于非生成feature的，简单的查询检索的任务，直接后台撰写代码然后告诉我结果。**如无要求，不要在本地写入py文件和报告！**

---
## 6. 每次生成新 feature 后，默认反馈该 feature 的 descriptive statistics

- 至少包括 `min`、`max`、`mean`
- 大概告诉我这个变量的 distribution 的数值范围，让我了解这个变量分布是咋样的
- 默认补充若干 sample rows，优先看命中值为 `1` 的 case
- 注意如果 sample 爆长你不要直接输出，你简略告诉我就行保留关键要点，我只是想看是不是识别的准
- 不需要把描述性统计和 sample 什么的存成 csv，直接在对话中告诉我

---
## 7. 运行 python 脚本

- 不要直接从脚本文件路径裸调用 Python，否则可能报 `ModuleNotFoundError`
- 默认用 notebook 对应的解释器，并在 workspace 根目录下设置 `PYTHONPATH=/Users/dylanchen/Desktop/current_folder_name/panel_factory/src` 后再运行
- 例如：`PYTHONPATH=/Users/dylanchen/Desktop/current_folder_name/panel_factory/src /Users/dylanchen/miniconda3/envs/cityu/bin/python panel_factory/src/panels/build_question_panel.py`

---
---
## User-Specific Rules

<!-- 在此添加你的 src 层特定规则 -->