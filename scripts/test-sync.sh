#!/bin/bash
# test-sync.sh
# 测试 sync-claude-md.sh 脚本的功能

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_DIR="${SCRIPT_DIR}/test_sync"

echo "🧪 Testing sync-claude-md.sh..."
echo ""

# 清理旧测试目录
if [ -d "$TEST_DIR" ]; then
    rm -rf "$TEST_DIR"
fi

# 创建测试环境
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

# 初始化 git repo
git init -q -b main
git config user.email "test@example.com"
git config user.name "Test User"

# 创建测试文件结构
mkdir -p subdir

# 创建初始 CLAUDE.md（模拟 upstream）
cat > CLAUDE.md << 'EOF'
# CLAUDE.md

Upstream rule 1
Upstream rule 2

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
EOF

cat > subdir/CLAUDE.md << 'EOF'
# CLAUDE.md

Subdir upstream rule 1

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
EOF

# 提交到 main
git add .
git commit -q -m "Initial commit"

# 创建 "fork" - 新分支模拟用户的 fork
git checkout -q -b user-fork

# 用户添加自己的规则
cat > CLAUDE.md << 'EOF'
# CLAUDE.md

Upstream rule 1
Upstream rule 2

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
- My custom rule 1
- My custom rule 2
EOF

cat > subdir/CLAUDE.md << 'EOF'
# CLAUDE.md

Subdir upstream rule 1

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
- Subdir custom rule
EOF

git add .
git commit -q -m "Add user rules"

# 模拟 upstream 更新
git checkout -q main

cat > CLAUDE.md << 'EOF'
# CLAUDE.md

Upstream rule 1 (updated)
Upstream rule 2
Upstream rule 3 (new)

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
EOF

cat > subdir/CLAUDE.md << 'EOF'
# CLAUDE.md

Subdir upstream rule 1 (updated)
Subdir upstream rule 2 (new)

---
---
## User-Specific Rules

<!-- 在此添加你的项目特定规则 -->
EOF

git add .
git commit -q -m "Update upstream rules"

# 回到 user fork
git checkout -q user-fork

# 设置 upstream remote（指向同一个 repo 的 main 分支）
git remote add upstream .

echo "✓ Test environment created"
echo ""

# 运行 sync 脚本
echo "Running sync script..."
bash "${SCRIPT_DIR}/sync-claude-md.sh" upstream main

echo ""
echo "📋 Results:"
echo ""

# 检查根目录 CLAUDE.md
echo "=== Root CLAUDE.md ==="
cat CLAUDE.md
echo ""

# 检查子目录 CLAUDE.md
echo "=== subdir/CLAUDE.md ==="
cat subdir/CLAUDE.md
echo ""

# 验证结果
echo "🔍 Verification:"
echo ""

# 检查是否包含更新的 upstream 内容
if grep -q "Upstream rule 1 (updated)" CLAUDE.md && \
   grep -q "Upstream rule 3 (new)" CLAUDE.md && \
   grep -q "My custom rule 1" CLAUDE.md && \
   grep -q "My custom rule 2" CLAUDE.md; then
    echo "✓ Root CLAUDE.md: upstream updated, user rules preserved"
else
    echo "✗ Root CLAUDE.md: FAILED"
    exit 1
fi

if grep -q "Subdir upstream rule 1 (updated)" subdir/CLAUDE.md && \
   grep -q "Subdir upstream rule 2 (new)" subdir/CLAUDE.md && \
   grep -q "Subdir custom rule" subdir/CLAUDE.md; then
    echo "✓ subdir/CLAUDE.md: upstream updated, user rules preserved"
else
    echo "✗ subdir/CLAUDE.md: FAILED"
    exit 1
fi

echo ""
echo "✅ All tests passed!"

# 清理
cd ..
rm -rf "$TEST_DIR"
