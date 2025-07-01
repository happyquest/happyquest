#!/bin/bash

# HappyQuest クリーンインストール模擬テスト
# 既存環境での新規インストール動作検証

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
║         HappyQuest クリーンインストール模擬テスト            ║
║            既存環境での新規インストール検証                  ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# テスト用の一時ディレクトリ作成
setup_test_environment() {
    log "テスト環境セットアップ中..."
    
    TEST_DIR="/tmp/happyquest-clean-test-$(date +%s)"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"
    
    success "テストディレクトリ: $TEST_DIR"
    
    # テスト用bashrcを作成（クリーンな状態を模擬）
    TEST_BASHRC="$TEST_DIR/.bashrc_test"
    cat > "$TEST_BASHRC" << 'EOF'
# Test bashrc - simulating clean environment
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
EOF
    
    success "クリーン環境模擬設定完了"
}

# システムパッケージ確認（インストール済みを前提）
verify_system_packages() {
    log "システムパッケージ確認中..."
    
    local packages=(
        "build-essential"
        "curl" 
        "git"
        "wget"
        "unzip"
        "ca-certificates"
        "gnupg"
        "lsb-release"
    )
    
    for package in "${packages[@]}"; do
        if dpkg -l | grep -q "^ii  $package "; then
            success "システムパッケージ: $package"
        else
            warning "システムパッケージ: $package (未インストール)"
        fi
    done
}

# pyenvインストールテスト（テスト環境）
test_pyenv_installation() {
    log "pyenv インストールテスト中..."
    
    # テスト用pyenvディレクトリ
    TEST_PYENV_ROOT="$TEST_DIR/.pyenv"
    
    if [ ! -d "$TEST_PYENV_ROOT" ]; then
        log "pyenv をテスト環境にインストール中..."
        
        # pyenv-installerをダウンロード・実行
        export PYENV_ROOT="$TEST_PYENV_ROOT"
        curl -L https://github.com/pyenv/pyenv-installer/raw/master/bin/pyenv-installer | bash
        
        # テスト用bashrc設定
        cat >> "$TEST_BASHRC" << EOF

# pyenv configuration for test
export PYENV_ROOT="$TEST_PYENV_ROOT"
[[ -d \$PYENV_ROOT/bin ]] && export PATH="\$PYENV_ROOT/bin:\$PATH"
eval "\$(pyenv init - bash)"
EOF
        
        success "pyenv テストインストール完了"
    else
        success "pyenv 既存確認"
    fi
    
    # pyenv動作確認
    export PYENV_ROOT="$TEST_PYENV_ROOT"
    export PATH="$PYENV_ROOT/bin:$PATH"
    eval "$(pyenv init - bash)"
    
    if command -v pyenv &> /dev/null; then
        success "pyenv 動作確認: $(pyenv --version)"
    else
        error "pyenv 動作確認失敗"
    fi
}

# nvmインストールテスト（テスト環境）
test_nvm_installation() {
    log "nvm インストールテスト中..."
    
    # テスト用nvmディレクトリ
    TEST_NVM_DIR="$TEST_DIR/.nvm"
    
    if [ ! -d "$TEST_NVM_DIR" ]; then
        log "nvm をテスト環境にインストール中..."
        
        # 一時的にNVM_DIRを設定してインストール
        export NVM_DIR="$TEST_NVM_DIR"
        mkdir -p "$TEST_NVM_DIR"
        
        # nvm installer実行
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.1/install.sh | NVM_DIR="$TEST_NVM_DIR" bash
        
        # テスト用bashrc設定
        cat >> "$TEST_BASHRC" << EOF

# nvm configuration for test
export NVM_DIR="$TEST_NVM_DIR"
[ -s "\$NVM_DIR/nvm.sh" ] && \\. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \\. "\$NVM_DIR/bash_completion"
EOF
        
        success "nvm テストインストール完了"
    else
        success "nvm 既存確認"
    fi
    
    # nvm動作確認
    export NVM_DIR="$TEST_NVM_DIR"
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
        
        if command -v nvm &> /dev/null; then
            success "nvm 動作確認: $(nvm --version)"
            
            # Node.js 23.8.0インストールテスト
            log "Node.js 23.8.0 インストールテスト中..."
            nvm install 23.8.0
            nvm use 23.8.0
            
            node_version=$(node --version)
            if [[ "$node_version" == "v23.8.0" ]]; then
                success "Node.js インストール確認: $node_version"
            else
                error "Node.js バージョン不一致: $node_version"
            fi
        else
            warning "nvm コマンドが見つかりません"
        fi
    else
        warning "nvm.sh が見つかりません: $NVM_DIR/nvm.sh"
    fi
}

# uvインストールテスト
test_uv_installation() {
    log "uv インストールテスト中..."
    
    # uvインストール（テスト環境）
    if ! command -v uv &> /dev/null; then
        log "uv をインストール中..."
        curl -LsSf https://astral.sh/uv/install.sh | sh
        
        # パス設定
        export PATH="$HOME/.local/bin:$PATH"
        
        if command -v uv &> /dev/null; then
            success "uv インストール確認: $(uv --version)"
        else
            warning "uv インストール確認失敗"
        fi
    else
        success "uv 既存確認: $(uv --version)"
    fi
}

# 統合テスト実行
integration_test() {
    log "統合テスト実行中..."
    
    # テスト用bashrcを読み込んで新しいシェルでテスト
    bash -c "
        source '$TEST_BASHRC'
        
        echo '=== 環境変数確認 ==='
        echo \"PYENV_ROOT: \$PYENV_ROOT\"
        echo \"NVM_DIR: \$NVM_DIR\"
        echo \"PATH: \$PATH\"
        echo
        
        echo '=== コマンド確認 ==='
        command -v pyenv && echo \"pyenv: \$(pyenv --version)\"
        command -v nvm && echo \"nvm: \$(nvm --version)\"
        command -v node && echo \"node: \$(node --version)\"
        command -v npm && echo \"npm: \$(npm --version)\"
        command -v uv && echo \"uv: \$(uv --version)\"
    "
    
    success "統合テスト完了"
}

# クリーンアップ
cleanup() {
    log "テスト環境クリーンアップ中..."
    
    if [ -d "$TEST_DIR" ]; then
        rm -rf "$TEST_DIR"
        success "テストディレクトリ削除完了"
    fi
}

# メイン実行
main() {
    print_banner
    
    trap cleanup EXIT
    
    setup_test_environment
    verify_system_packages
    test_pyenv_installation
    test_nvm_installation
    test_uv_installation
    integration_test
    
    echo
    success "🎉 クリーンインストール模擬テスト完了"
    log "実際のクリーンインストールの準備ができています"
    echo
    log "PowerShellでの新インスタンス作成:"
    log "  ./test-new-wsl-instance.ps1"
    echo
}

main "$@"