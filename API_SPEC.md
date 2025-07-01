# API仕様書

## 概要
HappyQuestシステムのREST API仕様

## 目的と対象読者
- **目的**: APIエンドポイント・データフォーマットの標準化
- **対象読者**: 開発チーム、フロントエンド開発者、API利用者

## 最終更新日
2025-06-29

## 更新者
HappyQuest開発チーム

## 関連文書
- [SRS.md](./SRS.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [TEST_POLICY.md](./TEST_POLICY.md)

## API設計原則

### RESTful設計
- **リソース指向**: URL はリソースを表現
- **HTTPメソッド**: 適切な動詞使用 (GET, POST, PUT, DELETE)
- **ステートレス**: セッション状態をサーバー側で保持しない
- **統一インターフェース**: 一貫したURL・データ形式

### バージョニング
- **URLベース**: `/api/v1/`, `/api/v2/`
- **後方互換性**: 破壊的変更時のみバージョンアップ
- **廃止予定**: Deprecation Header使用

### セキュリティ
- **認証**: JWT Bearer Token
- **認可**: RBAC (Role-Based Access Control)
- **レート制限**: 100req/min/user
- **CORS**: 適切なオリジン制限

## ベースURL

```
開発環境: http://localhost:3000/api/v1
ステージング: https://staging-api.happyquest.ai/api/v1
本番環境: https://api.happyquest.ai/api/v1
```

## 認証・認可

### JWT認証
```http
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

### 権限レベル
- **admin**: 全リソースアクセス可能
- **user**: 個人リソースのみアクセス可能
- **readonly**: 読み取り専用アクセス

## 共通レスポンス形式

### 成功レスポンス
```json
{
  "success": true,
  "data": {
    // レスポンスデータ
  },
  "meta": {
    "timestamp": "2025-06-29T10:00:00Z",
    "version": "v1"
  }
}
```

### エラーレスポンス
```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input parameters",
    "details": [
      {
        "field": "email",
        "message": "Invalid email format"
      }
    ]
  },
  "meta": {
    "timestamp": "2025-06-29T10:00:00Z",
    "version": "v1"
  }
}
```

## データモデル

### Project
```json
{
  "id": "string",
  "name": "string",
  "description": "string",
  "status": "active|inactive|archived",
  "created_at": "string (ISO 8601)",
  "updated_at": "string (ISO 8601)",
  "owner_id": "string"
}
```

### Document
```json
{
  "id": "string",
  "title": "string",
  "content": "string",
  "type": "markdown|html|text",
  "project_id": "string",
  "created_at": "string (ISO 8601)",
  "updated_at": "string (ISO 8601)"
}
```

### Agent
```json
{
  "id": "string",
  "name": "string",
  "type": "scraper|processor|analyzer",
  "status": "running|stopped|error",
  "config": "object",
  "created_at": "string (ISO 8601)",
  "last_run": "string (ISO 8601)"
}
```

## APIエンドポイント

### プロジェクト管理

#### プロジェクト一覧取得
```http
GET /api/v1/projects
```

**Query Parameters:**
- `page` (integer): ページ番号 (default: 1)
- `limit` (integer): 1ページあたりの件数 (default: 20, max: 100)
- `status` (string): プロジェクトステータスフィルタ
- `search` (string): 検索キーワード

**Response:**
```json
{
  "success": true,
  "data": {
    "projects": [
      {
        "id": "proj_123",
        "name": "AI Development Project",
        "description": "Machine learning project",
        "status": "active",
        "created_at": "2025-06-01T10:00:00Z",
        "updated_at": "2025-06-29T10:00:00Z",
        "owner_id": "user_456"
      }
    ],
    "pagination": {
      "page": 1,
      "limit": 20,
      "total": 50,
      "pages": 3
    }
  }
}
```

#### プロジェクト詳細取得
```http
GET /api/v1/projects/{project_id}
```

**Path Parameters:**
- `project_id` (string): プロジェクトID

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "proj_123",
    "name": "AI Development Project",
    "description": "Machine learning project",
    "status": "active",
    "created_at": "2025-06-01T10:00:00Z",
    "updated_at": "2025-06-29T10:00:00Z",
    "owner_id": "user_456",
    "documents_count": 15,
    "agents_count": 3
  }
}
```

#### プロジェクト作成
```http
POST /api/v1/projects
```

**Request Body:**
```json
{
  "name": "New AI Project",
  "description": "Description of the project",
  "status": "active"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "proj_789",
    "name": "New AI Project",
    "description": "Description of the project",
    "status": "active",
    "created_at": "2025-06-29T10:00:00Z",
    "updated_at": "2025-06-29T10:00:00Z",
    "owner_id": "user_456"
  }
}
```

#### プロジェクト更新
```http
PUT /api/v1/projects/{project_id}
```

**Request Body:**
```json
{
  "name": "Updated Project Name",
  "description": "Updated description",
  "status": "inactive"
}
```

#### プロジェクト削除
```http
DELETE /api/v1/projects/{project_id}
```

### ドキュメント管理

#### ドキュメント一覧取得
```http
GET /api/v1/projects/{project_id}/documents
```

#### ドキュメント詳細取得
```http
GET /api/v1/documents/{document_id}
```

#### ドキュメント作成
```http
POST /api/v1/projects/{project_id}/documents
```

**Request Body:**
```json
{
  "title": "API Documentation",
  "content": "# API Documentation\n\nThis is the content...",
  "type": "markdown"
}
```

#### ドキュメント更新
```http
PUT /api/v1/documents/{document_id}
```

#### ドキュメント削除
```http
DELETE /api/v1/documents/{document_id}
```

### エージェント管理

#### エージェント一覧取得
```http
GET /api/v1/agents
```

#### エージェント詳細取得
```http
GET /api/v1/agents/{agent_id}
```

#### エージェント作成
```http
POST /api/v1/agents
```

**Request Body:**
```json
{
  "name": "Web Scraper Agent",
  "type": "scraper",
  "config": {
    "target_urls": ["https://example.com"],
    "interval": 3600,
    "timeout": 30
  }
}
```

#### エージェント実行
```http
POST /api/v1/agents/{agent_id}/run
```

#### エージェント停止
```http
POST /api/v1/agents/{agent_id}/stop
```

### データ処理

#### RAG検索
```http
POST /api/v1/search/rag
```

**Request Body:**
```json
{
  "query": "How to implement machine learning?",
  "limit": 10,
  "threshold": 0.7
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "results": [
      {
        "document_id": "doc_123",
        "title": "ML Implementation Guide",
        "content": "Machine learning implementation...",
        "score": 0.95,
        "metadata": {
          "project_id": "proj_123",
          "created_at": "2025-06-01T10:00:00Z"
        }
      }
    ],
    "query_time": 0.15
  }
}
```

#### エンベディング生成
```http
POST /api/v1/embeddings
```

**Request Body:**
```json
{
  "text": "Text to generate embeddings for",
  "model": "text-embedding-ada-002"
}
```

### システム情報

#### ヘルスチェック
```http
GET /api/v1/health
```

**Response:**
```json
{
  "success": true,
  "data": {
    "status": "healthy",
    "timestamp": "2025-06-29T10:00:00Z",
    "services": {
      "database": "healthy",
      "vector_db": "healthy",
      "cache": "healthy"
    }
  }
}
```

#### システム統計
```http
GET /api/v1/stats
```

**Response:**
```json
{
  "success": true,
  "data": {
    "projects_count": 25,
    "documents_count": 1250,
    "agents_count": 15,
    "active_agents": 8,
    "storage_usage": {
      "total_gb": 100,
      "used_gb": 35,
      "usage_percent": 35
    }
  }
}
```

## エラーコード

### 4xx クライアントエラー
- `400 Bad Request`: 不正なリクエスト
- `401 Unauthorized`: 認証が必要
- `403 Forbidden`: アクセス権限なし
- `404 Not Found`: リソースが見つからない
- `409 Conflict`: リソースの競合
- `422 Unprocessable Entity`: バリデーションエラー
- `429 Too Many Requests`: レート制限超過

### 5xx サーバーエラー
- `500 Internal Server Error`: サーバー内部エラー
- `502 Bad Gateway`: 上流サーバーエラー
- `503 Service Unavailable`: サービス利用不可
- `504 Gateway Timeout`: タイムアウト

## レート制限

### 制限値
- **認証済みユーザー**: 1000 requests/hour
- **未認証ユーザー**: 100 requests/hour
- **管理者**: 無制限

### ヘッダー
```http
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1640995200
```

## WebSocket API

### リアルタイム通知
```javascript
// 接続
const ws = new WebSocket('wss://api.happyquest.ai/ws');

// 認証
ws.send(JSON.stringify({
  type: 'auth',
  token: 'jwt_token_here'
}));

// メッセージ受信
ws.onmessage = (event) => {
  const data = JSON.parse(event.data);
  console.log(data);
};
```

### 通知タイプ
- `agent_status_changed`: エージェントステータス変更
- `document_updated`: ドキュメント更新
- `project_activity`: プロジェクト活動

## SDK・クライアントライブラリ

### JavaScript/TypeScript
```bash
npm install @happyquest/api-client
```

```javascript
import { HappyQuestClient } from '@happyquest/api-client';

const client = new HappyQuestClient({
  baseURL: 'https://api.happyquest.ai/api/v1',
  token: 'your_jwt_token'
});

const projects = await client.projects.list();
```

### Python
```bash
pip install happyquest-client
```

```python
from happyquest import HappyQuestClient

client = HappyQuestClient(
    base_url='https://api.happyquest.ai/api/v1',
    token='your_jwt_token'
)

projects = client.projects.list()
```

## 変更履歴

### v1.0.0 (2025-06-29)
- 初回リリース
- 基本CRUD操作実装
- 認証・認可機能実装

### 今後の予定
- **v1.1.0**: GraphQL API対応
- **v1.2.0**: 大容量ファイルアップロード対応
- **v2.0.0**: マルチテナント対応