# Atlassian Remote MCP Server（ベータ版）調査

## 📋 公式情報

### Atlassian Remote MCP Server とは
- **提供元**: Atlassian公式
- **状態**: ベータ版
- **目的**: Rovo DevとCursor等のIDEを直接連携

### 🔍 アクセス方法の調査

#### 1. Atlassian Developer Console
```
https://developer.atlassian.com/
```

#### 2. Rovo Dev ベータプログラム
```
https://www.atlassian.com/software/rovo/dev
```

#### 3. MCP公式リポジトリ
```
https://github.com/modelcontextprotocol/servers
```

## 🎯 必要な確認事項

### ベータプログラム参加状況
- [ ] Atlassian Rovo Dev ベータに登録済み？
- [ ] Remote MCP Serverへのアクセス権限あり？
- [ ] 専用のAPIキーやエンドポイント提供済み？

### 設定情報
- [ ] Remote MCP Serverのエンドポイント
- [ ] 認証方法（APIキー、OAuth等）
- [ ] 利用可能な機能一覧

## 💡 代替案

### 1. 公式MCPサーバーの直接利用
```bash
npx @modelcontextprotocol/server-atlassian
```

### 2. サードパーティMCPサーバー
```bash
# kornbed/jira-mcp-server
npm install -g jira-mcp-server

# sooperset/mcp-atlassian  
npm install -g @sooperset/mcp-atlassian
```

### 3. 自作MCPサーバー（現在のDocker環境）
```bash
# 既存のhappyquest-mcp-serverを拡張
docker exec happyquest-mcp-server node /app/atlassian-mcp.js
```

## 🔧 推奨アクション

### 即座に実行可能
1. **公式MCPサーバーの確認**
2. **サードパーティオプションのテスト**
3. **現在のDocker環境での実装**

### ベータプログラム参加後
1. **Remote MCP Serverの設定**
2. **公式エンドポイントの利用**
3. **高度な統合機能の活用**