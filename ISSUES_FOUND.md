#!/bin/bash

# HappyQuest Ubuntu 24.04 WSL2 環境自動構築スクリプト（修正版）
# 作成者: HappyQuest開発チーム
# 最終更新: 2025-01-27

set -e

# 色付きテキスト用の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ログ関数
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}"
    exit 1
}

# 環境判定
detect_environment() {
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        echo "wsl"
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "win32" ]]; then
        echo "windows"
    else
        echo "linux"
    fi
}

# 前提条件チェック（修正版）
check_prerequisites() {
    log "前提条件をチェック中..."
    
    local env=$(detect_environment)
    log "検出された環境: $env"
    
    case $env in
        "wsl")
            log "WSL環境内で実行中です"
            # WSL内部では直接構築処理を実行
            ;;
        "windows")
            log "Windows環境で実行中です"
            # WSLコマンドが利用可能かチェック
            if ! command -v wsl &> /dev/null; then
                error "WSL2が利用できません。Windows 11でWSL2を有効化してください。"
            fi
            ;;
        "linux")
            log "Linux環境で実行中です"
            # 通常のLinux環境
            ;;
    esac
    
    # 必要なツールのチェック
    local missing_tools=()
    
    if ! command -v git &> /dev/null; then
        missing_tools+=("git")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        warning "不足しているツール: ${missing_tools[*]}"
        log "必要なツールをインストールします..."
        sudo apt update && sudo apt install -y "${missing_tools[@]}"
    fi
    
    success "前提条件チェック完了"
}

# シンプル構築プロセス（Packer代替）
run_simple_build() {
    log "シンプル構築プロセスを開始..."
    
    # 既存のubuntu2204setup.shベースの改良版を使用
    if [[ -f "../ubuntu2204setup.sh" ]]; then
        log "既存のセットアップスクリプトを使用します"
        
        # Ubuntu 24.04用に調整して実行
        log "Ubuntu 24.04セットアップを実行中..."
        run_ubuntu24_setup
    else
        log "手動セットアップを実行します"
        run_manual_setup
    fi
    
    success "構築プロセス完了"
}

# Ubuntu 24.04セットアップ（ubuntu2204setup.shベース）
run_ubuntu24_setup() {
    log "Ubuntu 24.04環境セットアップ開始..."
    
    # システム更新
    sudo apt update && sudo apt upgrade -y
    
    # 基本パッケージ
    sudo apt install -y curl wget git vim build-essential
    
    # Docker インストール
    install_docker
    
    # GitHub CLI インストール
    install_github_cli
    
    # Python環境（pyenv + uv）
    install_python_env
    
    # Node.js環境（nvm）
    install_nodejs_env
    
    # HashiCorp Vault
    install_vault
    
    # プロジェクト構造作成
    setup_project_structure
    
    success "Ubuntu 24.04セットアップ完了"
}

# Docker インストール
install_docker() {
    log "Dockerをインストール中..."
    
    # 古いDockerを削除
    sudo apt remove -y docker docker-engine docker.io containerd runc 2>/dev/null || true
    
    # 必要なパッケージをインストール
    sudo apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
    
    # Docker GPGキーを追加
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Dockerリポジトリを追加
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Dockerをインストール
    sudo apt update && sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    
    # 現在のユーザーをdockerグループに追加
    sudo usermod -aG docker $USER
    
    # Dockerサービスを開始
    sudo systemctl enable docker
    sudo systemctl start docker
    
    success "Docker インストール完了"
}

# GitHub CLI インストール
install_github_cli() {
    log "GitHub CLIをインストール中..."
    
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
    sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
    sudo apt update && sudo apt install -y gh
    
    success "GitHub CLI インストール完了"
}

# Python環境セットアップ
install_python_env() {
    log "Python環境をセットアップ中..."
    
    # pyenvの依存関係
    sudo apt install -y make build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev python3-openssl
    
    # pyenvインストール
    if [[ ! -d "$HOME/.pyenv" ]]; then
        curl https://pyenv.run | bash
        
        # .bashrcに追加
        cat >> ~/.bashrc << 'EOF'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init -)"
EOF
        
        # 現在のセッションで有効化
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)"
    fi
    
    # Python 3.12.9インストール
    pyenv install 3.12.9
    pyenv global 3.12.9
    
    # uvインストール
    curl -LsSf https://astral.sh/uv/install.sh | sh
    
    success "Python環境セットアップ完了"
}

# Node.js環境セットアップ
install_nodejs_env() {
    log "Node.js環境をセットアップ中..."
    
    # nvmインストール
    if [[ ! -d "$HOME/.nvm" ]]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
        
        # .bashrcに追加
        cat >> ~/.bashrc << 'EOF'

# nvm configuration
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
EOF
        
        # 現在のセッションで有効化
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Node.js 23.8.0インストール
    nvm install 23.8.0
    nvm use 23.8.0
    nvm alias default 23.8.0
    
    success "Node.js環境セットアップ完了"
}

# HashiCorp Vault インストール
install_vault() {
    log "HashiCorp Vaultをインストール中..."
    
    # HashiCorp GPGキーを追加
    wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
    
    # Vaultインストール
    sudo apt update && sudo apt install -y vault
    
    success "HashiCorp Vault インストール完了"
}

# プロジェクト構造セットアップ
setup_project_structure() {
    log "プロジェクト構造をセットアップ中..."
    
    local project_dir="$HOME/happyquest"
    
    # ディレクトリ作成
    mkdir -p "$project_dir"/{src,tests,docs,infrastructure,作業報告書,トラブル事例,アーカイブ}
    mkdir -p "$project_dir/docs"/{plantuml,database,images}
    mkdir -p "$project_dir"/.github/workflows
    
    # 基本ファイル作成
    create_basic_files "$project_dir"
    
    success "プロジェクト構造セットアップ完了"
}

# 基本ファイル作成
create_basic_files() {
    local project_dir="$1"
    
    # .gitignore
    cat > "$project_dir/.gitignore" << 'EOF'
# Python
__pycache__/
*.py[cod]
.pytest_cache/
.coverage
htmlcov/

# Node.js
node_modules/
npm-debug.log*

# IDE
.vscode/
.idea/

# OS
.DS_Store

# Vault
.vault-token
vault-data/

# Logs
*.log
EOF

    # Makefile
    cat > "$project_dir/Makefile" << 'EOF'
.PHONY: help test lint format clean

help:
	@echo 'Usage: make [target]'
	@echo 'Targets:'
	@echo '  test     Run tests'
	@echo '  lint     Run linting'
	@echo '  format   Format code'
	@echo '  clean    Clean build artifacts'

test:
	pytest
	npm test

lint:
	flake8 src/
	npm run lint

format:
	black src/
	npm run format

clean:
	find . -name __pycache__ -exec rm -rf {} +
	rm -rf node_modules/
EOF

    # README.md
    cat > "$project_dir/README.md" << 'EOF'
# HappyQuest Development Project

## 概要
AI開発プロジェクトのための統合開発環境

## セットアップ
```bash
make install
make test
```

## 環境情報
- Ubuntu 24.04 WSL2
- Python 3.12.9 (pyenv)
- Node.js 23.8.0 (nvm)
- Docker CE
- HashiCorp Vault
EOF
}

# 環境テスト
test_environment() {
    log "環境テストを実行中..."
    
    # バージョン確認
    echo "=== ソフトウェアバージョン ==="
    python3 --version || warning "Python3が利用できません"
    node --version || warning "Node.jsが利用できません"
    docker --version || warning "Dockerが利用できません"
    gh --version || warning "GitHub CLIが利用できません"
    vault --version || warning "Vaultが利用できません"
    
    success "環境テスト完了"
}

# メイン処理
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               HappyQuest 環境構築（修正版）                    ║"
    echo "║                Ubuntu 24.04 WSL2 Simple Setup                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "HappyQuest環境構築（修正版）を開始します..."
    
    check_prerequisites
    run_simple_build
    test_environment
    
    success "🎉 HappyQuest環境構築が完了しました！"
    echo ""
    echo "📋 次のステップ:"
    echo "   cd ~/happyquest"
    echo "   make help"
    echo ""
}

# ヘルプ表示
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  --help, -h    このヘルプを表示"
    echo "  --test-only   環境テストのみ実行"
    echo ""
    exit 0
fi

if [[ "$1" == "--test-only" ]]; then
    test_environment
    exit 0
fi

# メイン処理実行
main "$@" 