# MCPサーバー

このディレクトリには、VeyraX-MCPサーバーのDocker環境が含まれています。

## 前提条件

- Docker
- Docker Compose
- Git

## セットアップ手順

1. 環境変数の設定
   ```bash
   cp .env.example .env
   # .envファイルを編集し、必要な環境変数を設定
   ```

2. Dockerイメージのビルドと起動
   ```bash
   docker-compose up --build
   ```

3. サーバーの確認
   - ブラウザで http://localhost:8000/docs にアクセス
   - APIドキュメントが表示されることを確認

## ディレクトリ構造

```
MCP/
├── Dockerfile          # Dockerイメージの定義
├── docker-compose.yml  # Docker Compose設定
├── requirements.txt    # Python依存パッケージ
├── .env               # 環境変数
├── config/            # 設定ファイル
└── data/              # データファイル
```

## 主な機能

- LangChain/LangGraphとの統合
- RESTful APIエンドポイント
- プロンプト管理
- リソース管理
- ツール呼び出し

## トラブルシューティング

1. ポート競合
   - 8000番ポートが使用中の場合は、.envファイルでMCP_PORTを変更

2. メモリ不足
   - docker-compose.ymlのdeploy.resources.limits.memoryを調整

3. ログの確認
   ```bash
   docker-compose logs -f mcp-server
   ```

## セキュリティ

- APIキーは.envファイルで管理
- 許可されたオリジンはMCP_ALLOWED_ORIGINSで設定
- 本番環境ではMCP_DEBUG=falseに設定 