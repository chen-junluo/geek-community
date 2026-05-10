---
## 标准 Header Template

- 所有 `src/features/build_*.py` 和 `src/panels/build_*.py` 必须使用此模板
- 放在文件最顶部，作为 docstring
- 严格遵守格式，确保可自动化解析

---
## 模板格式

```python
# Artifact:    {intermediate|feature|panel}/{artifact_name}
# Grain:       {question|human_answer|full_answer|user_activity}
# Merge Keys:  {key1, key2, ...}
#
# Inputs:
#   - {input_artifact_1}  # {path or description}
#   - {input_artifact_2}
#
# Output:      {output_path}
#   - Index: {index_columns}
#   - Core: {core_columns}
#   - Derived: {derived_columns}
#
# Logic:
#   - {key_logic_point_1}
#   - {key_logic_point_2}
```

---
## 字段说明

- **Artifact**: `{intermediate|feature|panel}/{name}` 格式，例如 `intermediate/question_intermediate_MISQ`
- **Grain**: 只能是 `question`、`human_answer`、`full_answer` 或 `user_activity` 之一
- **Merge Keys**: 该 artifact 的 index columns，用于 merge 操作
- **Inputs**: 列出所有输入文件或 artifact，可附加路径或简短描述
- **Output**: 输出文件路径，紧接着列出输出列结构
  - **Index**: index columns
  - **Core**: 核心业务字段
  - **Derived**: 派生计算字段
- **Logic**: 关键处理逻辑，用 bullet points 简要描述

---
## 格式规则

- 使用纯 `#` 注释，不使用装饰性字符（`═`、`─`、`║` 等）
- 用缩进表达层级关系（2 空格）
- section 之间用一个空 `#` 行分隔
