#!/bin/bash

# プロジェクト状況確認ダッシュボード
# 作成日: 2025年6月23日

set -e

echo "🎯 HappyQuest プロジェクト状況ダッシュボード"
echo "=============================================="
echo "📅 実行日時: $(date)"
echo

# Git情報
echo "📊 Git情報"
echo "----------"
echo "🌿 現在のブランチ: $(git branch --show-current)"
echo "📝 最新コミット: $(git log -1 --oneline)"
echo "🔄 リモート状況: $(git remote -v | head -1)"
echo

# ファイル統計
echo "📁 ファイル統計"
echo "-------------"
echo "📄 総ファイル数: $(find . -type f | wc -l)"
echo "🐍 Pythonファイル: $(find . -name '*.py' | wc -l)"
echo "🟨 JavaScriptファイル: $(find . -name '*.js' | wc -l)"
echo "📝 Markdownファイル: $(find . -name '*.md' | wc -l)"
echo "⚙️ 設定ファイル: $(find . -name '*.json' -o -name '*.yml' -o -name '*.yaml' | wc -l)"
echo

# コード統計
echo "💻 コード統計"
echo "------------"
TOTAL_LINES=$(find . -name '*.py' -o -name '*.js' -o -name '*.sh' -exec wc -l {} + 2>/dev/null | tail -1 | awk '{print $1}' || echo "0")
echo "📏 総行数: $TOTAL_LINES"
echo "🔧 スクリプトファイル: $(find scripts/ -name '*.sh' 2>/dev/null | wc -l)"
echo

# GitHub Actions状況
echo "🚀 CI/CD状況"
echo "------------"
if [ -d .github/workflows ]; then
  WORKFLOW_COUNT=$(find .github/workflows -name '*.yml' | wc -l)
  echo "⚙️ ワークフローファイル数: $WORKFLOW_COUNT"
  echo "📋 ワークフロー一覧:"
  find .github/workflows -name '*.yml' -exec basename {} \; | sed 's/^/  - /'
else
  echo "❌ GitHub Actionsワークフローが見つかりません"
fi
echo

# MCP設定状況
echo "🔗 MCP設定状況"
echo "-------------"
if [ -f .cursor/mcp.json ]; then
  echo "✅ MCP設定ファイル存在"
  SERVER_COUNT=$(cat .cursor/mcp.json | grep -c "command" || echo "0")
  echo "🖥️ 設定済みサーバー数: $SERVER_COUNT"
  echo "📋 サーバー一覧:"
  cat .cursor/mcp.json | grep "description" | sed 's/.*: "\(.*\)",/  - \1/'
else
  echo "❌ MCP設定ファイルが見つかりません"
fi
echo

# 依存関係状況
echo "📦 依存関係状況"
echo "-------------"
if [ -f package.json ]; then
  echo "✅ package.json存在"
  if [ -d node_modules ]; then
    echo "✅ node_modules存在"
    PACKAGE_COUNT=$(ls node_modules 2>/dev/null | wc -l || echo "0")
    echo "📦 インストール済みパッケージ数: $PACKAGE_COUNT"
  else
    echo "⚠️ node_modulesが見つかりません (npm install が必要)"
  fi
else
  echo "❌ package.jsonが見つかりません"
fi
echo

# テスト状況
echo "🧪 テスト状況"
echo "------------"
if [ -d tests ]; then
  TEST_FILES=$(find tests -name '*.test.js' -o -name '*.spec.js' -o -name 'test_*.py' | wc -l)
  echo "🧪 テストファイル数: $TEST_FILES"
  if [ $TEST_FILES -gt 0 ]; then
    echo "📋 テストファイル一覧:"
    find tests -name '*.test.js' -o -name '*.spec.js' -o -name 'test_*.py' | sed 's/^/  - /'
  fi
else
  echo "⚠️ testsディレクトリが見つかりません"
fi
echo

# ドキュメント状況
echo "📚 ドキュメント状況"
echo "----------------"
if [ -d docs ]; then
  DOC_COUNT=$(find docs -name '*.md' | wc -l)
  echo "📖 ドキュメントファイル数: $DOC_COUNT"
  echo "📋 主要ドキュメント:"
  [ -f README.md ] && echo "  ✅ README.md"
  [ -f docs/README.md ] && echo "  ✅ docs/README.md"
  [ -f .github/CODE_REVIEW_GUIDELINES.md ] && echo "  ✅ コードレビューガイドライン"
  [ -f PROJECT_RULES.md ] && echo "  ✅ プロジェクトルール"
else
  echo "⚠️ docsディレクトリが見つかりません"
fi
echo

# セキュリティ状況
echo "🔒 セキュリティ状況"
echo "----------------"
echo "🔍 機密情報スキャン実行中..."
if grep -r "api[_-]key\|password\|secret\|token" --include="*.js" --include="*.py" --include="*.sh" . 2>/dev/null | grep -v "YOUR_.*_HERE" | grep -v "example" | grep -v "test" | grep -v "template" >/dev/null; then
  echo "⚠️ 潜在的な機密情報が検出されました"
  echo "   詳細確認が必要です"
else
  echo "✅ 機密情報は検出されませんでした"
fi
echo

# 推奨アクション
echo "💡 推奨アクション"
echo "---------------"
if [ ! -d node_modules ] && [ -f package.json ]; then
  echo "📦 npm install を実行してください"
fi

if [ $TEST_FILES -eq 0 ]; then
  echo "🧪 テストファイルの追加を検討してください"
fi

if [ ! -f .gitignore ]; then
  echo "📝 .gitignoreファイルの作成を検討してください"
fi

echo
echo "🎉 ダッシュボード完了"
echo "詳細な情報が必要な場合は、個別のスクリプトを実行してください："
echo "  - ./scripts/check-mcp-config.sh (MCP設定詳細)"
echo "  - ./scripts/run-tests.sh (テスト実行)"