# 📁 HappyQuest ファイル管理ルール

**作成日**: 2025年6月8日  
**目的**: ファイル管理の標準化とゴミファイル防止  
**対象**: プロジェクト全体のファイル作成・保存・削除

---

## 🚨 **発見された問題**

### **不要ファイル蓄積状況**
```
❌ 問題のあるファイル（削除対象）:
├── unsloth_finetuning_guide.html (20KB) - AI学習関連（本プロジェクト外）
├── playwright_mcp_article.html (367KB) - 巨大HTMLファイル
├── mcp-playwright-readme.html (293KB) - 巨大ドキュメント
├── brave_search_playwright_mcp.json (33KB) - 検索結果一時ファイル
├── brave_search_mcp_encoded.json (66KB) - 検索結果一時ファイル
├── LangChainエコシステムによるマルチエージェント構築ガイド (37KB) - 外部参考資料
├── Google Cloud Astroサイト構築 (45KB) - 外部参考資料
├── gemini_agent_v2.py (14KB) - 実験コード
├── gemini_agent.py (14KB) - 実験コード
├── simple_agent.py (8.8KB) - 実験コード
├── agent_log.txt (4.1KB) - ログファイル
├── ubuntu2204setup.sh (7.0KB) - 旧バージョン（Ubuntu22.04）
├── capabilities_and_limitations.md (7.1KB) - 一時的分析ファイル
└── TROUBLE_CASES_20250606.md (5.9KB) - 過去のトラブル記録

🎯 削除により削減容量: 約1.2MB
```

### **今日作成の必要ファイル（保持）**
```
✅ 保持対象ファイル:
├── github-cicd-implementation.md - CI/CD実装計画
├── mcp-configuration-fix.md - MCP設定修正記録
├── docker-mcp-startup.sh - Docker MCP起動スクリプト
├── Dockerfile.github-mcp - GitHub MCP用Docker設定
├── PROJECT_RULES.md - プロジェクトルール
└── file-management-rules.md - ファイル管理ルール（新規）
```

---

## 📋 **ファイル管理ルール策定**

### **Rule 1: ディレクトリ構造原則**

#### **🎯 標準ディレクトリ構造**
```
happyquest/
├── docs/                    # 📚 プロジェクトドキュメント
│   ├── guides/             # 操作ガイド・マニュアル
│   ├── architecture/       # 設計・アーキテクチャ文書
│   └── api/               # API仕様書
├── infrastructure/         # 🔧 インフラ設定
│   ├── ansible/           # 環境構築自動化
│   ├── packer/            # イメージビルド
│   └── docker/            # Docker設定
├── scripts/               # 🔨 実行スクリプト
│   ├── setup/             # セットアップスクリプト
│   ├── deploy/            # デプロイスクリプト
│   └── utils/             # ユーティリティ
├── src/                   # 💻 ソースコード
│   ├── agents/            # AIエージェント
│   ├── tools/             # ツール類
│   └── config/            # 設定ファイル
├── tests/                 # 🧪 テストファイル
├── .github/               # 🔄 GitHub設定
├── .cursor/               # 🎯 Cursor設定
└── 作業報告書/            # 📋 作業記録（日本語）
```

#### **❌ 禁止場所**
- **ルート直下**に一時ファイル作成禁止
- **.gitignore外**での巨大ファイル作成禁止
- **目的不明**なディレクトリ作成禁止

### **Rule 2: ファイル作成基準**

#### **✅ 作成許可条件**
1. **明確な目的**: 何に使用するか明記
2. **適切な配置**: 正しいディレクトリに配置
3. **ライフサイクル**: 保存期間・削除条件明確化
4. **命名規則**: 目的が分かるファイル名

#### **🔍 作成時チェックリスト**
- [ ] プロジェクト目標に合致するか？
- [ ] 既存ファイルで代替できないか？
- [ ] 適切なディレクトリに配置するか？
- [ ] ファイル名は目的を表しているか？
- [ ] 削除条件が明確か？

### **Rule 3: ファイル命名規則**

#### **📝 命名パターン**
```bash
# 設計ドキュメント
{category}-{purpose}-{version}.md
例: mcp-configuration-guide-v1.md

# スクリプトファイル
{action}-{target}-{env}.sh
例: setup-docker-ubuntu24.sh

# 設定ファイル
{service}-{env}-config.{ext}
例: ansible-production-config.yml

# 作業報告
WORK_REPORT_{YYYYMMDD}_{purpose}.md
例: WORK_REPORT_20250608_mcp-optimization.md

# 一時ファイル（temp/ディレクトリ内のみ）
tmp-{purpose}-{timestamp}.{ext}
例: tmp-analysis-20250608143000.json
```

### **Rule 4: 削除ルール**

#### **🗑️ 自動削除対象**
1. **一時ファイル**: 7日経過後
2. **ログファイル**: 30日経過後  
3. **実験コード**: プルリクエストマージ後
4. **外部参考資料**: プロジェクト完了後

#### **⚠️ 削除前確認事項**
- [ ] 他のファイルから参照されていないか？
- [ ] バックアップが必要か？
- [ ] 削除理由をコミットログに記録したか？

### **Rule 5: 参照ファイル管理**

#### **📚 docs/references/ 運用**
```
docs/references/
├── external/              # 外部リソース参照
│   ├── links.md          # URL集
│   └── specifications/   # 仕様書
├── internal/             # 内部参照
│   ├── decisions.md      # 設計判断記録
│   └── lessons-learned.md # 学習記録
└── archive/              # アーカイブ
    └── {YYYY-MM}/        # 月別アーカイブ
```

---

## 🧹 **今回の削除実行計画**

### **Phase 1: 巨大不要ファイル削除**
```bash
# HTMLファイル（850KB削減）
rm -f unsloth_finetuning_guide.html
rm -f playwright_mcp_article.html
rm -f mcp-playwright-readme.html

# 検索結果一時ファイル（99KB削減）
rm -f brave_search_playwright_mcp.json
rm -f brave_search_mcp_encoded.json
```

### **Phase 2: 外部参考資料整理**
```bash
# 参考資料をアーカイブへ移動
mkdir -p アーカイブ/参考資料/
mv "LangChainエコシステムによるマルチエージェント構築ガイド" アーカイブ/参考資料/
mv "Google Cloud Astroサイト構築" アーカイブ/参考資料/
```

### **Phase 3: 実験コード整理**
```bash
# 実験コードをアーカイブへ移動
mkdir -p アーカイブ/実験コード/
mv gemini_agent_v2.py アーカイブ/実験コード/
mv gemini_agent.py アーカイブ/実験コード/
mv simple_agent.py アーカイブ/実験コード/
mv agent_log.txt アーカイブ/実験コード/
```

### **Phase 4: 旧設定ファイル削除**
```bash
# Ubuntu22.04用設定（24.04で置き換え済み）
rm -f ubuntu2204setup.sh

# 一時分析ファイル
rm -f capabilities_and_limitations.md
```

---

## 📊 **削除効果予測**

| カテゴリ | ファイル数 | 削減容量 | 効果 |
|----------|-----------|----------|------|
| **巨大HTMLファイル** | 3個 | 850KB | ✅ 大幅軽量化 |
| **検索結果一時ファイル** | 2個 | 99KB | ✅ 不要データ除去 |
| **外部参考資料** | 2個 | 82KB | ✅ アーカイブ移動 |
| **実験コード** | 4個 | 45KB | ✅ アーカイブ移動 |
| **旧設定・分析ファイル** | 2個 | 14KB | ✅ 冗長削除 |

**総削減効果: 13ファイル、約1.1MB削減**

---

## 🎯 **PROJECT_RULES.md統合内容**

```markdown
## 📁 ファイル管理原則

### ファイル作成時の必須確認事項
1. プロジェクト目標への貢献度確認
2. 適切なディレクトリ配置
3. 明確な命名規則適用
4. 削除条件の明確化

### 禁止事項
- ルート直下への一時ファイル作成
- 目的不明なファイル・ディレクトリ作成
- 1MB超の参考資料ファイル保存（docs/references/external/へ）
- AI実験コードの恒久保存（アーカイブ移動必須）

### 定期メンテナンス
- 月1回の不要ファイル確認
- 四半期1回のアーカイブ整理
- リリース前の全体ファイル監査
```

**適用効果: ファイル数50%削減、容量30%削減予想** 