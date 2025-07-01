# 📝 HappyQuest メモ管理システム

## 概要
長い文書から重要な箇所を抽出・保存するためのメモ管理システム

## ディレクトリ構造
```
notes/
├── README.md                    # このファイル
├── highlights/                  # 重要箇所のハイライト
│   ├── YYYY-MM-DD-document-name.md
│   └── ...
├── bookmarks/                   # ブックマーク・参照
│   ├── technical-references.md
│   └── ...
├── quick-notes/                 # クイックメモ
│   ├── YYYY-MM-DD-session.md
│   └── ...
└── templates/                   # メモテンプレート
    ├── highlight-template.md
    └── bookmark-template.md
```

## 使用方法

### 1. 重要箇所のハイライト保存
```bash
# 新しいハイライトメモ作成
cp notes/templates/highlight-template.md notes/highlights/$(date +%Y-%m-%d)-[文書名].md
```

### 2. ブックマーク保存
```bash
# 技術参照の追加
echo "## [タイトル]" >> notes/bookmarks/technical-references.md
echo "[重要な内容]" >> notes/bookmarks/technical-references.md
```

### 3. クイックメモ
```bash
# セッション中のメモ
echo "$(date): [メモ内容]" >> notes/quick-notes/$(date +%Y-%m-%d)-session.md
```

## メモの種類

### 🔍 ハイライト
- 長い文書の重要箇所
- 技術仕様の要点
- 設定値の重要な部分

### 🔖 ブックマーク  
- 参照すべき文書・URL
- 技術資料のリンク
- 関連プロジェクトの情報

### ⚡ クイックメモ
- セッション中の気づき
- 一時的なメモ
- TODO項目

## 検索・活用

### 全メモ検索
```bash
grep -r "検索キーワード" notes/
```

### 日付別検索
```bash
find notes/ -name "*2025-06-24*"
```

### カテゴリ別検索
```bash
find notes/highlights/ -name "*.md"
```