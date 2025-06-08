#!/bin/bash

# HappyQuest Ubuntu 24.04 WSL2 環境自動構築スクリプト（taki用）
# 作成者: HappyQuest開発チーム
# 最終更新: 2025-01-27

set -e

# 色付きテキスト用の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ユーザー設定（takiユーザー用）
CURRENT_USER=$(whoami)
PROJECT_DIR="$HOME/happyquest"

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

# 前提条件チェック
check_prerequisites() {
    log "前提条件をチェック中... (ユーザー: $CURRENT_USER)"
    
    local env=$(detect_environment)
    log "検出された環境: $env"
    
    case $env in
        "wsl")
            log "WSL環境内で実行中です"
            ;;
        "windows")
            log "Windows環境で実行中です"
            if ! command -v wsl &> /dev/null; then
                error "WSL2が利用できません。Windows 11でWSL2を有効化してください。"
            fi
            ;;
        "linux")
            log "Linux環境で実行中です"
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

# プロジェクト構造セットアップ
setup_project_structure() {
    log "プロジェクト構造をセットアップ中... ($PROJECT_DIR)"
    
    # ディレクトリ作成
    mkdir -p "$PROJECT_DIR"/{src,tests,docs,infrastructure,作業報告書,トラブル事例,アーカイブ}
    mkdir -p "$PROJECT_DIR/docs"/{plantuml,database,images}
    mkdir -p "$PROJECT_DIR"/.github/workflows
    
    # 基本ファイル作成
    create_basic_files
    
    success "プロジェクト構造セットアップ完了"
}

# 基本ファイル作成
create_basic_files() {
    log "基本ファイルを作成中..."
    
    # .gitignore
    cat > "$PROJECT_DIR/.gitignore" << 'EOF'
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
    cat > "$PROJECT_DIR/Makefile" << 'EOF'
.PHONY: help test lint format clean install

help:
	@echo 'Usage: make [target]'
	@echo 'Targets:'
	@echo '  install  Install dependencies'
	@echo '  test     Run tests'
	@echo '  lint     Run linting'
	@echo '  format   Format code'
	@echo '  clean    Clean build artifacts'

install:
	@echo 'Installing Python dependencies...'
	pip install pytest black flake8 || echo 'Python packages installation skipped'
	@echo 'Installing Node.js dependencies...'
	npm install || echo 'npm install skipped'

test:
	@echo 'Running Python tests...'
	pytest || echo 'pytest not available'
	@echo 'Running Node.js tests...'
	npm test || echo 'npm test not available'

lint:
	@echo 'Running Python linting...'
	flake8 src/ || echo 'flake8 not available'
	@echo 'Running Node.js linting...'
	npm run lint || echo 'npm lint not available'

format:
	@echo 'Formatting Python code...'
	black src/ || echo 'black not available'
	@echo 'Formatting Node.js code...'
	npm run format || echo 'npm format not available'

clean:
	find . -name __pycache__ -exec rm -rf {} + 2>/dev/null || true
	rm -rf node_modules/ .coverage htmlcov/ 2>/dev/null || true
EOF

    # README.md
    cat > "$PROJECT_DIR/README.md" << EOF
# HappyQuest Development Project

## 概要
AI開発プロジェクトのための統合開発環境

## ユーザー情報
- **ユーザー**: $CURRENT_USER
- **プロジェクトディレクトリ**: $PROJECT_DIR
- **作成日時**: $(date '+%Y年%m月%d日 %H:%M:%S')

## セットアップ
\`\`\`bash
cd $PROJECT_DIR
make install
make test
\`\`\`

## 環境情報
- Ubuntu 24.04 WSL2
- ユーザー: $CURRENT_USER

## 次のステップ
1. 開発ツールのインストール
2. Python環境のセットアップ
3. Node.js環境のセットアップ
4. HashiCorp Vault設定
EOF

    # package.json
    cat > "$PROJECT_DIR/package.json" << EOF
{
  "name": "happyquest-$CURRENT_USER",
  "version": "1.0.0",
  "description": "HappyQuest Development Project for $CURRENT_USER",
  "main": "index.js",
  "scripts": {
    "test": "echo 'Tests will be implemented'",
    "lint": "echo 'Linting will be implemented'",
    "format": "echo 'Formatting will be implemented'"
  },
  "keywords": ["happyquest", "ai", "development"],
  "author": "$CURRENT_USER",
  "license": "MIT"
}
EOF

    # pytest.ini
    cat > "$PROJECT_DIR/pytest.ini" << 'EOF'
[tool:pytest]
testpaths = tests
python_files = test_*.py
python_classes = Test*
python_functions = test_*
addopts = 
    --verbose
    --tb=short
EOF
}

# 環境テスト
test_environment() {
    log "環境テストを実行中..."
    
    echo "=== システム情報 ==="
    echo "ユーザー: $CURRENT_USER"
    echo "ホームディレクトリ: $HOME"
    echo "プロジェクトディレクトリ: $PROJECT_DIR"
    echo "作業ディレクトリ: $(pwd)"
    
    echo ""
    echo "=== ソフトウェアバージョン ==="
    
    # 基本コマンド確認
    if command -v python3 &> /dev/null; then
        echo "Python: $(python3 --version)"
    else
        warning "Python3が利用できません"
    fi
    
    if command -v node &> /dev/null; then
        echo "Node.js: $(node --version)"
    else
        warning "Node.jsが利用できません"
    fi
    
    if command -v docker &> /dev/null; then
        echo "Docker: $(docker --version)"
    else
        warning "Dockerが利用できません"
    fi
    
    if command -v gh &> /dev/null; then
        echo "GitHub CLI: $(gh --version | head -1)"
    else
        warning "GitHub CLIが利用できません"
    fi
    
    if command -v vault &> /dev/null; then
        echo "Vault: $(vault --version)"
    else
        warning "HashiCorp Vaultが利用できません"
    fi
    
    echo ""
    echo "=== プロジェクト構造 ==="
    if [[ -d "$PROJECT_DIR" ]]; then
        tree "$PROJECT_DIR" -L 2 2>/dev/null || ls -la "$PROJECT_DIR"
    else
        warning "プロジェクトディレクトリが存在しません"
    fi
    
    success "環境テスト完了"
}

# テスト実行
run_basic_tests() {
    log "基本機能テストを実行中..."
    
    if [[ -d "$PROJECT_DIR" ]]; then
        cd "$PROJECT_DIR"
        
        echo "=== Makefileテスト ==="
        make help
        
        echo ""
        echo "=== インストールテスト ==="
        make install
        
        echo ""
        echo "=== テスト実行 ==="
        make test
        
        success "基本機能テスト完了"
    else
        error "プロジェクトディレクトリが存在しません: $PROJECT_DIR"
    fi
}

# メイン処理
main() {
    echo -e "${GREEN}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║               HappyQuest 環境テスト（taki用）                  ║"
    echo "║                Ubuntu 24.04 WSL2 Environment Test            ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    log "HappyQuest環境テスト（$CURRENT_USER用）を開始します..."
    
    check_prerequisites
    setup_project_structure
    test_environment
    
    # 基本テストの実行確認
    read -p "基本機能テストを実行しますか？ (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        run_basic_tests
    fi
    
    success "🎉 HappyQuest環境テストが完了しました！"
    echo ""
    echo "📋 結果:"
    echo "   プロジェクトディレクトリ: $PROJECT_DIR"
    echo "   次のコマンド: cd $PROJECT_DIR && make help"
    echo ""
}

# ヘルプ表示
if [[ "$1" == "--help" || "$1" == "-h" ]]; then
    echo "使用方法: $0 [オプション]"
    echo ""
    echo "オプション:"
    echo "  --help, -h      このヘルプを表示"
    echo "  --test-only     環境テストのみ実行"
    echo "  --setup-only    プロジェクト構造作成のみ"
    echo ""
    exit 0
fi

if [[ "$1" == "--test-only" ]]; then
    test_environment
    exit 0
fi

if [[ "$1" == "--setup-only" ]]; then
    setup_project_structure
    exit 0
fi

# メイン処理実行
main "$@" 