# HappyQuest ドキュメント

## 📚 ドキュメント一覧

### AI駆動型開発ワークフロー

1. **[Qodo Merge による AI 駆動型コードレビュー](01-qodo-merge-code-review.md)**
   - Qodo Merge (旧Codium) の概要と機能
   - 対応範囲（Ansible、Shell、Docker、YAML）
   - JetBrains Qodana との比較

2. **[GitHub Actions による静的解析とリンティングの自動化](02-github-actions-automation.md)**
   - Ansible Playbook のリンティング (ansible-lint)
   - シェルスクリプトの静的解析 (ShellCheck)
   - Dockerfile の検証 (Hadolint)
   - YAML ファイルのリンティング (yamllint)

### インフラストラクチャ

- **infrastructure/**: Packer + Ansible 自動化スクリプト
- **infrastructure/ansible/**: Ubuntu 24.04 環境構築プレイブック
- **infrastructure/packer/**: WSL2 環境用 Packer 設定

### GitHub Actions ワークフロー

- **ansible-lint.yml**: Ansible プレイブックの品質チェック
- **ci-integration.yml**: 統合CI/CDパイプライン
- **document-quality.yml**: ドキュメント品質管理
- **pr-review-ai.yml**: AIによるプルリクエストレビュー

## 🔧 セットアップガイド

1. **前提条件**
   - Windows 11 + WSL2 Ubuntu 24.04
   - Docker Desktop
   - GitHub CLI

2. **環境構築**
   ```bash
   # Ansible requirements インストール
   cd infrastructure/ansible
   ansible-galaxy install -r requirements.yml
   
   # プレイブック実行
   ansible-playbook ubuntu24-setup.yml
   ```

3. **CI/CD設定**
   - GitHub Actions ワークフローが自動実行
   - Pull Request 時に品質チェック実行
   - マージ後にデプロイメント実行

## 📋 開発フロー

1. **ブランチ作成**: `feature/機能名`
2. **開発・テスト**: ローカル環境での実装とテスト
3. **Pull Request**: GitHub Actions による自動品質チェック
4. **コードレビュー**: Qodo Merge による AI アシスト
5. **マージ**: 品質基準通過後にメインブランチへマージ

## 🎯 PROJECT_RULES 準拠

このドキュメント構造は `PROJECT_RULES.md` に定義された以下の原則に従っています：

- **Pull Request 必須**: すべての変更はPRベースで管理
- **テスト駆動開発**: 自動テストとCI/CD統合
- **品質基準**: Google コーディング規約準拠
- **セキュリティ**: 静的解析とセキュリティスキャン必須 