---
name: regression-reports
description: Generate formatted Word documents from R regression HTML tables. Workflow: align HTML export naming and model labels in R, user runs R manually, then Claude parses HTML tables, applies variable mappings, and creates a publication-ready Word report.
trigger: Use when the user wants a Word regression report from R `htmlreg()` outputs, or wants help patching an R regression script so its HTML outputs can be turned into a report.
---

# Regression Reports Skill

## Purpose
- 把 `htmlreg()` 导出的 regression HTML tables 转成格式统一的 `Word report`
- 在需要时，先帮用户修改现有 `R` 脚本
  - 补上缺失的 `htmlreg()` 输出
  - 把 `models` 的列标题手动改成真正的 `DV label`
- 再由用户手动运行 `R`
- 最后由 Claude 读取生成好的 `HTML`，结合 `variable_mapping.md` 输出最终 `docx`

## When to Use
- 用户要把 `R regression` 结果整理成 `Word report`
- 用户要你检查或补 `htmlreg()` 输出逻辑
- 用户已经有 `HTML regression tables`，要你直接生成 `docx`

## Required reads
- 执行前必须读取：
  - `Documents/regression-reports/variable_mapping.md`
  - `Documents/regression-reports/regression_conventions.md`

## Workflow

### 1. Clarify scope with the user
- 先确认：
  - 哪些 `section` 要进 report
  - 每个 `section` 下有几个 `models <- list()` block
  - 输出 `HTML` 文件名
  - 最终 `docx` 文件名
- 如果变量名、文件名、section title 不清楚，先和用户敲定再改代码。敲定之后，更新对应的 `Documents/regression-reports/variable_mapping.md` 文档。

### 2. Patch the R file
- 只做两类最小修改：
  - 为每个 `models <- list()` block 补 `htmlreg()` 输出（如果缺失）
  - 把 `models[[...]]` 的列标题改成真正的 `DV label`
- 目标：让 `HTML` 本身就携带正确的 `DV` 名字，而不是后处理时猜测
- `DV label` 处理规则：
  - 不要保留 `OLS: ...`、`Cox: ...`、`No Interaction` 这类 `model labels` 作为 `DV`
  - 要手动把 `models[[...]]` 改成该列真正对应的因变量，例如：
    - `Experience Binary`
    - `Insight Binary`
    - `Alternative Binary`
    - `Answer 1–2 Similarity`
    - `Human 1–2 Similarity`
    - `Answer Count within 7 Days (log)`
    - `Human Answer Hazard`
- `HTML` 文件命名规则：
  - 先和用户确认
  - 默认遵守用户习惯：`meeting` 或 `explore` + `YYMMDD`/`260509` 这类六位日期 + descriptive suffix
  - 不要擅自发明命名

### 3. Required htmlreg style
- 如果要补 `htmlreg()`，默认严格使用下面这种紧凑格式，只改 `file` 路径：
```r
htmlreg(models,
  file = "Projects/.../outputs/meeting260505_example.html",
          stars = c(0.1, 0.05, 0.01, 0.001),
          digits = 3, dcolumn = TRUE, threeparttable = TRUE, fontsize = "tiny",
          include.fstatistic = TRUE, include.adjrs = FALSE, include.rsquared = FALSE, robust = TRUE,
          include.groups = FALSE, single.row = FALSE,
          omit.coef = omit_pattern
)
```
- 一个 `models <- list()` block 对应一个 `htmlreg()` 输出
- 不要把多个 block 误合并到一个 `HTML`

### 4. User runs R manually
- `HTML` 输出主要由用户自己手动 `run R` 完成
- Claude 默认不负责主动运行 `R`，除非用户另行明确要求

### 5. Generate the report after HTML exists
- 用户告诉你 `HTML` 已生成后：
  - 读取实际存在的 `HTML files`
  - 为本次任务临时写一个很小的 `Python runner`
  - 这个 runner：
    - 指定本次 `HTML` 列表
    - 指定 `section title / sample / DV / IV`
    - 调用 skill 内核心脚本
  - 不要把这个 task-specific runner 永久保存在 skill 目录里
  - 直接在背后执行，仅用于本次 report generation

## Core script responsibility
- skill 目录里长期保留的核心执行文件只有：
  - `generate_report_from_html.py`
- 这个文件负责：
  - 解析 `HTML regression table`
  - 应用 `variable mapping`
  - 生成 `Word table`
  - 输出最终 `docx`
- 每次具体项目的 `HTML file list / section config / output path`
  - 由 Claude 针对当次任务临时生成 runner
  - 不固化到 skill 目录

## Word formatting rules
- 表格样式：黑白简洁，不做多余美化
- `section` 之间分页
- 同一 `section` 下可有多个 tables，共享一个 `section title`
- Notes 使用紧凑 bullet points：
  - `Sample`
  - `DV`
  - `IV`
- `DV` 显示规则：
  - 优先使用已经在 `R models[[...]]` 中手动改好的真实 `DV label`
  - 不要把 `model specification label` 当 `DV`

## Current design decisions
- 保留 `generate_report_from_html.py`
- 不在 skill 目录中保留 task-specific runner 模板文件
- 不保留 `README.md`
- 不保留 `example_usage.py`
- `generate_report_from_html.py` 不应该再带一个绑定旧路径的 demo workflow

## Things Claude should double-check
- `HTML` 数量是否等于 `models <- list()` block 数量
- `HTML` 文件名是否和用户确认过的 naming scheme 一致
- `models[[...]]` 是否已经被手动改成真实 `DV`
- `variable_mapping.md` 是否已覆盖新变量
- 本次 runner 的输出路径是否就是用户指定的 `outputs/` folder
