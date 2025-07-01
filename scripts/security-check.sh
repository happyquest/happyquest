#!/bin/bash

# セキュリティチェックスクリプト
# 作業開始前の必須セキュリティ確認

set -e

echo "🔍 HappyQuest セキュリティチェック開始"
echo "========================================"
echo "📅 実行日時: $(date)"
echo

# 結果格納用
SECURITY_REPORT="security-reports/security-check-$(date +%Y%m%d-%H%M%S).md"
mkdir -p security-reports

# レポートヘッダー作成
cat > "$SECURITY_REPORT" << EOF
# セキュリティチェックレポート

**実行日時**: $(date)  
**実行者**: $(whoami)  
**ブランチ**: $(git branch --show-current)  
**コミット**: $(git rev-parse HEAD)

## チェック結果

EOF

echo "📝 レポート作成: $SECURITY_REPORT"
echo

# 1. 機密情報検出
echo "🔍 1. 機密情報検出チェック"
echo "------------------------"

SECRETS_FOUND=0
SECRET_PATTERNS=(
    "api[_-]key"
    "password"
    "secret"
    "token"
    "private[_-]key"
    "access[_-]key"
    "auth[_-]token"
    "bearer"
    "oauth"
    "credential"
)

echo "## 1. 機密情報検出" >> "$SECURITY_REPORT"

for pattern in "${SECRET_PATTERNS[@]}"; do
    echo "  🔍 パターン検索: $pattern"
    
    # 検索実行（除外パターンあり）
    MATCHES=$(grep -ri "$pattern" \
        --include="*.js" \
        --include="*.py" \
        --include="*.sh" \
        --include="*.json" \
        --include="*.yml" \
        --include="*.yaml" \
        --include="*.md" \
        . 2>/dev/null | \
        grep -v "YOUR_.*_HERE" | \
        grep -v "example" | \
        grep -v "test" | \
        grep -v "template" | \
        grep -v "placeholder" | \
        grep -v "sample" | \
        grep -v "demo" | \
        grep -v "# " | \
        grep -v "//" | \
        grep -v "node_modules" | \
        grep -v ".git/" | \
        grep -v "security-reports/" || true)
    
    if [ -n "$MATCHES" ]; then
        echo "    ⚠️ 検出: $pattern"
        echo "### ⚠️ 検出パターン: $pattern" >> "$SECURITY_REPORT"
        echo '```' >> "$SECURITY_REPORT"
        echo "$MATCHES" >> "$SECURITY_REPORT"
        echo '```' >> "$SECURITY_REPORT"
        echo >> "$SECURITY_REPORT"
        SECRETS_FOUND=$((SECRETS_FOUND + 1))
    else
        echo "    ✅ 問題なし: $pattern"
    fi
done

if [ $SECRETS_FOUND -eq 0 ]; then
    echo "✅ 機密情報は検出されませんでした"
    echo "**結果**: ✅ 機密情報検出なし" >> "$SECURITY_REPORT"
else
    echo "⚠️ $SECRETS_FOUND 個のパターンで機密情報が検出されました"
    echo "**結果**: ⚠️ $SECRETS_FOUND 個のパターンで検出" >> "$SECURITY_REPORT"
fi

echo >> "$SECURITY_REPORT"
echo

# 2. 総合判定
echo "📊 2. 総合判定"
echo "------------"

echo "## 2. 総合判定" >> "$SECURITY_REPORT"

if [ $SECRETS_FOUND -eq 0 ]; then
    SECURITY_LEVEL="✅ 安全"
    echo "🎉 セキュリティチェック完了: 問題なし"
    echo "**総合判定**: ✅ 安全 (問題なし)" >> "$SECURITY_REPORT"
else
    SECURITY_LEVEL="⚠️ 注意"
    echo "⚠️ セキュリティチェック完了: 問題あり ($SECRETS_FOUND 件)"
    echo "**総合判定**: ⚠️ 注意 ($SECRETS_FOUND 件の問題)" >> "$SECURITY_REPORT"
fi

echo >> "$SECURITY_REPORT"

echo
echo "📄 詳細レポート: $SECURITY_REPORT"
echo "🔒 セキュリティレベル: $SECURITY_LEVEL"
echo
echo "✅ セキュリティチェック完了"