# Playwright MCPサーバー 基本操作マニュアル (2025/03/30)

## インストール手順 (Ubuntu 22.04 で検証済み)

1.  **前提条件:** Node.js および npm がインストールされていること。
    *   バージョン確認: `node --version`, `npm --version`

2.  **Smithery CLI を使用したインストール:**
    以下のコマンドを実行して、Playwright MCPサーバーをインストールします。
    ```bash
    npx -y @smithery/cli install @executeautomation/playwright-mcp-server --client claude
    ```
    *   このコマンドは、必要なパッケージをインストールし、設定ファイルへの登録を試みます（ただし、設定は後述の手順で手動確認・修正が必要な場合があります）。

3.  **Playwright ブラウザのインストール:**
    Playwrightが操作するブラウザ本体をインストールします。
    ```bash
    npx playwright install
    ```

4.  **システム依存関係のインストール:**
    Playwrightがブラウザを実行するために必要なシステムライブラリをインストールします。
    *   まずパッケージリストを更新します:
        ```bash
        sudo apt-get update
        ```
    *   次に依存ライブラリをインストールします (例: `libavif13`):
        ```bash
        sudo apt-get install -y libavif13 
        ```
    *   (注記: `sudo npx playwright install-deps` コマンドは環境によって `npx` が見つからないエラーになる場合があります。その場合は `apt-get` を使用してください。)

5.  **MCP設定ファイルの確認・修正:**
    `~/.config/Cursor/User/globalStorage/saoudrizwan.claude-dev/settings/cline_mcp_settings.json` (または同等の設定ファイル) を開き、以下のようになっていることを確認または修正します。
    ```json
    {
      "mcpServers": {
        // ... 他のサーバー設定 ...
        "playwright": {
          "command": "npx",
          "args": [
            "-y",
            "@executeautomation/playwright-mcp-server"
          ],
          "disabled": false,
          "autoApprove": []
        }
      }
    }
    ```
    *   `command` が `"npx"`、`args` が `["-y", "@executeautomation/playwright-mcp-server"]` となっている点が重要です。
    *   `disabled` が `false` であることを確認します。

6.  **再起動と確認:**
    設定ファイルを変更した後、MCPクライアント（Claude DesktopやCursorなど）を再起動すると、Playwrightサーバーに接続されます。基本的なツール（例: `playwright_navigate`）を実行して接続を確認します。

## 概要

このマニュアルは、Playwright MCPサーバーの基本的なツールとその使用例をまとめたものです。Webページの操作や情報収集を行う際の参考にしてください。

**前提:** Playwright MCPサーバーが `cline_mcp_settings.json` で正しく設定され、接続されていること。

## 基本的なツールと使用例

### 1. ページへの移動 (`playwright_navigate`)

指定したURLのWebページを開きます。

**使用例:** `https://example.com` を開く

```xml
<use_mcp_tool>
<server_name>playwright</server_name>
<tool_name>playwright_navigate</tool_name>
<arguments>
{
  "url": "https://example.com",
  "headless": true
}
</arguments>
</use_mcp_tool>
```

*   `url`: (必須) 移動先のURL。
*   `headless`: (任意) `true` に設定すると、GUIなしでバックグラウンドでブラウザを実行します。Linux環境などGUIがない場合に必要です。デフォルトは `false`。

**結果例:** `Navigated to https://example.com`

### 2. ページのタイトル取得 (`playwright_evaluate`)

現在開いているページのタイトルなど、JavaScriptを実行して情報を取得します。

**使用例:** 現在のページのタイトルを取得

```xml
<use_mcp_tool>
<server_name>playwright</server_name>
<tool_name>playwright_evaluate</tool_name>
<arguments>
{
  "script": "document.title"
}
</arguments>
</use_mcp_tool>
```

*   `script`: (必須) ブラウザで実行するJavaScriptコード。

**結果例:**
```
Executed JavaScript:

document.title

Result:

"Example Domain"
```

### 3. 表示テキストの取得 (`playwright_get_visible_text`)

現在開いているページに表示されているテキストコンテンツを取得します。

**使用例:**

```xml
<use_mcp_tool>
<server_name>playwright</server_name>
<tool_name>playwright_get_visible_text</tool_name>
<arguments>
{}
</arguments>
</use_mcp_tool>
```

**結果例:**
```
Visible text content:
Example Domain
This domain is for use in illustrative examples in documents. You may use this
    domain in literature without prior coordination or asking for permission.
More information...
```

### 4. スクリーンショットの取得 (`playwright_screenshot`)

現在開いているページのスクリーンショットを撮ります。

**使用例:** ページ全体のスクリーンショットをPNGファイルとして保存

```xml
<use_mcp_tool>
<server_name>playwright</server_name>
<tool_name>playwright_screenshot</tool_name>
<arguments>
{
  "name": "example_screenshot",
  "fullPage": true,
  "savePng": true,
  "storeBase64": false
}
</arguments>
</use_mcp_tool>
```

*   `name`: (必須) スクリーンショットのファイル名のベース。
*   `fullPage`: (任意) `true` にするとページ全体を撮影します。デフォルトは `false` (表示領域のみ)。
*   `savePng`: (任意) `true` にするとPNGファイルとして保存します。デフォルトは `false`。
*   `storeBase64`: (任意) `true` にするとBase64エンコードされた画像データを結果として返します。`savePng` と同時に `true` にはできません。デフォルトは `true`。
*   `downloadsDir`: (任意) 保存先ディレクトリを指定します。デフォルトはユーザーのDownloadsフォルダ。

**結果例:** `Screenshot saved to: Downloads/example_screenshot-2025-03-30T08-48-30-716Z.png`

### 5. 要素のクリック (`playwright_click`)

CSSセレクタで指定した要素をクリックします。

**使用例:** ページ内の最初のリンク (`<a>` タグ) をクリック

```xml
<use_mcp_tool>
<server_name>playwright</server_name>
<tool_name>playwright_click</tool_name>
<arguments>
{
  "selector": "a"
}
</arguments>
</use_mcp_tool>
```

*   `selector`: (必須) クリックする要素を指定するCSSセレクタ。

**結果例:** `Clicked element: a`

### 6. ブラウザを閉じる (`playwright_close`)

現在Playwrightが操作しているブラウザを閉じます。

**使用例:**

```xml
<use_mcp_tool>
<server_name>playwright</server_name>
<tool_name>playwright_close</tool_name>
<arguments>
{}
</arguments>
</use_mcp_tool>
```

**結果例:** `Browser closed successfully`

## その他のツール

上記以外にも、フォームへの入力 (`playwright_fill`)、ドロップダウンの選択 (`playwright_select`)、要素へのホバー (`playwright_hover`) など、様々なツールがあります。詳細はシステムプロンプトの「Connected MCP Servers」セクションにある `playwright` サーバーのツールリストをご参照ください。
