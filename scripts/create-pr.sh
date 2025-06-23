#!/bin/bash

# プルリクエスト作成スクリプト
# 使用方法: ./scripts/create-pr.sh "タイトル" "説明"

set -e

# 引数チェック
if [ $# -lt 2 ]; then
  echo "使用方法: $0 \"タイトル\" \"説明\""
  exit 1
fi

PR_TITLE="$1"
PR_BODY="$2"
CURRENT_BRANCH=$(git branch --show-current)
TARGET_BRANCH="main"

echo "===== プルリクエスト作成 ====="
echo "現在のブランチ: $CURRENT_BRANCH"
echo "ターゲットブランチ: $TARGET_BRANCH"
echo "タイトル: $PR_TITLE"
echo "説明: $PR_BODY"
echo

# 変更をプッシュ
echo "📤 変更をプッシュ中..."
git push -u origin "$CURRENT_BRANCH"

# プルリクエスト作成
echo "🔄 プルリクエスト作成中..."
PR_URL=$(gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base "$TARGET_BRANCH" --head "$CURRENT_BRANCH" --web)

echo "✅ プルリクエスト作成完了"
echo "🔗 URL: $PR_URL"