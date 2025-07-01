#!/bin/bash

# 成果物品質確認スクリプト
# Playwright自動テスト + 手動確認項目チェック

set -e

echo "🎯 成果物品質確認"
echo "=================="

# 設定
REPORT_DIR="quality-reports"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
REPORT_FILE="$REPORT_DIR/quality-check-$TIMESTAMP.md"

mkdir -p "$REPORT_DIR"

echo "📅 確認日時: $(date)" | tee "$REPORT_FILE"
echo "👤 確認者: $(whoami)" | tee -a "$REPORT_FILE"
echo "🌿 ブランチ: $(git branch --show-current)" | tee -a "$REPORT_FILE"
echo "📋 コミット: $(git log --oneline -1)" | tee -a "$REPORT_FILE"
echo | tee -a "$REPORT_FILE"

# 1. 環境確認
echo "🔍 1. 環境確認" | tee -a "$REPORT_FILE"
echo "=============" | tee -a "$REPORT_FILE"

# Node.js確認
if command -v node &> /dev/null; then
    NODE_VERSION=$(node --version)
    echo "✅ Node.js: $NODE_VERSION" | tee -a "$REPORT_FILE"
else
    echo "❌ Node.js: 未インストール" | tee -a "$REPORT_FILE"
fi

# npm確認
if command -v npm &> /dev/null; then
    NPM_VERSION=$(npm --version)
    echo "✅ npm: $NPM_VERSION" | tee -a "$REPORT_FILE"
else
    echo "❌ npm: 未インストール" | tee -a "$REPORT_FILE"
fi

# package.json確認
if [ -f package.json ]; then
    echo "✅ package.json: 存在" | tee -a "$REPORT_FILE"
    
    # Playwright確認
    if grep -q "playwright" package.json; then
        echo "✅ Playwright: 設定済み" | tee -a "$REPORT_FILE"
        PLAYWRIGHT_AVAILABLE=true
    else
        echo "⚠️ Playwright: 未設定" | tee -a "$REPORT_FILE"
        PLAYWRIGHT_AVAILABLE=false
    fi
else
    echo "❌ package.json: 存在しない" | tee -a "$REPORT_FILE"
    PLAYWRIGHT_AVAILABLE=false
fi

echo | tee -a "$REPORT_FILE"

# 2. 自動テスト実行
echo "🧪 2. 自動テスト実行" | tee -a "$REPORT_FILE"
echo "==================" | tee -a "$REPORT_FILE"

# 基本テスト
if [ -f package.json ] && npm run test &> /dev/null 2>&1; then
    echo "✅ 基本テスト: 通過" | tee -a "$REPORT_FILE"
    BASIC_TEST_PASS=true
else
    echo "❌ 基本テスト: 失敗または未設定" | tee -a "$REPORT_FILE"
    BASIC_TEST_PASS=false
fi

# Playwrightテスト
if [ "$PLAYWRIGHT_AVAILABLE" = true ]; then
    echo "🎭 Playwright テスト実行中..." | tee -a "$REPORT_FILE"
    
    # E2Eテスト実行
    if npm run test:e2e &> /dev/null 2>&1; then
        echo "✅ Playwright E2E: 通過" | tee -a "$REPORT_FILE"
        PLAYWRIGHT_TEST_PASS=true
    else
        echo "❌ Playwright E2E: 失敗" | tee -a "$REPORT_FILE"
        PLAYWRIGHT_TEST_PASS=false
        
        # エラー詳細を取得
        echo "📝 エラー詳細:" | tee -a "$REPORT_FILE"
        npm run test:e2e 2>&1 | tail -20 | sed 's/^/   /' | tee -a "$REPORT_FILE"
    fi
    
    # テストレポート生成
    if npm run test:report &> /dev/null 2>&1; then
        echo "✅ テストレポート: 生成完了" | tee -a "$REPORT_FILE"
    else
        echo "⚠️ テストレポート: 生成失敗" | tee -a "$REPORT_FILE"
    fi
else
    echo "⚠️ Playwright: 利用不可" | tee -a "$REPORT_FILE"
    PLAYWRIGHT_TEST_PASS=false
fi

echo | tee -a "$REPORT_FILE"

# 3. 手動確認項目
echo "👁️ 3. 手動確認項目" | tee -a "$REPORT_FILE"
echo "=================" | tee -a "$REPORT_FILE"

MANUAL_CHECKS=(
    "画面表示の正常性"
    "機能動作の完全性"
    "レスポンシブ対応"
    "アクセシビリティ"
    "パフォーマンス"
    "セキュリティ"
)

echo "以下の項目を手動で確認してください:" | tee -a "$REPORT_FILE"
for check in "${MANUAL_CHECKS[@]}"; do
    echo "- [ ] $check" | tee -a "$REPORT_FILE"
done

echo | tee -a "$REPORT_FILE"

# 4. 既存成果物の問題チェック
echo "🔍 4. 既存成果物問題チェック" | tee -a "$REPORT_FILE"
echo "=========================" | tee -a "$REPORT_FILE"

# 一般的な問題パターンをチェック
ISSUES_FOUND=()

# 文字化け確認
if find . -name "*.html" -o -name "*.md" | xargs grep -l "�" 2>/dev/null; then
    ISSUES_FOUND+=("文字化けファイルが存在")
fi

# 壊れたリンク確認（基本的なチェック）
if find . -name "*.md" | xargs grep -E "\[.*\]\(.*\)" | grep -E "\(http.*404\|broken\|error\)" 2>/dev/null; then
    ISSUES_FOUND+=("壊れたリンクの可能性")
fi

# 大きなファイル確認
LARGE_FILES=$(find . -type f -size +10M 2>/dev/null | grep -v ".git" | grep -v "node_modules" || true)
if [ -n "$LARGE_FILES" ]; then
    ISSUES_FOUND+=("大きなファイルが存在: $(echo $LARGE_FILES | tr '\n' ' ')")
fi

# セキュリティ問題確認
if grep -r "password\|secret\|key" . --include="*.js" --include="*.py" --include="*.md" 2>/dev/null | grep -v "example\|template\|placeholder" | head -5; then
    ISSUES_FOUND+=("機密情報の可能性がある記述")
fi

if [ ${#ISSUES_FOUND[@]} -eq 0 ]; then
    echo "✅ 既存成果物: 明らかな問題なし" | tee -a "$REPORT_FILE"
else
    echo "⚠️ 発見した問題:" | tee -a "$REPORT_FILE"
    for issue in "${ISSUES_FOUND[@]}"; do
        echo "   - $issue" | tee -a "$REPORT_FILE"
    done
fi

echo | tee -a "$REPORT_FILE"

# 5. 総合評価
echo "📊 5. 総合評価" | tee -a "$REPORT_FILE"
echo "=============" | tee -a "$REPORT_FILE"

SCORE=0
MAX_SCORE=4

if [ "$BASIC_TEST_PASS" = true ]; then
    SCORE=$((SCORE + 1))
fi

if [ "$PLAYWRIGHT_TEST_PASS" = true ]; then
    SCORE=$((SCORE + 2))
fi

if [ ${#ISSUES_FOUND[@]} -eq 0 ]; then
    SCORE=$((SCORE + 1))
fi

PERCENTAGE=$((SCORE * 100 / MAX_SCORE))

echo "📈 品質スコア: $SCORE/$MAX_SCORE ($PERCENTAGE%)" | tee -a "$REPORT_FILE"

if [ $PERCENTAGE -ge 85 ]; then
    QUALITY_LEVEL="🟢 優秀"
    RECOMMENDATION="✅ 成果物として問題なし"
elif [ $PERCENTAGE -ge 70 ]; then
    QUALITY_LEVEL="🟡 良好"
    RECOMMENDATION="⚠️ 軽微な改善後に成果物として利用可能"
else
    QUALITY_LEVEL="🔴 要改善"
    RECOMMENDATION="❌ 改善が必要"
fi

echo "🎯 品質レベル: $QUALITY_LEVEL" | tee -a "$REPORT_FILE"
echo "💡 推奨事項: $RECOMMENDATION" | tee -a "$REPORT_FILE"

echo | tee -a "$REPORT_FILE"

# 6. 次のアクション
echo "🚀 6. 次のアクション" | tee -a "$REPORT_FILE"
echo "=================" | tee -a "$REPORT_FILE"

if [ $PERCENTAGE -ge 85 ]; then
    echo "1. ✅ 成果物確認依頼メール送信" | tee -a "$REPORT_FILE"
    echo "2. 📧 ./scripts/send-completion-notice.sh を実行" | tee -a "$REPORT_FILE"
    echo "3. 🔄 レビュー・承認待ち" | tee -a "$REPORT_FILE"
else
    echo "1. 🔧 発見した問題の修正" | tee -a "$REPORT_FILE"
    echo "2. 🧪 再テスト実行" | tee -a "$REPORT_FILE"
    echo "3. 📊 品質スコア再確認" | tee -a "$REPORT_FILE"
fi

echo | tee -a "$REPORT_FILE"
echo "📄 詳細レポート: $REPORT_FILE" | tee -a "$REPORT_FILE"
echo "📅 確認完了: $(date)" | tee -a "$REPORT_FILE"

echo
echo "✅ 成果物品質確認完了"
echo "📄 レポート保存: $REPORT_FILE"

# 結果に応じた次のステップの提案
if [ $PERCENTAGE -ge 85 ]; then
    echo
    echo "🎉 品質基準をクリアしています！"
    echo "📧 確認依頼メールを送信しますか？"
    read -p "送信する場合は機能名を入力してください (Enter でスキップ): " FEATURE_NAME
    
    if [ -n "$FEATURE_NAME" ]; then
        # PR番号を取得
        CURRENT_BRANCH=$(git branch --show-current)
        echo "現在のブランチ: $CURRENT_BRANCH"
        read -p "PR番号を入力してください: " PR_NUMBER
        
        if [ -n "$PR_NUMBER" ]; then
            ./scripts/send-completion-notice.sh "$FEATURE_NAME" "$PR_NUMBER"
        fi
    fi
else
    echo
    echo "⚠️ 品質改善が必要です"
    echo "🔧 発見した問題を修正してから再実行してください"
fi