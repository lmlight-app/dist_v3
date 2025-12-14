# LM Light 利用マニュアル (Perpetual License)

> **ライセンス方式**: MACアドレスベース永続ライセンス
> オフライン・オンプレミス環境に最適

## インストール

### macOS

```bash
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-macos.sh | bash
```

### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-linux.sh | bash
```

### Windows

**EXEインストーラー (推奨):**
1. [最新リリース](https://github.com/lmlight-app/dist_v3/releases/latest)から `LMLight-Setup-X.X.X.exe` をダウンロード
2. ダブルクリックしてインストール

**PowerShellスクリプト:**
```powershell
irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-windows.ps1 | iex
```

---

インストール先:
- macOS/Linux: `~/.local/lmlight`
- Windows: `%LOCALAPPDATA%\lmlight`

**Docker:**
```bash
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-docker.sh | bash
```

または手動で:
```bash
# イメージ取得
curl -fSL https://github.com/lmlight-app/dist_v3/releases/latest/download/lmlight-perpetual-docker.tar.gz | docker load
curl -fSL https://github.com/lmlight-app/dist_v3/releases/latest/download/lmlight-web-docker.tar.gz | docker load

# 起動
docker run -d --name lmlight-perpetual -p 8000:8000 --env-file .env lmlight-perpetual
docker run -d --name lmlight-web -p 3000:3000 --env-file .env lmlight-web
```

## 環境構築 (インストール前に実行)

### 必要な依存関係

| 依存関係 | macOS | Linux (Ubuntu/Debian) | Windows |
|---------|-------|----------------------|---------|
| Node.js 18+ | `brew install node` | `sudo apt install nodejs npm` | `winget install OpenJS.NodeJS.LTS` |
| PostgreSQL 16+ | `brew install postgresql@16` | `sudo apt install postgresql` | `winget install PostgreSQL.PostgreSQL` |
| pgvector | `brew install pgvector` | `sudo apt install postgresql-16-pgvector` | [手動インストール](https://github.com/pgvector/pgvector#windows) |
| Ollama | `brew install ollama` | `curl -fsSL https://ollama.com/install.sh \| sh` | `winget install Ollama.Ollama` |
| Tesseract OCR | `brew install tesseract` | `sudo apt install tesseract-ocr` | [UB-Mannheim版](https://github.com/UB-Mannheim/tesseract/wiki) |

### データベース

インストーラーがDB作成・テーブル作成・初期ユーザー作成を自動実行します。

問題が発生した場合のみ手動実行:

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/db_setup.sh | bash
```

```powershell
# Windows
irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/db_setup.ps1 | iex
```

**DBリセット (⚠️ 全データ削除):**
```bash
psql -U postgres -c "DROP DATABASE lmlight;"
# その後、上記のdb_setupを再実行
```

※ アップデート時も既存データは保持されます

### Ollamaモデル

[Ollama モデル一覧](https://ollama.com/search) から好みのモデルを選択:

```bash
ollama pull <model_name>        # 例: gemma3:4b, llama3.2, qwen2.5 など
ollama pull nomic-embed-text    # RAG用埋め込みモデル (推奨)
```

### 設定ファイル (.env)

インストール後、`~/.local/lmlight/.env` を編集:

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://<user>:<password>@localhost:5432/<database>` |
| `OLLAMA_BASE_URL` | OllamaサーバーURL | `http://localhost:11434` |
| `LICENSE_FILE_PATH` | ライセンスファイルのパス | `~/.local/lmlight/license.lic` |
| `NEXTAUTH_SECRET` | セッション暗号化キー (任意の文字列) | - |
| `NEXTAUTH_URL` | WebアプリのURL | `http://localhost:3000` |
| `NEXT_PUBLIC_API_URL` | APIサーバーURL | `http://localhost:8000` |
| `API_PORT` | APIポート | `8000` |
| `WEB_PORT` | Webポート | `3000` |

※ インストーラーが自動設定します。手動変更が必要な場合のみ編集してください。

### ライセンス (Perpetual License)

**ライセンス方式**: MACアドレスベース永続ライセンス

- デバイスのMACアドレスに紐付けられた永続ライセンス
- 有効期限なし (issued_atチェックなし)
- オフライン・オンプレミス環境での利用に最適
- 1ライセンス = 1デバイス

`license.lic` を `~/.local/lmlight/` に配置

## 起動・停止

**macOS:**
- Launchpad または `/Applications` から「LM Light」をクリック
- Dockにピン留めしてトグル操作 (起動中→停止、停止中→起動)

**Linux:**
```bash
# 起動
~/.local/lmlight/start.sh

# 停止
~/.local/lmlight/stop.sh
```

**Windows:**
- スタートメニュー → 「LM Light」をクリック
- タスクバーにピン留めしてトグル操作

または:
```powershell
& "$env:LOCALAPPDATA\lmlight\start.ps1"
& "$env:LOCALAPPDATA\lmlight\stop.ps1"
```

## アクセス

- Web: http://localhost:3000
- API: http://localhost:8000

デフォルトログイン: `admin@local` / `admin123`

※ 初回ログイン後、パスワードを変更してください

## アップデート

同じインストールコマンドを再実行 (データは保持)

## アンインストール

**macOS:**
```bash
rm -rf ~/.local/lmlight
rm -rf "/Applications/LM Light.app"
```

**Linux:**
```bash
rm -rf ~/.local/lmlight
```

**Windows:**
- EXEインストーラー版: 設定 → アプリ → インストールされているアプリ → LM Light → アンインストール
- PowerShellスクリプト版:
```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\lmlight"
```

## ディレクトリ構造

```
~/.local/lmlight/
├── api             # APIバイナリ (lmlight-perpetual-*)
├── web/            # Webフロントエンド
├── .env            # 設定ファイル
├── license.lic     # ライセンス (MACアドレスベース)
├── start.sh        # 起動
├── stop.sh         # 停止
└── logs/           # ログ
```

## ライセンス比較

| 項目 | dist_v2 (Time-based) | dist_v3 (Perpetual) |
|------|---------------------|---------------------|
| ライセンスチェック | issued_at (有効期限) | MACアドレス |
| オフライン利用 | 期限内のみ | 完全対応 |
| ライセンスタイプ | サブスクリプション | 永続 |
| 用途 | クラウド・更新環境 | オンプレミス・固定環境 |
