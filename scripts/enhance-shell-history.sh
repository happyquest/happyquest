#!/bin/bash

# シェル履歴強化スクリプト
# より多くのコマンド履歴を保存・表示できるように設定

echo "🚀 シェル履歴設定を強化します"
echo "================================"

# バックアップ作成
if [ ! -f ~/.bashrc.backup ]; then
    cp ~/.bashrc ~/.bashrc.backup
    echo "✅ ~/.bashrc のバックアップを作成しました"
fi

# 現在の設定確認
echo "📊 現在の設定:"
echo "HISTSIZE: ${HISTSIZE:-未設定}"
echo "HISTFILESIZE: ${HISTFILESIZE:-未設定}"
echo "HISTCONTROL: ${HISTCONTROL:-未設定}"
echo

# 履歴設定を更新
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "

# .bashrcに設定を追加（重複チェック）
if ! grep -q "履歴設定の強化" ~/.bashrc; then
    cat >> ~/.bashrc << 'EOF'

# 🚀 履歴設定の強化
export HISTSIZE=50000
export HISTFILESIZE=100000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%Y-%m-%d %H:%M:%S "
shopt -s histappend
PROMPT_COMMAND="history -a; history -c; history -r; $PROMPT_COMMAND"

EOF
    echo "✅ ~/.bashrc に履歴設定を追加しました"
else
    echo "ℹ️ 履歴設定は既に追加済みです"
fi

# 設定を即座に反映
shopt -s histappend

echo
echo "🎉 履歴設定強化完了!"
echo "📈 新しい設定:"
echo "  - HISTSIZE: $HISTSIZE (メモリ内履歴)"
echo "  - HISTFILESIZE: $HISTFILESIZE (ファイル履歴)"
echo "  - 重複除去: 有効"
echo "  - タイムスタンプ: 有効"
echo "  - 即座保存: 有効"
echo
echo "💡 使用方法:"
echo "  - history | tail -50    # 最新50件表示"
echo "  - history | grep 'git'  # git関連コマンド検索"
echo "  - Ctrl+R               # 履歴検索"
echo "  - !!                   # 直前のコマンド実行"
echo "  - !git                 # 最新のgitコマンド実行"
echo
echo "🔄 新しいターミナルセッションで設定が完全に有効になります"