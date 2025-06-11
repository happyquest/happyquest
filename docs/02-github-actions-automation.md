# GitHub Actions による静的解析とリンティングの自動化

## はじめに

本ドキュメントは、GitHub Actionsを使用した静的解析とリンティングの自動化について説明します。提供された資料に基づいて、Ansible、Shell、Docker、YAMLファイルの品質管理を自動化します。

## 1. Ansible Playbook のリンティング (ansible-lint)

AnsibleのPlaybookやロールの品質を維持するためには、`ansible-lint`による静的解析が不可欠です。`ansible-lint`は、ベストプラクティスや潜在的な問題をチェックします。

### 公式アクションの使用

GitHub Actionsでこれを利用するには、Ansibleチームが提供する公式アクション `ansible/ansible-lint` が推奨されます。このアクションはGitHubによって検証済みクリエーターとして認定されています。

### 重要なパラメータ

- `args`: `ansible-lint`コマンドに渡す追加の引数を指定します（例: `--strict`, `-x RULE_ID`）
- `working_directory`: `ansible-lint`を実行するディレクトリを指定します
- `requirements_file`: ロールやコレクションの依存関係を定義した`requirements.yml`ファイルのパスを指定します

### Requirements ファイルの重要性

Ansibleプロジェクトでは、Ansible Galaxyや他のソースから取得した外部ロールやコレクションに依存することが一般的です。`ansible-lint`がこれらの依存関係を正しく認識し、それらを使用するPlaybookを適切に解析するためには、この`requirements_file`パラメータが極めて重要になります。

### 設定例

```yaml
#.github/workflows/ansible-lint.yml
name: Ansible Lint
on:
  pull_request:
    branches: [ "main", "stable", "release/v*" ]
jobs:
  build:
    name: Ansible Lint
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - name: Run ansible-lint
        uses: ansible/ansible-lint@main # または特定のバージョンタグ (例: v25.2.1)
        with:
          requirements_file: 'ansible/requirements.yml' # Ansibleの依存関係ファイルへのパス
          working_directory: 'ansible' # Ansibleコンテンツのルートディレクトリ
          args: "--strict -p -v --force-color" # ansible-lintへの追加引数
```

## 2. シェルスクリプトの静的解析 (ShellCheck)

シェルスクリプトは、環境構築やデプロイメントタスクで頻繁に使用されます。これらのスクリプトの品質と信頼性を確保するために、静的解析ツール`ShellCheck`の利用が強く推奨されます。

### 主な機能

- 構文エラーの検出
- セマンティックな問題の特定
- 一般的な落とし穴の警告

### 設定オプション

- `SHELLCHECK_OPTS`: `ShellCheck`コマンドに渡すオプションを指定
- `ignore_paths`, `ignore_names`: 特定のディレクトリやファイルをスキャン対象から除外
- `severity`: アクションを失敗させる最小の警告レベル
- `scandir`: スキャン対象を特定のディレクトリに限定
- `version`: 使用する`ShellCheck`のバージョンを固定

### 設定例

```yaml
#.github/workflows/shellcheck.yml
name: ShellCheck
on:
  pull_request:
    branches: [ main ]
jobs:
  shellcheck:
    name: Shellcheck
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run ShellCheck
        uses: ludeeus/action-shellcheck@master # または特定のバージョンタグ
        with:
          scandir: './scripts' # スキャン対象ディレクトリ
          severity: 'warning' # warning以上の指摘でジョブを失敗させる
        env:
          SHELLCHECK_OPTS: '-e SC2034 -e SC2154' # 特定の警告コードを無視
```

## 3. Dockerfile の検証 (Hadolint)

Dockerfileはコンテナイメージの設計図であり、その品質はセキュリティ、パフォーマンス、再現性に直結します。

### Hadolint の特徴

- Dockerfileのベストプラクティスをチェック
- `RUN`命令内のシェルコマンドに対してはShellCheckを内部利用
- DLプレフィックス（Hadolint独自ルール）とSCプレフィックス（ShellCheckルール）

### 設定オプション

- `dockerfile`: 解析対象のDockerfileへのパス（シェル展開も利用可能 `**/Dockerfile`）
- `config_file`: カスタム設定ファイル（`.hadolint.yaml`）へのパス
- `error_level`: CIを失敗させるHadolintの出力レベル
- `annotate`: GitHub PRビューアにインラインでアノテーションを表示するかどうか

### 設定例

```yaml
#.github/workflows/hadolint.yml
name: Hadolint
on:
  pull_request:
    branches: [ main ]
jobs:
  hadolint:
    name: Hadolint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run Hadolint
        uses: jbergstroem/hadolint-gh-action@v1 # または特定のバージョンタグ
        with:
          dockerfile: '**/Dockerfile' # リポジトリ内の全てのDockerfileを対象
          config_file: '.hadolint.yaml' # カスタム設定ファイル
          error_level: 'warning' # warning以上の指摘でジョブを失敗させる
```

## 4. YAML ファイルのリンティング (yamllint)

YAMLは、AnsibleのPlaybook、GitHub Actionsのワークフロー、n8nのワークフロー（一部）、その他多くの設定ファイルで使用される汎用的なデータシリアライゼーション言語です。

### yamllint の機能

- YAMLファイルの構文エラーをチェック
- スタイルに関する問題を検出
- カスタマイズ可能なルール設定

### 利用可能なアクション

- `karancode/yamllint-github-action`: 対象ファイル/ディレクトリの指定、厳格モード、カスタム設定ファイル、PRへのコメント投稿
- `bewuethr/yamllint-action`: リポジトリ内の全てのYAMLファイルを対象、設定ファイルの指定が可能

### 設定例

```yaml
#.github/workflows/yamllint.yml
name: YAML Lint
on:
  pull_request:
    branches: [ main ]
jobs:
  yamllint:
    name: Yamllint
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Run yamllint
        uses: karancode/yamllint-github-action@master
        with:
          yamllint_file_or_dir: '.'
          yamllint_strict: false
          yamllint_comment: true
```

## 5. 統合的なワークフロー設定例

以下は、これまでに説明した各種リンターを組み合わせ、プルリクエストが`main`ブランチにマージされる前に自動的にチェックを実行するGitHub Actionsワークフローの統合例です。

```yaml
name: Code Quality Checks
on:
  pull_request:
    branches: [ main ]

jobs:
  lint-ansible:
    if: contains(github.event.pull_request.changed_files, 'infrastructure/ansible/')
    runs-on: ubuntu-24.04
    steps:
      - uses: actions/checkout@v4
      - uses: ansible/ansible-lint@main
        with:
          requirements_file: 'infrastructure/ansible/requirements.yml'
          working_directory: 'infrastructure/ansible'
          args: "--strict -p -v --force-color"

  lint-shell:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ludeeus/action-shellcheck@master
        with:
          scandir: './scripts'
          severity: 'warning'

  lint-docker:
    if: contains(github.event.pull_request.changed_files, 'Dockerfile')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: jbergstroem/hadolint-gh-action@v1
        with:
          dockerfile: '**/Dockerfile'
          error_level: 'warning'

  lint-yaml:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: karancode/yamllint-github-action@master
        with:
          yamllint_file_or_dir: '.'
          yamllint_strict: false
``` 