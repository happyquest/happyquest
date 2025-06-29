#!/bin/bash

# メモ検索スクリプト
# 使用方法: ./scripts/search-notes.sh "検索キーワード"

set -e

# 色付きテキスト用の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# 引数チェック
if [ $# -eq 0 ]; then
    echo -e "${BLUE}📝 HappyQuest メモ検索システム${NC}"
    echo "使用方法: $0 \"検索キーワード\""
    echo
    echo "例:"
    echo "  $0 \"タイムアウト\"     # キーワード検索"
    echo "  $0 \"2025-06-24\"      # 日付検索"
    echo "  $0 \"#設定\"           # タグ検索"
    echo
    echo -e "${YELLOW}📊 メモ統計:${NC}"
    echo "ハイライト数: $(find notes/highlights -name '*.md' 2>/dev/null | wc -l)"
    echo "ブックマーク数: $(find notes/bookmarks -name '*.md' 2>/dev/null | wc -l)"
    echo "クイックメモ数: $(find notes/quick-notes -name '*.md' 2>/dev/null | wc -l)"
    echo
    echo -e "${BLUE}📋 最新のメモ:${NC}"
    find notes/ -name '*.md' -not -path '*/templates/*' -not -name 'README.md' 2>/dev/null | head -5 | while read -r file; do
        echo "  - $(basename "$file")"
    done
    exit 0
fi

SEARCH_TERM="$1"

echo -e "${BLUE}🔍 メモ検索: \"$SEARCH_TERM\"${NC}"
echo "=================================="

# ハイライト検索
echo -e "${GREEN}📋 ハイライト検索結果:${NC}"
HIGHLIGHT_RESULTS=$(grep -r -l "$SEARCH_TERM" notes/highlights/ 2>/dev/null || true)
if [ -n "$HIGHLIGHT_RESULTS" ]; then
    echo "$HIGHLIGHT_RESULTS" | while read -r file; do
        echo "  📄 $(basename "$file")"
        grep -n "$SEARCH_TERM" "$file" | head -2 | sed 's/^/    /'
        echo
    done
else
    echo "  該当なし"
fi

echo

# ブックマーク検索
echo -e "${GREEN}🔖 ブックマーク検索結果:${NC}"
BOOKMARK_RESULTS=$(grep -r -l "$SEARCH_TERM" notes/bookmarks/ 2>/dev/null || true)
if [ -n "$BOOKMARK_RESULTS" ]; then
    echo "$BOOKMARK_RESULTS" | while read -r file; do
        echo "  📄 $(basename "$file")"
        grep -n "$SEARCH_TERM" "$file" | head -2 | sed 's/^/    /'
        echo
    done
else
    echo "  該当なし"
fi

echo

# クイックメモ検索
echo -e "${GREEN}⚡ クイックメモ検索結果:${NC}"
QUICK_RESULTS=$(grep -r -l "$SEARCH_TERM" notes/quick-notes/ 2>/dev/null || true)
if [ -n "$QUICK_RESULTS" ]; then
    echo "$QUICK_RESULTS" | while read -r file; do
        echo "  📄 $(basename "$file")"
        grep -n "$SEARCH_TERM" "$file" | head -2 | sed 's/^/    /'
        echo
    done
else
    echo "  該当なし"
fi

echo

# 全体統計
TOTAL_MATCHES=$(grep -r "$SEARCH_TERM" notes/ 2>/dev/null | wc -l || echo "0")
echo -e "${YELLOW}📊 検索統計:${NC}"
echo "総マッチ数: $TOTAL_MATCHES"

if [ "$TOTAL_MATCHES" -gt 0 ]; then
    echo
    echo -e "${BLUE}💡 詳細表示のヒント:${NC}"
    echo "  grep -r \"$SEARCH_TERM\" notes/ | head -10"
fi