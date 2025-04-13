# MCPサーバー用Dockerfile
FROM node:18-slim

# 作業ディレクトリの設定
WORKDIR /app

# 必要なパッケージのインストール
RUN apt-get update && apt-get install -y \
    git \
    && rm -rf /var/lib/apt/lists/*

# 依存関係のインストール
COPY package*.json ./
RUN npm install

# MCPサーバー関連のパッケージをインストール
RUN npm install -g \
    @modelcontextprotocol/server-filesystem \
    @modelcontextprotocol/server-github \
    @modelcontextprotocol/server-sequential-thinking

# アプリケーションのコピー
COPY . .

# .cursor ディレクトリの作成とmcp.jsonのコピー
RUN mkdir -p .cursor
COPY .cursor/mcp.json .cursor/

# 環境変数の設定
ENV NODE_ENV=production

# ポート設定（必要に応じて）
EXPOSE 3000

# 起動コマンド
CMD ["npm", "start"] 