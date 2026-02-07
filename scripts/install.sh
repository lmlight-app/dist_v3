#!/bin/bash
# LM Light Installer (auto-detect OS)
# Usage: curl -fsSL https://raw.githubusercontent.com/lmlight-app/lmlight/main/scripts/install.sh | bash
set -e

BASE_URL="${LMLIGHT_BASE_URL:-https://github.com/lmlight-app/lmlight/releases/latest/download}"
INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight}"

OS="$(uname -s)"
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; esac
case "$OS" in Linux) OS="linux" ;; Darwin) OS="macos" ;; *) echo "Unsupported OS: $OS"; exit 1 ;; esac

echo "Installing LM Light ($OS-$ARCH) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"/{app,logs}

[ -f "$INSTALL_DIR/stop.sh" ] && "$INSTALL_DIR/stop.sh" 2>/dev/null || true

# Download API binary (directly to INSTALL_DIR, not bin/)
curl -fSL "$BASE_URL/lmlight-api-$OS-$ARCH" -o "$INSTALL_DIR/api"
chmod +x "$INSTALL_DIR/api"

# Download Web
curl -fSL "$BASE_URL/lmlight-app.tar.gz" -o "/tmp/lmlight-app.tar.gz"
rm -rf "$INSTALL_DIR/app" && mkdir -p "$INSTALL_DIR/app"
tar -xzf "/tmp/lmlight-app.tar.gz" -C "$INSTALL_DIR/app"
rm -f /tmp/lmlight-app.tar.gz

# Create .env template only if not exists
[ ! -f "$INSTALL_DIR/.env" ] && cat > "$INSTALL_DIR/.env" << 'EOF'
# LM Light Configuration

# PostgreSQL
DATABASE_URL=postgresql://lmlight:lmlight@localhost:5432/lmlight

# Ollama
OLLAMA_BASE_URL=http://localhost:11434

# License
LICENSE_FILE_PATH=./license.lic

# Network Configuration
API_HOST=0.0.0.0
API_PORT=8000
WEB_HOST=0.0.0.0
WEB_PORT=3000

# Web
NEXT_PUBLIC_API_URL=http://localhost:8000
EOF

# start.sh
cat > "$INSTALL_DIR/start.sh" << 'STARTEOF'
#!/bin/bash
cd "$(dirname "$0")"

# Load .env
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Check requirements
command -v node &>/dev/null || { echo "❌ Node.js not found"; exit 1; }
pg_isready -q 2>/dev/null || { echo "❌ PostgreSQL not running"; exit 1; }

# Start Ollama if not running
pgrep -x "ollama" >/dev/null || { ollama serve >/dev/null 2>&1 & sleep 2; }

# Kill existing processes on ports
lsof -ti:${API_PORT:-8000} 2>/dev/null | xargs kill -9 2>/dev/null || true
lsof -ti:${WEB_PORT:-3000} 2>/dev/null | xargs kill -9 2>/dev/null || true

mkdir -p logs

echo "🚀 Starting LM Light..."

# Start API
ROOT="$(pwd)"
nohup ./api > logs/api.log 2>&1 & echo $! > logs/api.pid

# Start Web (Next.js standalone requires both HOSTNAME and PORT)
cd app
nohup env HOSTNAME="${WEB_HOST:-0.0.0.0}" PORT="${WEB_PORT:-3000}" node server.js > "$ROOT/logs/app.log" 2>&1 & echo $! > "$ROOT/logs/app.pid"

echo "✅ Started - API: http://localhost:${API_PORT:-8000} | Web: http://localhost:${WEB_PORT:-3000}"

# Show LAN IP if available (auto-detect OS)
if command -v ip &>/dev/null; then
    # Linux
    LAN_IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
else
    # macOS
    LAN_IP=$(ifconfig 2>/dev/null | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}' | head -n1)
fi

if [ -n "$LAN_IP" ]; then
    echo ""
    echo "🌐 LAN access (from other PCs):"
    echo "   API: http://$LAN_IP:${API_PORT:-8000}"
    echo "   Web: http://$LAN_IP:${WEB_PORT:-3000}"
fi

echo ""
echo "Press Ctrl+C to stop or run stop.sh"
STARTEOF
chmod +x "$INSTALL_DIR/start.sh"

# stop.sh
cat > "$INSTALL_DIR/stop.sh" << 'STOPEOF'
#!/bin/bash
cd "$(dirname "$0")"

# Load .env for port numbers
[ -f .env ] && source .env

[ -f logs/app.pid ] && kill $(cat logs/app.pid) 2>/dev/null
[ -f logs/api.pid ] && kill $(cat logs/api.pid) 2>/dev/null
rm -f logs/*.pid

lsof -ti:${WEB_PORT:-3000},${API_PORT:-8000} 2>/dev/null | xargs kill -9 2>/dev/null || true
echo "Stopped"
STOPEOF
chmod +x "$INSTALL_DIR/stop.sh"

echo "Done. Edit $INSTALL_DIR/.env then run: $INSTALL_DIR/start.sh"
