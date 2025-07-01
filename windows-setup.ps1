# HappyQuest Windows 11 → WSL2 Ubuntu 自動環境構築スクリプト
# 作成者: HappyQuest開発チーム
# 目的: PC販売サービス向けシステム環境自動構築

param(
    [string]$WSLDistro = "Ubuntu-24.04",
    [string]$ProjectDir = "happyquest",
    [switch]$TestOnly = $false,
    [switch]$Verbose = $false
)

# 管理者権限チェック
if (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Error "このスクリプトは管理者権限で実行してください"
    exit 1
}

# ログ関数
function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

# バナー表示
function Show-Banner {
    Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║               HappyQuest Windows 11 Automation              ║
║            自動システム環境構築 for PC販売サービス             ║
║                                                              ║
║  🚀 WSL2 + Ubuntu 24.04 + 完全開発環境                      ║
║  📦 Docker + Python + Node.js + AI開発ツール一式            ║
║  🔧 ワンクリック自動インストール                               ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green
}

# WSL2有効化チェック・実行
function Enable-WSL2 {
    Write-Log "WSL2有効化状況をチェック中..."
    
    $wslFeature = Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux
    $vmPlatform = Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform
    
    if ($wslFeature.State -ne "Enabled") {
        Write-Log "WSL機能を有効化中..." "WARN"
        Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -NoRestart
    }
    
    if ($vmPlatform.State -ne "Enabled") {
        Write-Log "仮想マシンプラットフォームを有効化中..." "WARN"
        Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -NoRestart
    }
}

# Ubuntu 24.04インストール
function Install-Ubuntu {
    Write-Log "Ubuntu 24.04インストール状況をチェック中..."
    
    $distroList = wsl --list --quiet
    if ($distroList -notcontains $WSLDistro) {
        Write-Log "Ubuntu 24.04をインストール中..." "WARN"
        wsl --install -d $WSLDistro
        
        # インストール完了待機
        do {
            Start-Sleep -Seconds 5
            $distroList = wsl --list --quiet
        } while ($distroList -notcontains $WSLDistro)
    }
    
    Write-Log "WSL2をデフォルトバージョンに設定中..."
    wsl --set-default-version 2
    wsl --set-version $WSLDistro 2
}

# 環境変数・プロジェクト設定
function Setup-Environment {
    $linuxPath = "/home/$(wsl whoami)/$ProjectDir"
    $windowsPath = "\\wsl.localhost\$WSLDistro\home\$(wsl whoami)\$ProjectDir"
    
    Write-Log "プロジェクトディレクトリ: $windowsPath"
    Write-Log "Linux内パス: $linuxPath"
    
    return @{
        LinuxPath = $linuxPath
        WindowsPath = $windowsPath
    }
}

# 前提条件テスト
function Test-Prerequisites {
    Write-Log "前提条件テスト実行中..." "WARN"
    $results = @()
    
    # WSL2動作確認
    try {
        $wslVersion = wsl --version
        $results += @{Test="WSL2"; Status="PASS"; Details=$wslVersion[0]}
    } catch {
        $results += @{Test="WSL2"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    # Ubuntu接続確認
    try {
        $ubuntuVersion = wsl -d $WSLDistro -- lsb_release -d
        $results += @{Test="Ubuntu"; Status="PASS"; Details=$ubuntuVersion}
    } catch {
        $results += @{Test="Ubuntu"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    # ネットワーク接続確認
    try {
        $internetTest = Test-NetConnection -ComputerName "github.com" -Port 443
        $status = if ($internetTest.TcpTestSucceeded) { "PASS" } else { "FAIL" }
        $results += @{Test="Internet"; Status=$status; Details="GitHub接続"}
    } catch {
        $results += @{Test="Internet"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    # ディスク容量確認 (最低10GB)
    $freeSpace = (Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='C:'").FreeSpace / 1GB
    $status = if ($freeSpace -gt 10) { "PASS" } else { "WARN" }
    $results += @{Test="DiskSpace"; Status=$status; Details="$([math]::Round($freeSpace, 1))GB 空き容量"}
    
    return $results
}

# Ansibleプレイブック実行
function Invoke-AnsibleSetup {
    param([hashtable]$Paths)
    
    Write-Log "Ubuntu側でAnsible環境構築を実行中..." "WARN"
    
    # Ansibleインストール確認・実行
    $ansibleCmd = @"
cd $($Paths.LinuxPath) && \
if ! command -v ansible &> /dev/null; then \
    sudo apt update && sudo apt install -y ansible; \
fi && \
chmod +x infrastructure/run-setup.sh && \
./infrastructure/run-setup.sh --non-interactive
"@
    
    try {
        wsl -d $WSLDistro -- bash -c $ansibleCmd
        Write-Log "Ansible環境構築完了" "SUCCESS"
        return $true
    } catch {
        Write-Log "Ansible実行エラー: $($_.Exception.Message)" "ERROR"
        return $false
    }
}

# 環境検証テスト
function Test-Environment {
    param([hashtable]$Paths)
    
    Write-Log "環境検証テスト実行中..." "WARN"
    $results = @()
    
    # Python環境確認
    try {
        $pythonVersion = wsl -d $WSLDistro -- bash -c "source ~/.bashrc && python3 --version"
        $results += @{Test="Python"; Status="PASS"; Details=$pythonVersion}
    } catch {
        $results += @{Test="Python"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    # Node.js環境確認
    try {
        $nodeVersion = wsl -d $WSLDistro -- bash -c "source ~/.bashrc && node --version"
        $results += @{Test="Node.js"; Status="PASS"; Details=$nodeVersion}
    } catch {
        $results += @{Test="Node.js"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    # Docker確認
    try {
        $dockerVersion = wsl -d $WSLDistro -- docker --version
        $results += @{Test="Docker"; Status="PASS"; Details=$dockerVersion}
    } catch {
        $results += @{Test="Docker"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    # MCPサーバー確認
    try {
        $mcpStatus = wsl -d $WSLDistro -- bash -c "cd $($Paths.LinuxPath) && docker ps | grep mcp"
        $status = if ($mcpStatus) { "PASS" } else { "WARN" }
        $results += @{Test="MCP-Servers"; Status=$status; Details="Docker MCP確認"}
    } catch {
        $results += @{Test="MCP-Servers"; Status="FAIL"; Details=$_.Exception.Message}
    }
    
    return $results
}

# レポート生成
function Generate-Report {
    param([array]$PreTests, [array]$PostTests, [string]$ReportPath)
    
    $report = @"
# HappyQuest 自動環境構築レポート
生成日時: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
WSLディストリビューション: $WSLDistro

## 前提条件テスト結果
"@
    
    foreach ($test in $PreTests) {
        $status = if ($test.Status -eq "PASS") { "✅" } elseif ($test.Status -eq "WARN") { "⚠️" } else { "❌" }
        $report += "`n- $status **$($test.Test)**: $($test.Details)"
    }
    
    $report += "`n`n## 環境構築後テスト結果"
    foreach ($test in $PostTests) {
        $status = if ($test.Status -eq "PASS") { "✅" } elseif ($test.Status -eq "WARN") { "⚠️" } else { "❌" }
        $report += "`n- $status **$($test.Test)**: $($test.Details)"
    }
    
    $report += "`n`n## 利用可能機能"
    $report += "`n- 🐍 Python 3.12.9 + pyenv"
    $report += "`n- 🟢 Node.js 23.8.0 + nvm"
    $report += "`n- 🐳 Docker CE + MCP Servers"
    $report += "`n- 📝 GitHub CLI + Atlassian MCP"
    $report += "`n- 🧪 Playwright + テスト環境"
    
    $report | Out-File -FilePath $ReportPath -Encoding UTF8
    Write-Log "レポート保存: $ReportPath" "SUCCESS"
}

# メイン実行関数
function Start-Setup {
    Show-Banner
    
    # テストのみモード
    if ($TestOnly) {
        Write-Log "テストモードで実行中..." "WARN"
        $preTests = Test-Prerequisites
        Generate-Report -PreTests $preTests -PostTests @() -ReportPath ".\happyquest-test-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        return
    }
    
    try {
        # 1. 前提条件テスト
        Write-Log "=== フェーズ 1: 前提条件テスト ===" "WARN"
        $preTests = Test-Prerequisites
        
        # 2. WSL2セットアップ
        Write-Log "=== フェーズ 2: WSL2セットアップ ===" "WARN"
        Enable-WSL2
        Install-Ubuntu
        
        # 3. 環境パス設定
        Write-Log "=== フェーズ 3: 環境設定 ===" "WARN"
        $paths = Setup-Environment
        
        # 4. Windows 11対応環境構築実行
        Write-Log "=== フェーズ 4: 開発環境構築 ===" "WARN"
        $setupSuccess = Invoke-CompatibleSetup -Paths $paths
        
        if (-not $setupSuccess) {
            Write-Log "環境構築で問題が発生しました。手動確認が必要です。" "ERROR"
            return
        }
        
        # 5. 環境検証
        Write-Log "=== フェーズ 5: 環境検証 ===" "WARN"
        $postTests = Test-Environment -Paths $paths
        
        # 6. レポート生成
        Write-Log "=== フェーズ 6: レポート生成 ===" "WARN"
        $reportPath = ".\happyquest-setup-$(Get-Date -Format 'yyyyMMdd-HHmmss').md"
        Generate-Report -PreTests $preTests -PostTests $postTests -ReportPath $reportPath
        
        Write-Log "HappyQuest環境構築が完了しました！" "SUCCESS"
        Write-Log "WSLアクセス: wsl -d $WSLDistro" "SUCCESS"
        Write-Log "プロジェクト: $($paths.WindowsPath)" "SUCCESS"
        
    } catch {
        Write-Log "セットアップエラー: $($_.Exception.Message)" "ERROR"
        exit 1
    }
}

# スクリプト実行
Start-Setup