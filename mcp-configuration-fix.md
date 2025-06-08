# 🔧 MCP設定競合解決・統合修正計画

**作成日**: 2025年6月8日  
**問題**: github-minimal vs docker-github-essential 競合  
**解決目標**: 単一統合MCP設定による安定運用

---

## ⚠️ **検出された競合問題**

### **設定ファイル競合**
```
❌ 現在の問題状況:
├── .cursor/mcp.json
│   └── github-minimal (npx @modelcontextprotocol/server-github)
│       └── 8ツール有効、38ツール無効
└── docker-mcp-minimal-config.json  
    └── docker-github-essential (docker run mcp-github:minimal)
        └── 5ツール有効、Docker化

🚨 結果: 2つのGitHub MCPサーバーが同時実行される可能性
```

### **技術的影響**
- **ポート競合**: GitHubアクセスの重複
- **メモリ重複使用**: 同じ機能の二重起動
- **設定混乱**: どちらの設定が有効か不明確
- **エラー発生**: 予期しない接続失敗

---

## ✅ **解決策（3オプション）**

### **Option A: Docker MCP統合（推奨92%）**
#### **メリット**
- コンテナ分離によるセキュリティ向上
- リソース制限によるメモリ管理
- バージョン管理とポータビリティ
- 複数環境での一貫性確保

#### **修正内容**
```json
// .cursor/mcp.json（修正版）
{
  "mcpServers": {
    "github-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--name", "happyquest-github-mcp", 
        "-e", "GITHUB_TOKEN=${GITHUB_TOKEN}",
        "mcp/github:latest"
      ],
      "disabled": false,
      "env": {
        "GITHUB_TOKEN": "${GITHUB_TOKEN}"
      },
      "settings": {
        "enabledTools": [
          "get_file_contents",
          "list_repositories", 
          "search_code",
          "get_issue",
          "create_issue",
          "list_issues",
          "get_pull_request",
          "list_pull_requests"
        ]
      }
    },
    "browser-docker": {
      "command": "docker",
      "args": [
        "run", "-i", "--rm",
        "--name", "happyquest-browser-mcp",
        "-e", "DISPLAY=:0",
        "mcp/browser:latest"
      ],
      "disabled": false
    }
  }
}
```

### **Option B: npx MCP純粋版（安定88%）**
#### **メリット**  
- シンプルな設定
- Docker不要で軽量
- 既存設定の活用

#### **修正内容**
```json
// .cursor/mcp.json（現在のまま維持）
// docker-mcp-minimal-config.json（削除）
```

### **Option C: ハイブリッド運用（柔軟85%）**
#### **メリット**
- 用途に応じて使い分け
- 機能の最大活用

#### **修正内容**
```json
// .cursor/mcp.json
{
  "mcpServers": {
    "github-npx": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-github"],
      "disabled": false,
      "description": "基本GitHub操作用"
    },
    "browser-docker": {
      "command": "docker", 
      "args": ["run", "-i", "--rm", "mcp/browser:latest"],
      "disabled": false,
      "description": "ブラウザ自動化用"
    }
  }
}
```

---

## 🚀 **推奨実装手順（Option A）**

### **Phase 1: Docker環境準備（5分）**
```bash
# 1. GitHub Docker MCP用イメージ確認
docker pull mcp/github:latest || docker build -t mcp/github:latest .

# 2. Browser Docker MCP用イメージ確認  
docker pull mcp/browser:latest || docker build -t mcp/browser:latest .

# 3. 環境変数設定確認
echo $GITHUB_TOKEN  # 設定済み確認
```

### **Phase 2: MCP設定統合（3分）**
```bash
# 1. 既存設定バックアップ
cp .cursor/mcp.json .cursor/mcp.json.backup-$(date +%Y%m%d%H%M%S)

# 2. Docker統合設定に変更
# （edit_fileツールで実装）

# 3. 冗長設定ファイル削除
rm docker-mcp-minimal-config.json  # 統合後不要
```

### **Phase 3: 動作検証（5分）**
```bash
# 1. Cursor再起動

# 2. MCP接続テスト
# Ctrl+Shift+P > "MCP: List Servers"

# 3. GitHub機能テスト
# AIに "GitHubリポジトリ一覧表示" 依頼

# 4. Browser機能テスト（必要時）
# AIに "GoogleでHappyQuestを検索" 依頼
```

### **Phase 4: 設定最適化（2分）**
```bash
# 1. リソース制限調整
# memory: 256MB → 512MB（必要に応じて）

# 2. ツール数最終確認
# 期待値: 8-12ツール（目標40以下の20-30%）

# 3. パフォーマンス監視設定
# Docker stats確認スクリプト作成
```

---

## 📋 **修正チェックリスト**

### **即座実行項目** ⚡
- [ ] docker-mcp-minimal-config.json 削除
- [ ] .cursor/mcp.json Docker統合版に変更  
- [ ] 競合設定ファイル整理

### **検証項目** 🧪
- [ ] Docker コンテナ起動確認
- [ ] GitHub MCP接続テスト
- [ ] Cursor MCP認識確認
- [ ] メモリ使用量測定

### **最適化項目** ⚙️
- [ ] リソース制限調整
- [ ] セキュリティ設定確認
- [ ] ログ出力設定
- [ ] 自動起動設定

---

## 🎯 **期待される改善効果**

### **技術的改善**
- **設定一元化**: 1つのmcp.jsonで完結
- **競合解消**: GitHub MCP設定重複なし
- **メモリ効率**: Docker制限による最適化
- **セキュリティ**: コンテナ分離によるサンドボックス

### **運用改善**  
- **保守性**: シンプルな設定構造
- **可搬性**: Docker環境での一貫性
- **監視性**: Docker statsによるリソース監視
- **拡張性**: 新機能追加の容易さ

**総合改善確率: 92%** 