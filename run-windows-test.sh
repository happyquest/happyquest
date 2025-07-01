#!/bin/bash

# WSL内からWindows PowerShellでテスト実行
# HappyQuest WSL2テスト環境作成

echo "🔧 Windows PowerShellでWSL2テストインスタンス作成中..."

# PowerShellスクリプトのパス（Windows形式）
SCRIPT_PATH="$(wslpath -w "$(pwd)/test-new-wsl-instance.ps1")"

echo "📁 スクリプトパス: $SCRIPT_PATH"

# Windows PowerShellで管理者権限実行
powershell.exe -Command "Start-Process PowerShell -ArgumentList '-ExecutionPolicy Bypass -File \"$SCRIPT_PATH\"' -Verb RunAs"

echo "✅ PowerShellスクリプト実行開始"
echo "💡 管理者権限の確認ダイアログが表示される場合があります"