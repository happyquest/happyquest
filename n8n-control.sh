#!/bin/bash
# n8n制御スクリプト - 必要時のみ起動

case "$1" in
  "start")
    echo "n8nを起動中..."
    docker start happyquest-n8n
    echo "n8n起動完了: http://localhost:5678"
    echo "メモリ使用量が約168MB増加します"
    ;;
    
  "stop")
    echo "n8nを停止中..."
    docker stop happyquest-n8n
    echo "n8n停止完了（168MB解放）"
    ;;
    
  "restart")
    echo "n8nを再起動中..."
    docker restart happyquest-n8n
    echo "n8n再起動完了: http://localhost:5678"
    ;;
    
  "status")
    echo "=== n8n状態確認 ==="
    docker ps -a --filter name=happyquest-n8n --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    echo ""
    if docker ps --filter name=happyquest-n8n | grep -q happyquest-n8n; then
      echo "✅ n8nは稼働中: http://localhost:5678"
      echo "📊 現在のメモリ使用量:"
      docker stats --no-stream happyquest-n8n
    else
      echo "⏹️ n8nは停止中"
      echo "💡 起動する場合: $0 start"
    fi
    ;;
    
  "temp")
    echo "n8nを一時起動中（30分後自動停止）..."
    docker start happyquest-n8n
    echo "n8n起動完了: http://localhost:5678"
    echo "30分後に自動停止します..."
    (sleep 1800 && docker stop happyquest-n8n && echo "n8n自動停止完了") &
    ;;
    
  "logs")
    echo "=== n8nログ ==="
    docker logs --tail 20 happyquest-n8n
    ;;
    
  *)
    echo "n8n制御スクリプト"
    echo ""
    echo "使用方法:"
    echo "  $0 start     # n8n開始"
    echo "  $0 stop      # n8n停止"
    echo "  $0 restart   # n8n再起動"
    echo "  $0 status    # 状態確認"
    echo "  $0 temp      # 30分間一時起動"
    echo "  $0 logs      # ログ確認"
    echo ""
    echo "現在の状態:"
    docker ps -a --filter name=happyquest-n8n --format "{{.Names}}: {{.Status}}"
    ;;
esac