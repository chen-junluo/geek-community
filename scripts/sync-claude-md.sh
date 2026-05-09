#!/bin/bash
# sync-claude-md.sh
# 从 upstream 同步 CLAUDE.md 文件，保留用户自定义规则

set -e

# 配置
UPSTREAM_REMOTE="${1:-upstream}"
UPSTREAM_BRANCH="${2:-main}"
MARKER="## User-Specific Rules"

# 颜色输出
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔄 Syncing CLAUDE.md files from ${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}..."
echo ""

# 检查 upstream remote 是否存在
if ! git remote | grep -q "^${UPSTREAM_REMOTE}$"; then
    echo -e "${RED}✗ Remote '${UPSTREAM_REMOTE}' not found${NC}"
    echo ""
    echo "Please add the upstream remote first:"
    echo "  git remote add ${UPSTREAM_REMOTE} <upstream-repo-url>"
    exit 1
fi

# Fetch upstream
echo "Fetching from ${UPSTREAM_REMOTE}..."
git fetch "${UPSTREAM_REMOTE}" "${UPSTREAM_BRANCH}"

# 查找所有 CLAUDE.md 文件
CLAUDE_FILES=$(find . -name "CLAUDE.md" -not -path "*/\.*" -not -path "*/node_modules/*")

if [ -z "$CLAUDE_FILES" ]; then
    echo -e "${YELLOW}⚠ No CLAUDE.md files found${NC}"
    exit 0
fi

# 处理每个文件
UPDATED_COUNT=0
SKIPPED_COUNT=0

for LOCAL_FILE in $CLAUDE_FILES; do
    # 移除开头的 ./
    RELATIVE_PATH="${LOCAL_FILE#./}"

    echo "Processing: ${RELATIVE_PATH}"

    # 检查 upstream 是否有这个文件
    if ! git cat-file -e "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}:${RELATIVE_PATH}" 2>/dev/null; then
        echo -e "  ${YELLOW}⊘ Not in upstream, skipping${NC}"
        ((SKIPPED_COUNT++))
        continue
    fi

    # 检查本地文件是否有 user-specific section
    if grep -q "$MARKER" "$LOCAL_FILE"; then
        # 提取 user 部分（从 marker 开始到文件末尾）
        USER_PART=$(mktemp)
        sed -n "/^${MARKER}/,\$p" "$LOCAL_FILE" > "$USER_PART"

        # 获取 upstream 部分
        UPSTREAM_PART=$(mktemp)
        git show "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}:${RELATIVE_PATH}" > "$UPSTREAM_PART"

        # 检查 upstream 是否也有 marker
        if grep -q "$MARKER" "$UPSTREAM_PART"; then
            # upstream 有 marker，只取 marker 之前的部分（不包含 marker 本身）
            sed -n "1,/^${MARKER}/p" "$UPSTREAM_PART" | sed '$d' > "${UPSTREAM_PART}.tmp"
            mv "${UPSTREAM_PART}.tmp" "$UPSTREAM_PART"
        fi

        # 合并：upstream 部分 + user 部分（user 部分已包含 marker）
        cat "$UPSTREAM_PART" > "$LOCAL_FILE"
        cat "$USER_PART" >> "$LOCAL_FILE"

        # 清理临时文件
        rm "$USER_PART" "$UPSTREAM_PART"

        echo -e "  ${GREEN}✓ Updated (preserved user rules)${NC}"
    else
        # 没有 user 部分，直接覆盖
        git show "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}:${RELATIVE_PATH}" > "$LOCAL_FILE"
        echo -e "  ${GREEN}✓ Updated (no user rules)${NC}"
    fi

    ((UPDATED_COUNT++))
done

echo ""
echo -e "${GREEN}✓ Sync complete${NC}"
echo "  Updated: ${UPDATED_COUNT} file(s)"
if [ $SKIPPED_COUNT -gt 0 ]; then
    echo "  Skipped: ${SKIPPED_COUNT} file(s) (not in upstream)"
fi
echo ""
echo "Review the changes with: git diff"
echo "Commit if satisfied: git add . && git commit -m 'Sync CLAUDE.md from upstream'"
