#!/bin/bash
# Docker リソース管理スクリプト

# 基本コマンド
echo "=== Docker リソース管理 ==="

case "$1" in
  "stop-heavy")
    echo "重いサービスを停止中..."
    docker stop happyquest-n8n
    echo "n8n停止完了（168MB解放）"
    ;;
  
  "start-heavy")
    echo "重いサービスを開始中..."
    docker start happyquest-n8n
    echo "n8n開始完了"
    ;;
    
  "stop-optional")
    echo "任意サービスを停止中..."
    docker stop happyquest-postgres happyquest-redis
    echo "DB系サービス停止完了（44MB解放）"
    ;;
    
  "start-core")
    echo "コアサービスのみ開始..."
    docker start happyquest-mcp-server github-mcp-server
    echo "MCP系サービス開始完了"
    ;;
    
  "cleanup")
    echo "クリーンアップ中..."
    docker system prune -f
    docker volume prune -f
    echo "未使用リソース削除完了"
    ;;
    
  "status")
    echo "=== リソース使用状況 ==="
    docker stats --no-stream
    echo ""
    echo "=== メモリ使用状況 ==="
    free -h
    ;;
    
  "auto-stop")
    echo "30分後に重いサービスを自動停止します..."
    (sleep 1800 && docker stop happyquest-n8n || echo "Auto-stop failed: $?" >&2) &
echo "Background job PID: $!"
    echo "バックグラウンドで30分タイマー開始"
    ;;
    
  *)
    echo "使用方法:"
    echo "  $0 stop-heavy    # 重いサービス停止"
    echo "  $0 start-heavy   # 重いサービス開始"
    echo "  $0 stop-optional # 任意サービス停止"
    echo "  $0 start-core    # コアサービスのみ"
    echo "  $0 cleanup       # リソース整理"
    echo "  $0 status        # 使用状況確認"
    echo "  $0 auto-stop     # 30分後自動停止"
    ;;
esac