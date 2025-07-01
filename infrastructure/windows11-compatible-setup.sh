#!/bin/bash

# Windows 11 → WSL2 Ubuntu 対応自動環境構築スクリプト
# Homebrew不要版

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

print_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║          HappyQuest Windows 11 対応環境構築                   ║
║              Homebrew不要・直接インストール版                  ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# システム更新・基本パッケージインストール
install_system_packages() {
    log "システムパッケージを更新・インストール中..."
    
    sudo apt update
    sudo apt install -y \
        build-essential \
        curl \
        git \
        wget \
        unzip \
        software-properties-common \
        ca-certificates \
        gnupg \
        lsb-release \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        libncurses5-dev \
        libncursesw5-dev \
        libffi-dev \
        liblzma-dev \
        python3-dev \
        python3-pip \
        python3-venv
        
    success "システムパッケージインストール完了"
}

# pyenv インストール (Homebrew不要)
install_pyenv() {
    log "pyenv をインストール中..."
    
    if [ ! -d "$HOME/.pyenv" ]; then
        curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
        
        # bashrc設定
        cat >> ~/.bashrc << 'EOF'

# pyenv configuration
export PYENV_ROOT="$HOME/.pyenv"
[[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init - bash)"
EOF
        
        # 現在のセッションに適用
        export PYENV_ROOT="$HOME/.pyenv"
        export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init - bash)"
        
        success "pyenv インストール完了"
    else
        success "pyenv 既にインストール済み"
    fi
}

# Python 3.12.9 インストール
install_python() {
    log "Python 3.12.9 をインストール中..."
    
    export PYENV_ROOT="$HOME/.pyenv"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - bash)"
    
    if ! pyenv versions | grep -q "3.12.9"; then
        pyenv install 3.12.9
        pyenv global 3.12.9
        success "Python 3.12.9 インストール完了"
    else
        success "Python 3.12.9 既にインストール済み"
    fi
    
    # pip最新化
    pip install --upgrade pip
}

# uv インストール (Python経由)
install_uv() {
    log "uv パッケージマネージャーをインストール中..."
    
    if ! command -v uv &> /dev/null; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
        source ~/.bashrc
        success "uv インストール完了"
    else
        success "uv 既にインストール済み"
    fi
}

# nvm インストール (Homebrew不要)
install_nvm() {
    log "nvm をインストール中..."
    
    if [ ! -d "$HOME/.nvm" ]; then
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | bash
        
        # 現在のセッションに適用
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        success "nvm インストール完了"
    else
        success "nvm 既にインストール済み"
    fi
}

# Node.js 23.8.0 インストール
install_nodejs() {
    log "Node.js 23.8.0 をインストール中..."
    
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if ! nvm list | grep -q "v23.8.0"; then
        nvm install 23.8.0
        nvm alias default 23.8.0
        nvm use 23.8.0
        success "Node.js 23.8.0 インストール完了"
    else
        success "Node.js 23.8.0 既にインストール済み"
    fi
}

# Docker インストール
install_docker() {
    log "Docker をインストール中..."
    
    if ! command -v docker &> /dev/null; then
        # Docker公式リポジトリ追加
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        sudo apt update
        sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
        
        # ユーザーをdockerグループに追加
        sudo usermod -aG docker $USER
        
        success "Docker インストール完了"
    else
        success "Docker 既にインストール済み"
    fi
}

# GitHub CLI インストール (apt経由)
install_github_cli() {
    log "GitHub CLI をインストール中..."
    
    if ! command -v gh &> /dev/null; then
        # GitHub CLI公式リポジトリ追加
        curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
        
        sudo apt update
        sudo apt install -y gh
        
        success "GitHub CLI インストール完了"
    else
        success "GitHub CLI 既にインストール済み"
    fi
}

# 環境検証
verify_installation() {
    log "インストール検証中..."
    
    echo "=== インストール結果 ==="
    
    # Python確認
    if command -v python3 &> /dev/null; then
        success "Python: $(python3 --version)"
    else
        error "Python インストール失敗"
    fi
    
    # pyenv確認
    if [ -d "$HOME/.pyenv" ]; then
        success "pyenv: インストール済み"
    else
        warning "pyenv: 未インストール"
    fi
    
    # Node.js確認
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        if [[ "$node_version" == "v23.8.0" ]]; then
            success "Node.js: $node_version (期待値一致)"
        else
            warning "Node.js: $node_version (期待値: v23.8.0)"
        fi
    else
        error "Node.js インストール失敗"
    fi
    
    # Docker確認
    if command -v docker &> /dev/null; then
        success "Docker: $(docker --version)"
    else
        warning "Docker: 未インストール"
    fi
    
    # GitHub CLI確認
    if command -v gh &> /dev/null; then
        success "GitHub CLI: $(gh --version | head -1)"
    else
        warning "GitHub CLI: 未インストール"
    fi
    
    # uv確認
    if command -v uv &> /dev/null; then
        success "uv: $(uv --version)"
    else
        warning "uv: 未インストール"
    fi
}

# Windows 11対応確認
check_windows_compatibility() {
    log "Windows 11 WSL2対応状況確認中..."
    
    # WSL環境確認
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
        success "WSL2環境: $WSL_DISTRO_NAME"
    else
        warning "WSL環境の検出ができません"
    fi
    
    # Windows PathからLinuxへのアクセス確認
    local windows_path="\\\\wsl.localhost\\Ubuntu-24.04\\home\\$(whoami)\\happyquest"
    success "Windows アクセスパス: $windows_path"
    
    log "Windows PowerShell からのアクセス:"
    log "  wsl -d Ubuntu-24.04 -- bash -c 'cd /home/$(whoami)/happyquest && ./infrastructure/windows11-compatible-setup.sh'"
}

# メイン実行
main() {
    print_banner
    
    log "Windows 11対応自動環境構築を開始します..."
    
    # 実行前確認
    echo "この処理では以下がインストールされます:"
    echo "- Python 3.12.9 (pyenv経由)"
    echo "- Node.js 23.8.0 (nvm経由)"
    echo "- Docker CE"
    echo "- GitHub CLI"
    echo "- uv パッケージマネージャー"
    echo
    
    install_system_packages
    install_pyenv
    install_python
    install_uv
    install_nvm
    install_nodejs
    install_docker
    install_github_cli
    
    verify_installation
    check_windows_compatibility
    
    echo
    success "🎉 Windows 11対応環境構築完了！"
    warning "⚠️ 新しいターミナルを開いて環境変数を再読み込みしてください"
    log "または以下を実行: source ~/.bashrc"
}

# スクリプト実行
main "$@"