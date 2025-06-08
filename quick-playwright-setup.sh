#!/bin/bash

# HappyQuest Playwright迅速セットアップ＆テストスクリプト
# 作成日: 2025-06-08
# 対象: WSL Ubuntu 24.04環境

set -e

# 色付きテキスト用の定義
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# 環境確認
check_environment() {
    log "環境確認を開始..."
    
    # WSL環境チェック
    if [[ -f /proc/version ]] && grep -qi microsoft /proc/version; then
        success "WSL環境で実行中です"
    else
        warning "WSL環境ではない可能性があります"
    fi
    
    # 基本コマンドチェック
    if ! command -v curl &> /dev/null; then
        log "curlをインストール中..."
        sudo apt update && sudo apt install -y curl
    fi
    
    if ! command -v git &> /dev/null; then
        log "gitをインストール中..."
        sudo apt install -y git
    fi
    
    success "環境確認完了"
}

# Node.js環境セットアップ
setup_nodejs() {
    log "Node.js環境セットアップ中..."
    
    # nvmインストール（未インストールの場合）
    if [[ ! -d "$HOME/.nvm" ]]; then
        log "nvmをインストール中..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.3/install.sh | bash
        
        # nvmの環境変数設定
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
    else
        log "nvmは既にインストール済みです"
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    fi
    
    # Node.js最新LTSインストール
    log "Node.js LTSをインストール中..."
    nvm install --lts
    nvm use --lts
    
    # バージョン確認
    node_version=$(node --version)
    npm_version=$(npm --version)
    success "Node.js ${node_version}, npm ${npm_version} インストール完了"
}

# Playwrightセットアップ
setup_playwright() {
    log "Playwrightセットアップ中..."
    
    # package.jsonの依存関係更新
    log "package.jsonにPlaywrightを追加中..."
    
    # 既存のpackage.jsonをバックアップ
    if [[ -f "package.json" ]]; then
        cp package.json package.json.backup
    fi
    
    # Playwrightと関連パッケージをインストール
    npm install --save-dev @playwright/test
    npm install --save-dev playwright
    
    # Playwrightブラウザーインストール
    log "Playwrightブラウザーをインストール中..."
    npx playwright install
    
    # システム依存関係インストール
    log "システム依存関係をインストール中..."
    npx playwright install-deps
    
    success "Playwright インストール完了"
}

# テストファイル作成
create_test_files() {
    log "テストファイルを作成中..."
    
    # testsディレクトリ作成
    mkdir -p tests
    
    # 基本的なPlaywrightテスト作成
    cat > tests/basic-playwright.spec.js << 'EOF'
const { test, expect } = require('@playwright/test');

test.describe('HappyQuest Basic Tests', () => {
  test('should load Google homepage', async ({ page }) => {
    await page.goto('https://www.google.com');
    await expect(page).toHaveTitle(/Google/);
    console.log('✅ Google homepage test passed');
  });

  test('should be able to search', async ({ page }) => {
    await page.goto('https://www.google.com');
    await page.fill('input[name="q"]', 'HappyQuest AI');
    await page.press('input[name="q"]', 'Enter');
    await page.waitForSelector('div#search');
    console.log('✅ Search functionality test passed');
  });

  test('should capture screenshot', async ({ page }) => {
    await page.goto('https://example.com');
    await page.screenshot({ path: 'tests/example-screenshot.png' });
    console.log('✅ Screenshot capture test passed');
  });
});
EOF

    # Playwright設定ファイル作成
    cat > playwright.config.js << 'EOF'
module.exports = {
  testDir: './tests',
  timeout: 30000,
  expect: {
    timeout: 5000
  },
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,
  reporter: 'html',
  use: {
    baseURL: 'http://localhost:3000',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure'
  },

  projects: [
    {
      name: 'chromium',
      use: { ...require('@playwright/test').devices['Desktop Chrome'] },
    },
    {
      name: 'firefox',
      use: { ...require('@playwright/test').devices['Desktop Firefox'] },
    },
    {
      name: 'webkit',
      use: { ...require('@playwright/test').devices['Desktop Safari'] },
    },
  ],
};
EOF

    success "テストファイル作成完了"
}

# package.jsonスクリプト更新
update_package_scripts() {
    log "package.jsonスクリプトを更新中..."
    
    # 一時的にjqをインストール（JSON操作用）
    if ! command -v jq &> /dev/null; then
        sudo apt install -y jq
    fi
    
    # package.jsonのscriptsセクション更新
    cat package.json | jq '.scripts += {
        "test:playwright": "playwright test",
        "test:playwright:ui": "playwright test --ui",
        "test:playwright:debug": "playwright test --debug",
        "test:playwright:report": "playwright show-report"
    }' > package.json.tmp && mv package.json.tmp package.json
    
    success "package.jsonスクリプト更新完了"
}

# テスト実行
run_tests() {
    log "Playwrightテストを実行中..."
    
    # 環境変数設定
    export PLAYWRIGHT_BROWSERS_PATH="$HOME/.cache/ms-playwright"
    
    # テスト実行
    echo "=== Playwright Version ==="
    npx playwright --version
    
    echo "=== Available Browsers ==="
    npx playwright list-projects
    
    echo "=== Running Basic Tests ==="
    npx playwright test --reporter=list
    
    # テスト結果表示
    if [[ -f "playwright-report/index.html" ]]; then
        success "テストレポートが生成されました: playwright-report/index.html"
    fi
    
    success "Playwrightテスト実行完了"
}

# メイン実行
main() {
    log "=== HappyQuest Playwright迅速セットアップ開始 ==="
    
    check_environment
    setup_nodejs
    setup_playwright
    create_test_files
    update_package_scripts
    run_tests
    
    success "=== セットアップ＆テスト完了 ==="
    
    echo ""
    echo "🎉 次のコマンドでPlaywrightを使用できます："
    echo "  npm run test:playwright          # 全テスト実行"
    echo "  npm run test:playwright:ui       # UIモードでテスト"
    echo "  npm run test:playwright:debug    # デバッグモード"
    echo "  npm run test:playwright:report   # レポート表示"
    echo ""
}

# スクリプト引数処理
case "${1:-}" in
    "--test-only")
        log "テストのみ実行モード"
        run_tests
        ;;
    "--setup-only")
        log "セットアップのみ実行モード"
        check_environment
        setup_nodejs
        setup_playwright
        create_test_files
        update_package_scripts
        ;;
    *)
        main
        ;;
esac 