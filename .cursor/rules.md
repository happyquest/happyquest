# HappyQuest Project Rules

このファイルは、HappyQuestプロジェクトにおけるCursor AI開発の統一ルールを定義します。

## 📁 ルール構成

Project Rulesは以下のカテゴリに分類されています：

### 🎯 コアルール（常時適用）
- `core-rules/ai-behavior-always.mdc` - AI基本動作ルール
- `core-rules/project-context-always.mdc` - プロジェクト文脈ルール

### 🔍 レビュールール
- `review-rules/pr-review-agent.mdc` - Pull Request自動レビュー

### 🧪 テストルール
- `testing-rules/tdd-workflow-agent.mdc` - テスト駆動開発ワークフロー

### 🛠️ ツールルール
- `tool-rules/git-safety-always.mdc` - Git安全操作ルール

### 🔒 セキュリティルール
- `security-rules/security-standards-always.mdc` - セキュリティ基準

## 🚀 使用方法

### 1. 自動適用ルール
`alwaysApply: true` が設定されたルールは、すべてのAI操作で自動的に適用されます。

### 2. 条件付きルール
特定の条件下でのみ適用されるルールは、必要に応じて手動で参照してください。

### 3. レビュー実行
Pull Requestレビューを実行する場合：
```
@pr-review この変更をレビューしてください
```

## 📋 重要な原則

1. **日本語優先**: すべての応答は日本語で行う
2. **Pull Request必須**: すべての変更はPRを通して行う
3. **テスト駆動**: TDDサイクルに従って開発する
4. **セキュリティ重視**: 機密情報の管理を徹底する
5. **品質基準**: 80%以上のテストカバレッジを維持する

## 🔄 ルール更新

Project Rulesの更新は以下の手順で行います：

1. 該当するルールファイルを編集
2. Pull Requestを作成
3. レビューと承認
4. マージ後に自動適用

## 📊 品質メトリクス

- **テストカバレッジ**: 80%以上
- **静的解析**: エラー0件
- **セキュリティスキャン**: 脆弱性0件
- **コード品質スコア**: 80点以上

---

*このProject Rulesは、HappyQuestプロジェクトの開発効率と品質向上を目的として策定されています。* 