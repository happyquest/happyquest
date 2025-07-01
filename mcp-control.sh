#!/bin/bash
# MCP総合制御スクリプト

echo "=== MCP サーバー制御 ==="

case "$1" in
  "status")
    echo "📊 現在のMCPサーバー状況:"
    echo ""
    echo "🔄 稼働中:"
    docker ps --filter name=mcp --format "  ✅ {{.Names}} ({{.Status}})"
    echo ""
    echo "⏹️ 停止中:"
    docker ps -a --filter name=mcp --filter status=exited --format "  ❌ {{.Names}} ({{.Status}})"
    echo ""
    echo "💾 リソース使用量:"
    docker stats --no-stream --filter name=mcp
    ;;
    
  "start-core")
    echo "🚀 コアMCPサーバー起動中..."
    docker start happyquest-mcp-server github-mcp-server
    echo "✅ コアMCPサーバー起動完了"
    ;;
    
  "stop-optional")
    echo "⏸️ 任意MCPサーバー停止中..."
    docker stop happyquest-postgres happyquest-redis 2>/dev/null || true
    echo "✅ 任意MCPサーバー停止完了"
    ;;
    
  "restart-core")
    echo "🔄 コアMCPサーバー再起動中..."
    docker restart happyquest-mcp-server github-mcp-server
    echo "✅ コアMCPサーバー再起動完了"
    ;;
    
  "cleanup")
    echo "🧹 MCPリソースクリーンアップ中..."
    docker system prune -f --filter label=mcp
    echo "✅ クリーンアップ完了"
    ;;
    
  "logs")
    echo "📋 MCPサーバーログ:"
    echo ""
    echo "--- happyquest-mcp-server ---"
    docker logs --tail 10 happyquest-mcp-server 2>/dev/null || echo "ログなし"
    echo ""
    echo "--- github-mcp-server ---"
    docker logs --tail 10 github-mcp-server 2>/dev/null || echo "ログなし"
    ;;
    
  "test")
    echo "🧪 MCP接続テスト:"
    echo ""
    echo "Testing happyquest-mcp (port 3001):"
    curl -s http://localhost:3001/health | jq '.' 2>/dev/null || echo "❌ 接続失敗"
    echo ""
    echo "Testing github-mcp (port 3003):"
    curl -s http://localhost:3003/health | jq '.' 2>/dev/null || echo "❌ 接続失敗"
    ;;
    
  *)
    echo "MCP サーバー制御スクリプト"
    echo ""
    echo "🎯 稼働中MCPサーバー役割:"
    echo "  ✅ happyquest-mcp-server (3001) - HappyQuestプロジェクト固有機能"
    echo "  ✅ github-mcp-server (3003)     - GitHub操作・Issue管理"
    echo ""
    echo "⏸️ 停止済み（メモリ節約）:"
    echo "  ❌ happyquest-postgres          - データベース（44MB削減）"
    echo "  ❌ happyquest-redis             - キャッシュ"
    echo "  ❌ happyquest-n8n               - ワークフロー（168MB削減）"
    echo ""
    echo "📝 使用方法:"
    echo "  $0 status        # 全体状況確認"  
    echo "  $0 start-core    # コアサーバー起動"
    echo "  $0 stop-optional # 任意サーバー停止"
    echo "  $0 restart-core  # コア再起動"
    echo "  $0 cleanup       # リソース整理"
    echo "  $0 logs          # ログ確認"
    echo "  $0 test          # 接続テスト"
    echo ""
    echo "🎛️ Gemini CLI設定:"
    echo "  設定ファイル: ~/.config/gemini/config.json"
    echo "  MCPサーバー: happyquest-mcp, github-mcp, filesystem"
    ;;
esac