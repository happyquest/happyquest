#!/bin/bash

# GitHub Issue作成ヘルパースクリプト
# 標準化されたIssue作成を支援

set -e

echo "🎯 GitHub Issue作成ヘルパー"
echo "============================"

# 引数チェック
if [ $# -lt 2 ]; then
    echo "使用方法: $0 <機能名> <改善内容> [詳細説明]"
    echo
    echo "例:"
    echo "  $0 'チャットログ' 'エクスポート機能追加' '複数形式でのエクスポート機能'"
    echo "  $0 'セキュリティ' 'パスワード強化' 'パスワードポリシーの強化'"
    exit 1
fi

FEATURE_NAME="$1"
IMPROVEMENT="$2"
DETAIL="${3:-詳細は後で追記}"

# Issueタイトル生成
TITLE="${FEATURE_NAME}: ${IMPROVEMENT}"

# Issue本文テンプレート生成
BODY="## 📋 概要
${IMPROVEMENT}

## 🎯 目的
${DETAIL}

## 📝 詳細
### 現状の問題
- [ ] 問題点1
- [ ] 問題点2

### 提案する解決策
- [ ] 解決策1
- [ ] 解決策2

### 実装方針
- [ ] 実装手順1
- [ ] 実装手順2

## ✅ 完了条件
- [ ] 機能実装完了
- [ ] テスト実施
- [ ] ドキュメント更新
- [ ] レビュー完了

## 🔗 関連
- 関連Issue: 
- 参考資料: 

## 🏷️ ラベル
enhancement

## 📅 予定
- 開始予定: $(date +%Y-%m-%d)
- 完了予定: 
- 優先度: 中

## 💡 備考
追加の考慮事項があれば記載"

echo "📝 Issue情報:"
echo "  タイトル: $TITLE"
echo "  機能名: $FEATURE_NAME"
echo "  改善内容: $IMPROVEMENT"
echo

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

echo "🚀 Issue作成中..."

# Issue作成実行
ISSUE_URL=$(gh issue create \
    --title "$TITLE" \
    --body "$BODY" \
    --label "enhancement" \
    --assignee "@me")

if [ $? -eq 0 ]; then
    echo "✅ Issue作成完了!"
    echo "🔗 URL: $ISSUE_URL"
    
    # Issue番号を抽出
    ISSUE_NUMBER=$(echo "$ISSUE_URL" | grep -o '[0-9]*$')
    echo "📋 Issue番号: #$ISSUE_NUMBER"
    
    echo
    echo "🔄 次のステップ:"
    echo "1. Issue詳細を編集: gh issue edit $ISSUE_NUMBER"
    echo "2. 作業ブランチ作成: git checkout -b feature/issue-$ISSUE_NUMBER-$(echo $FEATURE_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
    echo "3. 作業開始"
    echo "4. PR作成: ./scripts/create-pr.sh $ISSUE_NUMBER"
    
    # 作業ブランチ作成の提案
    echo
    read -p "🤔 作業ブランチを今すぐ作成しますか? (y/N): " CREATE_BRANCH
    if [[ $CREATE_BRANCH =~ ^[Yy]$ ]]; then
        BRANCH_NAME="feature/issue-$ISSUE_NUMBER-$(echo $FEATURE_NAME | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"
        git checkout -b "$BRANCH_NAME"
        echo "✅ ブランチ作成完了: $BRANCH_NAME"
    fi
    
else
    echo "❌ Issue作成に失敗しました"
    exit 1
fi