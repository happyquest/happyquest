#!/bin/bash

# HappyQuest 環境検証・テスト実行スクリプト
# 結果を分かりやすく表示・保存

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

REPORT_DIR="quality-reports"
TIMESTAMP=$(date +"%Y%m%d-%H%M%S")

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

mkdir -p "$REPORT_DIR"

print_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║              HappyQuest 環境検証テスト                        ║
║                  結果確認版                                  ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# テスト実行・結果収集
run_validation_tests() {
    log "環境検証テストを実行中..."
    
    local results=""
    local pass_count=0
    local warn_count=0
    local fail_count=0
    
    echo "=== システム環境テスト ===" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    
    # OS確認
    if command -v lsb_release &> /dev/null; then
        local ubuntu_version=$(lsb_release -d | cut -f2)
        success "OS: $ubuntu_version"
        results+="✅ OS|$ubuntu_version"$'\n'
        ((pass_count++))
    else
        error "OS: lsb_release未インストール"
        results+="❌ OS|lsb_release未インストール"$'\n'
        ((fail_count++))
    fi
    
    # メモリ確認
    local memory_gb=$(free -g | grep '^Mem:' | awk '{print $2}')
    if [ "$memory_gb" -ge 4 ]; then
        success "Memory: ${memory_gb}GB (十分)"
        results+="✅ Memory|${memory_gb}GB"$'\n'
        ((pass_count++))
    else
        warning "Memory: ${memory_gb}GB (推奨4GB以上)"
        results+="⚠️ Memory|${memory_gb}GB"$'\n'
        ((warn_count++))
    fi
    
    # Python確認
    if command -v python3 &> /dev/null; then
        local python_version=$(python3 --version 2>&1)
        success "Python: $python_version"
        results+="✅ Python|$python_version"$'\n'
        ((pass_count++))
    else
        error "Python: 未インストール"
        results+="❌ Python|未インストール"$'\n'
        ((fail_count++))
    fi
    
    # Node.js確認
    if command -v node &> /dev/null; then
        local node_version=$(node --version)
        if [[ "$node_version" == "v23.8.0" ]]; then
            success "Node.js: $node_version (期待値一致)"
            results+="✅ Node.js|$node_version (期待値一致)"$'\n'
            ((pass_count++))
        else
            warning "Node.js: $node_version (期待値: v23.8.0)"
            results+="⚠️ Node.js|$node_version (期待値: v23.8.0)"$'\n'
            ((warn_count++))
        fi
    else
        error "Node.js: 未インストール"
        results+="❌ Node.js|未インストール"$'\n'
        ((fail_count++))
    fi
    
    # pyenv確認
    if [ -d "$HOME/.pyenv" ]; then
        success "pyenv: インストール済み"
        results+="✅ pyenv|インストール済み"$'\n'
        ((pass_count++))
    else
        error "pyenv: 未インストール"
        results+="❌ pyenv|未インストール"$'\n'
        ((fail_count++))
    fi
    
    # nvm確認
    if [ -d "$HOME/.nvm" ]; then
        success "nvm: インストール済み"
        results+="✅ nvm|インストール済み"$'\n'
        ((pass_count++))
    else
        error "nvm: 未インストール"
        results+="❌ nvm|未インストール"$'\n'
        ((fail_count++))
    fi
    
    # Docker確認
    if command -v docker &> /dev/null; then
        local docker_version=$(docker --version)
        success "Docker: $docker_version"
        results+="✅ Docker|$docker_version"$'\n'
        ((pass_count++))
    else
        error "Docker: 未インストール"
        results+="❌ Docker|未インストール"$'\n'
        ((fail_count++))
    fi
    
    # GitHub CLI確認
    if command -v gh &> /dev/null; then
        local gh_version=$(gh --version | head -1)
        success "GitHub CLI: $gh_version"
        results+="✅ GitHub CLI|$gh_version"$'\n'
        ((pass_count++))
    else
        error "GitHub CLI: 未インストール"
        results+="❌ GitHub CLI|未インストール"$'\n'
        ((fail_count++))
    fi
    
    # MCPサーバー確認
    local mcp_containers=$(docker ps --filter "name=mcp" --format "{{.Names}}" 2>/dev/null | wc -l)
    if [ "$mcp_containers" -gt 0 ]; then
        success "MCP Servers: ${mcp_containers}個稼働中"
        results+="✅ MCP Servers|${mcp_containers}個稼働中"$'\n'
        ((pass_count++))
    else
        warning "MCP Servers: 稼働なし"
        results+="⚠️ MCP Servers|稼働なし"$'\n'
        ((warn_count++))
    fi
    
    # MCP設定ファイル確認
    if [ -f ".cursor/mcp.json" ]; then
        success "MCP Config: 設定ファイル存在"
        results+="✅ MCP Config|設定ファイル存在"$'\n'
        ((pass_count++))
    else
        error "MCP Config: 設定ファイルなし"
        results+="❌ MCP Config|設定ファイルなし"$'\n'
        ((fail_count++))
    fi
    
    # プロジェクト構造確認
    echo
    echo "=== プロジェクト構造テスト ===" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    
    local docs=("README.md" "PROJECT_RULES.md" "SRS.md" "ARCHITECTURE.md" "TEST_POLICY.md" "API_SPEC.md" "CLAUDE.md")
    for doc in "${docs[@]}"; do
        if [ -f "$doc" ]; then
            success "Document: $doc"
            results+="✅ Document|$doc"$'\n'
            ((pass_count++))
        else
            error "Document: $doc (必須)"
            results+="❌ Document|$doc (必須)"$'\n'
            ((fail_count++))
        fi
    done
    
    local dirs=("src" "tests" "docs" "scripts" "infrastructure")
    for dir in "${dirs[@]}"; do
        if [ -d "$dir" ]; then
            success "Directory: $dir/"
            results+="✅ Directory|$dir/"$'\n'
            ((pass_count++))
        else
            warning "Directory: $dir/ (推奨)"
            results+="⚠️ Directory|$dir/ (推奨)"$'\n'
            ((warn_count++))
        fi
    done
    
    # 統計出力
    echo
    echo "=== テスト結果統計 ===" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    echo -e "${GREEN}PASS: $pass_count${NC}" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    echo -e "${YELLOW}WARN: $warn_count${NC}" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    echo -e "${RED}FAIL: $fail_count${NC}" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    
    local total_tests=$((pass_count + warn_count + fail_count))
    local success_rate=$(echo "scale=1; $pass_count * 100 / $total_tests" | bc -l 2>/dev/null || echo "N/A")
    echo "総合成功率: ${success_rate}%" | tee -a "$REPORT_DIR/test-results-$TIMESTAMP.log"
    
    # 結果ファイル保存
    echo "$results" > "$REPORT_DIR/test-details-$TIMESTAMP.txt"
    
    # HTMLレポート生成
    generate_html_report "$results" "$pass_count" "$warn_count" "$fail_count" "$success_rate"
    
    return $fail_count
}

# HTMLレポート生成
generate_html_report() {
    local results="$1"
    local pass_count="$2"
    local warn_count="$3"
    local fail_count="$4"
    local success_rate="$5"
    
    local html_file="$REPORT_DIR/test-report-$TIMESTAMP.html"
    
    cat > "$html_file" << EOF
<!DOCTYPE html>
<html lang="ja">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>HappyQuest 環境検証レポート</title>
    <style>
        body { font-family: 'Segoe UI', sans-serif; margin: 0; padding: 20px; background: #f5f5f5; }
        .container { max-width: 1000px; margin: 0 auto; background: white; border-radius: 8px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; border-radius: 8px 8px 0 0; }
        .header h1 { margin: 0; font-size: 2em; }
        .summary { display: flex; justify-content: space-around; padding: 20px; background: #f8f9fa; }
        .summary-item { text-align: center; }
        .summary-number { font-size: 2em; font-weight: bold; }
        .pass { color: #28a745; }
        .warn { color: #ffc107; }
        .fail { color: #dc3545; }
        .results { padding: 20px; }
        .test-item { margin: 10px 0; padding: 10px; border-radius: 5px; }
        .test-item.pass { background: #d4edda; border-left: 4px solid #28a745; }
        .test-item.warn { background: #fff3cd; border-left: 4px solid #ffc107; }
        .test-item.fail { background: #f8d7da; border-left: 4px solid #dc3545; }
        .footer { text-align: center; padding: 20px; color: #666; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚀 HappyQuest 環境検証レポート</h1>
            <p>生成日時: $(date '+%Y年%m月%d日 %H時%M分%S秒')</p>
        </div>
        
        <div class="summary">
            <div class="summary-item">
                <div class="summary-number pass">$pass_count</div>
                <div>PASS</div>
            </div>
            <div class="summary-item">
                <div class="summary-number warn">$warn_count</div>
                <div>WARN</div>
            </div>
            <div class="summary-item">
                <div class="summary-number fail">$fail_count</div>
                <div>FAIL</div>
            </div>
        </div>
        
        <div class="results">
            <h2>テスト結果詳細</h2>
EOF

    # 結果を HTMLに変換
    echo "$results" | while IFS='|' read -r status_icon test details; do
        if [ -n "$test" ]; then
            local css_class=""
            case "${status_icon:0:1}" in
                "✅") css_class="pass" ;;
                "⚠") css_class="warn" ;;
                "❌") css_class="fail" ;;
            esac
            echo "            <div class=\"test-item $css_class\">" >> "$html_file"
            echo "                <strong>$test</strong>: $details" >> "$html_file"
            echo "            </div>" >> "$html_file"
        fi
    done

    cat >> "$html_file" << EOF
        </div>
        
        <div class="footer">
            <p><strong>総合成功率: $success_rate%</strong></p>
            <p>HappyQuest TDD自動品質保証システム</p>
        </div>
    </div>
</body>
</html>
EOF

    echo "$html_file"
}

# メイン実行
main() {
    print_banner
    
    log "環境検証テストを開始します..."
    
    if run_validation_tests; then
        echo
        success "テスト実行完了！"
        log "レポートファイル:"
        log "  📄 ログ: $REPORT_DIR/test-results-$TIMESTAMP.log"
        log "  📊 詳細: $REPORT_DIR/test-details-$TIMESTAMP.txt"
        log "  🌐 HTML: $REPORT_DIR/test-report-$TIMESTAMP.html"
        echo
        log "HTMLレポートを開く: open $REPORT_DIR/test-report-$TIMESTAMP.html"
        echo
    else
        warning "テスト実行完了 (一部問題あり)"
        log "詳細は上記レポートファイルを確認してください。"
    fi
}

main "$@"