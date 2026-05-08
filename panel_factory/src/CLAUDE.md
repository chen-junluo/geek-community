# panel_factory/src rules
- 不要重复实现前序步骤已经完成的处理逻辑。
  - 如果当前变量的生成需要依赖 raw-like source、某些 intermediate 或 feature，而这些 intermediate 或 feature 已经可以由 `src/` 下现有脚本生成，则默认优先复用已有产物。
  - 当前脚本应直接使用这些已有的 intermediate 或 feature 作为输入，不要在本文件中重复生成相同产物。
- `src/` 的核心结构
  - `features/`：生成 compact feature tables。
  - `panels/`：把 features late merge 到某个 intermediate 上，生成 final panel。
  - `utils/`：shared utilities。
- panel 构建原则
  - 不要在一个 full panel 上一路追加很多变量，再输出更大的 intermediate。
  - 优先保持 `intermediate`、`features`、`panel` 三层解耦。
  - panel builder 的职责应尽量收敛到：读取 intermediate、merge features、写出 panel。

- 命名与 artifact naming
  - `src/` 下的文件命名、artifact naming、变量命名，统一参考 `../documents/naming_conventions.md`。
  - 本文件不再重复内嵌 `build_xxx_intermediate.py`、`build_xxx.py`、`build_xxx_panel.py` 等命名细则。
  - 如需新增或修正 naming rule，应先更新 `../documents/naming_conventions.md`，再视需要调整本文件或上层 `CLAUDE.md` 的 reference。

- 每个 `build_*.py` 文件顶部默认应有简短 bullets，写清：
  - 本文件生成什么 artifact
  - 关键输入是什么
  - grain 是什么
  - merge keys 是什么

- 写新代码时的默认判断
  - 不要在 panel script 里重复生成已经可以独立生成的 feature。
  - 不要为了加一个变量，就在 full panel 上一路 mutate 出更多中间表。
  - 新变量如果能作为 compact feature 独立存在，就优先写成 feature builder。
  - panel builder 的职责应尽量收敛到：读取某个 intermediate，merge 所需 features，输出 final panel。

- 每次生成新 feature 后，默认反馈该 feature 的 descriptive statistics。
  - 至少包括 `min`、`max`、`mean`。大概告诉我这个变量的 distribution 的数值范围，让我了解这个变量分布是咋样的。
  - 默认补充若干 sample rows，优先看命中值为 `1` 的 case。注意如果sample爆长你不要直接输出，你简略告诉我就行保留关键要点，我只是想看是不是识别的准。
  - 不需要把描述性统计和sample什么的存成csv，直接在对话中告诉我。




---
---
## User-Specific Rules


- 运行 python 脚本
  - 不要直接从脚本文件路径裸调用 Python，否则可能报 `ModuleNotFoundError`。
  - 默认用 notebook 对应的解释器，并在 workspace 根目录下设置 `PYTHONPATH=/Users/dylanchen/Desktop/geek-community/panel_factory/src` 后再运行。
  - 例如：`PYTHONPATH=/Users/dylanchen/Desktop/geek-community/panel_factory/src /Users/dylanchen/miniconda3/envs/cityu/bin/python panel_factory/src/panels/build_question_panel.py`