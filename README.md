# LM Light 利用マニュアル 

## Ollamaバージョン

### インストール | アップデート 

### macOS

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/install-macos.sh | bash
```

### Linux

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/install-linux.sh | bash
```

### Windows

```powershell
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/install-windows.ps1 | iex
```

---

インストール先:
- macOS/Linux: `~/.local/lmlight`
- Windows: `%LOCALAPPDATA%\lmlight`

**Docker:** [Docker版](#docker版) を参照

## 環境構築 (インストール前に実行)

### 必要な依存関係

#### macOS

Node.js 18+, PostgreSQL 17, pgvector, Ollama, FFmpeg, Tesseract OCR

```bash
brew install node postgresql@17 pgvector ollama ffmpeg tesseract
```

#### Linux (Ubuntu/Debian)

Node.js 18+, PostgreSQL, FFmpeg, Tesseract OCR, Ollama

```bash
sudo apt install -y nodejs npm postgresql ffmpeg tesseract-ocr
```

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

**pgvector:** インストール済みの PostgreSQL バージョンに合わせてインストールしてください。

```bash
# PostgreSQL のバージョン確認
psql --version

# バージョンに合わせてインストール (例: PG17 の場合)
sudo apt install -y postgresql-17-pgvector
```

#### Windows

> **⚠️ [Visual C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) が必須です。** pgvector のビルドや一部の依存パッケージのコンパイルに必要なため、先にインストールしてください。

Node.js 18+, PostgreSQL 17, Ollama, FFmpeg, Tesseract OCR

```powershell
winget install OpenJS.NodeJS.LTS PostgreSQL.PostgreSQL.17 Ollama.Ollama Gyan.FFmpeg UB-Mannheim.TesseractOCR
```

pgvector は [手動インストール](https://github.com/pgvector/pgvector#windows) が必要です。

### データベース

インストーラーがDB作成・テーブル作成・初期ユーザー作成を自動実行します。

データベースのみを手動実行:

```bash
# macOS/Linux
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/db_setup.sh | bash
```

```powershell
# Windows
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/db_setup.ps1 | iex
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
| `API_HOST` | APIバインドアドレス | `0.0.0.0` (全インターフェース) |
| `API_PORT` | APIポート | `8000` |
| `WEB_HOST` | Webバインドアドレス | `0.0.0.0` (全インターフェース) |
| `WEB_PORT` | Webポート | `3000` |

**ネットワーク設定:**
- `API_HOST` / `WEB_HOST` を `0.0.0.0` に設定すると、同じLAN内の他のPCからアクセス可能になります
- `127.0.0.1` に設定すると、同じマシンからのみアクセス可能になります（セキュリティ強化）

※ インストーラーが自動設定します。手動変更が必要な場合のみ編集してください。
※ NEXTAUTH_SECRET等のセキュリティ関連設定はアプリ内蔵のため、.envでの設定は不要です。

### 文字起こし機能 (オプション)

音声ファイルをテキストに変換する機能です。詳細は [TRANSCRIBE.md](TRANSCRIBE.md) を参照。

```bash
# macOS / Linux
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/install-transcribe.sh | bash
```

```powershell
# Windows
irm https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/install-transcribe.ps1 | iex
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

### ローカルアクセス（同じPC）

- Web: http://localhost:3000
- API: http://localhost:8000

### LANアクセス（他のPC・スマホ・タブレット）

起動時に表示される LAN IP アドレスを使用してください：

```
🌐 LAN access (from other PCs):
   API: http://192.168.1.100:8000
   Web: http://192.168.1.100:3000
```

**IP アドレスの確認方法:**
- macOS: `ifconfig | grep "inet "`
- Linux: `ip addr show`
- Windows: `ipconfig`

**ネットワーク接続の詳細:** [NETWORK.md](NETWORK.md) を参照してください

### デフォルトログイン

`admin@local` / `admin123`

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
sudo rm -f /usr/local/bin/lmlight
```

**Windows (PowerShell):**

```powershell
Remove-Item -Recurse -Force "$env:LOCALAPPDATA\lmlight"
# PATH から削除
$p = [Environment]::GetEnvironmentVariable("Path", "User") -split ";" | Where-Object { $_ -notlike "*lmlight*" }
[Environment]::SetEnvironmentVariable("Path", ($p -join ";"), "User")
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

## vLLMバージョン


### インストール | アップデート (Linux のみ)

```bash
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/install-linux-vllm.sh | bash
```

インストール先: `~/.local/lmlight-vllm`

### 必要な依存関係

| 依存関係 | インストール |
|---------|------------|
| Node.js 18+ | `sudo apt install nodejs npm` |
| PostgreSQL | `sudo apt install postgresql` |
| uv (Python パッケージマネージャー) | `curl -LsSf https://astral.sh/uv/install.sh \| sh` |
| FFmpeg (文字起こし用) | `sudo apt install ffmpeg` |
| Tesseract OCR | `sudo apt install tesseract-ocr tesseract-ocr-jpn` |

※ NVIDIA GPU + CUDA 12.x 以上が必要です。CUDA 13 にも対応しています。

**pgvector:** インストール済みの PostgreSQL バージョンに合わせてインストールしてください。

```bash
# PostgreSQL のバージョン確認
psql --version

# バージョンに合わせてインストール (例: PG17 の場合)
sudo apt install -y postgresql-17-pgvector
```

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
| `VLLM_GPU_MEMORY_UTILIZATION_CHAT` | Chat GPUメモリ使用率 | `0.55` |
| `VLLM_GPU_MEMORY_UTILIZATION_EMBED` | Embed GPUメモリ使用率 | `0.35` |
| `VLLM_GPU_MEMORY_UTILIZATION_VISION` | Vision GPUメモリ使用率 | (未設定=0.9) |
| `VLLM_MAX_MODEL_LEN` | 最大コンテキスト長 | `4096` |
| `WHISPER_MODEL` | 文字起こしモデル (tiny/base/small/medium/large) | `base` |
| `API_HOST` | APIバインドアドレス | `0.0.0.0` (全インターフェース) |
| `API_PORT` | APIポート | `8000` |
| `WEB_HOST` | Webバインドアドレス | `0.0.0.0` (全インターフェース) |
| `WEB_PORT` | Webポート | `3000` |
| `LICENSE_FILE_PATH` | ライセンスファイルのパス | `~/.local/lmlight-vllm/license.lic` |

**ネットワーク設定:** Ollama版と同様に、LAN内の他のPCからアクセス可能です。詳細は [NETWORK.md](NETWORK.md) を参照してください。

### 起動・停止

```bash
lmlight-vllm start   # 起動
lmlight-vllm stop    # 停止
```

### カスタムモデルの使用

**ファインチューニング済みモデルやローカルモデルを使う場合**

`.env`ファイルの`VLLM_CHAT_MODEL`と`VLLM_EMBED_MODEL`を変更：

```bash
# ~/.local/lmlight-vllm/.env

# 1. HuggingFace Hub上のモデル
VLLM_CHAT_MODEL=username/your-finetuned-model
VLLM_EMBED_MODEL=intfloat/multilingual-e5-large-instruct

# 2. ローカルモデル（絶対パス）
VLLM_CHAT_MODEL=/home/user/models/my-finetuned-llama
VLLM_EMBED_MODEL=/home/user/models/my-finetuned-embeddings

# 3. プライベートHuggingFaceモデル
HF_TOKEN=hf_your_token_here
VLLM_CHAT_MODEL=private-org/private-model
```

**ローカルモデルの要件**：HuggingFace Transformers形式（`config.json`, `tokenizer_config.json`, `model.safetensors`等）

設定変更後、再起動：
```bash
lmlight-vllm stop
lmlight-vllm start
```

### 注意事項

- **バイナリサイズ**: API本体は約170MB。vLLM/PyTorchは別途venvにインストール（約6GB）
- **初回起動時**はHuggingFaceからモデルをダウンロード（約3GB、ネットワーク必要）
- ダウンロード後は `~/.cache/huggingface/hub/` にキャッシュされオフライン動作可能
- GPU 1枚でchat + embedを動かす場合は `VLLM_GPU_MEMORY_UTILIZATION_CHAT=0.55` / `_EMBED=0.35` を推奨

### ディレクトリ構造

```
~/.local/lmlight-vllm/
├── api/
│   └── lmlight-vllm-linux-amd64  # 実行ファイル (約170MB)
├── venv/                          # Python venv (vLLM + whisper、約6GB)
├── app/                           # フロントエンド
├── .env                           # 設定ファイル
├── license.lic                    # ライセンス (Hardware UUIDベース)
├── start.sh                       # 起動
├── stop.sh                        # 停止
├── lmlight-vllm                   # CLIコマンド
└── logs/                          # ログ
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

## Docker版

Docker Compose を使ったデプロイ方法です。PostgreSQL (pgvector) も含まれるため、DB の個別インストールは不要です。

### 必要な依存関係

| 依存関係 | インストール |
|---------|------------|
| Docker Engine | [Install Docker](https://docs.docker.com/engine/install/) |
| Docker Compose v2 | Docker Engine に同梱 |
| NVIDIA GPU (vLLM版のみ) | [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/install-guide.html) |

### 必要なファイル

以下の3ファイルを同じディレクトリに配置してください。

#### 1. `docker-compose.yml`

```yaml
services:
  postgres:
    image: pgvector/pgvector:pg16
    environment:
      POSTGRES_USER: lmlight
      POSTGRES_PASSWORD: lmlight
      POSTGRES_DB: lmlight
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  api:
    image: lmlight/lmlight-vllm:latest   # Ollama版: lmlight/lmlight-perpetual:latest
    env_file: .env
    volumes:
      - ./license.lic:/app/license.lic:ro
    ports:
      - "8000:8000"
    extra_hosts:
      - "host.docker.internal:host-gateway"
    depends_on:
      - postgres
    restart: unless-stopped

  app:
    image: lmlight/lmlight-app:latest
    env_file: .env
    ports:
      - "3000:3000"
    depends_on:
      - postgres
      - api
    restart: unless-stopped

  whisper:
    image: onerahmet/openai-whisper-asr-webservice:latest
    environment:
      ASR_MODEL: base
      ASR_ENGINE: openai_whisper
    ports:
      - "9000:9000"
    restart: unless-stopped

volumes:
  pgdata:
```

#### 2. `.env`

**vLLM版:**

```bash
DATABASE_URL=postgresql://lmlight:lmlight@postgres:5432/lmlight

# vLLM サーバー URL（上記の docker run コマンドで起動した場合）
VLLM_BASE_URL=http://host.docker.internal:8080       # Chat モデル
VLLM_EMBED_BASE_URL=http://host.docker.internal:8081  # Embedding モデル

VLLM_AUTO_START=false
VLLM_CHAT_MODEL=Qwen/Qwen2.5-1.5B-Instruct
VLLM_EMBED_MODEL=intfloat/multilingual-e5-large-instruct
VLLM_TENSOR_PARALLEL=1
VLLM_GPU_MEMORY_UTILIZATION_CHAT=0.55
VLLM_GPU_MEMORY_UTILIZATION_EMBED=0.35
# VLLM_MAX_MODEL_LEN=4096

WHISPER_API_URL=http://whisper:9000
API_PORT=8000
API_HOST=0.0.0.0
LICENSE_FILE_PATH=/app/license.lic
NEXT_PUBLIC_API_URL=http://localhost:8000
```

**Ollama版:**

```
DATABASE_URL=postgresql://lmlight:lmlight@postgres:5432/lmlight
OLLAMA_BASE_URL=http://host.docker.internal:11434
API_PORT=8000
API_HOST=0.0.0.0
LICENSE_FILE_PATH=/app/license.lic
NEXT_PUBLIC_API_URL=http://localhost:8000
```

#### 3. `license.lic`

発行されたライセンスファイルを同じディレクトリに配置。

### 起動・停止

#### vLLM 版

**1. vLLM を起動（公式 Docker イメージ）**

```bash
# Chat モデル（ポート 8080）
docker run -d --name vllm-chat \
  --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 8080:8000 \
  --ipc=host \
  vllm/vllm-openai:latest \
  --model Qwen/Qwen2.5-1.5B-Instruct

# Embedding モデル（ポート 8081）
docker run -d --name vllm-embed \
  --gpus all \
  -v ~/.cache/huggingface:/root/.cache/huggingface \
  -p 8081:8000 \
  --ipc=host \
  vllm/vllm-openai:latest \
  --model intfloat/multilingual-e5-large-instruct \
  --task embed
```

**2. LM Light を起動**

```bash
docker compose up -d      # 起動（初回はイメージを自動pull）
docker compose logs -f    # ログ確認
```

**3. 停止**

```bash
docker compose down           # LM Light 停止
docker stop vllm-chat vllm-embed  # vLLM 停止
docker compose down -v        # LM Light 停止 + データ削除
```

#### Ollama 版

**1. Ollama をインストール・起動（ホスト側）**

```bash
# macOS/Linux
brew install ollama  # または curl -fsSL https://ollama.com/install.sh | sh
ollama serve &
ollama pull gemma3:4b
ollama pull nomic-embed-text
```

**2. LM Light を起動**

```bash
docker compose up -d      # 起動
docker compose down        # 停止
docker compose down -v     # 停止 + データ削除
```

初回起動時に `app` コンテナが自動で DB スキーマ作成・初期ユーザー作成を実行します。

### アクセス

- Web: http://localhost:3000
- API: http://localhost:8000
- 初回ログイン: `admin@local` / `admin123`

### Docker Hub イメージ一覧

| イメージ | 説明 |
|---------|------|
| `lmlight/lmlight-vllm:latest` | API (vLLM版) |
| `lmlight/lmlight-perpetual:latest` | API (Ollama版) |
| `lmlight/lmlight-app:latest` | フロントエンド (共通) |
| `pgvector/pgvector:pg16` | PostgreSQL + pgvector (公式) |

```bash
# イメージの手動pull（docker compose up -d で自動pullされますが、事前取得も可能）
docker pull lmlight/lmlight-vllm:latest                        # vLLM版
docker pull lmlight/lmlight-perpetual:latest                   # Ollama版
docker pull lmlight/lmlight-app:latest                         # フロントエンド
docker pull pgvector/pgvector:pg16                             # PostgreSQL
docker pull onerahmet/openai-whisper-asr-webservice:latest     # 文字起こし
```

### 注意事項

**vLLM 版:**
- vLLM は **公式 Docker イメージ**を使用してください: `vllm/vllm-openai:latest`
- vLLM の詳細な設定（モデル選択、GPU設定など）は[公式ドキュメント](https://docs.vllm.ai/)を参照
- `.env` の `VLLM_BASE_URL` / `VLLM_EMBED_BASE_URL` はポートに合わせて設定（デフォルト: 8080, 8081）
- Kubernetes 等で vLLM が別 Pod にある場合は、そのサービス URL を指定してください

**Ollama 版:**
- Ollama はホスト側で起動（`host.docker.internal` 経由で接続）
- `.env` の `OLLAMA_BASE_URL` はホスト側のサーバーアドレスに合わせてください

---

## ライセンス比較

| 項目 | Subscription | Perpetual |
|------|---------------------|---------------------|
| ライセンスチェック | 有効期限 | Hardware UUID |
| ライセンスタイプ | サブスクリプション | 永続 |
