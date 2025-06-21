# 🔐 HappyQuest セキュリティガイドライン

## 🚨 重要な原則

### ❌ 絶対にやってはいけないこと
- **Personal Access Token の平文保存**
- **パスワードやAPIキーのコミット**
- **認証情報のプレーンテキスト保存**
- **機密データのGitHub公開リポジトリへの送信**

### ✅ 推奨されるセキュリティ対策

#### 1. 環境変数の使用
```bash
# .env ファイル（.gitignoreに含まれている）
GITHUB_TOKEN=your_token_here
GOOGLE_CLOUD_PROJECT=your_project_id
```

#### 2. Git設定での認証
```bash
# 安全なGit認証設定
git config --global user.name "happyquest"
git config --global user.email "d.takikita@happyquest.ai"
# Personal Access Tokenは環境変数またはGit Credential Managerで管理
```

#### 3. Google Cloud認証
```bash
# Google Cloud CLI認証
gcloud auth login
gcloud config set project happyquest-dev-2025
```

## 🛡️ ファイル管理ルール

### 機密ファイルの扱い
- **認証情報**: 環境変数またはシークレット管理ツール
- **設定ファイル**: `.env.example` でテンプレート提供
- **一時ファイル**: 作業後は必ず削除

### .gitignore 管理対象
- `.env*` - 環境設定ファイル
- `auth-credentials.md` - 認証情報ファイル
- `google-cloud-sdk/` - GCPツール
- `oauth2-diagnosis.sh` - 診断スクリプト

## 📋 セキュリティチェックリスト

### コミット前チェック
- [ ] Personal Access Token が含まれていないか
- [ ] パスワードや機密情報が含まれていないか
- [ ] `.env` ファイルが `.gitignore` に含まれているか
- [ ] 一時的な認証ファイルが削除されているか

### 定期的な確認
- [ ] 不要なPersonal Access Tokenの削除
- [ ] アクセス権限の最小化
- [ ] 機密ファイルの棚卸し

## 🔄 インシデント対応

### 機密情報が誤ってコミットされた場合
1. **即座にトークンを無効化**
2. **新しいトークンを生成**
3. **コミット履歴から完全削除**
4. **チーム全体への通知**

## 📞 連絡先
- セキュリティ問題: `security@happyquest.ai`
- 緊急時対応: 開発チームSlack `#security-incidents`

---
**最終更新**: 2025-06-19
**責任者**: HappyQuest Security Team 