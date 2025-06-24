#!/bin/bash

# セッション情報自動収集スクリプト
# チャットセッション中の技術的情報を自動収集

set -e

echo "📊 セッション情報収集"
echo "===================="

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SESSION_INFO="chat-logs/session-info-$TIMESTAMP.md"
mkdir -p chat-logs

echo "📁 保存先: $SESSION_INFO"
echo

cat > "$SESSION_INFO" << EOF
# セッション情報

**収集日時**: $(date)
**作業者**: $(whoami)
**ホスト**: $(hostname)
**作業ディレクトリ**: $(pwd)

## Git状況

### 現在のブランチ・状態
\`\`\`
$(git status 2>/dev/null || echo "Gitリポジトリではありません")
\`\`\`

### 最近のコミット
\`\`\`
$(git log --oneline -10 2>/dev/null || echo "Git履歴なし")
\`\`\`

### 変更されたファイル（最近5コミット）
\`\`\`
$(git diff --name-only HEAD~5..HEAD 2>/dev/null || echo "変更ファイルなし")
\`\`\`

### ブランチ一覧
\`\`\`
$(git branch -a 2>/dev/null || echo "ブランチ情報なし")
\`\`\`

## プロジェクト状況

### ディレクトリ構造（主要部分）
\`\`\`
$(find . -maxdepth 2 -type d | grep -E "(scripts|docs|\.github|tests|src)" | sort 2>/dev/null || echo "主要ディレクトリなし")
\`\`\`

### 設定ファイル
\`\`\`
$(ls -la | grep -E "(package\.json|\.env|\.gitignore|README\.md|PROJECT_RULES\.md)" 2>/dev/null || echo "設定ファイルなし")
\`\`\`

### スクリプトファイル
\`\`\`
$(find scripts -name "*.sh" 2>/dev/null | sort || echo "スクリプトなし")
\`\`\`

## 環境情報

### システム情報
- **OS**: $(uname -a)
- **シェル**: $SHELL
- **ユーザー**: $(whoami)
- **ホームディレクトリ**: $HOME

### 開発ツール
- **Node.js**: $(node --version 2>/dev/null || echo "未インストール")
- **npm**: $(npm --version 2>/dev/null || echo "未インストール")
- **Git**: $(git --version 2>/dev/null || echo "未インストール")
- **Python**: $(python3 --version 2>/dev/null || echo "未インストール")
- **GitHub CLI**: $(gh --version 2>/dev/null | head -1 || echo "未インストール")

### 依存関係情報
EOF

# package.json の情報
if [ -f package.json ]; then
    echo "#### Node.js依存関係" >> "$SESSION_INFO"
    echo '```json' >> "$SESSION_INFO"
    cat package.json | jq '.dependencies // {}' 2>/dev/null || echo "依存関係情報の取得に失敗" >> "$SESSION_INFO"
    echo '```' >> "$SESSION_INFO"
    echo >> "$SESSION_INFO"
fi

# requirements.txt の情報
if [ -f requirements.txt ]; then
    echo "#### Python依存関係" >> "$SESSION_INFO"
    echo '```' >> "$SESSION_INFO"
    cat requirements.txt >> "$SESSION_INFO"
    echo '```' >> "$SESSION_INFO"
    echo >> "$SESSION_INFO"
fi

cat >> "$SESSION_INFO" << EOF

## プロセス・メモリ情報

### 現在のプロセス
\`\`\`
$(ps aux | head -10)
\`\`\`

### メモリ使用量
\`\`\`
$(free -h 2>/dev/null || echo "メモリ情報取得不可")
\`\`\`

### ディスク使用量
\`\`\`
$(df -h . 2>/dev/null || echo "ディスク情報取得不可")
\`\`\`

## ネットワーク情報

### GitHub接続確認
\`\`\`
$(curl -s https://api.github.com/user 2>/dev/null | jq '.login // "認証なし"' 2>/dev/null || echo "GitHub API接続不可")
\`\`\`

### リモートリポジトリ
\`\`\`
$(git remote -v 2>/dev/null | sed 's/ghp_[a-zA-Z0-9_]*/[GITHUB_TOKEN_MASKED]/g' | sed 's/gho_[a-zA-Z0-9_]*/[GITHUB_TOKEN_MASKED]/g' || echo "リモートリポジトリなし")
\`\`\`

## 最近のコマンド履歴

### Git関連コマンド
\`\`\`bash
EOF

# コマンド履歴の取得（可能な場合）
if [ -f ~/.bash_history ]; then
    grep -E "^git " ~/.bash_history | tail -10 >> "$SESSION_INFO" 2>/dev/null || echo "Git履歴なし" >> "$SESSION_INFO"
else
    echo "履歴ファイルなし" >> "$SESSION_INFO"
fi

cat >> "$SESSION_INFO" << EOF
\`\`\`

### npm/Node.js関連コマンド
\`\`\`bash
EOF

if [ -f ~/.bash_history ]; then
    grep -E "^(npm|node|npx)" ~/.bash_history | tail -5 >> "$SESSION_INFO" 2>/dev/null || echo "npm/node履歴なし" >> "$SESSION_INFO"
else
    echo "履歴ファイルなし" >> "$SESSION_INFO"
fi

cat >> "$SESSION_INFO" << EOF
\`\`\`

### スクリプト実行履歴
\`\`\`bash
EOF

if [ -f ~/.bash_history ]; then
    grep -E "^\./scripts/" ~/.bash_history | tail -5 >> "$SESSION_INFO" 2>/dev/null || echo "スクリプト実行履歴なし" >> "$SESSION_INFO"
else
    echo "履歴ファイルなし" >> "$SESSION_INFO"
fi

cat >> "$SESSION_INFO" << EOF
\`\`\`

## セキュリティ情報

### 最新セキュリティチェック結果
EOF

# セキュリティチェックの最新結果
if [ -d security-reports ]; then
    LATEST_SECURITY=$(ls -t security-reports/*.md 2>/dev/null | head -1)
    if [ -n "$LATEST_SECURITY" ]; then
        echo "**最新レポート**: $LATEST_SECURITY" >> "$SESSION_INFO"
        echo '```' >> "$SESSION_INFO"
        tail -20 "$LATEST_SECURITY" >> "$SESSION_INFO"
        echo '```' >> "$SESSION_INFO"
    else
        echo "セキュリティレポートなし" >> "$SESSION_INFO"
    fi
else
    echo "セキュリティレポートディレクトリなし" >> "$SESSION_INFO"
fi

cat >> "$SESSION_INFO" << EOF

## 作業コンテキスト

### 現在の作業ブランチの目的
$(git log -1 --pretty=format:"**最新コミット**: %s%n**作成者**: %an%n**日時**: %ad" --date=format:"%Y-%m-%d %H:%M:%S" 2>/dev/null || echo "コミット情報なし")

### 未コミットの変更
\`\`\`
$(git diff --stat 2>/dev/null || echo "変更なし")
\`\`\`

### ステージングエリア
\`\`\`
$(git diff --cached --stat 2>/dev/null || echo "ステージング変更なし")
\`\`\`

---

**情報収集完了**: $(date)
**次回収集予定**: [手動実行]

EOF

echo "✅ セッション情報収集完了: $SESSION_INFO"
echo
echo "📊 収集された情報:"
echo "   - Git状況・履歴"
echo "   - 環境・ツール情報"
echo "   - プロジェクト構造"
echo "   - セキュリティ状況"
echo "   - コマンド履歴"
echo
echo "🔗 次のステップ:"
echo "   1. ログファイルを確認: cat $SESSION_INFO"
echo "   2. チャットログと組み合わせ: ./scripts/save-chat-log.sh \"セッション概要\""
echo "   3. 重要な情報をチャットログに転記"