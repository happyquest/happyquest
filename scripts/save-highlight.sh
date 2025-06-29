#!/bin/bash

# 重要箇所ハイライト保存スクリプト
# 使用方法: ./scripts/save-highlight.sh "文書名" "重要箇所の説明"

set -e

# 色付きテキスト用の定義
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 引数チェック
if [ $# -lt 2 ]; then
    echo "使用方法: $0 \"文書名\" \"重要箇所の説明\" [カテゴリ]"
    echo "例: $0 \"PROJECT_RULES.md\" \"タイムアウト設定\" \"設定\""
    exit 1
fi

DOCUMENT_NAME="$1"
DESCRIPTION="$2"
CATEGORY="${3:-技術}"
DATE=$(date +%Y-%m-%d)
TIME=$(date +%H:%M)
FILENAME="notes/highlights/${DATE}-$(echo "$DOCUMENT_NAME" | sed 's/[^a-zA-Z0-9._-]/_/g').md"

echo -e "${BLUE}📝 重要箇所ハイライトを保存します${NC}"
echo "文書名: $DOCUMENT_NAME"
echo "説明: $DESCRIPTION"
echo "カテゴリ: $CATEGORY"
echo "保存先: $FILENAME"
echo

# テンプレートをコピーして編集
cp notes/templates/highlight-template.md "$FILENAME"

# テンプレートの置換
sed -i "s/\[元文書のファイル名\]/$DOCUMENT_NAME/g" "$FILENAME"
sed -i "s/\$(date +%Y-%m-%d\\\\ %H:%M)/$DATE $TIME/g" "$FILENAME"
sed -i "s/\[技術\/設定\/仕様\/その他\]/$CATEGORY/g" "$FILENAME"
sed -i "s/\[なぜこの箇所が重要かを1-2行で説明\]/$DESCRIPTION/g" "$FILENAME"

echo -e "${GREEN}✅ ハイライトファイルを作成しました: $FILENAME${NC}"
echo -e "${YELLOW}📝 エディタで開いて詳細を記入してください${NC}"

# ファイルを開く（オプション）
if command -v code &> /dev/null; then
    echo "VS Codeで開きますか？ (y/n)"
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        code "$FILENAME"
    fi
fi

echo
echo -e "${BLUE}📋 クイックメモも追加しますか？${NC}"
echo "1) はい - クイックメモに追加"
echo "2) いいえ - ハイライトのみ"
read -r choice

if [[ "$choice" == "1" ]]; then
    QUICK_NOTE_FILE="notes/quick-notes/${DATE}-session.md"
    echo "## $(date +%H:%M) - $DOCUMENT_NAME ハイライト" >> "$QUICK_NOTE_FILE"
    echo "- **内容**: $DESCRIPTION" >> "$QUICK_NOTE_FILE"
    echo "- **ファイル**: [$FILENAME]($FILENAME)" >> "$QUICK_NOTE_FILE"
    echo "" >> "$QUICK_NOTE_FILE"
    echo -e "${GREEN}✅ クイックメモにも追加しました${NC}"
fi

echo -e "${GREEN}🎉 メモ保存完了！${NC}"