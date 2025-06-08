packer {
  required_plugins {
    windows = {
      version = ">= 0.14.0"
      source  = "github.com/hashicorp/windows"
    }
    ansible = {
      version = "~> 1"
      source = "github.com/hashicorp/ansible"
    }
  }
}

# Variables
variable "project_name" {
  type        = string
  default     = "happyquest"
  description = "Project name for resource naming"
}

variable "admin_user" {
  type        = string
  default     = "nanashi7777"
  description = "Admin user name"
}

variable "regular_user" {
  type        = string
  default     = "taki"
  description = "Regular user name"
}

variable "wsl_instance_name" {
  type        = string
  default     = "Ubuntu-24.04-HappyQuest"
  description = "WSL instance name"
}

# WSL2 Ubuntu 24.04 Build
source "null" "ubuntu24-wsl2" {
  communicator = "none"
}

build {
  name = "ubuntu24-wsl2-setup"
  sources = ["source.null.ubuntu24-wsl2"]

  # Step 1: WSL2 Ubuntu 24.04 Installation
  provisioner "powershell" {
    inline = [
      "Write-Host 'Starting WSL2 Ubuntu 24.04 installation...'",
      "# Enable WSL2 feature if not already enabled",
      "if ((Get-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux).State -ne 'Enabled') {",
      "  Enable-WindowsOptionalFeature -Online -FeatureName Microsoft-Windows-Subsystem-Linux -All -NoRestart",
      "}",
      "if ((Get-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform).State -ne 'Enabled') {",
      "  Enable-WindowsOptionalFeature -Online -FeatureName VirtualMachinePlatform -All -NoRestart",
      "}",
      "",
      "# Set WSL default version to 2",
      "wsl --set-default-version 2",
      "",
      "# Install Ubuntu 24.04 if not exists",
      "$distroExists = wsl -l -v | Select-String '${var.wsl_instance_name}'",
      "if (-not $distroExists) {",
      "  Write-Host 'Installing Ubuntu 24.04...'",
      "  wsl --install -d Ubuntu-24.04",
      "  Write-Host 'Ubuntu 24.04 installation initiated'",
      "} else {",
      "  Write-Host 'Ubuntu 24.04 already installed'",
      "}",
      "",
      "# Wait for WSL to be ready",
      "Start-Sleep -Seconds 30",
      "",
      "# Verify installation",
      "wsl -l -v"
    ]
  }

  # Step 2: Initial System Setup
  provisioner "shell" {
    inline = [
      "#!/bin/bash",
      "set -e",
      "echo 'Starting initial system setup...'",
      "",
      "# Update system",
      "sudo apt update && sudo apt upgrade -y",
      "",
      "# Install essential packages",
      "sudo apt install -y curl wget git vim nano htop tree unzip zip",
      "sudo apt install -y build-essential software-properties-common",
      "sudo apt install -y apt-transport-https ca-certificates gnupg lsb-release",
      "",
      "# Setup Japanese locale",
      "sudo apt install -y language-pack-ja",
      "sudo locale-gen ja_JP.UTF-8",
      "sudo update-locale LANG=ja_JP.UTF-8",
      "",
      "# Setup Japanese Ubuntu sources",
      "sudo cp /etc/apt/sources.list /etc/apt/sources.list.backup",
      "sudo tee /etc/apt/sources.list > /dev/null <<EOF",
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble main restricted",
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble-updates main restricted",
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble universe",
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble-updates universe",
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble multiverse", 
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble-updates multiverse",
      "deb http://jp.archive.ubuntu.com/ubuntu/ noble-backports main restricted universe multiverse",
      "deb http://security.ubuntu.com/ubuntu/ noble-security main restricted",
      "deb http://security.ubuntu.com/ubuntu/ noble-security universe",
      "deb http://security.ubuntu.com/ubuntu/ noble-security multiverse",
      "EOF",
      "",
      "sudo apt update",
      "echo 'Initial system setup completed'"
    ]
  }

  # Step 3: User Management
  provisioner "shell" {
    inline = [
      "#!/bin/bash",
      "set -e",
      "echo 'Setting up users...'",
      "",
      "# Create admin user (nanashi7777) if not exists",
      "if ! id '${var.admin_user}' &>/dev/null; then",
      "  sudo useradd -m -s /bin/bash -G sudo '${var.admin_user}'",
      "  echo '${var.admin_user}:admin123' | sudo chpasswd",
      "  echo '${var.admin_user} ALL=(ALL) NOPASSWD:ALL' | sudo tee /etc/sudoers.d/${var.admin_user}",
      "fi",
      "",
      "# Create regular user (taki) if not exists", 
      "if ! id '${var.regular_user}' &>/dev/null; then",
      "  sudo useradd -m -s /bin/bash '${var.regular_user}'",
      "  echo '${var.regular_user}:user123' | sudo chpasswd",
      "fi",
      "",
      "# Setup happyquest directory structure",
      "sudo -u ${var.admin_user} mkdir -p /home/${var.admin_user}/happyquest/{src,tests,docs,infrastructure,作業報告書,トラブル事例,アーカイブ}",
      "sudo -u ${var.admin_user} mkdir -p /home/${var.admin_user}/happyquest/docs/{plantuml,database,images}",
      "",
      "echo 'User setup completed'"
    ]
  }

  # Step 4: Run Ansible for detailed configuration
  provisioner "ansible" {
    playbook_file = "./ansible/ubuntu24-setup.yml"
    user = "${var.admin_user}"
    extra_arguments = [
      "-e", "admin_user=${var.admin_user}",
      "-e", "regular_user=${var.regular_user}",
      "-e", "project_name=${var.project_name}"
    ]
  }

  # Step 5: HashiCorp Vault Setup
  provisioner "shell" {
    inline = [
      "#!/bin/bash",
      "set -e",
      "echo 'Setting up HashiCorp Vault...'",
      "",
      "# Install HashiCorp GPG key",
      "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
      "echo \"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",
      "",
      "# Install Vault",
      "sudo apt update && sudo apt install -y vault",
      "",
      "# Create Vault configuration",
      "sudo mkdir -p /etc/vault.d",
      "sudo tee /etc/vault.d/vault.hcl > /dev/null <<EOF",
      "ui = true",
      "disable_mlock = true",
      "",
      "storage \"file\" {",
      "  path = \"/opt/vault/data\"",
      "}",
      "",
      "listener \"tcp\" {",
      "  address     = \"127.0.0.1:8200\"",
      "  tls_disable = 1",
      "}",
      "",
      "api_addr = \"http://127.0.0.1:8200\"",
      "cluster_addr = \"https://127.0.0.1:8201\"",
      "EOF",
      "",
      "# Create Vault data directory",
      "sudo mkdir -p /opt/vault/data",
      "sudo chown -R vault:vault /opt/vault",
      "",
      "# Create systemd service",
      "sudo tee /etc/systemd/system/vault.service > /dev/null <<EOF",
      "[Unit]",
      "Description=HashiCorp Vault",
      "Documentation=https://www.vaultproject.io/docs/",
      "Requires=network-online.target",
      "After=network-online.target",
      "ConditionFileNotEmpty=/etc/vault.d/vault.hcl",
      "",
      "[Service]",
      "Type=notify",
      "User=vault",
      "Group=vault",
      "ProtectSystem=full",
      "ProtectHome=read-only",
      "PrivateTmp=yes",
      "PrivateDevices=yes",
      "SecureBits=keep-caps",
      "AmbientCapabilities=CAP_IPC_LOCK",
      "NoNewPrivileges=yes",
      "ExecStart=/usr/bin/vault server -config=/etc/vault.d/vault.hcl",
      "ExecReload=/bin/kill -HUP \\$MAINPID",
      "KillMode=process",
      "Restart=on-failure",
      "RestartSec=5",
      "TimeoutStopSec=30",
      "StartLimitBurst=3",
      "LimitNOFILE=65536",
      "",
      "[Install]",
      "WantedBy=multi-user.target",
      "EOF",
      "",
      "# Enable and start Vault service",
      "sudo systemctl daemon-reload",
      "sudo systemctl enable vault",
      "sudo systemctl start vault",
      "",
      "echo 'HashiCorp Vault setup completed'"
    ]
  }

  # Step 6: Final validation and reporting  
  provisioner "shell" {
    inline = [
      "#!/bin/bash",
      "set -e",
      "echo 'Running final validation...'",
      "",
      "# Check installed software versions",
      "echo '=== Software Versions ==='",
      "python3 --version || echo 'Python3: Not installed'",
      "node --version || echo 'Node.js: Not installed'",
      "docker --version || echo 'Docker: Not installed'",
      "gh --version || echo 'GitHub CLI: Not installed'",
      "vault --version || echo 'Vault: Not installed'",
      "",
      "# Check services",
      "echo '=== Service Status ==='",
      "sudo systemctl is-active docker || echo 'Docker: Not running'",
      "sudo systemctl is-active vault || echo 'Vault: Not running'",
      "",
      "# Generate setup report",
      "sudo -u ${var.admin_user} tee /home/${var.admin_user}/happyquest/作業報告書/setup-report-$(date +%Y%m%d-%H%M%S).md > /dev/null <<EOF",
      "# Ubuntu 24.04 WSL2 環境構築完了レポート",
      "",
      "## 構築日時",
      "$(date '+%Y年%m月%d日 %H:%M:%S')",
      "",
      "## 構築内容",
      "- Ubuntu 24.04 WSL2環境",
      "- ユーザー: ${var.admin_user}(管理者), ${var.regular_user}(一般)",
      "- 開発ツール一式インストール",
      "- HashiCorp Vault セットアップ",
      "- プロジェクト構造作成",
      "",
      "## 次のステップ",
      "1. Vault初期化: export VAULT_ADDR='http://127.0.0.1:8200' && vault operator init",
      "2. 開発環境テスト実行",
      "3. CI/CD パイプライン設定",
      "",
      "EOF",
      "",
      "echo 'Setup completed successfully!'"
    ]
  }
} 