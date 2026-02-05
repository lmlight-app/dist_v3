# LM Light 利用マニュアル 

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

---

## vLLM Edition (GPU高速推論版)

NVIDIA GPU環境向けの高スループット版です。Ollamaの代わりにvLLMを使用します。

### インストール (Linux のみ)

```bash
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/install-linux-vllm.sh | bash
```

インストール先: `~/.local/lmlight-vllm`

### 必要な依存関係

| 依存関係 | インストール |
|---------|------------|
| Node.js 18+ | `sudo apt install nodejs npm` |
| PostgreSQL 17 + pgvector | `sudo apt install postgresql postgresql-17-pgvector` |
| NVIDIA GPU + CUDA | [NVIDIA CUDA Toolkit](https://developer.nvidia.com/cuda-downloads) |
| FFmpeg (文字起こし用) | `sudo apt install ffmpeg` |

### 設定ファイル (.env)

`~/.local/lmlight-vllm/.env` を編集:

| 環境変数 | 説明 | デフォルト |
|---------|------|-----------|
| `DATABASE_URL` | PostgreSQL接続URL | `postgresql://lmlight:lmlight@localhost:5432/lmlight` |
| `VLLM_BASE_URL` | vLLMチャットサーバーURL | `http://localhost:8080` |
| `VLLM_EMBED_BASE_URL` | vLLM埋め込みサーバーURL | `http://localhost:8081` |
| `VLLM_VISION_BASE_URL` | vLLM Visionサーバー (任意) | (空 = チャットサーバー使用) |
| `VLLM_AUTO_START` | vLLM自動起動 | `true` |
| `VLLM_CHAT_MODEL` | チャットモデル (HuggingFace ID) | `Qwen/Qwen2.5-1.5B-Instruct` |
| `VLLM_EMBED_MODEL` | 埋め込みモデル | `intfloat/multilingual-e5-large-instruct` |
| `VLLM_TENSOR_PARALLEL` | テンソル並列GPU数 | `1` |
| `VLLM_GPU_MEMORY_UTILIZATION` | GPUメモリ使用率 | `0.45` |
| `VLLM_MAX_MODEL_LEN` | 最大コンテキスト長 | `4096` |
| `API_PORT` | APIポート | `8000` |
| `WEB_PORT` | Webポート | `3000` |
| `LICENSE_FILE_PATH` | ライセンスファイルのパス | `~/.local/lmlight-vllm/license.lic` |

### 起動・停止

```bash
lmlight-vllm start   # 起動
lmlight-vllm stop    # 停止
```

### 注意事項

- **初回起動時**はHuggingFaceからモデルをダウンロード（約3GB、ネットワーク必要）
- ダウンロード後は `~/.cache/huggingface/hub/` にキャッシュされオフライン動作可能
- GPU 1枚でchat + embedを動かす場合は `VLLM_GPU_MEMORY_UTILIZATION=0.45` を推奨

### ディレクトリ構造

```
~/.local/lmlight-vllm/
├── api                    # APIバイナリ (lmlight-vllm-*)
├── app/                   # フロントエンド
├── .env                   # 設定ファイル
├── license.lic            # ライセンス (Hardware UUIDベース)
├── start.sh               # 起動
├── stop.sh                # 停止
├── lmlight-vllm           # CLIコマンド
└── logs/                  # ログ
```

### Ollama版との違い

| 項目 | Ollama版 | vLLM版 |
|------|---------|--------|
| LLMエンジン | Ollama | vLLM |
| GPU要件 | 任意 (CPU可) | NVIDIA GPU必須 |
| 並列処理 | Ollama依存 | Continuous Batching |
| モデル形式 | GGUF | HuggingFace |
| 対応OS | macOS/Linux/Windows | Linux |
| インストール先 | `~/.local/lmlight` | `~/.local/lmlight-vllm` |

---

## ライセンス比較

| 項目 | Subscription | Perpetual |
|------|---------------------|---------------------|
| ライセンスチェック | 有効期限 | Hardware UUID |
| ライセンスタイプ | サブスクリプション | 永続 |
