# 🔄 作業再開手順書

## 📋 トークン制限で中断時の復旧手順

### 1. **現在の状況確認**
```bash
# 現在のブランチ確認
git branch --show-current

# リモートとの同期状態確認
git status

# 最新のPR確認
gh pr list --head $(git branch --show-current)

# GitHub Actions状況確認
gh run list --limit 3
```

### 2. **作業コンテキスト復元**
```bash
# CLAUDE.mdで現在の状況確認
cat CLAUDE.md | grep -A 10 "Memory Notes"

# 最新のコミットメッセージで作業内容確認
git log --oneline -5

# TODOがあれば確認
find . -name "*.md" -exec grep -l "TODO\|FIXME" {} \;
```

### 3. **Issue駆動開発での再開手順**

#### A. **新しいIssueから開始**
```bash
# Issue作成（ブラウザまたはCLI）
gh issue create --title "作業タイトル" --body "作業内容詳細"

# 自動ブランチ作成（practical-ci.ymlで自動実行）
# または手動作成
ISSUE_NUM=123
git checkout -b "feature/issue-${ISSUE_NUM}-description"
```

#### B. **既存作業の継続**
```bash
# 現在のブランチで作業継続
git checkout feature/clean-integration-secure

# 作業進捗確認
cat WORK_PROGRESS.md 2>/dev/null || echo "進捗ファイルなし"
```

### 4. **作業再開チェックリスト**

#### 🔍 **環境確認**
- [ ] Docker状況: `docker ps`
- [ ] MCP状況: `./mcp-control.sh status`
- [ ] GitHub認証: `gh auth status`
- [ ] ブランチ状況: `git branch -a`

#### 📝 **作業状況確認**
- [ ] 現在のIssue: `gh issue list --assignee @me`
- [ ] 進行中のPR: `gh pr list --author @me`
- [ ] 失敗中のActions: `gh run list --status failure`
- [ ] 未コミット変更: `git status --porcelain`

#### 🎯 **作業優先順位**
1. **緊急**: GitHub Actions失敗修正
2. **重要**: セキュリティ問題対応
3. **通常**: 機能追加・改善
4. **将来**: 最適化・リファクタリング

### 5. **PR作成・マージまでの流れ**

#### ✅ **推奨ワークフロー**
```bash
# 1. Issue作成
gh issue create --title "Fix GitHub Actions failures" --label bug

# 2. ブランチ作成（自動 or 手動）
git checkout -b feature/issue-123-fix-actions

# 3. 作業実行
# ... コード修正 ...

# 4. コミット・プッシュ
git add .
git commit -m "🔧 Fix: GitHub Actions error handling"
git push origin feature/issue-123-fix-actions

# 5. PR作成（自動テスト実行）
gh pr create --title "Fix GitHub Actions failures" --body "Closes #123"

# 6. レビュー・修正対応
# ... 修正があれば追加コミット ...

# 7. マージ（承認後）
gh pr merge --squash
```

### 6. **緊急時の対応**

#### 🚨 **Actions全失敗時**
```bash
# 実用的CI-に切り替え
git checkout .github/workflows/practical-ci.yml
git add .github/workflows/practical-ci.yml
git commit -m "🔧 Switch to practical CI pipeline"
git push
```

#### 🔐 **セキュリティ問題時**
```bash
# シークレット削除・環境変数化
# APIトークンなどを環境変数に移行
git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch FILE_WITH_SECRET' --prune-empty -- --all
```

#### 💾 **Docker高負荷時**
```bash
# 重いサービス停止
./n8n-control.sh stop
./mcp-control.sh stop-optional

# メモリ確認
free -h
docker stats --no-stream
```

### 7. **定期メンテナンス**

#### 📅 **週次タスク**
```bash
# 古いブランチ整理
git branch --merged main | grep -v main | xargs git branch -d

# 未使用Dockerイメージ削除
docker system prune -f

# MCPサーバー状況確認
./mcp-control.sh status
```

#### 📊 **品質確認**
```bash
# GitHub Actions成功率確認
gh run list --limit 20 | grep -c "success"

# セキュリティ状況確認
gh security-advisory list

# 依存関係更新確認
npm audit || echo "No package.json"
```

---

## 📞 **サポート情報**

- **GitHub CLI**: `gh --help`
- **Git**: `git --help`
- **Docker**: `docker --help`
- **プロジェクト固有**: `./mcp-control.sh` `./n8n-control.sh`

---

**🎯 このファイルはトークン制限時の作業再開を円滑化するためのものです。**
**定期的に更新し、プロジェクトの変化に合わせて調整してください。**