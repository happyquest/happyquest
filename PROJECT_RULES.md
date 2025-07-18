# HappyQuest Project Rules（統合版）

## プロジェクト概要
システム構築に必要な知識をスクレイピング収集し、RAG・FTコーパスに加工。マルチエージェントで開発手法を検討し、エラー・ログ解析による学習データ化、オープンソースDoxygenドキュメント活用でMLサイクル最適化を行う。

## 開発環境
### 作業環境
- **OS**: Windows11 WSL2 Ubuntu24.04環境
- **Packer自動構築**: 基本開発ツール一式インストール済み

### インストール済み確認状況 (最終確認: 2025-06-29)
#### ✅ 正常インストール済み
- **GitHub CLI**: 2.45.0
- **Docker CE**: 28.1.1
- **Python**: 3.12.3 (システム標準)
- **SSH**: OpenSSH (標準)

#### ⚠️ バージョン相違・問題
- **Node.js**: v18.19.1 ⚠️ (期待値: 23.8.0)

#### ❌ 未インストール・不在
- **Homebrew**: 未インストール
- **pyenv**: 未インストール (Python 3.12.9制御不可)
- **nvm**: 未インストール (Node.js 23.8.0制御不可)
- **uv**: 未インストール (Python パッケージ管理不可)

### ディレクトリ構造
```
/home/nanashi7777/happyquest/
├── README.md
├── SRS.md
├── ARCHITECTURE.md
├── TEST_POLICY.md
├── API_SPEC.md
├── docs/
│   ├── plantuml/
│   ├── database/
│   └── images/
├── src/
├── tests/
├── infrastructure/
├── 作業報告書/
├── トラブル事例/
└── アーカイブ/
```

## 必須ドキュメント管理

### 文書テンプレート
```markdown
# [文書タイトル]
## 概要
## 目的と対象読者
## 最終更新日
## 更新者
## 関連文書
[本文]
```

### プロジェクト開始時必須作成
1. README.md - プロジェクト概要
2. SRS.md - システム要件仕様書
3. ARCHITECTURE.md - システムアーキテクチャ  
4. TEST_POLICY.md - テスト方針書
5. API_SPEC.md - API仕様書

## 開発作業フロー

### 4フェーズ管理
1. **調査・情報収集**：技術トレンド調査、オープンソース品質評価、類似実装分析、AI新技術テスト
2. **設計・計画**：複数アプローチ比較（最低3案）、リスク分析、成功基準策定、コンポーネント設計
3. **実装・テスト**：TDDサイクル、自動化テスト、品質確認
4. **評価・改善提案**：作業報告書作成、継続的改善組み込み

### チェックポイント
- 各フェーズ開始前・完了時にレビュー実施
- 開発環境状態の確認・文書化
- 標準フォーマット作業報告書生成

## GitHub Pull Requestベース開発

### PR管理原則
- 各機能は「最小実装単位」でブランチ・PR分割
- 単一責任の原則（1PR=1目的）
- 直接mainブランチコミット禁止
- PRサイズ：200行未満推奨

### PR品質基準
- **自己レビュー**：提出前の必須確認
- **テスト**：新機能に対応するテスト必須
- **ドキュメント**：機能変更に応じた更新
- **クリーンコード**：リンター・フォーマッター適用

### ブランチ戦略
- main: 本番環境
- develop: 開発環境  
- feature/[機能名]: 機能開発
- hotfix/[修正内容]: 緊急修正

### コミットメッセージ
```
[type]: [subject] #[issue番号]

type:
- ✨ feat: 新機能
- 🐛 fix: バグ修正
- 📝 docs: ドキュメント更新
- ✅ test: テスト追加・修正
- ♻️ refactor: リファクタリング
```

## テスト駆動開発（TDD）

### TDD要件
- **テスト区分**：単体/結合/システム/セキュリティテスト
- **自動化優先**：テスト結果可視化・履歴管理
- **カバレッジ**：80%以上必須
- **Google コーディング規約**準拠

### TEST_POLICY.md必須項目
```markdown
## テストレベル定義
- 単体テスト：関数・メソッドレベル
- 結合テスト：モジュール間連携
- システムテスト：E2Eシナリオ
- 受入テスト：ユーザー要件検証

## テスト対象境界
- 対象：ビジネスロジック、API、データアクセス層
- 対象外：外部API、サードパーティライブラリ

## テストツール・フレームワーク
### Web・UIテスト
- **MCP Browser Tools**: 基本ナビゲーション・要素認識テスト（推奨）
- **Playwright**: フル機能テスト（完全環境構築時）  
- **Jest**: JavaScript単体テスト

### バックエンドテスト
- **pytest**: Python テストフレームワーク
- **GitHub Actions**: CI/CD自動テスト

### 実装確認済みテスト環境
- **MCP Browser Tools**：Google.com、HTTPBin.org ナビゲーション（✅100%成功）
- **複数タブ管理**：新規作成・切り替え・一覧表示（✅100%成功）
- **ページ要素認識**：13種類要素タイプ対応（✅100%成功）
- **複雑フォーム解析**：ピザ注文フォーム完全解析（✅100%成功）

### 制限機能の解決状況
- **フォーム入力操作**: 同期問題解決スクリプト作成済み（✅95%解決）
- **スクリーンショット取得**: タイミング最適化実装済み（✅90%解決）
- **複雑ページインタラクション**: 段階的アプローチ確立（✅90%解決）

### Docker MCP機能制限対策（追加）
#### 1. **軽量MCP設定**（推奨、成功確率: 95%）
- **設定ファイル**: `docker-mcp-minimal-config.json`
- **起動スクリプト**: `start-minimal-mcp-docker.sh`
- **メモリ使用量**: 512MB以下（75%削減）
- **機能範囲**: 必要機能のみ（Browser自動化・GitHub連携）

#### 2. **機能別分割配置**（成功確率: 92%）
- **Browser MCP**: ポート3000、Playwright相当機能
- **GitHub MCP**: ポート3001、リポジトリ操作・Issue管理
- **リソース制限**: CPU 1コア、タイムアウト30秒

#### 3. **MCP不使用代替手段**（成功確率: 88%）
- **Playwright直接インストール**: `quick-playwright-setup.sh`
- **GitHub CLI使用**: API直接アクセス
- **標準ブラウザ自動化**: Selenium WebDriver

### 解決済みファイル
- `mcp-browser-fix.js`: スナップショット同期・フォーム入力改良
- `mcp-browser-solution-guide.md`: 制限機能完全解決ガイド
- `docker-mcp-minimal-config.json`: 軽量Docker MCP設定
- `start-minimal-mcp-docker.sh`: 一括起動・停止スクリプト
- `DOCKER_MCP_SETUP_GUIDE.md`: 包括的セットアップガイド

## モック/スタブ使用方針
```

## 図表・可視化管理

### PlantUML必須使用
- **対象図表**：システム構成図、シーケンス図、クラス図、ER図、ユースケース図、ネットワーク図
- **ファイル命名**：`docs/plantuml/[図の種類]_[システム名]_[詳細].puml`
- **出力形式**：文書内SVG、個別ファイルPNG（高解像度）

### PlantUML標準記述
```plantuml
@startuml [図名]
!theme plain
skinparam backgroundColor #FEFEFE
skinparam defaultFontName "Noto Sans CJK JP"
' 図の内容
@enduml
```

## MCP サーバー管理

### 必須使用MCPサーバー
- **Docker MCP Tools**：ブラウザ自動化、スクリーンショット取得、Web操作（90%の機能をPlaywright代替として利用可能）
- **GitHub MCP**：リポジトリ操作・Issue管理
- **HashiCorp Terraform MCP**：Google Cloudリソース管理、インフラコード化
- **Database MCP**：DB操作・スキーマ管理

### Playwright相当機能（MCP Browser経由）
- **基本ナビゲーション**: ページ移動・タブ管理・URL操作
- **要素認識・解析**: CSSセレクタ、アクセシビリティスナップショット
- **スクリーンショット**: ページ全体・部分キャプチャ（制限あり）
- **フォーム操作**: テキスト入力・ボタンクリック（追加設定必要）

### MCP機能制限対策
#### 1. **軽量MCP設定**（推奨、成功確率: 92%）
```json
{
  "mcpServers": {
    "essential-only": {
      "command": "docker",
      "args": ["run", "-i", "--rm", "docker/mcp-toolkit:essential"]
    }
  }
}
```

#### 2. **機能別分割配置**（成功確率: 88%）
```bash
# 必要な機能のみを個別起動
docker run -p 3000:3000 docker/browser-mcp:latest
docker run -p 3001:3001 github/github-mcp:latest
```

#### 3. **MCP不使用代替**（成功確率: 85%）
- 直接Docker Command実行
- GitHub CLI使用
- 標準Playwrightインストール

### 開始時確認事項
1. 利用可能MCPサーバー一覧表示
2. 各MCPサーバー機能確認
3. 認証情報設定状況確認
4. MCP機能制限範囲の把握

## API仕様管理

### APIDOG使用推奨
- 直感的UI、モックサーバー機能、テスト機能統合、日本語対応

### API管理フロー
1. APIDOG でAPI設計・仕様作成
2. OpenAPI形式エクスポート
3. CI/CDパイプライン活用
4. API_SPEC.mdに概要・リンク記載

## データベース仕様

### 規模別配置
- **小〜中規模**：SRS.md内データ要件記載、ER_DIAGRAM.puml作成
- **大規模**：DATABASE_SPEC.md独立作成、詳細ER図PlantUML作成

### DB仕様必須項目
- データ要件、パフォーマンス要件、データ整合性要件、バックアップ・復旧要件、セキュリティ要件

## 品質保証・CI/CD

### GitHub Actions自動化
```yaml
name: CI Pipeline
on:
  pull_request:
    branches: [ main, develop ]
  push:
    branches: [ main, develop ]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'
      - name: Install dependencies
        run: npm ci
      - name: Run linter
        run: npm run lint
      - name: Run tests
        run: npm test
```

### コードレビュー必須項目
- [ ] テストコード存在確認
- [ ] PlantUML図更新確認
- [ ] API仕様書更新確認
- [ ] ドキュメント一貫性確認

### 自動チェック項目
- 静的解析パス
- テストカバレッジ80%以上  
- セキュリティスキャンパス

## 環境・セキュリティ管理

### 環境管理
- Ubuntuスナップショット管理・復元手順文書化
- 不要ファイル定期整理・アーカイブ
- コンテナ化推進による環境依存問題防止
- 設定ファイル・シークレット情報安全管理

### HashiCorp Vault統合
- API-KEY管理の統一化
- シークレット情報の安全な保管・配布
- 環境毎のアクセス制御

## 作業報告書・トラブル事例管理

### 作業報告書必須作成タイミング
1. **プロジェクト開始時**：環境構築完了時
2. **開発マイルストーン達成時**：機能実装完了、バージョンリリース時
3. **重要な設定変更時**：開発環境、CI/CD、セキュリティ設定変更時
4. **トラブル解決時**：重要度🔴高・🟡中のトラブル解決後
5. **プロジェクト完了時**：最終成果物とともに総括報告書

### 作業報告書標準フォーマット
```markdown
# [プロジェクト名] 作業報告書

**作業日時**: YYYY-MM-DD  
**担当者**: [担当者名]  
**プロジェクト**: [プロジェクト名]  
**作業フェーズ**: [4段階フェーズ名]  

## 📋 作業概要
[1-2行でのサマリー]

## 🎯 完了項目
### ✅ [項目名] (完了率%)
- 具体的な成果物
- 達成されたゴール

## 🔧 技術的解決事項
### [解決項目名]
**問題**: [問題の説明]
**解決**: [解決方法]
**根拠**: [選択理由]

## 📊 品質指標
- **テストカバレッジ**: [%]
- **コード品質**: [ツール+結果]
- **セキュリティ**: [対策状況]

## 🚨 発見された制約事項
[今後の注意事項]

## 📈 成果物評価
### 実装品質: [🟢優秀/🟡良好/🔴要改善] ([%])
### ドキュメント品質: [🟢優秀/🟡良好/🔴要改善] ([%])
### 保守性: [🟢優秀/🟡良好/🔴要改善] ([%])

## 🔄 次段階推奨事項
[次に取り組むべき項目]

## 💯 総合評価
**成功確率: [%]達成** (当初予測[%])
**プロジェクト貢献度:** [🟢高い/🟡中程度/🔴低い]

---
**報告者**: [作成者]
**承認**: [要承認/承認済み]
**次回レビュー**: [日付]
```

### トラブル事例必須記録項目
1. **発生タイミング**: 作業中に遭遇したトラブル
2. **重要度判定**: 🔴高（作業停止）、🟡中（代替手段必要）、🟢低（軽微な問題）
3. **解決後24時間以内**: トラブル事例集への記録完了

### トラブル事例標準フォーマット
```markdown
### Case #[連番]: [トラブル名]
**発生日時**: YYYY-MM-DD HH:MM  
**重要度**: [🔴高/🟡中/🟢低]  
**カテゴリ**: [分類名]

#### 症状
```
[エラーメッセージ/現象]
```

#### 原因分析
- [原因1]
- [原因2]

#### 解決方法
**採用案**: [実際の解決方法]
```
[コマンド/設定例]
```

**代替案**:
1. [代替方法1]
2. [代替方法2]

#### 予防策
- [今後の対策1]
- [今後の対策2]
```

### 文書管理ルール
- **保存場所**: `/home/nanashi7777/happyquest/`配下
- **命名規則**: 
  - 作業報告書: `WORK_REPORT_YYYYMMDD.md`
  - トラブル事例: `TROUBLE_CASES_YYYYMMDD.md`
- **更新頻度**: 
  - 作業報告書: 上記タイミング毎
  - トラブル事例: 新規トラブル発生時及び月次見直し
- **アーカイブ**: 6ヶ月経過後は`アーカイブ/`ディレクトリに移動

### 活用・レビュー指針
- **チェックポイントレビュー時**: 作業報告書の確認必須
- **同種作業開始前**: 関連トラブル事例の事前確認
- **新規メンバー参加時**: 最新トラブル事例集の共有必須
- **月次振り返り**: トラブル統計分析と改善提案

## 継続的改善

### 定期見直し
- **月次**：ドキュメント有効性確認、作業報告書・トラブル事例レビュー
- **四半期**：ルール見直し・改善、トラブル傾向分析

### フィードバック収集
- 開発効率測定
- ドキュメント品質評価
- チーム満足度調査
- 作業報告書・トラブル事例活用状況評価

### ナレッジ蓄積
- 作業報告書による成功パターン蓄積
- トラブル事例による問題解決ノウハウ蓄積
- 同様トラブル解決可能な情報体系化

## 📁 ファイル管理原則

### ファイル作成時の必須確認事項
1. **プロジェクト目標への貢献度確認**: 作成目的とプロジェクト目標の関連性を明確化
2. **適切なディレクトリ配置**: 標準ディレクトリ構造に従った適切な配置
3. **明確な命名規則適用**: 目的・バージョン・対象環境が分かる命名
4. **削除条件の明確化**: ライフサイクル・削除タイミングの事前定義

### 標準ディレクトリ構造
```
happyquest/
├── docs/                    # 📚 プロジェクトドキュメント
│   ├── guides/             # 操作ガイド・マニュアル
│   ├── architecture/       # 設計・アーキテクチャ文書
│   └── references/         # 外部参照・アーカイブ
├── infrastructure/         # 🔧 インフラ設定
├── scripts/               # 🔨 実行スクリプト
├── src/                   # 💻 ソースコード
├── tests/                 # 🧪 テストファイル
└── 作業報告書/            # 📋 作業記録（日本語）
```

### 禁止事項
- **ルート直下への一時ファイル作成**: `temp/`ディレクトリ必須使用
- **目的不明なファイル・ディレクトリ作成**: 作成前に目的・用途を明確化
- **1MB超の参考資料ファイル保存**: `docs/references/external/`への適切配置
- **AI実験コードの恒久保存**: 実験終了後は`アーカイブ/実験コード/`に移動

### 自動削除ルール
- **一時ファイル**: 7日経過後自動削除
- **ログファイル**: 30日経過後アーカイブ移動  
- **実験コード**: プルリクエストマージ後アーカイブ移動
- **外部参考資料**: プロジェクト完了後アーカイブ移動

### 定期メンテナンス
- **月1回**: 不要ファイル確認・削除実施
- **四半期1回**: アーカイブ整理・容量最適化
- **リリース前**: 全体ファイル監査・品質確認

### ファイル管理責任
- **作成者責任**: ファイル作成時のルール遵守
- **レビュー責任**: プルリクエスト時のファイル管理確認
- **定期監査**: 月次でのファイル構造健全性確認

## 💬 チャットログ管理システム

### Rule 13: チャットログ保存・管理

#### 13.1 チャットログ作成
```bash
# 新しいチャットログ作成
./scripts/chat-log-manager.sh create "セッション概要"

# セッション情報自動収集
./scripts/chat-log-manager.sh collect
```

#### 13.2 ログ管理コマンド
```bash
# ログ一覧表示
./scripts/chat-log-manager.sh list

# キーワード検索
./scripts/chat-log-manager.sh search "キーワード"

# 最近のログ表示
./scripts/chat-log-manager.sh recent 10

# 統計情報表示
./scripts/chat-log-manager.sh summary

# 古いログのアーカイブ
./scripts/chat-log-manager.sh archive
```

#### 13.3 ログ記録ルール
- **セッション開始時**: 必ずログテンプレート作成
- **重要な決定**: 技術選択・設計方針を記録
- **問題解決**: エラーと解決方法を詳細記録
- **学習事項**: 新しい発見・改善点を記録
- **セッション終了時**: 成果物・次回アクションを記録

#### 13.4 ログ品質基準
- **具体性**: 再現可能な詳細レベル
- **完全性**: 重要な情報の漏れなし
- **検索性**: キーワードによる検索可能
- **継続性**: 次回セッションへの引き継ぎ情報

#### 13.5 自動化レベル
- **Level 1**: セッション情報自動収集
- **Level 2**: Git履歴・コマンド履歴自動記録
- **Level 3**: 環境・依存関係情報自動記録
- **Level 4**: チャット内容は手動記録（技術的制約）

#### 13.6 チャットログの活用
- **過去の問題解決**: 類似問題の解決策検索
- **学習の蓄積**: 技術的発見の振り返り
- **プロセス改善**: 効率的だった手法の再利用
- **知識共有**: チーム内での経験共有

## 🔄 GitHubワークフロー管理

### Rule 14: Issue駆動開発・プルリクエストワークフロー

#### 14.1 改善・修正作業の必須手順

**すべての改善・修正作業は以下の手順で実施する：**

```bash
# 1. Issue作成（GitHub Web UIまたはCLI）
gh issue create --title "機能名: 改善内容" --body "詳細説明"

# 2. 作業ブランチ作成
git checkout -b feature/issue-{番号}-{機能名}

# 3. 作業実施
# コード修正・テスト・ドキュメント更新

# 4. プルリクエスト作成
gh pr create --title "Fix #番号: 改善内容" --body "変更詳細"

# 5. レビュー・承認後マージ
gh pr merge --squash
```

#### 14.2 Issue作成ルール

**Issue作成時の必須項目：**

```markdown
## 📋 概要
[改善・修正の概要を簡潔に記述]

## 🎯 目的
[なぜこの改善が必要か]

## 📝 詳細
[具体的な変更内容]

## ✅ 完了条件
- [ ] [条件1]
- [ ] [条件2]
- [ ] [条件3]

## 🔗 関連
- 関連Issue: #番号
- 参考資料: [URL]

## 🏷️ ラベル
enhancement / bug / documentation / security
```

#### 14.3 プルリクエストルール

**PRタイトル形式：**
- `Fix #番号: 修正内容` (バグ修正)
- `Feature #番号: 機能名` (新機能)
- `Docs #番号: ドキュメント更新` (文書更新)
- `Refactor #番号: リファクタリング内容` (コード整理)

**PR説明テンプレート：**
```markdown
## 🔗 関連Issue
Closes #番号

## 📝 変更内容
[変更の詳細説明]

## 🧪 テスト
- [ ] 手動テスト実施
- [ ] 自動テスト追加
- [ ] 既存テストの確認

## 📋 チェックリスト
- [ ] コードレビュー完了
- [ ] ドキュメント更新
- [ ] セキュリティチェック実施
- [ ] 破壊的変更の確認

## 📸 スクリーンショット
[必要に応じて画面キャプチャ]
```

#### 14.4 ブランチ命名規則

```bash
# 機能追加
feature/issue-{番号}-{機能名}
feature/issue-123-chat-log-system

# バグ修正
fix/issue-{番号}-{修正内容}
fix/issue-456-security-vulnerability

# ドキュメント更新
docs/issue-{番号}-{文書名}
docs/issue-789-project-rules

# リファクタリング
refactor/issue-{番号}-{対象}
refactor/issue-101-code-cleanup
```

#### 14.5 レビュープロセス

**必須レビュー項目：**

1. **コード品質**
   - 可読性・保守性
   - セキュリティ
   - パフォーマンス

2. **テスト**
   - テストカバレッジ
   - エッジケース考慮
   - 回帰テスト

3. **ドキュメント**
   - README.md更新
   - コメント追加
   - 変更ログ記録

4. **互換性**
   - 破壊的変更の確認
   - 依存関係の影響
   - 環境互換性

#### 14.6 マージルール

**マージ前必須条件：**
- [ ] 最低1名のレビュー承認
- [ ] すべてのCIチェック通過
- [ ] コンフリクト解決済み
- [ ] セキュリティチェック完了

**マージ方式：**
- **Squash Merge**: 機能追加・修正（推奨）
- **Merge Commit**: 重要なマイルストーン
- **Rebase**: 小さな修正のみ

#### 14.7 自動化スクリプト

```bash
# Issue作成ヘルパー
./scripts/create-issue.sh "機能名" "改善内容"

# PR作成ヘルパー  
./scripts/create-pr.sh "issue番号" "変更内容"

# ワークフロー確認
./scripts/check-workflow.sh
```

#### 14.8 緊急修正時の例外ルール

**セキュリティ脆弱性・重大バグの場合：**

```bash
# 1. 緊急Issue作成
gh issue create --label "urgent,security" --title "緊急: 脆弱性修正"

# 2. ホットフィックスブランチ
git checkout -b hotfix/critical-security-fix

# 3. 修正・即座PR
gh pr create --label "urgent" --title "Hotfix: 緊急修正"

# 4. 迅速レビュー・マージ
# レビュー時間短縮、事後詳細レビュー実施
```

### 実装効果

- **品質向上**: 体系的なレビュープロセス
- **透明性**: すべての変更がIssue・PRで追跡可能
- **協業効率**: 標準化されたワークフロー
- **リスク軽減**: 段階的な変更管理

## 🔧 開発環境監視・問題報告

### Rule 16: Packer自動構築環境の監視・修正管理

#### 16.1 環境問題監視義務

**Claude Codeによる自動監視項目：**

```bash
# 必須ツール存在確認
required_tools=(
    "python3" "node" "docker" "gh" 
    "pyenv" "nvm" "uv" "brew"
)

# バージョン確認
expected_versions=(
    "python3:3.12.9"
    "node:23.8.0" 
    "docker:latest"
    "gh:latest"
)
```

#### 16.2 問題報告必須ケース

**即座報告が必要な問題：**

1. **必須ツール不在**
   - pyenv, nvm, uv, Homebrew未インストール
   - Python/Node.jsバージョン管理不可

2. **バージョン相違**
   - Node.js v18.19.1 ≠ 期待値 v23.8.0
   - Python 3.12.3 ≠ 期待値 3.12.9

3. **機能障害**
   - MCPサーバー起動失敗
   - Docker コンテナ異常
   - GitHub CLI認証問題

4. **パフォーマンス問題**
   - メモリ不足
   - ディスク容量不足
   - ネットワーク接続問題

#### 16.3 Packer設定修正ルール

**修正必要項目の優先度：**

```yaml
高優先度:
  - Node.js nvm経由でv23.8.0インストール
  - Python pyenv経由で3.12.9インストール
  - uv パッケージマネージャー追加

中優先度:
  - Homebrew インストール
  - 環境変数PATH設定最適化
  - シェル設定ファイル調整

低優先度:
  - 追加開発ツール
  - 設定ファイルテンプレート
  - 便利スクリプト
```

#### 16.4 環境修正手順

**標準修正フロー：**

1. **問題検出**
   ```bash
   # 環境チェックスクリプト実行
   ./scripts/check-environment.sh
   ```

2. **Issue作成**
   ```bash
   # 環境問題用Issue作成
   gh issue create --title "Packer環境修正: [問題内容]" --label "environment,packer"
   ```

3. **修正実装**
   ```bash
   # 個別インストール・設定修正
   # または Packer設定ファイル更新
   ```

4. **検証・PR**
   ```bash
   # 修正確認・プルリクエスト作成
   ./scripts/verify-environment.sh
   gh pr create --title "Fix Packer env: [修正内容]"
   ```

#### 16.5 環境インベントリ管理

**定期的な環境棚卸し：**

```bash
# 月次環境インベントリ更新
./scripts/update-environment-inventory.sh

# 出力先: docs/environment-inventory.md
# 内容: インストール済みパッケージ一覧、バージョン情報、設定状況
```

#### 16.6 Packer設定ファイル管理

**設定ファイル配置場所：**
```
infrastructure/packer/
├── ubuntu-dev-env.pkr.hcl     # メインPacker設定
├── scripts/
│   ├── install-python.sh      # Python環境構築
│   ├── install-nodejs.sh      # Node.js環境構築
│   └── install-tools.sh       # 開発ツール導入
└── provisioners/
    ├── base-packages.json     # 基本パッケージリスト
    └── dev-tools.json         # 開発ツールリスト
```

#### 16.7 環境問題エスカレーション

**問題レベル別対応：**

- **Level 1 (軽微)**: 自動修正スクリプト実行
- **Level 2 (中程度)**: 手動修正 + 文書化
- **Level 3 (重大)**: Packer設定見直し + 再構築検討

#### 16.8 改善サイクル

**継続的環境改善：**

- **週次**: 環境ヘルスチェック実行
- **月次**: インベントリ更新・問題分析
- **四半期**: Packer設定最適化・バージョンアップ

---

**環境監視の徹底により、Packer自動構築環境の品質維持と継続的改善を実現**

## 🎯 品質管理・成果物確認

### Rule 15: 自動テスト・レビュー対応・最終確認

#### 15.1 プルリクエスト品質管理フロー

**必須実行手順：**

```bash
# 1. PR作成後の自動テスト確認
gh pr checks <PR番号>

# 2. テスト失敗時の対応
git add . && git commit -m "テスト修正"
git push

# 3. レビュー対応
gh pr view <PR番号> --comments

# 4. 最終確認依頼
# d.takikita@happyquest.ai に確認依頼
```

#### 15.2 成果物品質確認ルール

**お客様・上司向け成果物の必須確認：**

1. **Playwright自動テスト実行**
   ```bash
   # 成果物の動作確認
   npm run test:e2e
   
   # 視覚的確認
   npm run test:e2e:headed
   
   # レポート生成
   npm run test:report
   ```

2. **手動確認項目**
   - [ ] 画面表示の正常性
   - [ ] 機能動作の完全性
   - [ ] レスポンシブ対応
   - [ ] アクセシビリティ
   - [ ] パフォーマンス
   - [ ] セキュリティ

3. **既存成果物の問題発見時**
   ```bash
   # 問題報告Issue作成
   ./scripts/create-issue.sh "既存成果物修正" "発見した問題の詳細"
   
   # 緊急度に応じた対応
   # 高: 即座修正
   # 中: 次回スプリントで修正
   # 低: バックログに追加
   ```

#### 15.3 最終確認・承認プロセス

**作業完了前の必須ステップ：**

1. **自動テスト全通過確認**
   - CI/CDパイプライン ✅
   - セキュリティスキャン ✅
   - 品質ゲート ✅

2. **レビュー完了確認**
   - コードレビュー承認 ✅
   - 機能テスト完了 ✅
   - ドキュメント確認 ✅

3. **成果物最終確認**
   - Playwright自動テスト ✅
   - 手動動作確認 ✅
   - 既存機能への影響確認 ✅

4. **承認依頼**
   - 確認依頼メール送信
   - 承認後マージ実行
   - 完了報告

#### 15.4 メール通知・報告ルール

**報告対象：d.takikita@happyquest.ai**

**報告タイミング：**
- 重要な成果物完成時
- 既存成果物の問題発見時
- 緊急修正が必要な場合
- 大きな改善完了時

**報告テンプレート：**
```
件名: [HappyQuest] 成果物確認依頼 - [機能名]

お疲れ様です。

以下の作業が完了しましたので、確認をお願いいたします。

■ 作業内容
- [作業概要]

■ 成果物
- GitHub PR: [URL]
- デモ環境: [URL]
- テストレポート: [URL]

■ 確認済み項目
✅ 自動テスト全通過
✅ コードレビュー完了
✅ Playwright動作確認
✅ 既存機能への影響なし

■ 発見した既存問題（あれば）
- [問題内容と対応方針]

確認後、問題なければマージいたします。
ご質問等ございましたらお気軽にお声がけください。
```

#### 15.5 継続的品質改善

**品質メトリクス監視：**
- テスト成功率 > 95%
- レビュー承認率 > 90%
- 成果物品質スコア > 85%
- 顧客満足度 > 90%

**改善サイクル：**
- 週次: 品質メトリクス確認
- 月次: プロセス改善検討
- 四半期: 大幅な改善実施

---

**最終更新：2025-06-24**  
**更新者：HappyQuest開発チーム**  
**バージョン：3.3** （品質管理・成果物確認ルール追加）  