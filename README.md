# HappyQuest 開発環境構築

Ubuntu 24.04向けの開発環境自動構築スクリプト

## 機能

- Python 3.12環境のセットアップ
- Node.js開発環境の構築
- Docker環境の構築
- 開発ツール（Git, GitHub CLI等）のインストール

## 必要条件

- Ubuntu 24.04
- Ansible 2.9以上
- sudo権限

## インストール方法

```bash
# リポジトリのクローン
git clone https://github.com/happyquest/happyquest.git
cd happyquest

# Ansibleのインストール
sudo apt update
sudo apt install -y ansible

# 環境構築の実行
cd ansible
ansible-playbook site.yml
```

## 構成

```
happyquest/
├── .github/
│   └── workflows/      # GitHub Actions設定
├── ansible/
│   ├── roles/         # Ansibleロール
│   ├── inventory/     # インベントリ設定
│   └── site.yml      # メインプレイブック
├── docs/
│   └── environment/   # ドキュメント
└── scripts/          # ユーティリティスクリプト
```

## 開発者向け情報

- 環境構築の詳細は `docs/environment/setup.md` を参照
- トラブルシューティングは `docs/environment/troubleshooting.md` を参照

## ライセンス

MIT License

## 貢献

1. このリポジトリをフォーク
2. 新しいブランチを作成 (`git checkout -b feature/amazing-feature`)
3. 変更をコミット (`git commit -m 'Add some amazing feature'`)
4. ブランチをプッシュ (`git push origin feature/amazing-feature`)
5. Pull Requestを作成 