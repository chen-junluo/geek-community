---
name: regression-reports
description: Generate formatted Word documents from R regression code. Automatically adds HTML output logic if missing, runs the code, parses HTML tables, applies variable name mapping, and creates publication-ready regression reports.
trigger: Use when the user selects R regression code and asks to generate reports, output tables, or create Word documents from regression results.
---

# Regression Reports Skill

## Purpose
- 从用户选中的 R 回归代码自动生成 Word 文档
- 如果代码缺少 HTML 输出逻辑，自动添加 `htmlreg()` 输出
- 运行代码生成 HTML 文件
- 解析 HTML 表格并应用变量名映射
- 生成格式化的回归报告

## When to Use
- 用户选中 R 回归代码并要求生成报告
- 用户要求输出回归表格到 Word
- 用户提供回归代码并说"生成报告"

## Prerequisites
执行前必须读取：
- `Documents/Notes/variable_mapping.md`：变量名映射表
- `Documents/Notes/regression_conventions.md`：回归分析项目级常识

## Workflow

### 1. 检查用户选中的代码
- 识别 `models <- list()` 块
- 识别 section title（`##############` 包围的注释）
- 检查是否有 HTML 输出逻辑

### 2. 补充 HTML 输出逻辑（如果缺失）
如果代码只有 `screenreg()` 或 `print(screenreg())`，添加：
```r
# Save to HTML
htmlreg(models, 
        file = "outputs/[section_name]_[sample_name].html",
        stars = c(0.1, 0.05, 0.01, 0.001),
        digits = 3,
        include.fstatistic = TRUE,
        include.adjrs = FALSE,
        include.rsquared = FALSE,
        robust = TRUE,
        include.groups = FALSE,
        single.row = FALSE,
        omit.coef = omit_pattern
)
```

### 3. 运行 R 代码
- 执行修改后的代码
- 生成 HTML 文件到 `outputs/` 目录

### 4. 解析 HTML 并生成 Word
- 读取生成的 HTML 文件
- 应用变量名映射
- 生成 Word 文档

### 5. Word 文档格式
- **表格样式**：黑白简洁样式，无彩色背景
- **Section 结构**：
  - 一个 section title 下可以有多个 table
  - 同一 section 的多个 table 共享一个 title
- **分页**：section 之间插入分页符
- **表头**：
  - 第一行：`DV: [变量名]`（跨列合并）
  - 第二行：`(1)` `(2)` `(3)` ...
- **数据行**：每个变量占两行（系数 + 标准误）
- **统计量**：直接接在系数后，无空行
- **Notes**：紧凑的 bullet points（Sample, DV, IV）

## Section 识别规则
从代码注释中识别 section：
```r
##############################################
######## [Section Title]
##############################################
```

同一 section 下的所有 `models <- list()` 块共享一个 section title。

## Sample 识别规则
从 `data = ` 参数识别样本：
- `mydata_answer` → "All human answers"
- `mydata_answer_firstHumanAns` → "First human answer only"
- 其他：从 `regression_conventions.md` 查找

## Notes
- 自动推断 DV 类型（从变量名判断 continuous/binary）
- 自动提取 IV（treatment 及其交互项）
- 输出文件名格式：`[section_name]_[sample_name].html`
- 最终 Word 文档保存在 `outputs/regression_report.docx`

## Files
- `generate_report_from_html.py`：解析 HTML 并生成 Word
- `run_and_generate_report.py`：完整 workflow（检查代码 → 运行 → 生成报告）
