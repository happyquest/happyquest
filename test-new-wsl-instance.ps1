# HappyQuest WSL2 新インスタンステスト
# PC販売自動化システム完全検証

param(
    [string]$TestInstanceName = "Ubuntu-24-04-Test",
    [string]$SourceDistro = "Ubuntu-24.04"
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

Write-Host @"
╔══════════════════════════════════════════════════════════════╗
║           HappyQuest WSL2 新インスタンステスト               ║
║              PC販売自動化システム完全検証                    ║
╚══════════════════════════════════════════════════════════════╝
"@ -ForegroundColor Green

# 現在のWSL状況確認
Write-Log "現在のWSL2インスタンス一覧確認"
wsl --list --verbose

# 新しいテスト用インスタンス作成
Write-Log "新しいテストインスタンス作成: $TestInstanceName"

try {
    # Ubuntu 24.04をテスト用にエクスポート・インポート
    $exportPath = "$env:TEMP\ubuntu-test-export.tar"
    
    Write-Log "既存Ubuntu-24.04をエクスポート中..."
    wsl --export $SourceDistro $exportPath
    
    Write-Log "テスト用インスタンスをインポート中..."
    $importPath = "C:\WSL\$TestInstanceName"
    New-Item -Path $importPath -ItemType Directory -Force | Out-Null
    wsl --import $TestInstanceName $importPath $exportPath
    
    # エクスポートファイル削除
    Remove-Item $exportPath -Force
    
    Write-Log "WSL2バージョン設定"
    wsl --set-version $TestInstanceName 2
    
    Write-Log "新インスタンス作成完了" "SUCCESS"
    
    # テストインスタンス動作確認
    Write-Log "テストインスタンス動作確認中..."
    $testResult = wsl -d $TestInstanceName -- echo "テストインスタンス動作確認"
    
    if ($testResult -eq "テストインスタンス動作確認") {
        Write-Log "テストインスタンス正常動作確認" "SUCCESS"
    } else {
        Write-Log "テストインスタンス動作異常" "ERROR"
        exit 1
    }
    
    # プロジェクトディレクトリ作成・ファイルコピー
    Write-Log "プロジェクトファイルをテストインスタンスにコピー中..."
    
    # happyquestディレクトリ作成
    wsl -d $TestInstanceName -- mkdir -p /home/root/happyquest-test
    
    # 必要なファイルをコピー
    $sourceFiles = @(
        "infrastructure/windows11-compatible-setup.sh",
        "environment-verification.sh"
    )
    
    foreach ($file in $sourceFiles) {
        $sourcePath = "\\wsl.localhost\Ubuntu-24.04\home\nanashi7777\happyquest\$file"
        $targetPath = "\\wsl.localhost\$TestInstanceName\home\root\happyquest-test\$($file -replace '.*/','')'"
        
        if (Test-Path $sourcePath) {
            Write-Log "コピー中: $file"
            Copy-Item $sourcePath "\\wsl.localhost\$TestInstanceName\home\root\happyquest-test\" -Force
        } else {
            Write-Log "ファイルが見つかりません: $file" "WARN"
        }
    }
    
    Write-Log "テスト環境準備完了" "SUCCESS"
    Write-Log "次のコマンドでテストインスタンスにアクセス:"
    Write-Log "wsl -d $TestInstanceName" "SUCCESS"
    Write-Log "テストディレクトリ: /home/root/happyquest-test" "SUCCESS"
    
} catch {
    Write-Log "エラー: $($_.Exception.Message)" "ERROR"
    exit 1
}