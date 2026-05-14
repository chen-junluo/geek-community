# Regression Reports Skill

## 功能
从 R 回归输出（HTML 格式）生成格式化的 Word 文档。

## 文件说明
- `skill.md`：Skill 定义和使用说明
- `generate_report_from_html.py`：主脚本，解析 HTML 并生成 Word 文档
- `example_usage.py`：使用示例

## 依赖
- Python 3.x
- `python-docx`
- `beautifulsoup4`

安装依赖：
```bash
pip3 install python-docx beautifulsoup4
```

## 使用方法

### 方法 1：直接运行主脚本
编辑 `generate_report_from_html.py` 中的 `html_files` 列表，然后运行：
```bash
python3 .claude/skills/regression-reports/generate_report_from_html.py
```

### 方法 2：使用示例脚本
编辑 `example_usage.py` 自定义输入输出，然后运行：
```bash
python3 .claude/skills/regression-reports/example_usage.py
```

### 方法 3：在 Claude 中调用
直接告诉 Claude："请生成回归报告"，Claude 会自动调用这个 skill。

## 输入格式
HTML 文件必须是 `texreg` 包生成的标准格式，包含：
- `<table class="texreg">` 标签
- 表头行（DV 名称）
- 系数行和标准误行（交替出现）
- 统计量行（Num. obs., F statistics 等）

## 输出格式
Word 文档包含：
- 两行表头（DV 名称 + 列编号）
- 每个变量占两行（系数 + 标准误）
- 统计量行
- Notes（Sample, DV, IV）

## 变量名映射
变量名映射表位于：`Documents/Notes/variable_mapping.md`

格式：
```
treatment → Treatment
log_textLengthCNAI_fillna → AI Length (log)
```

## 项目级常识
回归分析的项目级常识位于：`Documents/Notes/regression_conventions.md`

包含：
- 样本定义
- 变量命名模式
- 标准控制变量
- 标准 Fixed Effects
