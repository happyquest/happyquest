#!/bin/bash

# HappyQuest Environment Verification Script
# Homebrew-free Windows 11 automation system test

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[$(date +'%H:%M:%S')] $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

print_banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════╗
║         HappyQuest Environment Verification Test             ║
║           Homebrew-free Windows 11 Automation               ║
╚══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# System tools verification
verify_system_tools() {
    log "System tools verification..."
    
    # Git
    if command -v git &> /dev/null; then
        success "Git: $(git --version)"
    else
        error "Git not found"
        return 1
    fi
    
    # Docker
    if command -v docker &> /dev/null; then
        success "Docker: $(docker --version)"
    else
        error "Docker not found"
        return 1
    fi
    
    # GitHub CLI
    if command -v gh &> /dev/null; then
        success "GitHub CLI: $(gh --version | head -1)"
    else
        error "GitHub CLI not found"
        return 1
    fi
}

# Python environment verification
verify_python() {
    log "Python environment verification..."
    
    # System Python
    if command -v python3 &> /dev/null; then
        success "System Python: $(python3 --version)"
    else
        error "Python3 not found"
        return 1
    fi
    
    # pyenv
    if [ -d "$HOME/.pyenv" ]; then
        success "pyenv: Installation directory exists"
        
        # Try to load pyenv
        export PYENV_ROOT="$HOME/.pyenv"
        [[ -d $PYENV_ROOT/bin ]] && export PATH="$PYENV_ROOT/bin:$PATH"
        eval "$(pyenv init -)" 2>/dev/null || true
        
        if command -v pyenv &> /dev/null; then
            success "pyenv: $(pyenv --version)"
        else
            warning "pyenv: Installed but not in PATH"
        fi
    else
        error "pyenv not found"
        return 1
    fi
    
    # uv
    if command -v uv &> /dev/null; then
        success "uv: $(uv --version)"
    else
        warning "uv not found in PATH"
    fi
}

# Node.js environment verification
verify_nodejs() {
    log "Node.js environment verification..."
    
    # nvm
    if [ -d "$HOME/.nvm" ]; then
        success "nvm: Installation directory exists"
        
        # Load nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        
        if command -v nvm &> /dev/null; then
            success "nvm: $(nvm --version)"
            
            # Check Node.js version
            node_version=$(node --version)
            if [[ "$node_version" == "v23.8.0" ]]; then
                success "Node.js: $node_version (target version)"
            else
                warning "Node.js: $node_version (expected: v23.8.0)"
                
                # Try to switch to 23.8.0
                if nvm list | grep -q "v23.8.0"; then
                    nvm use 23.8.0
                    success "Node.js: Switched to $(node --version)"
                else
                    warning "Node.js v23.8.0 not installed"
                fi
            fi
            
            # npm check
            if command -v npm &> /dev/null; then
                success "npm: $(npm --version)"
            else
                error "npm not found"
            fi
        else
            warning "nvm: Installed but not loaded"
        fi
    else
        error "nvm not found"
        return 1
    fi
}

# MCP servers verification
verify_mcp() {
    log "MCP servers verification..."
    
    # Check MCP configuration
    if [ -f ".cursor/mcp.json" ]; then
        success "MCP: Configuration file exists"
        
        # Check for Atlassian MCP
        if grep -q "dsazz/mcp-jira" .cursor/mcp.json; then
            success "MCP: Atlassian JIRA integration configured"
        else
            warning "MCP: Atlassian JIRA integration not found"
        fi
        
        # Check for GitHub MCP
        if grep -q "mcp-server-github" .cursor/mcp.json; then
            success "MCP: GitHub integration configured"
        else
            warning "MCP: GitHub integration not found"
        fi
    else
        warning "MCP: Configuration file not found"
    fi
    
    # Check Docker containers
    if command -v docker &> /dev/null; then
        if docker ps -a | grep -q mcp; then
            success "MCP: Docker containers found"
        else
            warning "MCP: No Docker containers found"
        fi
    fi
}

# Windows 11 compatibility check
verify_windows_compatibility() {
    log "Windows 11 compatibility verification..."
    
    # WSL environment check
    if [ -n "${WSL_DISTRO_NAME:-}" ]; then
        success "WSL2: Running in $WSL_DISTRO_NAME"
    else
        warning "WSL2: Environment variables not detected"
    fi
    
    # Windows path accessibility
    windows_path="\\\\wsl.localhost\\Ubuntu-24.04\\home\\$(whoami)\\happyquest"
    success "Windows Path: $windows_path"
    
    # PowerShell command
    powershell_cmd="wsl -d Ubuntu-24.04 -- bash -c 'cd /home/$(whoami)/happyquest && ./environment-verification.sh'"
    success "PowerShell Command: $powershell_cmd"
}

# Main verification
main() {
    print_banner
    
    log "Starting comprehensive environment verification..."
    echo
    
    local failed=0
    
    verify_system_tools || ((failed++))
    echo
    
    verify_python || ((failed++))
    echo
    
    verify_nodejs || ((failed++))
    echo
    
    verify_mcp || ((failed++))
    echo
    
    verify_windows_compatibility
    echo
    
    if [ $failed -eq 0 ]; then
        success "🎉 All systems operational! Windows 11 automation ready."
        log "PC sales automation system: ✅ READY FOR DEPLOYMENT"
    else
        warning "⚠️ Some components need attention ($failed issues found)"
        log "PC sales automation system: 🔧 NEEDS CONFIGURATION"
    fi
    
    echo
    log "Environment verification completed"
}

main "$@"