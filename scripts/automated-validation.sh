#!/bin/bash

# HappyQuest 自動テスト・バリデーションフレームワーク
# TDD準拠・GitHub Actions対応版

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
REPORT_DIR="$PROJECT_ROOT/quality-reports"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

log() { echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; exit 1; }

mkdir -p "$REPORT_DIR"

print_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              HappyQuest TDD 自動品質保証システム               ║
║            GitHub Actions統合テストフレームワーク              ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# テスト結果をJUnit XML形式で出力
generate_junit_xml() {
    local results="$1"
    local junit_file="$REPORT_DIR/junit-results-$TIMESTAMP.xml"
    
    local total_tests=0
    local failures=0
    local errors=0
    
    # 結果カウント
    while IFS='|' read -r category test status details; do
        if [ -n "$test" ]; then
            ((total_tests++))
            if [ "$status" = "FAIL" ]; then
                ((failures++))
            elif [ "$status" = "ERROR" ]; then
                ((errors++))
            fi
        fi
    done <<< "$results"
    
    cat > "$junit_file" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<testsuite name="HappyQuest-Validation" tests="$total_tests" failures="$failures" errors="$errors" time="60">
EOF

    # 各テストケース
    while IFS='|' read -r category test status details; do
        if [ -n "$test" ]; then
            local classname=$(echo "$category" | sed 's/_/./g')
            local testname=$(echo "$test" | sed 's/ /_/g')
            
            if [ "$status" = "PASS" ]; then
                echo "  <testcase classname=\"$classname\" name=\"$testname\" time=\"1.0\"/>" >> "$junit_file"
            else
                echo "  <testcase classname=\"$classname\" name=\"$testname\" time=\"1.0\">" >> "$junit_file"
                echo "    <failure message=\"$status\">$details</failure>" >> "$junit_file"
                echo "  </testcase>" >> "$junit_file"
            fi
        fi
    done <<< "$results"
    
    echo "</testsuite>" >> "$junit_file"
    echo "$junit_file"
}

# システム環境テスト
test_system_environment() {
    log "システム環境テスト実行中..."
    local results=""
    
    # OS確認
    if command -v lsb_release &> /dev/null; then
        local ubuntu_version=$(lsb_release -d | cut -f2)
        results+="system_environment|OS|PASS|$ubuntu_version"$'\n'
    else
        results+="system_environment|OS|FAIL|lsb_release未インストール"$'\n'
    fi
    
    # メモリ確認
    local memory_gb=$(free -g | grep '^Mem:' | awk '{print $2}')
    local memory_status=$([ "$memory_gb" -ge 4 ] && echo "PASS" || echo "WARN")
    results+="system_environment|Memory|$memory_status|${memory_gb}GB"$'\n'
    
    # ディスク容量
    local disk_avail=$(df -h / | tail -1 | awk '{print $4}')
    results+="system_environment|Disk|PASS|$disk_avail available"$'\n'
    
    # ネットワーク
    if curl -s --max-time 5 https://github.com > /dev/null; then
        results+="system_environment|Network|PASS|GitHub接続OK"$'\n'
    else
        results+="system_environment|Network|FAIL|外部接続エラー"$'\n'
    fi
    
    echo "$results"
}

# 開発ツールテスト
test_development_tools() {
    log "開発ツールテスト実行中..."
    local results=""
    
    # Python
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version 2>&1)
        results+="development_tools|Python|PASS|$python_version"$'\n'
    else
        results+="development_tools|Python|FAIL|Python3未インストール"$'\n'
    fi
    
    # pyenv
    if [ -d "$HOME/.pyenv" ]; then
        results+="development_tools|pyenv|PASS|インストール済み"$'\n'
    else
        results+="development_tools|pyenv|FAIL|未インストール"$'\n'
    fi
    
    # Node.js
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        if [[ "$node_version" == "v23.8.0" ]]; then
            results+="development_tools|Node.js|PASS|$node_version (期待値一致)"$'\n'
        else
            results+="development_tools|Node.js|WARN|$node_version (期待値: v23.8.0)"$'\n'
        fi
    else
        results+="development_tools|Node.js|FAIL|未インストール"$'\n'
    fi
    
    # nvm
    if [ -d "$HOME/.nvm" ]; then
        results+="development_tools|nvm|PASS|インストール済み"$'\n'
    else
        results+="development_tools|nvm|FAIL|未インストール"$'\n'
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version)
        results+="development_tools|Docker|PASS|$docker_version"$'\n'
    else
        results+="development_tools|Docker|FAIL|未インストール"$'\n'
    fi
    
    # GitHub CLI
    if command -v gh &> /dev/null; then
        local gh_version=$(gh --version | head -1)
        results+="development_tools|GitHub-CLI|PASS|$gh_version"$'\n'
    else
        results+="development_tools|GitHub-CLI|FAIL|未インストール"$'\n'
    fi
    
    echo "$results"
}

# MCPサーバーテスト
test_mcp_servers() {
    log "MCPサーバーテスト実行中..."
    local results=""
    
    # Docker MCPコンテナ
    local mcp_containers=$(docker ps --filter "name=mcp" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$mcp_containers" -gt 0 ]; then
        results+="mcp_servers|MCP-Containers|PASS|${mcp_containers}個稼働中"$'\n'
    else
        results+="mcp_servers|MCP-Containers|WARN|MCPコンテナなし"$'\n'
    fi
    
    # MCPポート確認
    local ports=("3001" "3003")
    for port in "${ports[@]}"; do
        if ss -tlnp | grep ":$port " > /dev/null; then
            results+="mcp_servers|MCP-Port-$port|PASS|稼働中"$'\n'
        else
            results+="mcp_servers|MCP-Port-$port|FAIL|未使用"$'\n'
        fi
    done
    
    # MCP設定ファイル
    if [ -f "$PROJECT_ROOT/.cursor/mcp.json" ]; then
        results+="mcp_servers|MCP-Config|PASS|設定ファイル存在"$'\n'
    else
        results+="mcp_servers|MCP-Config|FAIL|設定ファイルなし"$'\n'
    fi
    
    echo "$results"
}

# プロジェクト構造テスト
test_project_structure() {
    log "プロジェクト構造テスト実行中..."
    local results=""
    
    # 必須ドキュメント
    local docs=("README.md" "PROJECT_RULES.md" "SRS.md" "ARCHITECTURE.md" "TEST_POLICY.md" "API_SPEC.md" "CLAUDE.md")
    for doc in "${docs[@]}"; do
        if [ -f "$PROJECT_ROOT/$doc" ]; then
            results+="project_structure|Doc-$doc|PASS|存在"$'\n'
        else
            results+="project_structure|Doc-$doc|FAIL|欠如"$'\n'
        fi
    done
    
    # ディレクトリ構造
    local dirs=("src" "tests" "docs" "scripts" "infrastructure")
    for dir in "${dirs[@]}"; do
        if [ -d "$PROJECT_ROOT/$dir" ]; then
            results+="project_structure|Dir-$dir|PASS|存在"$'\n'
        else
            results+="project_structure|Dir-$dir|WARN|推奨ディレクトリなし"$'\n'
        fi
    done
    
    echo "$results"
}

# GitHub Actions設定テスト
test_github_actions() {
    log "GitHub Actions設定テスト実行中..."
    local results=""
    
    # ワークフローファイル確認
    if [ -d "$PROJECT_ROOT/.github/workflows" ]; then
        local workflow_count=$(find "$PROJECT_ROOT/.github/workflows" -name "*.yml" -o -name "*.yaml" | wc -l)
        if [ "$workflow_count" -gt 0 ]; then
            results+="github_actions|Workflows|PASS|${workflow_count}個のワークフロー"$'\n'
        else
            results+="github_actions|Workflows|WARN|ワークフローファイルなし"$'\n'
        fi
    else
        results+="github_actions|Workflows|FAIL|.github/workflows不在"$'\n'
    fi
    
    # GitHub認証確認
    if command -v gh &> /dev/null; then
        if gh auth status &> /dev/null; then
            results+="github_actions|GitHub-Auth|PASS|認証済み"$'\n'
        else
            results+="github_actions|GitHub-Auth|WARN|未認証"$'\n'
        fi
    else
        results+="github_actions|GitHub-Auth|FAIL|GitHub CLI未インストール"$'\n'
    fi
    
    # Git設定確認
    if git config user.name &> /dev/null && git config user.email &> /dev/null; then
        results+="github_actions|Git-Config|PASS|設定済み"$'\n'
    else
        results+="github_actions|Git-Config|FAIL|Git設定不完全"$'\n'
    fi
    
    echo "$results"
}

# メイン実行
main() {
    print_banner
    
    log "TDD準拠自動品質検証を開始..."
    
    # 全テスト実行
    local all_results=""
    all_results+=$(test_system_environment)
    all_results+=$(test_development_tools)
    all_results+=$(test_mcp_servers)
    all_results+=$(test_project_structure)
    all_results+=$(test_github_actions)
    
    # JUnit XML生成
    local junit_file=$(generate_junit_xml "$all_results")
    
    # 結果集計
    local total_tests=$(echo "$all_results" | grep -c '|')
    local pass_count=$(echo "$all_results" | grep -o '|PASS|' | wc -l)
    local warn_count=$(echo "$all_results" | grep -o '|WARN|' | wc -l)
    local fail_count=$(echo "$all_results" | grep -o '|FAIL|' | wc -l)
    
    # コンソール出力
    echo
    echo "=== テスト結果サマリー ==="
    success "PASS: $pass_count"
    warning "WARN: $warn_count"
    error "FAIL: $fail_count" || true
    echo
    
    # GitHub Actions対応出力
    if [ -n "$GITHUB_ACTIONS" ]; then
        echo "::set-output name=total_tests::$total_tests"
        echo "::set-output name=pass_count::$pass_count"
        echo "::set-output name=warn_count::$warn_count"
        echo "::set-output name=fail_count::$fail_count"
        echo "::set-output name=junit_file::$junit_file"
    fi
    
    # 詳細結果出力
    echo "=== 詳細テスト結果 ==="
    echo "$all_results" | while IFS='|' read -r category test status details; do
        case "$status" in
            "PASS") echo -e "${GREEN}✅ [$category] $test: $details${NC}" ;;
            "WARN") echo -e "${YELLOW}⚠️  [$category] $test: $details${NC}" ;;
            "FAIL") echo -e "${RED}❌ [$category] $test: $details${NC}" ;;
        esac
    done
    
    log "JUnit XMLレポート: $junit_file"
    
    # 終了コード設定
    if [ "$fail_count" -gt 0 ]; then
        exit 1
    elif [ "$warn_count" -gt 0 ]; then
        exit 0  # WARNは成功扱い
    else
        exit 0
    fi
}

main "$@"