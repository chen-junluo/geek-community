# Sync CLAUDE.md from Upstream

## 使用场景

当你 fork 了这个 repo 并在本地工作时，可以用这个脚本同步上游的 `CLAUDE.md` 更新，同时保留你自己的规则。

---

## 快速开始

### 1. 添加 upstream remote（首次）

```bash
git remote add upstream https://github.com/原作者/repo名.git
```

### 2. 运行同步脚本

```bash
./scripts/sync-claude-md.sh
```

### 3. 检查并提交

```bash
git diff                    # 查看变更
git add .                   # 如果满意
git commit -m "Sync CLAUDE.md from upstream"
```

---

## 工作原理

### 文件结构

每个 `CLAUDE.md` 分为两部分：

```markdown
# CLAUDE.md

...upstream 维护的通用规则...

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
```

- `## User-Specific Rules` 之前：upstream 规则，会被同步覆盖
- `## User-Specific Rules` 之后：你的自定义规则，永远不会被覆盖

### 同步逻辑

脚本会：
1. 从 upstream 拉取最新的 `CLAUDE.md`
2. 提取你本地的 `## User-Specific Rules` 部分
3. 用 upstream 的内容替换 marker 之前的部分
4. 保留你的 user-specific 部分不变

---

## 高级用法

### 指定不同的 remote 或 branch

```bash
./scripts/sync-claude-md.sh origin main
./scripts/sync-claude-md.sh upstream dev
```

### 添加自己的规则

在任何 `CLAUDE.md` 的 `## User-Specific Rules` 部分下添加：

```markdown
## User-Specific Rules

- 我的项目用 `polars` 而不是 `pandas`
- 所有回归用 `fixest` 包
- 图表输出到 `output/figures/` 而不是 `figures/`
```

这些规则会在同步时被保留。

---

## 注意事项

- 同步前建议先 commit 当前工作，以便回滚
- 同步后用 `git diff` 检查变更是否符合预期
- 如果 upstream 没有某个 `CLAUDE.md` 文件，会跳过不处理
- 脚本只修改 `CLAUDE.md` 文件，不影响其他内容
