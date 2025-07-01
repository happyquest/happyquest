#!/bin/bash

# MCP設定確認スクリプト
# 作成日: 2025年6月23日

echo "===== MCP設定確認スクリプト ====="
echo "現在の日時: $(date)"
echo

# .cursor/mcp.jsonの存在確認
if [ -f .cursor/mcp.json ]; then
  echo "✅ MCP設定ファイルが存在します"
  
  # 設定ファイルの内容を表示
  echo "--- MCP設定の概要 ---"
  cat .cursor/mcp.json | grep "description" | sed 's/.*: "\(.*\)",/\1/'
  echo
  
  # 設定されているサーバー数を表示
  SERVER_COUNT=$(cat .cursor/mcp.json | grep -c "command")
  echo "設定されているMCPサーバー数: $SERVER_COUNT"
  
  # グローバル設定の確認
  if grep -q "globalSettings" .cursor/mcp.json; then
    echo "✅ グローバル設定が存在します"
    
    # ツール制限の確認
    TOOL_LIMIT=$(cat .cursor/mcp.json | grep "totalToolLimit" | sed 's/.*: \([0-9]*\).*/\1/')
    echo "ツール制限: $TOOL_LIMIT"
  else
    echo "❌ グローバル設定が見つかりません"
  fi
else
  echo "❌ MCP設定ファイルが見つかりません"
fi

echo
echo "===== 依存関係の確認 ====="

# package.jsonの確認
if [ -f package.json ]; then
  echo "✅ package.jsonが存在します"
  
  # MCP関連の依存関係を確認
  if grep -q "modelcontextprotocol" package.json; then
    echo "✅ MCP関連の依存関係が設定されています"
  else
    echo "❌ MCP関連の依存関係が見つかりません"
  fi
else
  echo "❌ package.jsonが見つかりません"
fi

echo
echo "===== 確認完了 ====="