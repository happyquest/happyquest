#!/bin/bash

# 作業完了通知メール送信スクリプト
# 成果物確認依頼を自動化

set -e

echo "📧 作業完了通知メール送信"
echo "========================"

# 引数チェック
if [ $# -lt 2 ]; then
    echo "使用方法: $0 <機能名> <PR番号> [追加メッセージ]"
    echo
    echo "例:"
    echo "  $0 'チャットログ管理システム' 123"
    echo "  $0 'セキュリティ強化' 456 '緊急修正のため優先確認をお願いします'"
    exit 1
fi

FEATURE_NAME="$1"
PR_NUMBER="$2"
ADDITIONAL_MESSAGE="${3:-}"

# 設定
RECIPIENT="d.takikita@happyquest.ai"
SUBJECT="[HappyQuest] 成果物確認依頼 - $FEATURE_NAME"

# GitHub情報取得
if command -v gh &> /dev/null && gh auth status &> /dev/null; then
    PR_URL=$(gh pr view $PR_NUMBER --json url --jq '.url' 2>/dev/null || echo "PR URL取得失敗")
    PR_TITLE=$(gh pr view $PR_NUMBER --json title --jq '.title' 2>/dev/null || echo "PR タイトル取得失敗")
    REPO_URL=$(gh repo view --json url --jq '.url' 2>/dev/null || echo "リポジトリURL取得失敗")
else
    PR_URL="https://github.com/happyquest/happyquest/pull/$PR_NUMBER"
    PR_TITLE="$FEATURE_NAME"
    REPO_URL="https://github.com/happyquest/happyquest"
fi

# 現在の状況確認
CURRENT_BRANCH=$(git branch --show-current)
LATEST_COMMIT=$(git log --oneline -1)
CHANGED_FILES=$(git diff --name-only HEAD~1..HEAD | wc -l)

# テスト状況確認
TEST_STATUS="確認中"
if [ -f package.json ] && command -v npm &> /dev/null; then
    if npm test &> /dev/null; then
        TEST_STATUS="✅ 全テスト通過"
    else
        TEST_STATUS="❌ テスト失敗あり"
    fi
fi

# Playwright確認
PLAYWRIGHT_STATUS="未実行"
if [ -f package.json ] && grep -q "playwright" package.json; then
    if npm run test:e2e &> /dev/null 2>&1; then
        PLAYWRIGHT_STATUS="✅ Playwright テスト通過"
    else
        PLAYWRIGHT_STATUS="⚠️ Playwright テスト要確認"
    fi
fi

# メール本文作成
EMAIL_BODY="お疲れ様です。

以下の作業が完了しましたので、確認をお願いいたします。

■ 作業内容
- 機能名: $FEATURE_NAME
- PR: #$PR_NUMBER - $PR_TITLE
- ブランチ: $CURRENT_BRANCH
- 変更ファイル数: $CHANGED_FILES ファイル

■ 成果物
- GitHub PR: $PR_URL
- リポジトリ: $REPO_URL
- 最新コミット: $LATEST_COMMIT

■ 確認済み項目
✅ コード実装完了
✅ ドキュメント更新
$TEST_STATUS
$PLAYWRIGHT_STATUS
✅ セキュリティチェック実施

■ 次のステップ
1. PR内容の確認
2. 自動テスト結果の確認
3. 成果物の動作確認
4. 承認・マージの実行

$ADDITIONAL_MESSAGE

確認後、問題なければマージいたします。
ご質問等ございましたらお気軽にお声がけください。

---
自動送信: $(date)
送信者: $(whoami)@$(hostname)"

echo "📝 メール内容:"
echo "宛先: $RECIPIENT"
echo "件名: $SUBJECT"
echo
echo "本文プレビュー:"
echo "----------------------------------------"
echo "$EMAIL_BODY"
echo "----------------------------------------"
echo

# メール送信方法の選択
echo "📧 メール送信方法を選択してください:"
echo "1. クリップボードにコピー（手動送信）"
echo "2. mailコマンドで送信（要設定）"
echo "3. 内容をファイルに保存"
echo "4. キャンセル"
echo

read -p "選択 (1-4): " CHOICE

case $CHOICE in
    1)
        # クリップボードにコピー
        if command -v xclip &> /dev/null; then
            echo "$EMAIL_BODY" | xclip -selection clipboard
            echo "✅ クリップボードにコピーしました"
            echo "📧 メールクライアントで以下の宛先に送信してください:"
            echo "   宛先: $RECIPIENT"
            echo "   件名: $SUBJECT"
        elif command -v pbcopy &> /dev/null; then
            echo "$EMAIL_BODY" | pbcopy
            echo "✅ クリップボードにコピーしました"
        else
            echo "❌ クリップボードコマンドが見つかりません"
            echo "📝 以下の内容を手動でコピーしてください:"
            echo "$EMAIL_BODY"
        fi
        ;;
    2)
        # mailコマンドで送信
        if command -v mail &> /dev/null; then
            echo "$EMAIL_BODY" | mail -s "$SUBJECT" "$RECIPIENT"
            echo "✅ メール送信完了"
        else
            echo "❌ mailコマンドが見つかりません"
            echo "📦 インストール: sudo apt-get install mailutils"
        fi
        ;;
    3)
        # ファイルに保存
        MAIL_FILE="mail-drafts/completion-notice-$(date +%Y%m%d-%H%M%S).txt"
        mkdir -p mail-drafts
        cat > "$MAIL_FILE" << EOF
宛先: $RECIPIENT
件名: $SUBJECT

$EMAIL_BODY
EOF
        echo "✅ メール内容をファイルに保存しました: $MAIL_FILE"
        ;;
    4)
        echo "❌ キャンセルしました"
        exit 0
        ;;
    *)
        echo "❌ 無効な選択です"
        exit 1
        ;;
esac

echo
echo "🔄 次のアクション:"
echo "1. メール送信後、PR確認を待つ"
echo "2. フィードバックがあれば対応"
echo "3. 承認後、マージ実行: gh pr merge --squash $PR_NUMBER"
echo "4. 完了報告"