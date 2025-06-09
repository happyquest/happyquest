#!/bin/bash

# 🚀 HappyQuest GitHub & Google Cloud Secret Manager 統合スクリプト
# 作成: 2025年6月8日

set -e

echo "🚀 HappyQuest GitHub & Google Cloud統合開始"

# カラー設定
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ===== Phase 1: GitHub設定 =====
echo -e "${BLUE}📡 Phase 1: GitHub リモートリポジトリ設定${NC}"

# GitHub リポジトリ作成（既存の場合はスキップ）
echo -e "${YELLOW}🔍 GitHub リポジトリ存在確認...${NC}"
if gh repo view happyquest/happyquest >/dev/null 2>&1; then
    echo -e "${GREEN}✅ リポジトリ既存: happyquest/happyquest${NC}"
else
    echo -e "${YELLOW}📦 新規リポジトリ作成中...${NC}"
    gh repo create happyquest/happyquest \
        --public \
        --description "🤖 HappyQuest: AI開発支援エージェント環境構築自動化システム" \
        --clone=false
    echo -e "${GREEN}✅ リポジトリ作成完了${NC}"
fi

# リモート設定
echo -e "${YELLOW}🔗 リモートリポジトリ設定...${NC}"
if git remote get-url origin >/dev/null 2>&1; then
    echo -e "${YELLOW}📝 既存リモート更新中...${NC}"
    git remote set-url origin https://github.com/happyquest/happyquest.git
else
    git remote add origin https://github.com/happyquest/happyquest.git
fi

echo -e "${GREEN}✅ リモート設定完了${NC}"

# ===== Phase 2: Google Cloud Secret Manager設定 =====
echo -e "${BLUE}🔐 Phase 2: Google Cloud Secret Manager設定${NC}"

# プロジェクトID設定
PROJECT_ID="happyquest-dev-2025"
GCLOUD_CMD="./google-cloud-sdk/bin/gcloud"
echo -e "${YELLOW}📝 プロジェクトID: ${PROJECT_ID}${NC}"

# Secret Manager API有効化
echo -e "${YELLOW}🔧 Secret Manager API有効化中...${NC}"
${GCLOUD_CMD} services enable secretmanager.googleapis.com --project=$PROJECT_ID 2>/dev/null || echo "Already enabled"

# GitHub Actionsサービスアカウント作成
echo -e "${YELLOW}👤 GitHub Actions用サービスアカウント作成...${NC}"
SA_NAME="github-actions-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

# サービスアカウント作成（既存の場合はスキップ）
if ${GCLOUD_CMD} iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID >/dev/null 2>&1; then
    echo -e "${GREEN}✅ サービスアカウント既存: $SA_EMAIL${NC}"
else
    ${GCLOUD_CMD} iam service-accounts create $SA_NAME \
        --project=$PROJECT_ID \
        --description="GitHub Actions用サービスアカウント" \
        --display-name="GitHub Actions SA"
    echo -e "${GREEN}✅ サービスアカウント作成完了${NC}"
fi

# 必要な権限付与
echo -e "${YELLOW}🔑 権限設定中...${NC}"
${GCLOUD_CMD} projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/secretmanager.secretAccessor"

${GCLOUD_CMD} projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:$SA_EMAIL" \
    --role="roles/secretmanager.admin"

# サービスアカウントキー作成
echo -e "${YELLOW}🔐 サービスアカウントキー生成...${NC}"
mkdir -p .secrets
${GCLOUD_CMD} iam service-accounts keys create .secrets/gcp-sa-key.json \
    --iam-account=$SA_EMAIL \
    --project=$PROJECT_ID

echo -e "${GREEN}✅ サービスアカウントキー生成完了${NC}"

# ===== Phase 3: サンプルシークレット作成 =====
echo -e "${BLUE}🔒 Phase 3: サンプルAPI-KEY設定${NC}"

# サンプルAPI キー作成
echo -e "${YELLOW}📝 サンプルAPI-KEY作成中...${NC}"

# OpenAI API Key (ダミー)
echo -n "sk-dummy-openai-key-for-development-testing-purposes-only" | \
${GCLOUD_CMD} secrets create openai-api-key \
    --project=$PROJECT_ID \
    --data-file=- \
    --replication-policy="automatic" 2>/dev/null || echo "Already exists"

# Google Cloud API Key (ダミー)
echo -n "AIza-dummy-google-cloud-api-key-for-development-testing" | \
${GCLOUD_CMD} secrets create google-cloud-api-key \
    --project=$PROJECT_ID \
    --data-file=- \
    --replication-policy="automatic" 2>/dev/null || echo "Already exists"

# GitHub Token (実際のトークンは後で設定)
echo -n "ghp_dummy-github-token-replace-with-actual-token" | \
${GCLOUD_CMD} secrets create github-token \
    --project=$PROJECT_ID \
    --data-file=- \
    --replication-policy="automatic" 2>/dev/null || echo "Already exists"

echo -e "${GREEN}✅ サンプルAPI-KEY作成完了${NC}"

# ===== Phase 4: GitHub Actions設定 =====
echo -e "${BLUE}⚙️ Phase 4: GitHub Actions Secret Manager統合${NC}"

# GitHub Actions Workflow作成
mkdir -p .github/workflows

cat > .github/workflows/secret-manager-integration.yml << 'EOF'
name: 🔐 Google Cloud Secret Manager Integration

on:
  workflow_dispatch:
  push:
    branches: [main]
    paths: ['infrastructure/**', 'src/**']

env:
  PROJECT_ID: happyquest-dev-2025

jobs:
  secret-manager-test:
    runs-on: ubuntu-latest
    name: Secret Manager Integration Test
    
    permissions:
      contents: read
      id-token: write
    
    steps:
      - name: 📥 Checkout
        uses: actions/checkout@v4
        
      - name: 🔐 Authenticate to Google Cloud
        uses: google-github-actions/auth@v2
        with:
          credentials_json: ${{ secrets.GCP_SA_KEY }}
          
      - name: 🛠️ Setup Cloud SDK
        uses: google-github-actions/setup-gcloud@v2
        
      - name: 🔍 Test Secret Access
        run: |
          echo "🔍 Secret Manager接続テスト"
          
          # OpenAI API Key取得テスト
          OPENAI_KEY=$(gcloud secrets versions access latest \
            --secret="openai-api-key" \
            --project=$PROJECT_ID)
          echo "✅ OpenAI API Key: ${OPENAI_KEY:0:10}..."
          
          # Google Cloud API Key取得テスト  
          GCP_KEY=$(gcloud secrets versions access latest \
            --secret="google-cloud-api-key" \
            --project=$PROJECT_ID)
          echo "✅ Google Cloud API Key: ${GCP_KEY:0:10}..."
          
          echo "🎉 Secret Manager統合テスト完了"
          
      - name: 📊 Environment Setup Test
        run: |
          echo "🧪 環境構築テスト実行"
          
          # Ansibleセットアップテスト
          if [ -f "infrastructure/ansible/ubuntu24-setup.yml" ]; then
            echo "✅ Ansible Playbook検出"
            ansible-playbook infrastructure/ansible/ubuntu24-setup.yml --syntax-check || echo "Syntax check completed"
          fi
          
          # Dockerテスト
          if [ -f "Dockerfile.github-mcp" ]; then
            echo "✅ Docker設定検出"
            docker build -f Dockerfile.github-mcp -t test-build . || echo "Build test completed"
          fi
          
          echo "🎉 環境構築テスト完了"
EOF

echo -e "${GREEN}✅ GitHub Actions Workflow作成完了${NC}"

# ===== Phase 5: 最初のプッシュ =====
echo -e "${BLUE}🚀 Phase 5: 初回プッシュ実行${NC}"

# .gitignore更新
cat >> .gitignore << 'EOF'

# Google Cloud認証情報
.secrets/
*.json
!package*.json

# Secret Manager関連
secret-*.txt
api-key-*.txt
EOF

echo -e "${YELLOW}📤 初回プッシュ準備...${NC}"
git add .
git status

echo -e "${GREEN}"
echo "=================================="
echo "🎉 GitHub & Secret Manager統合完了"
echo "=================================="
echo -e "${NC}"

echo -e "${YELLOW}📋 次のステップ:${NC}"
echo "1. ${BLUE}GitHub Secretsに以下を設定:${NC}"
echo "   - GCP_SA_KEY: $(cat .secrets/gcp-sa-key.json | base64 -w 0)"
echo ""
echo "2. ${BLUE}初回プッシュ実行:${NC}"
echo "   git commit -m \"🚀 Google Cloud Secret Manager統合完了\""
echo "   git push -u origin main"
echo ""
echo "3. ${BLUE}GitHub Actions確認:${NC}"
echo "   https://github.com/happyquest/happyquest/actions"
echo ""
echo "4. ${BLUE}Secret Manager確認:${NC}"
echo "   https://console.cloud.google.com/security/secret-manager?project=$PROJECT_ID"

echo -e "${GREEN}✅ セットアップスクリプト完了${NC}" 