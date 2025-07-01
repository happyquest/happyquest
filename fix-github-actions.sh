#!/bin/bash
# GitHub Actions問題修正スクリプト

echo "🔧 GitHub Actions問題修正中..."

# 1. run-validation.shの改行コード修正
echo "1. 改行コード修正中..."
dos2unix scripts/run-validation.sh 2>/dev/null || (
    sed -i 's/\r$//' scripts/run-validation.sh
    echo "✅ CRLF→LF変換完了"
)

# 2. JUnitレポート生成機能を追加
echo "2. テストレポート生成機能追加中..."
cat >> scripts/run-validation.sh << 'EOF'

# JUnitレポート終了処理
generate_junit_report() {
    local total_tests=$((pass_count + warn_count + fail_count))
    
    sed -i "s/tests=\"0\"/tests=\"$total_tests\"/" "$JUNIT_REPORT"
    sed -i "s/failures=\"0\"/failures=\"$fail_count\"/" "$JUNIT_REPORT"
    sed -i "s/errors=\"0\"/errors=\"$warn_count\"/" "$JUNIT_REPORT"
    
    # テスト結果を追加
    local test_xml=""
    if [ $pass_count -gt 0 ]; then
        test_xml+="    <testcase name=\"System_Check\" classname=\"Environment\" time=\"1\"/>"$'\n'
    fi
    if [ $fail_count -gt 0 ]; then
        test_xml+="    <testcase name=\"Failed_Check\" classname=\"Environment\" time=\"1\">"$'\n'
        test_xml+="      <failure message=\"System validation failed\">Some checks failed</failure>"$'\n'
        test_xml+="    </testcase>"$'\n'
    fi
    
    sed -i "s|</testsuite>|$test_xml  </testsuite>|" "$JUNIT_REPORT"
    echo "  </testsuite>" >> "$JUNIT_REPORT"
    echo "</testsuites>" >> "$JUNIT_REPORT"
    
    success "JUnitレポート生成: $JUNIT_REPORT"
}

# メイン関数の最後で呼び出し
generate_junit_report
EOF

# 3. 実行権限確認
chmod +x scripts/run-validation.sh

# 4. PRテンプレート作成
echo "3. PRテンプレート確認中..."
if [ ! -f ".github/pull_request_template.md" ]; then
    cat > .github/pull_request_template.md << 'EOF'
## Summary
<!-- このPRの変更内容を簡潔に説明 -->

## Changes
<!-- 主な変更点をリスト形式で -->
- [ ] 

## Test Plan
<!-- テスト計画・実行結果 -->
- [ ] Unit tests pass
- [ ] Integration tests pass
- [ ] Manual testing completed

## Security
<!-- セキュリティ関連の確認 -->
- [ ] No secrets exposed
- [ ] Security scan passed

## Checklist
- [ ] Code follows project standards
- [ ] Documentation updated
- [ ] Tests added/updated
- [ ] Ready for review

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
    echo "✅ PRテンプレート作成完了"
fi

echo ""
echo "🎯 修正完了項目:"
echo "  ✅ 改行コード修正 (CRLF→LF)"
echo "  ✅ JUnitレポート生成機能追加"
echo "  ✅ 実行権限設定"
echo "  ✅ PRテンプレート作成"
echo ""
echo "📝 次の手順:"
echo "  1. git add ."
echo "  2. git commit -m '🔧 GitHub Actions修正'"
echo "  3. git push origin feature/clean-integration-secure"
echo "  4. gh pr create で PR作成"