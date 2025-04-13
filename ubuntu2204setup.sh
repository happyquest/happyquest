#!/bin/bash

# Ubuntu 22.04 開発環境セットアップスクリプト
# HappyQuest プロジェクト用

set -e  # エラーが発生したら終了
set -u  # 未定義の変数を使用したら終了

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a setup_log.txt
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - エラー: $1" | tee -a setup_log.txt
    exit 1
}

check_command() {
    if command -v "$1" >/dev/null 2>&1; then
        return 0
    else
        return 1
    fi
}

# ログ開始
log "Ubuntu 22.04 環境セットアップを開始します"

# スクリプトが root で実行されているか確認
if [ "$(id -u)" -eq 0 ]; then
    error "このスクリプトは一般ユーザーで実行してください（sudo 権限は必要に応じて要求します）"
fi

# 1. SSH サーバーのセットアップ
log "1. SSH サーバーをインストールしています..."
if ! dpkg -l | grep -q openssh-server; then
    sudo apt update
    sudo apt install -y openssh-server
    sudo systemctl enable ssh
    sudo service ssh restart
    log "SSH サーバーがインストールされ、有効化されました"
else
    log "SSH サーバーは既にインストールされています"
fi

# 2. Docker インストール
log "2. Docker をインストールしています..."
if ! check_command docker; then
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo usermod -aG docker "$USER"
    log "Docker がインストールされました - ユーザーが docker グループに追加されました"
    log "この変更を有効にするには、ログアウトして再度ログインが必要です"
else
    log "Docker は既にインストールされています"
fi

# 3. Homebrew インストール
log "3. Homebrew をインストールしています..."
if ! check_command brew; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || error "Homebrew のインストールに失敗しました"
    
    # Homebrew の環境変数設定
    if ! grep -q 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' "$HOME/.bashrc"; then
        echo 'eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"' >> "$HOME/.bashrc"
        eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
    fi

    # Homebrew の依存関係をインストール
    sudo apt-get install -y build-essential
    log "Homebrew がインストールされ、設定されました"
else
    log "Homebrew は既にインストールされています"
fi

# 4. pyenv インストール
log "4. pyenv をインストールしています..."
if ! check_command pyenv; then
    # pyenv ビルドの依存関係
    sudo apt-get install -y libssl-dev libncurses5-dev libncursesw5-dev libreadline-dev libsqlite3-dev \
        libgdbm-dev libdb5.3-dev libbz2-dev libexpat1-dev liblzma-dev zlib1g-dev tk-dev

    # PKG_CONFIG_PATH 設定
    if ! grep -q 'export PKG_CONFIG_PATH=' "$HOME/.bashrc"; then
        echo 'export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"' >> "$HOME/.bashrc"
        export PKG_CONFIG_PATH="/usr/lib/x86_64-linux-gnu/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig"
    fi

    # pyenv インストール
    brew install pyenv

    # pyenv 設定
    if ! grep -q 'export PYENV_ROOT=' "$HOME/.bashrc"; then
        echo 'export PYENV_ROOT="$HOME/.pyenv"' >> "$HOME/.bashrc"
        echo 'command -v pyenv >/dev/null || export PATH="$PYENV_ROOT/bin:$PATH"' >> "$HOME/.bashrc"
        echo 'eval "$(pyenv init -)"' >> "$HOME/.bashrc"
    fi

    # pyenv 用のディレクトリ作成
    mkdir -p "$HOME/.pyenv"
    cp -r "$(brew --prefix pyenv)"/* "$HOME/.pyenv/"

    source "$HOME/.bashrc"
    log "pyenv がインストールされ、設定されました"
else
    log "pyenv は既にインストールされています"
fi

# 5 & 6. Python 3.12 インストール
log "5 & 6. Python 3.12.9 をインストールしています..."
if ! pyenv versions | grep -q 3.12.9; then
    pyenv install 3.12.9
    pyenv global 3.12.9
    log "Python 3.12.9 がインストールされ、グローバルデフォルトに設定されました"
else
    log "Python 3.12.9 は既にインストールされています"
fi

# 7. GitHub CLI インストール
log "7. GitHub CLI をインストールしています..."
if ! check_command gh; then
    brew install gh
    log "GitHub CLI がインストールされました"
else
    log "GitHub CLI は既にインストールされています"
fi

# 8. UV パッケージマネージャーインストール
log "8. UV パッケージマネージャーをインストールしています..."
if ! check_command uv; then
    brew install uv
    log "UV パッケージマネージャーがインストールされました"
else
    log "UV パッケージマネージャーは既にインストールされています"
fi

# 9. NVM インストール
log "9. NVM をインストールしています..."
if ! check_command nvm; then
    brew install nvm
    
    # NVM 設定
    mkdir -p "$HOME/.nvm"
    if ! grep -q 'export NVM_DIR=' "$HOME/.bashrc"; then
        echo 'export NVM_DIR="$HOME/.nvm"' >> "$HOME/.bashrc"
        echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"' >> "$HOME/.bashrc"
        echo '[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/etc/bash_completion.d/nvm"' >> "$HOME/.bashrc"
    fi
    
    source "$HOME/.bashrc"
    log "NVM がインストールされ、設定されました"
else
    log "NVM は既にインストールされています"
fi

# 10. Node.js インストール
log "10. Node.js v23.8.0 をインストールしています..."
# nvm コマンドが使えるように環境変数を読み込む
export NVM_DIR="$HOME/.nvm"
[ -s "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh" ] && \. "/home/linuxbrew/.linuxbrew/opt/nvm/nvm.sh"

if ! command -v node >/dev/null 2>&1 || [ "$(node -v)" != "v23.8.0" ]; then
    nvm install 23.8.0
    log "Node.js v23.8.0 がインストールされました"
else
    log "Node.js v23.8.0 は既にインストールされています"
fi

log "環境構築が完了しました！"
log "変更を完全に適用するには、ターミナルを再起動するか、以下のコマンドを実行してください："
log "source ~/.bashrc"

# Docker グループの変更を適用するための注意
log "※ Docker グループの変更を反映するには、一度ログアウトして再度ログインしてください。"