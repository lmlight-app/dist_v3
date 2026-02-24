#!/bin/bash
# LM Light Installer for Linux (vLLM Edition)
set -e

BASE_URL="${LMLIGHT_BASE_URL:-https://github.com/lmlight-app/dist_v3/releases/latest/download}"
INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight-vllm}"
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; esac

echo " Installing LM Light vLLM Edition ($ARCH) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"/{app,logs}

[ -f "$INSTALL_DIR/stop.sh" ] && "$INSTALL_DIR/stop.sh" 2>/dev/null || true

# Download vLLM backend binary (onefile, ~170MB)
echo " Downloading vLLM backend..."

BINARY_URL="$BASE_URL/lmlight-vllm-linux-$ARCH"

mkdir -p "$INSTALL_DIR/api"
if command -v wget &>/dev/null; then
  wget --show-progress --timeout=600 --tries=3 "$BINARY_URL" -O "$INSTALL_DIR/api/lmlight-vllm-linux-$ARCH"
else
  curl -fL --connect-timeout 30 --max-time 0 --retry 3 --retry-delay 5 \
    "$BINARY_URL" -o "$INSTALL_DIR/api/lmlight-vllm-linux-$ARCH"
fi

if [ ! -f "$INSTALL_DIR/api/lmlight-vllm-linux-$ARCH" ] || [ ! -s "$INSTALL_DIR/api/lmlight-vllm-linux-$ARCH" ]; then
  echo "❌ Failed to download vLLM backend"
  echo "   Please check:"
  echo "   1. Network connection"
  echo "   2. File exists at: $BINARY_URL"
  exit 1
fi

chmod +x "$INSTALL_DIR/api/lmlight-vllm-linux-$ARCH"

# Python venv for vLLM + whisper (separate from PyInstaller binary)
echo "Setting up Python environment for vLLM..."

# Install uv (recommended by vLLM for faster and more reliable installation)
if ! command -v uv &>/dev/null; then
    echo " Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
fi

# ffmpeg is required by openai-whisper for audio format conversion
if ! command -v ffmpeg &>/dev/null; then
    echo " Installing ffmpeg..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y -qq ffmpeg
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y ffmpeg
    elif command -v yum &>/dev/null; then
        sudo yum install -y ffmpeg
    else
        echo "⚠️  ffmpeg not found. Please install ffmpeg manually for audio transcription."
    fi
fi

if [ ! -d "$INSTALL_DIR/venv" ]; then
    uv venv --python 3.12 "$INSTALL_DIR/venv"
    echo " Installing vLLM (this may take several minutes)..."
    uv pip install --python "$INSTALL_DIR/venv/bin/python" "vllm>=0.15.1" "openai-whisper>=20231117"
    echo "✅ Python venv ready"
else
    echo "✅ Python venv already exists (skip)"
fi

curl -fSL "$BASE_URL/lmlight-app.tar.gz" -o "/tmp/lmlight-app.tar.gz"
rm -rf "$INSTALL_DIR/app" && mkdir -p "$INSTALL_DIR/app"
tar -xzf "/tmp/lmlight-app.tar.gz" -C "$INSTALL_DIR/app"
rm -f /tmp/lmlight-app.tar.gz

[ ! -f "$INSTALL_DIR/.env" ] && cat > "$INSTALL_DIR/.env" << EOF
# =============================================================================
# LM Light Configuration (vLLM Edition)
# =============================================================================

# Python path for vLLM (auto-configured by installer)
VLLM_PYTHON=$INSTALL_DIR/venv/bin/python

# PostgreSQL Database
DATABASE_URL=postgresql://lmlight:lmlight@localhost:5432/lmlight

# =============================================================================
# vLLM Server URLs
# =============================================================================
VLLM_BASE_URL=http://localhost:8080
VLLM_EMBED_BASE_URL=http://localhost:8081
# Optional: Separate vision server (leave empty to use chat server for vision)
# VLLM_VISION_BASE_URL=http://localhost:8082

# =============================================================================
# vLLM Auto-Start Configuration
# When enabled, API will automatically start vLLM servers on startup.
# First run requires network to download models from HuggingFace.
# Models are cached at ~/.cache/huggingface/hub/
# =============================================================================
VLLM_AUTO_START=true

# Models (HuggingFace model IDs)
VLLM_CHAT_MODEL=Qwen/Qwen2.5-1.5B-Instruct
VLLM_EMBED_MODEL=intfloat/multilingual-e5-large-instruct
# Optional: Separate vision model (requires VLLM_VISION_BASE_URL)
# VLLM_VISION_MODEL=Qwen/Qwen2.5-VL-7B-Instruct

# GPU Configuration
# VLLM_TENSOR_PARALLEL: Number of GPUs for tensor parallelism (default: 1)
# VLLM_GPU_MEMORY_UTILIZATION_{CHAT,EMBED,VISION}: Per-server GPU memory ratio
#   Unset = vLLM default (0.9), set when running multiple servers on same GPU
#   2-server (chat + embed):  0.55 + 0.35 = 0.90
#   3-server (+ vision):      0.35 + 0.25 + 0.30 = 0.90
# VLLM_MAX_MODEL_LEN: Max context length (empty = model default)
VLLM_TENSOR_PARALLEL=1
VLLM_GPU_MEMORY_UTILIZATION_CHAT=0.55
VLLM_GPU_MEMORY_UTILIZATION_EMBED=0.35
# VLLM_MAX_MODEL_LEN=4096

# =============================================================================
# Whisper Transcription (GPU auto-detect)
# Models are downloaded automatically on first use to ~/.cache/whisper/
# Available: tiny, base, small, medium, large
# =============================================================================
WHISPER_MODEL=base

# =============================================================================
# API Server Configuration
# =============================================================================
API_HOST=0.0.0.0
API_PORT=8000

# =============================================================================
# Web Frontend Configuration
# =============================================================================
WEB_HOST=0.0.0.0
WEB_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:8000

# =============================================================================
# License Configuration
# =============================================================================
LICENSE_FILE_PATH=$INSTALL_DIR/license.lic
EOF

# Database setup - parse DATABASE_URL from .env if it exists (for updates with custom DB config)
if [ -f "$INSTALL_DIR/.env" ]; then
    _DB_URL=$(grep -E "^DATABASE_URL=" "$INSTALL_DIR/.env" | head -1 | cut -d= -f2-)
    if [ -n "$_DB_URL" ]; then
        export DB_USER=$(echo "$_DB_URL" | sed -n 's|.*://\([^:]*\):.*|\1|p')
        export DB_PASS=$(echo "$_DB_URL" | sed -n 's|.*://[^:]*:\([^@]*\)@.*|\1|p')
        export DB_NAME=$(echo "$_DB_URL" | sed -n 's|.*/\([^?]*\).*|\1|p')
    fi
fi
echo "Setting up database..."
curl -fsSL https://pub-a2cab4360f1748cab5ae1c0f12cddc0a.r2.dev/scripts/db_setup.sh | bash

cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
set -a; [ -f .env ] && source .env; set +a

# Check dependencies
command -v node &>/dev/null || { echo "❌ Node.js not found"; exit 1; }
pg_isready -q 2>/dev/null || { echo "❌ PostgreSQL not running"; exit 1; }

# Check NVIDIA GPU (vLLM requires CUDA)
if ! command -v nvidia-smi &>/dev/null; then
    echo "⚠️  nvidia-smi not found. vLLM requires NVIDIA GPU with CUDA."
fi

# Stop existing
pkill -f "lmlight-vllm-linux-amd64" 2>/dev/null; pkill -f "node.*server.js" 2>/dev/null; sleep 1

echo "🚀 Starting LM Light (vLLM Edition)..."

# Start API (vLLM auto-start is handled by the API if VLLM_AUTO_START=true)
./api/lmlight-vllm-linux-amd64 &
API_PID=$!

# Start Web (Next.js standalone requires both HOSTNAME and PORT)
cd app && HOSTNAME="${WEB_HOST:-0.0.0.0}" PORT="${WEB_PORT:-3000}" node server.js &
WEB_PID=$!

echo "✅ Started - API: http://localhost:${API_PORT:-8000} | Web: http://localhost:${WEB_PORT:-3000}"

# Show LAN IP
LAN_IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
[ -n "$LAN_IP" ] && echo "🌐 LAN access (from other PCs): $LAN_IP"

if [ "${VLLM_AUTO_START:-false}" = "true" ]; then
    echo ""
    echo "🔧 vLLM auto-start enabled (chat: ${VLLM_BASE_URL:-:8080}, embed: ${VLLM_EMBED_BASE_URL:-:8081})"
else
    echo ""
    echo "⚠️  vLLM auto-start disabled. Start vLLM servers manually."
fi

echo ""
echo "Press Ctrl+C to stop"

trap "kill $API_PID $WEB_PID 2>/dev/null; echo 'Stopped'" EXIT
wait
EOF
chmod +x "$INSTALL_DIR/start.sh"

cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash
# Kill start.sh first (which will trigger its trap to kill API/Web)
pkill -f "lmlight-vllm/start\.sh" 2>/dev/null
sleep 1
# Clean up any remaining processes
pkill -f "lmlight-vllm-linux-amd64" 2>/dev/null
pkill -f "lmlight-vllm/app.*server\.js" 2>/dev/null
echo "Stopped"
EOF
chmod +x "$INSTALL_DIR/stop.sh"

# Create lmlight-vllm CLI script
cat > "$INSTALL_DIR/lmlight-vllm" << 'EOF'
#!/bin/bash
LMLIGHT_HOME="${LMLIGHT_HOME:-$HOME/.local/lmlight-vllm}"
case "$1" in
    start) "$LMLIGHT_HOME/start.sh" ;;
    stop)  "$LMLIGHT_HOME/stop.sh" ;;
    *)     echo "Usage: lmlight-vllm {start|stop}"; exit 1 ;;
esac
EOF
chmod +x "$INSTALL_DIR/lmlight-vllm"

# Create symlink to /usr/local/bin (requires sudo)
sudo ln -sf "$INSTALL_DIR/lmlight-vllm" /usr/local/bin/lmlight-vllm 2>/dev/null || echo "⚠️  Run: sudo ln -sf $INSTALL_DIR/lmlight-vllm /usr/local/bin/lmlight-vllm"

echo ""
echo "Done. Edit $INSTALL_DIR/.env then run: lmlight-vllm start"
echo ""
echo "Note: vLLM requires NVIDIA GPU with CUDA."
echo "      First run will download models from HuggingFace (~3GB)."
echo "      Models are cached at ~/.cache/huggingface/hub/"