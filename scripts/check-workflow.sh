#!/bin/bash

# GitHubワークフロー状況確認スクリプト
# Issue・PR・ブランチの状況を一覧表示

set -e

echo "🔄 GitHubワークフロー状況確認"
echo "=============================="

# GitHub CLIの確認
if ! command -v gh &> /dev/null; then
    echo "❌ GitHub CLI (gh) がインストールされていません"
    echo "インストール方法: https://cli.github.com/"
    exit 1
fi

# GitHub認証確認
if ! gh auth status &> /dev/null; then
    echo "❌ GitHub認証が必要です"
    echo "認証方法: gh auth login"
    exit 1
fi

echo "📊 現在の状況:"
echo "  日時: $(date)"
echo "  ユーザー: $(whoami)"
echo "  ブランチ: $(git branch --show-current)"
echo "  リポジトリ: $(git remote get-url origin 2>/dev/null || echo '未設定')"
echo

# 1. オープンなIssue
echo "📋 オープンなIssue (最新10件)"
echo "--------------------------------"
OPEN_ISSUES=$(gh issue list --state open --limit 10 --json number,title,labels,assignees,createdAt 2>/dev/null)

if [ "$OPEN_ISSUES" = "[]" ]; then
    echo "  オープンなIssueはありません"
else
    echo "$OPEN_ISSUES" | jq -r '.[] | "  #\(.number): \(.title) [\(.labels | map(.name) | join(", "))]"' 2>/dev/null || echo "  Issue情報の取得に失敗"
fi
echo

# 2. オープンなプルリクエスト
echo "🔄 オープンなプルリクエスト (最新10件)"
echo "------------------------------------"
OPEN_PRS=$(gh pr list --state open --limit 10 --json number,title,headRefName,author,createdAt 2>/dev/null)

if [ "$OPEN_PRS" = "[]" ]; then
    echo "  オープンなプルリクエストはありません"
else
    echo "$OPEN_PRS" | jq -r '.[] | "  #\(.number): \(.title) (\(.headRefName)) by \(.author.login)"' 2>/dev/null || echo "  PR情報の取得に失敗"
fi
echo

# 3. 最近のブランチ
echo "🌿 最近のブランチ (最新10件)"
echo "----------------------------"
git branch -a --sort=-committerdate | head -10 | sed 's/^/  /'
echo

# 4. 最近のコミット
echo "📝 最近のコミット (最新5件)"
echo "---------------------------"
git log --oneline -5 | sed 's/^/  /'
echo

# 5. 現在のGit状況
echo "📊 現在のGit状況"
echo "----------------"
if git diff --quiet && git diff --cached --quiet; then
    echo "  ✅ 作業ディレクトリはクリーンです"
else
    echo "  ⚠️ 未コミットの変更があります:"
    if ! git diff --quiet; then
        echo "    - 未ステージの変更: $(git diff --name-only | wc -l) ファイル"
    fi
    if ! git diff --cached --quiet; then
        echo "    - ステージ済みの変更: $(git diff --cached --name-only | wc -l) ファイル"
    fi
fi

# 6. 推奨アクション
echo
echo "💡 推奨アクション"
echo "----------------"

# 未コミットの変更がある場合
if ! git diff --quiet || ! git diff --cached --quiet; then
    echo "  1. 変更をコミット: git add . && git commit -m '変更内容'"
fi

# オープンなIssueがある場合
if [ "$OPEN_ISSUES" != "[]" ]; then
    echo "  2. Issue対応: gh issue view <番号> で詳細確認"
fi

# オープンなPRがある場合
if [ "$OPEN_PRS" != "[]" ]; then
    echo "  3. PR確認: gh pr view <番号> でレビュー状況確認"
fi

echo "  4. 新しいIssue作成: ./scripts/create-issue.sh '機能名' '改善内容'"
echo "  5. 新しいPR作成: ./scripts/create-pr.sh <Issue番号>"

echo
echo "🔧 便利なコマンド"
echo "----------------"
echo "  gh issue list                    # Issue一覧"
echo "  gh pr list                       # PR一覧"
echo "  gh issue view <番号>             # Issue詳細"
echo "  gh pr view <番号>                # PR詳細"
echo "  gh pr checks <番号>              # PRのCI/CD状況"
echo "  gh pr merge --squash <番号>      # PRマージ"
echo "  git branch -d <ブランチ名>       # ローカルブランチ削除"
echo "  git push origin --delete <ブランチ名>  # リモートブランチ削除"

echo
echo "✅ ワークフロー状況確認完了"