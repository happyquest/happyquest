# Atlassian MCP Server セットアップガイド

## 現状分析
- GitHub MCP: ✅ 設定済み・稼働中
- Atlassian MCP: ❌ 未設定
- Browser MCP: ⚠️ 無効化状態

## 必要なAtlassian MCP機能

### Jira統合
```json
{
  "jira-mcp": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-jira"],
    "env": {
      "JIRA_HOST": "${JIRA_HOST}",
      "JIRA_EMAIL": "${JIRA_EMAIL}",
      "JIRA_API_TOKEN": "${JIRA_API_TOKEN}"
    },
    "settings": {
      "enabledTools": [
        "list_projects",
        "get_project",
        "list_issues",
        "get_issue",
        "create_issue",
        "update_issue",
        "add_comment",
        "get_transitions",
        "transition_issue",
        "search_issues"
      ]
    }
  }
}
```

### Confluence統合
```json
{
  "confluence-mcp": {
    "command": "npx",
    "args": ["-y", "@modelcontextprotocol/server-confluence"],
    "env": {
      "CONFLUENCE_HOST": "${CONFLUENCE_HOST}",
      "CONFLUENCE_EMAIL": "${CONFLUENCE_EMAIL}",
      "CONFLUENCE_API_TOKEN": "${CONFLUENCE_API_TOKEN}"
    },
    "settings": {
      "enabledTools": [
        "get_spaces",
        "get_pages_in_space",
        "get_page",
        "create_page",
        "update_page",
        "get_page_comments",
        "add_page_comment",
        "search_content"
      ]
    }
  }
}
```

## セットアップ手順

### 1. Atlassian APIトークンの取得
1. Atlassian アカウント設定にアクセス
2. セキュリティ → APIトークン
3. 新しいトークンを作成
4. 適切な権限を設定

### 2. 環境変数の設定
```bash
# .envファイルに追加
JIRA_HOST=https://your-domain.atlassian.net
JIRA_EMAIL=your-email@domain.com
JIRA_API_TOKEN=your-jira-token

CONFLUENCE_HOST=https://your-domain.atlassian.net
CONFLUENCE_EMAIL=your-email@domain.com
CONFLUENCE_API_TOKEN=your-confluence-token
```

### 3. MCP設定の更新
`.cursor/mcp.json`に上記の設定を追加

## テスト手順

### Jira接続テスト
```bash
# プロジェクト一覧の取得
curl -X GET \
  -H "Authorization: Basic $(echo -n 'email:token' | base64)" \
  -H "Accept: application/json" \
  "https://your-domain.atlassian.net/rest/api/3/project"
```

### Confluence接続テスト
```bash
# スペース一覧の取得
curl -X GET \
  -H "Authorization: Basic $(echo -n 'email:token' | base64)" \
  -H "Accept: application/json" \
  "https://your-domain.atlassian.net/wiki/rest/api/space"
```

## 利用可能な機能

### Jira操作
- ✅ プロジェクト管理
- ✅ 課題の作成・更新・検索
- ✅ コメント追加
- ✅ ステータス変更
- ✅ JQL検索

### Confluence操作
- ✅ ページ作成・更新
- ✅ スペース管理
- ✅ コンテンツ検索
- ✅ コメント機能
- ✅ ページ階層管理

### 統合ワークフロー例
1. **PRD作成**: Confluenceページ作成
2. **タスク分解**: JiraエピックとストーリーをPRDから生成
3. **進捗管理**: Jira課題のステータス更新
4. **ドキュメント更新**: 進捗に応じてConfluenceページを更新