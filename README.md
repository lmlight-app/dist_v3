# LM Light 利用マニュアル (Perpetual License)

> **ライセンス方式**: Hardware UUIDベース永続ライセンス

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
| PostgreSQL 17 | `brew install postgresql@17` | `sudo apt install postgresql` | `winget install PostgreSQL.PostgreSQL.17` |
| pgvector | `brew install pgvector` | `sudo apt install postgresql-17-pgvector` | [手動インストール](https://github.com/pgvector/pgvector#windows) |
| Ollama | `brew install ollama` | `curl -fsSL https://ollama.com/install.sh \| sh` | `winget install Ollama.Ollama` |
| FFmpeg (文字起こし用) | `brew install ffmpeg` | `sudo apt install ffmpeg` | `winget install Gyan.FFmpeg` |
| Tesseract OCR (任意) | `brew install tesseract` | `sudo apt install tesseract-ocr` | `winget install UB-Mannheim.TesseractOCR` |

### データベース

インストーラーがDB作成・テーブル作成・初期ユーザー作成を自動実行します。

データベースのみを手動実行:

```bash
# macOS/Linux
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/db_setup.sh | bash
```

```powershell
# Windows
irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/db_setup.ps1 | iex
```

**データベース削除:**
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

インストール後、`.env` を編集:
- macOS/Linux: `~/.local/lmlight/.env`
- Windows: `%LOCALAPPDATA%\lmlight\.env`

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
| `WHISPER_MODEL` | 文字起こしモデル (tiny/base/small/medium/large) | `tiny` |

※ インストーラーが自動設定します。手動変更が必要な場合のみ編集してください。

### 文字起こし機能 (オプション)

音声ファイルをテキストに変換する機能です。モデルは別途インストールが必要です。

#### モデル比較表

| モデル | サイズ | 30分音声の処理時間 (CPU) | 30分音声の処理時間 (RTX 5060) | 精度 | 想定用途 |
|--------|--------|--------------------------|-------------------------------|------|----------|
| tiny | 74MB | 約3分 | 約30秒 | ★★☆☆☆ | 高速プレビュー、メモ程度 |
| base | 142MB | 約5分 | 約45秒 | ★★★☆☆ | 日常会話、簡易議事録 |
| small | 466MB | 約15分 | 約1.5分 | ★★★★☆ | ビジネス文書、インタビュー |
| medium | 1.5GB | 約40分 | 約3分 | ★★★★☆ | 専門用語含む録音 |
| large | 2.9GB | 約90分 | 約5分 | ★★★★★ | 高精度が必須の文書化 |

※ 処理時間は目安です。実際の時間はCPU/GPU性能、音声品質により変動します。
※ GPU未使用時はCPUのみで処理されます。

#### モデルのインストール

**macOS / Linux:**

```bash
# デフォルト (tiny)
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash

# モデル指定
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- tiny
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- base
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- small
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- medium
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash -s -- large
```

**Windows:**

```powershell
# デフォルト (tiny)
irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1 | iex

# モデル指定
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName tiny
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName base
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName small
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName medium
& ([scriptblock]::Create((irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1))) -ModelName large
```

インストール後、LM Lightを再起動するとサイドバーに「文字起こし」が表示されます。

- 対応形式: WAV, MP3, M4A, WebM, OGG, FLAC, AAC
- 最大ファイルサイズ: 100MB
- 対応言語: 日本語, English
- GPU対応: Metal (macOS), CUDA (Linux/Windows)

### ライセンス (Perpetual License)

**ライセンス方式**: Hardware UUIDベース永続ライセンス

- デバイスのHardware UUIDに紐付けられた永続ライセンス
- 有効期限なし (issued_atチェックなし)
- オフライン・オンプレミス環境での利用に最適
- 1ライセンス = 1デバイス

`license.lic` を下記に配置:

- macOS/Linux: `~/.local/lmlight/license.lic`
- Windows: `%LOCALAPPDATA%\lmlight\license.lic`


## 起動・停止

**macOS / Linux:**
```bash
lmlight start   # 起動
lmlight stop    # 停止
```

**Windows:**
```powershell
lmlight start   # 起動
lmlight stop    # 停止
```

※ 詳細は [run.md](run.md) を参照

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
sudo rm -f /usr/local/bin/lmlight
```

**Linux:**
```bash
rm -rf ~/.local/lmlight
```

**Windows:**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\lmlight"
```

## ディレクトリ構造

```
~/.local/lmlight/
├── api                    # APIバイナリ (lmlight-perpetual-*)
├── web/                   # Webフロントエンド
├── models/whisper/        # 文字起こしモデル (オプション)
├── .env                   # 設定ファイル
├── license.lic            # ライセンス (Hardware UUIDベース)
├── start.sh               # 起動
├── stop.sh                # 停止
└── logs/                  # ログ
```

## ライセンス比較

| 項目 | dist_v2 (Subscription) | dist_v3 (Perpetual) |
|------|---------------------|---------------------|
| ライセンスチェック | 有効期限 | Hardware UUID |
| ライセンスタイプ | サブスクリプション | 永続 |
