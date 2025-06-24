#!/bin/bash

# シェル設定確認スクリプト

echo "🔍 現在のシェル設定確認"
echo "======================"
echo

echo "📊 履歴設定:"
echo "  HISTSIZE: ${HISTSIZE:-未設定}"
echo "  HISTFILESIZE: ${HISTFILESIZE:-未設定}"
echo "  HISTCONTROL: ${HISTCONTROL:-未設定}"
echo "  HISTTIMEFORMAT: ${HISTTIMEFORMAT:-未設定}"
echo

echo "📺 表示設定:"
echo "  PAGER: ${PAGER:-未設定}"
echo "  LESS: ${LESS:-未設定}"
echo "  LINES: ${LINES:-未設定}"
echo "  COLUMNS: ${COLUMNS:-未設定}"
echo

echo "🔧 利用可能なエイリアス:"
alias | grep -E "^(h|hgrep)" | sort
echo

echo "📝 履歴ファイル情報:"
if [ -f ~/.bash_history ]; then
    echo "  ファイル: ~/.bash_history"
    echo "  行数: $(wc -l < ~/.bash_history)"
    echo "  サイズ: $(du -h ~/.bash_history | cut -f1)"
else
    echo "  履歴ファイルなし"
fi
echo

echo "💡 便利なコマンド:"
echo "  h50                    # 最新50件表示"
echo "  hgrep 'git'           # git関連コマンド検索"
echo "  history | grep 'npm'  # npm関連コマンド検索"
echo "  Ctrl+R                # インタラクティブ履歴検索"
echo "  !!                    # 直前のコマンド再実行"
echo "  !git                  # 最新のgitコマンド再実行"