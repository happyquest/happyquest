#!/bin/bash

# GitHub プルリクエスト作成ヘルパースクリプト
# 標準化されたPR作成を支援

set -e

echo "🔄 GitHub プルリクエスト作成ヘルパー"
echo "===================================="

# 引数チェック
if [ $# -lt 1 ]; then
    echo "使用方法: $0 <Issue番号> [変更内容]"
    echo
    echo "例:"
    echo "  $0 123"
    echo "  $0 456 'セキュリティ強化機能を追加'"
    echo
    echo "レガシー使用方法: $0 \"タイトル\" \"説明\""
    exit 1
fi

# レガシー形式の判定（2つ目の引数がIssue番号でない場合）
if [ $# -eq 2 ] && [[ ! "$1" =~ ^[0-9]+$ ]]; then
    # レガシー形式
    PR_TITLE="$1"
    PR_BODY="$2"
    CURRENT_BRANCH=$(git branch --show-current)
    TARGET_BRANCH="main"
    
    echo "⚠️ レガシー形式で実行中"
    echo "現在のブランチ: $CURRENT_BRANCH"
    echo "ターゲットブランチ: $TARGET_BRANCH"
    echo "タイトル: $PR_TITLE"
    echo
    
    # 変更をプッシュ
    echo "📤 変更をプッシュ中..."
    git push -u origin "$CURRENT_BRANCH"
    
    # プルリクエスト作成
    echo "🔄 プルリクエスト作成中..."
    PR_URL=$(gh pr create --title "$PR_TITLE" --body "$PR_BODY" --base "$TARGET_BRANCH" --head "$CURRENT_BRANCH")
    
    echo "✅ プルリクエスト作成完了"
    echo "🔗 URL: $PR_URL"
    exit 0
fi

# 新しい標準形式
ISSUE_NUMBER="$1"
CHANGE_DESCRIPTION="${2:-}"

# GitHub CLIの確認
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) がインストールされていません"
    exit 1
fi

# GitHub認証確認
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub認証が必要です"
    echo "認証方法: gh auth login"
    exit 1
fi

# 現在のブランチ確認
CURRENT_BRANCH=$(git branch --show-current)
echo "📋 現在のブランチ: $CURRENT_BRANCH"

# Issue情報取得
echo "🔍 Issue #$ISSUE_NUMBER の情報を取得中..."
ISSUE_TITLE=$(gh issue view $ISSUE_NUMBER --json title --jq '.title' 2>/dev/null)

if [ $? -ne 0 ] || [ -z "$ISSUE_TITLE" ]; then
    echo "❌ Issue #$ISSUE_NUMBER が見つかりません"
    exit 1
fi

echo "📝 Issue タイトル: $ISSUE_TITLE"

# PR タイトル生成
if [[ "$ISSUE_TITLE" =~ ^[Bb]ug ]]; then
    PR_TITLE="Fix #$ISSUE_NUMBER: $ISSUE_TITLE"
elif [[ "$ISSUE_TITLE" =~ [Dd]ocs?|[Dd]ocument ]]; then
    PR_TITLE="Docs #$ISSUE_NUMBER: $ISSUE_TITLE"
elif [[ "$ISSUE_TITLE" =~ [Rr]efactor ]]; then
    PR_TITLE="Refactor #$ISSUE_NUMBER: $ISSUE_TITLE"
else
    PR_TITLE="Feature #$ISSUE_NUMBER: $ISSUE_TITLE"
fi

# 変更内容の自動検出
CHANGED_FILES=$(git diff --name-only HEAD~1..HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo "変更ファイルの検出に失敗")
COMMIT_MESSAGES=$(git log --oneline HEAD~5..HEAD 2>/dev/null | head -3 || echo "コミット履歴なし")

# PR本文テンプレート生成
BODY="## 🔗 関連Issue
Closes #$ISSUE_NUMBER

## 📝 変更内容
${CHANGE_DESCRIPTION:-$ISSUE_TITLE の実装}

### 主な変更
- 変更点1
- 変更点2
- 変更点3

### 変更されたファイル
\`\`\`
$CHANGED_FILES
\`\`\`

### 最近のコミット
\`\`\`
$COMMIT_MESSAGES
\`\`\`

## 🧪 テスト
- [ ] 手動テスト実施
- [ ] 自動テスト追加
- [ ] 既存テストの確認
- [ ] エッジケースの確認

### テスト手順
1. テスト手順1
2. テスト手順2
3. テスト手順3

## 📋 チェックリスト
- [ ] コードレビュー完了
- [ ] ドキュメント更新
- [ ] セキュリティチェック実施
- [ ] 破壊的変更の確認
- [ ] パフォーマンス影響確認

## 📸 スクリーンショット
<!-- 必要に応じて画面キャプチャを追加 -->

## 💡 備考
<!-- 追加の考慮事項があれば記載 -->"

echo
echo "📝 PR情報:"
echo "  タイトル: $PR_TITLE"
echo "  Issue: #$ISSUE_NUMBER"
echo "  ブランチ: $CURRENT_BRANCH"
echo

# 未コミットの変更確認
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "⚠️ 未コミットの変更があります"
    echo "コミットしてからPRを作成することをお勧めします"
    echo
    read -p "🤔 続行しますか? (y/N): " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        echo "❌ PR作成をキャンセルしました"
        exit 1
    fi
fi

# 変更をプッシュ
echo "📤 変更をプッシュ中..."
git push -u origin "$CURRENT_BRANCH"

echo "🚀 プルリクエスト作成中..."

# PR作成実行
PR_URL=$(gh pr create \
    --title "$PR_TITLE" \
    --body "$BODY" \
    --assignee "@me")

if [ $? -eq 0 ]; then
    echo "✅ プルリクエスト作成完了!"
    echo "🔗 URL: $PR_URL"
    
    # PR番号を抽出
    PR_NUMBER=$(echo "$PR_URL" | grep -o '[0-9]*$')
    echo "📋 PR番号: #$PR_NUMBER"
    
    echo
    echo "🔄 次のステップ:"
    echo "1. PR詳細を編集: gh pr edit $PR_NUMBER"
    echo "2. レビュー依頼: gh pr review --request-reviewer <username>"
    echo "3. CI/CDチェック確認"
    echo "4. レビュー対応"
    echo "5. マージ: gh pr merge --squash $PR_NUMBER"
    
else
    echo "❌ プルリクエスト作成に失敗しました"
    exit 1
fi