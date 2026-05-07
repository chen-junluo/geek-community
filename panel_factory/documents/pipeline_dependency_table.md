---
## 1. pipeline dependency table
- 作用
  - 记录 `intermediate`、`feature`、`panel` 之间的依赖关系，帮助 reconstruction、验收、以及下游 AI 分派。
  - 这是参考文档，不是 rule source；规则仍以 `CLAUDE.md` 为准。
- 使用规则
  - 当新增 artifact、修改依赖关系、或重构 pipeline 时，应同步更新本文件。
  - 如果依赖关系调整会影响协作方式或默认判断，还应在对应 `CLAUDE.md` 中补充 reference。

---
## 2. dependency table
| artifact_key | kind | depends_on | built_by | output_path | notes |
| --- | --- | --- | --- | --- | --- |
| `example_intermediate` | `intermediate` | `raw source` | `build_example_intermediate.py` | `data/features/example_intermediate.parquet` | replace with actual artifact |
| `example_feature` | `feature` | `example_intermediate` | `build_example_feature.py` | `data/features/example_feature.parquet` | replace with actual artifact |
| `example_panel` | `panel` | `example_intermediate`, `example_feature` | `build_example_panel.py` | `data/panels/example_panel.parquet` | replace with actual artifact |
