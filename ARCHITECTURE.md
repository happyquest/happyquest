# システムアーキテクチャ

## 概要
HappyQuestシステムの包括的なアーキテクチャ設計書

## 目的と対象読者
- **目的**: システム設計の全体像と技術選択根拠の明確化
- **対象読者**: 開発エンジニア、アーキテクト、運用チーム

## 最終更新日
2025-06-29

## 更新者
HappyQuest開発チーム

## 関連文書
- [SRS.md](./SRS.md)
- [TEST_POLICY.md](./TEST_POLICY.md)
- [API_SPEC.md](./API_SPEC.md)

## システム概要

### 高レベルアーキテクチャ

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   Web Frontend  │    │   API Gateway   │    │  Backend Services│
│   (React/Next)  │◄──►│    (Express)    │◄──►│   (Python/Node)  │
└─────────────────┘    └─────────────────┘    └─────────────────┘
         │                       │                       │
         ▼                       ▼                       ▼
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   MCP Tools     │    │   GitHub API    │    │   Vector DB     │
│  (Browser/Git)  │    │   Integration   │    │   (ChromaDB)    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

## レイヤー構成

### 1. プレゼンテーション層
- **Web UI**: React/Next.js ベースダッシュボード
- **CLI Interface**: Python Click ベースCLI
- **API Endpoints**: RESTful API

### 2. アプリケーション層
- **Business Logic**: ドメインロジック実装
- **Workflow Engine**: マルチエージェント協調
- **Task Queue**: 非同期処理管理

### 3. インフラストラクチャ層
- **Data Access**: ORM/ODM を使用したデータアクセス
- **External APIs**: GitHub, Docker Registry連携
- **MCP Integration**: Browser/Git/Database MCP

### 4. データ層
- **Primary DB**: PostgreSQL (構造化データ)
- **Vector DB**: ChromaDB (埋め込みベクトル)
- **Cache**: Redis (セッション・キャッシュ)

## コンポーネント設計

### データ収集・スクレイピングモジュール
```python
class DataCollector:
    - scrape_repositories()
    - extract_documentation()
    - parse_doxygen_docs()
    - validate_data_quality()
```

### RAG・コーパス処理モジュール
```python
class CorpusProcessor:
    - clean_text_data()
    - generate_embeddings()
    - create_vector_index()
    - similarity_search()
```

### マルチエージェントエンジン
```python
class AgentOrchestrator:
    - deploy_agents()
    - coordinate_tasks()
    - aggregate_results()
    - monitor_performance()
```

## 技術スタック

### バックエンド
- **言語**: Python 3.12.9, Node.js 23.8.0
- **フレームワーク**: FastAPI, Express.js
- **ORM**: SQLAlchemy, Prisma
- **AI/ML**: LangChain, OpenAI API, Transformers

### フロントエンド
- **フレームワーク**: React 18, Next.js 14
- **State Management**: Zustand/Redux Toolkit
- **UI Libraries**: Tailwind CSS, shadcn/ui
- **Testing**: Jest, React Testing Library

### インフラストラクチャ
- **コンテナ**: Docker, Docker Compose
- **CI/CD**: GitHub Actions
- **IaC**: Terraform (Google Cloud)
- **監視**: Prometheus, Grafana

### データベース
- **Primary**: PostgreSQL 15
- **Vector**: ChromaDB
- **Cache**: Redis 7
- **Search**: Elasticsearch (オプション)

## セキュリティアーキテクチャ

### 認証・認可
- **認証**: OAuth 2.0, JWT
- **認可**: RBAC (Role-Based Access Control)
- **API Security**: Rate Limiting, CORS

### データ保護
- **暗号化**: AES-256 (保存時), TLS 1.3 (転送時)
- **秘密管理**: HashiCorp Vault
- **監査**: アクセスログ記録・分析

## 可用性・スケーラビリティ

### 可用性設計
- **冗長化**: Multi-AZ配置
- **ヘルスチェック**: Kubernetes Liveness/Readiness
- **バックアップ**: 日次・週次・月次バックアップ

### スケーラビリティ設計
- **水平スケーリング**: Kubernetes HPA
- **負荷分散**: NGINX Ingress Controller
- **データ分散**: Database Sharding (将来対応)

## デプロイメント戦略

### 環境構成
```
┌─────────────┐    ┌─────────────┐    ┌─────────────┐
│ Development │    │   Staging   │    │ Production  │
│   (Local)   │───►│  (GCP/k8s)  │───►│  (GCP/k8s)  │
└─────────────┘    └─────────────┘    └─────────────┘
```

### CI/CDパイプライン
1. **Code Push** → GitHub Repository
2. **Build & Test** → GitHub Actions
3. **Security Scan** → SAST/DAST実行
4. **Deploy Staging** → 自動デプロイ
5. **E2E Test** → Playwright自動テスト
6. **Deploy Production** → 承認後デプロイ

## 監視・運用

### メトリクス収集
- **アプリケーション**: カスタムメトリクス
- **インフラ**: CPU, Memory, Network, Disk
- **ビジネス**: ユーザー行動、処理件数

### ログ管理
- **構造化ログ**: JSON形式
- **ログ集約**: Fluentd → Elasticsearch
- **検索・分析**: Kibana Dashboard

### アラート
- **閾値監視**: Prometheus AlertManager
- **通知**: Slack, Email
- **エスカレーション**: PagerDuty (本格運用時)

## データフロー

### 1. データ収集フロー
```
GitHub Repos → Scraper → Raw Data → Validator → Cleaned Data
```

### 2. RAG処理フロー
```
Text Data → Tokenizer → Embedder → Vector Store → Search Index
```

### 3. エージェント協調フロー
```
Task Queue → Agent Pool → Execution → Result Aggregation → Output
```

## 制約・前提条件

### 技術制約
- Ubuntu 24.04 WSL2環境
- Docker CE使用必須
- MCP Server依存関係

### 運用制約
- GitHub PR-based開発
- TDD準拠必須
- セキュリティ要件準拠

### スケール制約
- 初期: 50同時ユーザー
- データ: 1TB以内
- 処理: 1000件/分

## 今後の拡張計画

### Phase 1 (Q2 2025)
- 基本機能実装
- MCP統合完了
- CI/CD確立

### Phase 2 (Q3 2025)
- 高度なAI機能
- 性能最適化
- セキュリティ強化

### Phase 3 (Q4 2025)
- 大規模データ対応
- 多言語サポート
- Enterprise機能