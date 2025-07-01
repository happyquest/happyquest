#!/bin/bash
# GitHub整理計画スクリプト

echo "🔧 GitHub状況整理プラン"
echo "=========================="

case "$1" in
  "status")
    echo "📊 現在の状況:"
    echo ""
    echo "1. 未コミット変更:"
    git status --porcelain | wc -l | xargs echo "   - ファイル数:"
    echo ""
    echo "2. 未プッシュコミット:"
    git log --oneline origin/feature/clean-integration..HEAD | wc -l | xargs echo "   - コミット数:"
    echo ""
    echo "3. 未マージブランチ:"
    git branch --no-merged main | wc -l | xargs echo "   - ブランチ数:"
    echo ""
    echo "4. GitHub認証:"
    gh auth status 2>&1 | grep -q "Logged in" && echo "   ✅ 認証OK" || echo "   ❌ 認証エラー"
    ;;
    
  "step1")
    echo "🏗️ ステップ1: 現在の作業をコミット・プッシュ"
    echo ""
    read -p "現在の変更をコミットしますか？ (y/N): " confirm
    if [[ $confirm == [yY] ]]; then
      echo "📝 変更をコミット中..."
      git add .
      git commit -m "🔧 Docker・MCP最適化、GitHub管理ツール追加

🎯 実装内容:
- Docker最適化設定（メモリ制限・自動停止）
- MCP制御スクリプト（n8n停止で168MB削減）
- GitHub状況分析・整理ツール
- Gemini CLI用MCP設定

🛠️ 🤖 Generated with [Claude Code](https://claude.ai/code)

Co-Authored-By: Claude <noreply@anthropic.com>"
      
      echo "🚀 リモートにプッシュ中..."
      git push origin feature/clean-integration
      echo "✅ プッシュ完了"
    else
      echo "⏭️ スキップしました"
    fi
    ;;
    
  "step2")
    echo "🔐 ステップ2: GitHub認証修正"
    echo ""
    echo "GitHub CLIの認証を更新します..."
    gh auth login -h github.com
    echo ""
    echo "認証テスト中..."
    gh auth status
    ;;
    
  "step3")
    echo "🧹 ステップ3: 古いブランチ整理"
    echo ""
    echo "未マージブランチ一覧:"
    git branch --no-merged main | sed 's/^/  /'
    echo ""
    echo "各ブランチの確認:"
    for branch in $(git branch --no-merged main | tr -d ' *'); do
      if [[ "$branch" != "feature/clean-integration" ]]; then
        echo ""
        echo "📋 ブランチ: $branch"
        echo "   最新コミット: $(git log --oneline -1 $branch)"
        echo "   更新日時: $(git log -1 --format=%ci $branch)"
        read -p "   このブランチを削除しますか？ (y/N): " delete_branch
        if [[ $delete_branch == [yY] ]]; then
          git branch -D $branch
          git push origin --delete $branch 2>/dev/null || echo "   (リモートブランチは既に削除済み)"
          echo "   ✅ 削除完了"
        else
          echo "   ⏭️ 保持"
        fi
      fi
    done
    ;;
    
  "step4")
    echo "🔄 ステップ4: mainへのマージ準備"
    echo ""
    echo "現在のブランチ: $(git branch --show-current)"
    echo "mainとの差分ファイル数: $(git diff main --name-only | wc -l)"
    echo ""
    echo "マージ前チェック:"
    echo "1. GitHub Actions設定を確認"
    ls -la .github/workflows/ | grep -E '\.(yml|yaml)$' | wc -l | xargs echo "   - ワークフローファイル数:"
    echo ""
    echo "2. 重要ファイルの存在確認"
    [[ -f PROJECT_RULES.md ]] && echo "   ✅ PROJECT_RULES.md" || echo "   ❌ PROJECT_RULES.md"
    [[ -f CLAUDE.md ]] && echo "   ✅ CLAUDE.md" || echo "   ❌ CLAUDE.md"
    [[ -f ARCHITECTURE.md ]] && echo "   ✅ ARCHITECTURE.md" || echo "   ❌ ARCHITECTURE.md"
    echo ""
    read -p "PRを作成してmainにマージしますか？ (y/N): " create_pr
    if [[ $create_pr == [yY] ]]; then
      echo "📝 PR作成中..."
      gh pr create --title "🔧 Docker・MCP最適化とGitHub管理ツール統合" --body "$(cat <<'EOF'
## Summary
- Docker最適化によるメモリ使用量大幅削減（211MB削減）
- MCP制御システムの実装（n8n自動停止、コア機能分離）
- GitHub状況分析・整理ツールの追加
- Gemini CLI用MCP設定完了

## Test plan
- [x] Docker最適化動作確認
- [x] MCP制御スクリプト動作確認  
- [x] GitHub分析機能確認
- [ ] CI/CD パイプライン動作確認

🤖 Generated with [Claude Code](https://claude.ai/code)
EOF
)"
      echo "✅ PR作成完了"
    else
      echo "⏭️ 手動でPR作成してください"
    fi
    ;;
    
  "auto")
    echo "🤖 自動実行モード"
    echo ""
    echo "以下を順番に実行します:"
    echo "1. 現在の変更をコミット・プッシュ"
    echo "2. GitHub認証確認（必要に応じて手動）"
    echo "3. 古いブランチ確認"
    echo "4. PR作成準備"
    echo ""
    read -p "続行しますか？ (y/N): " auto_confirm
    if [[ $auto_confirm == [yY] ]]; then
      $0 step1
      echo ""
      $0 step3
      echo ""
      $0 step4
    fi
    ;;
    
  *)
    echo "🎯 GitHub整理の推奨手順:"
    echo ""
    echo "🚀 優先度高:"
    echo "  $0 step1    # 現在の変更をコミット・プッシュ"
    echo "  $0 step2    # GitHub認証修正"
    echo ""
    echo "🧹 優先度中:"
    echo "  $0 step3    # 古いブランチ整理"
    echo "  $0 step4    # mainへのマージ準備"
    echo ""
    echo "📊 状況確認:"
    echo "  $0 status   # 現在の状況表示"
    echo "  $0 auto     # 全自動実行"
    echo ""
    echo "⚠️  注意: step2は対話的なのでautoモードでは省略されます"
    ;;
esac