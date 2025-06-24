#!/bin/bash

# チャットログ管理システム
# チャットログの作成、検索、管理を統合

set -e

CHAT_DIR="chat-logs"
SCRIPT_NAME=$(basename "$0")

show_help() {
    cat << EOF
💬 チャットログ管理システム

使用方法:
  $SCRIPT_NAME <コマンド> [オプション]

コマンド:
  create <概要>     新しいチャットログを作成
  collect          現在のセッション情報を収集
  list             既存のチャットログ一覧表示
  search <キーワード> ログ内容を検索
  recent [数]      最近のログを表示（デフォルト: 5）
  summary          ログの統計情報表示
  archive          古いログをアーカイブ
  help             このヘルプを表示

例:
  $SCRIPT_NAME create "エラー予防システム実装"
  $SCRIPT_NAME collect
  $SCRIPT_NAME search "セキュリティ"
  $SCRIPT_NAME recent 10
  $SCRIPT_NAME summary

EOF
}

create_chat_log() {
    if [ -z "$1" ]; then
        echo "❌ エラー: セッション概要を指定してください"
        echo "使用方法: $SCRIPT_NAME create \"セッション概要\""
        exit 1
    fi
    
    echo "💬 チャットログ作成中..."
    ./scripts/save-chat-log.sh "$1"
}

collect_session_info() {
    echo "📊 セッション情報収集中..."
    ./scripts/collect-session-info.sh
}

list_chat_logs() {
    echo "📋 チャットログ一覧"
    echo "=================="
    
    if [ ! -d "$CHAT_DIR" ]; then
        echo "📁 チャットログディレクトリが存在しません"
        return
    fi
    
    echo "📅 作成日時          📝 ファイル名"
    echo "----------------------------------------"
    
    find "$CHAT_DIR" -name "*.md" -type f | sort -r | while read -r file; do
        if [ -f "$file" ]; then
            # ファイルの作成日時を取得
            DATE=$(stat -c %y "$file" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1 || echo "不明")
            BASENAME=$(basename "$file")
            printf "%-20s %s\n" "$DATE" "$BASENAME"
        fi
    done
}

search_chat_logs() {
    if [ -z "$1" ]; then
        echo "❌ エラー: 検索キーワードを指定してください"
        echo "使用方法: $SCRIPT_NAME search \"キーワード\""
        exit 1
    fi
    
    KEYWORD="$1"
    echo "🔍 チャットログ検索: \"$KEYWORD\""
    echo "================================"
    
    if [ ! -d "$CHAT_DIR" ]; then
        echo "📁 チャットログディレクトリが存在しません"
        return
    fi
    
    FOUND=0
    find "$CHAT_DIR" -name "*.md" -type f | sort -r | while read -r file; do
        if grep -l -i "$KEYWORD" "$file" >/dev/null 2>&1; then
            echo "📄 ファイル: $(basename "$file")"
            echo "   マッチした行:"
            grep -n -i --color=always "$KEYWORD" "$file" | head -3 | sed 's/^/   /'
            echo
            FOUND=$((FOUND + 1))
        fi
    done
    
    if [ $FOUND -eq 0 ]; then
        echo "🔍 \"$KEYWORD\" に一致するログが見つかりませんでした"
    fi
}

show_recent_logs() {
    COUNT=${1:-5}
    echo "📅 最近のチャットログ（最新 $COUNT 件）"
    echo "====================================="
    
    if [ ! -d "$CHAT_DIR" ]; then
        echo "📁 チャットログディレクトリが存在しません"
        return
    fi
    
    find "$CHAT_DIR" -name "*.md" -type f | sort -r | head -"$COUNT" | while read -r file; do
        if [ -f "$file" ]; then
            echo "📄 $(basename "$file")"
            echo "   作成日時: $(stat -c %y "$file" 2>/dev/null | cut -d'.' -f1 || echo "不明")"
            
            # セッション概要を抽出
            SUMMARY=$(grep "セッション概要" "$file" | head -1 | sed 's/.*: //' || echo "概要なし")
            echo "   概要: $SUMMARY"
            
            # 主な作業内容を抽出
            echo "   主な作業:"
            grep -A 3 "主な作業内容" "$file" | grep "^- \[" | head -3 | sed 's/^/     /' || echo "     作業内容なし"
            echo
        fi
    done
}

show_summary() {
    echo "📊 チャットログ統計情報"
    echo "====================="
    
    if [ ! -d "$CHAT_DIR" ]; then
        echo "📁 チャットログディレクトリが存在しません"
        return
    fi
    
    TOTAL_LOGS=$(find "$CHAT_DIR" -name "*.md" -type f | wc -l)
    echo "📄 総ログ数: $TOTAL_LOGS"
    
    if [ $TOTAL_LOGS -eq 0 ]; then
        echo "📝 ログファイルがありません"
        return
    fi
    
    # 最古と最新のログ
    OLDEST=$(find "$CHAT_DIR" -name "*.md" -type f | sort | head -1)
    NEWEST=$(find "$CHAT_DIR" -name "*.md" -type f | sort -r | head -1)
    
    if [ -n "$OLDEST" ]; then
        echo "📅 最古のログ: $(basename "$OLDEST")"
        echo "   作成日時: $(stat -c %y "$OLDEST" 2>/dev/null | cut -d'.' -f1 || echo "不明")"
    fi
    
    if [ -n "$NEWEST" ]; then
        echo "📅 最新のログ: $(basename "$NEWEST")"
        echo "   作成日時: $(stat -c %y "$NEWEST" 2>/dev/null | cut -d'.' -f1 || echo "不明")"
    fi
    
    # ディスク使用量
    TOTAL_SIZE=$(du -sh "$CHAT_DIR" 2>/dev/null | cut -f1 || echo "不明")
    echo "💾 総サイズ: $TOTAL_SIZE"
    
    # 頻出キーワード分析
    echo
    echo "🔍 頻出キーワード（上位10）:"
    find "$CHAT_DIR" -name "*.md" -type f -exec cat {} \; | \
        tr '[:upper:]' '[:lower:]' | \
        grep -oE '\b[a-zA-Z]{4,}\b' | \
        sort | uniq -c | sort -nr | head -10 | \
        while read -r count word; do
            printf "   %-15s: %d回\n" "$word" "$count"
        done 2>/dev/null || echo "   キーワード分析に失敗"
}

archive_old_logs() {
    echo "📦 古いログのアーカイブ"
    echo "===================="
    
    if [ ! -d "$CHAT_DIR" ]; then
        echo "📁 チャットログディレクトリが存在しません"
        return
    fi
    
    ARCHIVE_DIR="$CHAT_DIR/archive"
    mkdir -p "$ARCHIVE_DIR"
    
    # 30日以上古いファイルをアーカイブ
    ARCHIVED=0
    find "$CHAT_DIR" -name "*.md" -type f -mtime +30 | while read -r file; do
        if [ -f "$file" ] && [[ "$file" != *"/archive/"* ]]; then
            mv "$file" "$ARCHIVE_DIR/"
            echo "📦 アーカイブ: $(basename "$file")"
            ARCHIVED=$((ARCHIVED + 1))
        fi
    done
    
    if [ $ARCHIVED -eq 0 ]; then
        echo "📝 アーカイブ対象のログファイルはありません（30日以内のファイルのみ）"
    else
        echo "✅ $ARCHIVED 件のログをアーカイブしました"
    fi
}

# メイン処理
case "${1:-help}" in
    "create")
        create_chat_log "$2"
        ;;
    "collect")
        collect_session_info
        ;;
    "list")
        list_chat_logs
        ;;
    "search")
        search_chat_logs "$2"
        ;;
    "recent")
        show_recent_logs "$2"
        ;;
    "summary")
        show_summary
        ;;
    "archive")
        archive_old_logs
        ;;
    "help"|"-h"|"--help")
        show_help
        ;;
    *)
        echo "❌ 不明なコマンド: $1"
        echo
        show_help
        exit 1
        ;;
esac