#!/bin/bash

# 🐳 HappyQuest Docker MCP 統合起動スクリプト
# 作成日: 2025年6月8日
# 目的: GitHub & Browser MCP のDocker統合実行

set -euo pipefail

# カラー定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 環境チェック
check_environment() {
    log_info "環境チェック開始..."
    
    # Docker確認
    if ! command -v docker &> /dev/null; then
        log_error "Dockerがインストールされていません"
        exit 1
    fi
    
    # Docker daemon確認
    if ! docker info &> /dev/null; then
        log_error "Docker daemonが起動していません"
        log_info "以下のコマンドで起動してください:"
        echo "sudo systemctl start docker"
        exit 1
    fi
    
    # GitHub Token確認
    if [[ -z "${GITHUB_TOKEN:-}" ]]; then
        log_warning "GITHUB_TOKEN環境変数が設定されていません"
        log_info "GitHub MCPを使用するには以下を実行:"
        echo 'export GITHUB_TOKEN="your_token_here"'
    fi
    
    log_success "環境チェック完了"
}

# GitHub MCP Dockerイメージビルド
build_github_mcp() {
    log_info "GitHub MCP Dockerイメージ作成..."
    
    # Dockerfile作成
    cat > Dockerfile.github-mcp << 'EOF'
FROM node:18-slim

# 必要パッケージインストール
RUN apt-get update && apt-get install -y \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/*

# MCP GitHub server インストール
RUN npm install -g @modelcontextprotocol/server-github

# 作業ディレクトリ
WORKDIR /app

# エントリーポイント
ENTRYPOINT ["npx", "@modelcontextprotocol/server-github"]
EOF

    # イメージビルド
    docker build -t happyquest/mcp-github:latest -f Dockerfile.github-mcp .
    
    log_success "GitHub MCPイメージ作成完了"
}

# Browser MCP Dockerイメージビルド
build_browser_mcp() {
    log_info "Browser MCP Dockerイメージ作成..."
    
    # Dockerfile作成
    cat > Dockerfile.browser-mcp << 'EOF'
FROM mcr.microsoft.com/playwright:v1.40.0-focal

# 必要パッケージインストール
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# MCP Browser server インストール
RUN npm install -g @modelcontextprotocol/server-playwright

# 作業ディレクトリ
WORKDIR /app

# エントリーポイント
ENTRYPOINT ["npx", "@modelcontextprotocol/server-playwright"]
EOF

    # イメージビルド
    docker build -t happyquest/mcp-browser:latest -f Dockerfile.browser-mcp .
    
    log_success "Browser MCPイメージ作成完了"
}

# GitHub MCP起動
start_github_mcp() {
    log_info "GitHub MCP Docker起動..."
    
    # 既存コンテナ停止・削除
    docker stop happyquest-github-mcp 2>/dev/null || true
    docker rm happyquest-github-mcp 2>/dev/null || true
    
    # 新規起動
    docker run -d \
        --name happyquest-github-mcp \
        --restart unless-stopped \
        -e GITHUB_TOKEN="${GITHUB_TOKEN:-}" \
        -p 3001:3001 \
        --memory="512m" \
        --cpus="1" \
        happyquest/mcp-github:latest
    
    log_success "GitHub MCP起動完了 (Port: 3001)"
}

# Browser MCP起動
start_browser_mcp() {
    log_info "Browser MCP Docker起動..."
    
    # 既存コンテナ停止・削除
    docker stop happyquest-browser-mcp 2>/dev/null || true
    docker rm happyquest-browser-mcp 2>/dev/null || true
    
    # 新規起動
    docker run -d \
        --name happyquest-browser-mcp \
        --restart unless-stopped \
        -e DISPLAY=:0 \
        -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
        --shm-size=2gb \
        -p 3002:3002 \
        --memory="1g" \
        --cpus="1" \
        happyquest/mcp-browser:latest
    
    log_success "Browser MCP起動完了 (Port: 3002)"
}

# 動作確認
verify_setup() {
    log_info "動作確認中..."
    
    # GitHub MCP確認
    if docker ps | grep -q happyquest-github-mcp; then
        log_success "GitHub MCP: 動作中"
    else
        log_error "GitHub MCP: 起動失敗"
    fi
    
    # Browser MCP確認  
    if docker ps | grep -q happyquest-browser-mcp; then
        log_success "Browser MCP: 動作中"
    else
        log_warning "Browser MCP: 停止中 (オプション機能)"
    fi
    
    # リソース使用量表示
    log_info "リソース使用状況:"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}" | grep happyquest || true
}

# 停止関数
stop_mcp() {
    log_info "MCP Docker停止中..."
    docker stop happyquest-github-mcp happyquest-browser-mcp 2>/dev/null || true
    docker rm happyquest-github-mcp happyquest-browser-mcp 2>/dev/null || true
    log_success "MCP Docker停止完了"
}

# メイン実行
main() {
    case "${1:-start}" in
        "start")
            check_environment
            build_github_mcp
            # build_browser_mcp  # 必要時有効化
            start_github_mcp
            # start_browser_mcp  # 必要時有効化
            verify_setup
            ;;
        "stop")
            stop_mcp
            ;;
        "status")
            verify_setup
            ;;
        "rebuild")
            stop_mcp
            build_github_mcp
            # build_browser_mcp
            start_github_mcp
            # start_browser_mcp
            verify_setup
            ;;
        *)
            echo "使用法: $0 {start|stop|status|rebuild}"
            echo "  start   - MCP Docker起動"
            echo "  stop    - MCP Docker停止"
            echo "  status  - 動作状況確認"
            echo "  rebuild - 再ビルド&起動"
            exit 1
            ;;
    esac
}

main "$@" 