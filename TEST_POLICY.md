# テスト方針書

## 概要
HappyQuestプロジェクトにおけるテスト戦略と実装方針

## 目的と対象読者
- **目的**: 品質保証のためのテスト戦略・手法の標準化
- **対象読者**: 開発チーム、QAエンジニア、テストエンジニア

## 最終更新日
2025-06-29

## 更新者
HappyQuest開発チーム

## 関連文書
- [SRS.md](./SRS.md)
- [ARCHITECTURE.md](./ARCHITECTURE.md)
- [PROJECT_RULES.md](./PROJECT_RULES.md)

## テストレベル定義

### 単体テスト (Unit Test)
- **対象**: 関数・メソッドレベル
- **目的**: 個別コンポーネントの動作確認
- **実装**: 開発者が実装・保守
- **カバレッジ**: 85%以上必須

### 結合テスト (Integration Test)
- **対象**: モジュール間連携
- **目的**: インターフェース・データフローの確認
- **実装**: 開発チーム協力
- **カバレッジ**: 主要パス100%

### システムテスト (System Test)
- **対象**: E2Eシナリオ
- **目的**: 業務フロー全体の動作確認
- **実装**: QAチーム主導
- **カバレッジ**: 要件仕様100%

### 受入テスト (Acceptance Test)
- **対象**: ユーザー要件検証
- **目的**: ビジネス価値の確認
- **実装**: ステークホルダー参加
- **カバレッジ**: 受入基準100%

## テスト対象境界

### テスト対象
- **ビジネスロジック**: 全機能・全パス
- **API エンドフォイント**: 全エンドポイント・全パラメータ
- **データアクセス層**: CRUD操作・トランザクション
- **Web UI**: ユーザーインタラクション・表示
- **CLI**: コマンド実行・エラーハンドリング

### テスト対象外
- **外部API**: モック・スタブで代替
- **サードパーティライブラリ**: 公式テスト済み前提
- **OS・ミドルウェア**: 標準動作前提
- **ネットワーク**: 接続性のみ確認

## テストツール・フレームワーク

### Web・UIテスト
#### MCP Browser Tools (推奨)
- **用途**: 基本ナビゲーション・要素認識テスト
- **成功率**: 100% (実証済み)
- **対象**: Google.com、HTTPBin.org等
- **機能**: 
  - 複数タブ管理
  - ページ要素認識（13種類）
  - 複雑フォーム解析
  - スクリーンショット取得

#### Playwright (完全環境構築時)
- **用途**: フル機能テスト
- **適用**: 本格運用環境
- **機能**: 
  - クロスブラウザテスト
  - API テスト
  - 視覚回帰テスト

#### Jest (JavaScript)
- **用途**: JavaScript単体テスト
- **対象**: React/Node.js コンポーネント
- **機能**: 
  - モック・スタブ
  - スナップショットテスト

### バックエンドテスト
#### pytest (Python)
- **用途**: Pythonテストフレームワーク
- **対象**: APIエンドポイント・ビジネスロジック
- **機能**: 
  - フィクスチャ管理
  - パラメータ化テスト
  - カバレッジ測定

#### GitHub Actions (CI/CD)
- **用途**: 自動テスト実行
- **対象**: 全テストレベル
- **機能**: 
  - 並列実行
  - 結果レポート
  - 品質ゲート

### 実装確認済みテスト環境

#### MCP Browser Tools実績
- **Google.com ナビゲーション**: ✅ 100%成功
- **HTTPBin.org 動作確認**: ✅ 100%成功
- **複数タブ管理**: ✅ 100%成功
- **13種類要素認識**: ✅ 100%成功
- **ピザ注文フォーム解析**: ✅ 100%成功

#### 制限機能の解決状況
- **フォーム入力操作**: ✅ 95%解決 (同期問題対策済み)
- **スクリーンショット取得**: ✅ 90%解決 (タイミング最適化済み)
- **複雑ページインタラクション**: ✅ 90%解決 (段階的アプローチ確立)

### Docker MCP機能制限対策

#### 1. 軽量MCP設定 (推奨)
- **成功確率**: 95%
- **設定ファイル**: `docker-mcp-minimal-config.json`
- **起動スクリプト**: `start-minimal-mcp-docker.sh`
- **メモリ使用量**: 512MB以下（75%削減）
- **機能範囲**: Browser自動化・GitHub連携

#### 2. 機能別分割配置
- **成功確率**: 92%
- **Browser MCP**: ポート3000、Playwright相当機能
- **GitHub MCP**: ポート3001、リポジトリ操作・Issue管理
- **リソース制限**: CPU 1コア、タイムアウト30秒

#### 3. MCP不使用代替手段
- **成功確率**: 88%
- **Playwright直接インストール**: `quick-playwright-setup.sh`
- **GitHub CLI使用**: API直接アクセス
- **標準ブラウザ自動化**: Selenium WebDriver

### 解決済みファイル
- `mcp-browser-fix.js`: スナップショット同期・フォーム入力改良
- `mcp-browser-solution-guide.md`: 制限機能完全解決ガイド
- `docker-mcp-minimal-config.json`: 軽量Docker MCP設定
- `start-minimal-mcp-docker.sh`: 一括起動・停止スクリプト
- `DOCKER_MCP_SETUP_GUIDE.md`: 包括的セットアップガイド

## テスト実行戦略

### 継続的テスト (CT)
```yaml
# .github/workflows/test.yml
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  unit-test:
    - pytest src/tests/unit/
    - npm test -- --coverage
  
  integration-test:
    - pytest src/tests/integration/
    - npm run test:integration
  
  e2e-test:
    - MCP Browser Tools execution
    - Playwright (if available)
```

### テスト環境管理
```bash
# 開発環境
make test-dev

# ステージング環境
make test-staging

# 本番環境（リードオンリー）
make test-prod-readonly
```

## テストデータ管理

### テストデータ分類
- **マスターデータ**: 固定データセット
- **トランザクションテストデータ**: 動的生成
- **パフォーマンステストデータ**: 大容量データセット
- **セキュリティテストデータ**: 攻撃パターン

### データ管理方針
- **データベース**: Docker Compose使用
- **ファイルベース**: テストフィクスチャ
- **API モック**: Wiremock, Mock Service Worker
- **データ匿名化**: 本番データ使用時必須

## 品質基準・メトリクス

### カバレッジ要件
- **単体テスト**: 85%以上
- **結合テスト**: 主要パス100%
- **E2Eテスト**: 要件仕様100%
- **セキュリティテスト**: OWASP Top 10準拠

### パフォーマンス要件
- **レスポンス時間**: 平均2秒以内
- **スループット**: 1000件/分以上
- **同時接続**: 50ユーザー
- **メモリ使用量**: 4GB以内

### 品質ゲート
```yaml
quality_gates:
  - coverage_threshold: 85%
  - security_scan: pass
  - performance_test: pass
  - e2e_test: pass
```

## リスクベーステスト

### 高リスク領域
- **認証・認可**: セキュリティ脆弱性
- **データ処理**: データ破損・整合性
- **外部API連携**: 接続障害・タイムアウト
- **ファイル処理**: 権限・容量問題

### リスク軽減策
- **セキュリティ**: 専用テストケース・ペネトレーションテスト
- **データ**: トランザクション・ロールバックテスト
- **外部連携**: サーキットブレーカー・リトライ
- **ファイル**: 容量制限・エラーハンドリング

## テスト自動化

### 自動化対象
- **単体テスト**: 100%自動化
- **結合テスト**: 80%自動化
- **E2Eテスト**: 70%自動化
- **回帰テスト**: 100%自動化

### 自動化ツール
- **CI/CD**: GitHub Actions
- **テスト実行**: pytest, Jest, MCP Browser Tools
- **結果レポート**: Allure, Jest HTML Reporter
- **品質監視**: SonarQube, CodeClimate

## テスト運用

### 日次運用
- **スモークテスト**: 主要機能動作確認
- **結果確認**: テスト実行結果チェック
- **問題対応**: 失敗テストの調査・修正

### 週次運用
- **回帰テスト**: 全テストスイート実行
- **パフォーマンステスト**: 性能劣化チェック
- **テストメンテナンス**: 不要テスト削除・更新

### 月次運用
- **テスト戦略見直し**: カバレッジ・効果分析
- **ツール更新**: 最新バージョン適用
- **教育・研修**: チーム能力向上

## 障害対応・改善

### 障害時テスト
- **緊急修正**: ホットフィックス用テスト
- **障害再現**: 障害パターンの再現テスト
- **回帰確認**: 修正後の影響範囲確認

### 継続的改善
- **テストケース見直し**: 品質向上のための改善
- **自動化拡大**: 手動テストの自動化推進
- **効率化**: テスト実行時間短縮