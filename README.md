# LM Light 利用マニュアル (Perpetual License)

> **ライセンス方式**: Hardware UUIDベース永続ライセンス

## インストール | アップデート 

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
curl -fSL https://github.com/lmlight-app/dist_v3/releases/latest/download/lmlight-app-docker.tar.gz | docker load

# 起動
docker run -d --name lmlight-perpetual -p 8000:8000 --env-file .env lmlight-perpetual
docker run -d --name lmlight-app -p 3000:3000 --env-file .env lmlight-app
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
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://lmlight:lmlight@localhost:5432/lmlight` |
| `OLLAMA_BASE_URL` | OllamaサーバーURL | `http://localhost:11434` |
| `LICENSE_FILE_PATH` | ライセンスファイルのパス | `~/.local/lmlight/license.lic` |
| `API_PORT` | APIポート | `8000` |
| `WEB_PORT` | Webポート | `3000` |

※ インストーラーが自動設定します。手動変更が必要な場合のみ編集してください。
※ NEXTAUTH_SECRET等のセキュリティ関連設定はアプリ内蔵のため、.envでの設定は不要です。

### 文字起こし機能 (オプション)

音声ファイルをテキストに変換する機能です。詳細は [TRANSCRIBE.md](TRANSCRIBE.md) を参照。

```bash
# macOS / Linux
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.sh | bash
```

```powershell
# Windows
irm https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-transcribe.ps1 | iex
```

### ライセンス (Perpetual License)

**ライセンス方式**: Hardware UUIDベース永続ライセンス

- デバイスのHardware UUIDに紐付けられた永続ライセンス
- 有効期限なし (issued_atチェックなし)
- オフライン・オンプレミス環境での利用に最適
- 1ライセンス = 1デバイス

#### Hardware UUID 取得方法

ライセンス発行に必要なHardware UUIDを取得してください。

**macOS:**
- 設定 → 一般 → 情報 → システムレポート → ハードウェア → 「ハードウェアUUID」
- またはターミナルで: `ioreg -d2 -c IOPlatformExpertDevice | awk -F\" '/IOPlatformUUID/{print $4}'`

**Windows:**
- PowerShellで: `(Get-CimInstance Win32_ComputerSystemProduct).UUID`

**Linux:**
- ターミナルで: `sudo cat /sys/class/dmi/id/product_uuid` または `sudo dmidecode -s system-uuid`

#### ライセンスファイル配置

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
├── app/                   # フロントエンド
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
