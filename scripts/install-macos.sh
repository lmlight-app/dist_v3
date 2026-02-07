#!/bin/bash
# LM Light Installer for macOS
set -e

BASE_URL="${LMLIGHT_BASE_URL:-https://github.com/lmlight-app/dist_v3/releases/latest/download}"
INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight}"
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; esac

echo "Installing LM Light ($ARCH) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"/{app,logs}

[ -f "$INSTALL_DIR/stop.sh" ] && "$INSTALL_DIR/stop.sh" 2>/dev/null || true

curl -fSL "$BASE_URL/lmlight-perpetual-macos-$ARCH" -o "$INSTALL_DIR/api"
chmod +x "$INSTALL_DIR/api"

curl -fSL "$BASE_URL/lmlight-app.tar.gz" -o "/tmp/lmlight-app.tar.gz"
rm -rf "$INSTALL_DIR/app" && mkdir -p "$INSTALL_DIR/app"
tar -xzf "/tmp/lmlight-app.tar.gz" -C "$INSTALL_DIR/app"
rm -f /tmp/lmlight-app.tar.gz

[ ! -f "$INSTALL_DIR/.env" ] && cat > "$INSTALL_DIR/.env" << EOF
# LM Light Configuration
DATABASE_URL=postgresql://lmlight:lmlight@localhost:5432/lmlight
OLLAMA_BASE_URL=http://localhost:11434
# OLLAMA_NUM_PARALLEL=8
LICENSE_FILE_PATH=$INSTALL_DIR/license.lic
API_PORT=8000
WEB_PORT=3000
EOF

# Database setup
echo "Setting up database..."
curl -fsSL https://raw.githubusercontent.com/lmlight-app/dist_v3/main/scripts/db_setup.sh | bash

cat > "$INSTALL_DIR/start.sh" << 'EOF'
#!/bin/bash
cd "$(dirname "$0")"
set -a; [ -f .env ] && source .env; set +a

# Check dependencies
command -v node &>/dev/null || { echo "❌ Node.js not found"; exit 1; }
pg_isready -q 2>/dev/null || { echo "❌ PostgreSQL not running"; exit 1; }
pgrep -x ollama >/dev/null || { ollama serve &>/dev/null & sleep 2; }

# Stop existing
pkill -f "lmlight.*api" 2>/dev/null; pkill -f "node.*server.js" 2>/dev/null; sleep 1

echo "🚀 Starting LM Light..."

# Start API
./api &
API_PID=$!

# Start Web (Next.js standalone uses PORT env var)
cd app && PORT="${WEB_PORT:-3000}" node server.js &
WEB_PID=$!

echo "✅ Started - API: http://localhost:${API_PORT:-8000} | Web: http://localhost:${WEB_PORT:-3000}"
echo "   Press Ctrl+C to stop"

trap "kill $API_PID $WEB_PID 2>/dev/null; echo 'Stopped'" EXIT
wait
EOF
chmod +x "$INSTALL_DIR/start.sh"

cat > "$INSTALL_DIR/stop.sh" << 'EOF'
#!/bin/bash
# Kill start.sh first (which will trigger its trap to kill API/Web)
pkill -f "lmlight/start\.sh" 2>/dev/null
sleep 1
# Clean up any remaining processes
pkill -f "\./api$" 2>/dev/null
pkill -f "lmlight/app.*server\.js" 2>/dev/null
echo "Stopped"
EOF
chmod +x "$INSTALL_DIR/stop.sh"

# Create lmlight CLI script
cat > "$INSTALL_DIR/lmlight" << 'EOF'
#!/bin/bash
LMLIGHT_HOME="${LMLIGHT_HOME:-$HOME/.local/lmlight}"
case "$1" in
    start) "$LMLIGHT_HOME/start.sh" ;;
    stop)  "$LMLIGHT_HOME/stop.sh" ;;
    *)     echo "Usage: lmlight {start|stop}"; exit 1 ;;
esac
EOF
chmod +x "$INSTALL_DIR/lmlight"

# Create symlink to /usr/local/bin (requires sudo)
sudo ln -sf "$INSTALL_DIR/lmlight" /usr/local/bin/lmlight 2>/dev/null || echo "⚠️  Run: sudo ln -sf $INSTALL_DIR/lmlight /usr/local/bin/lmlight"

echo "Done. Edit $INSTALL_DIR/.env then run: lmlight start"
