#!/bin/bash
# LM Light Installer for Linux
set -e

BASE_URL="${LMLIGHT_BASE_URL:-https://github.com/lmlight-app/dist_v3/releases/latest/download}"
INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight}"
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; esac

echo "Installing LM Light ($ARCH) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"/{app,logs}

[ -f "$INSTALL_DIR/stop.sh" ] && "$INSTALL_DIR/stop.sh" 2>/dev/null || true

curl -fSL "$BASE_URL/lmlight-perpetual-linux-$ARCH" -o "$INSTALL_DIR/api"
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

# Network Configuration
API_HOST=0.0.0.0
API_PORT=8000
WEB_HOST=0.0.0.0
WEB_PORT=3000

# Authentication: local / ldap / oidc
NEXT_PUBLIC_AUTH_MODE=local

# LDAP (AUTH_MODE=ldap)
# LDAP_HOST=your-ad-server.company.local
# LDAP_PORT=389
# LDAP_USE_SSL=false
# LDAP_BASE_DN=dc=company,dc=local
# LDAP_USER_DN_FORMAT={username}@company.local
# LDAP_BIND_DN=
# LDAP_BIND_PASSWORD=

# OIDC / Azure AD (AUTH_MODE=oidc)
# OIDC_CLIENT_ID=
# OIDC_CLIENT_SECRET=
# OIDC_TENANT_ID=
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
pgrep -x ollama >/dev/null || { ollama serve &>/dev/null & sleep 2; }

# Stop existing
pkill -f "lmlight.*api" 2>/dev/null; pkill -f "node.*server.js" 2>/dev/null; sleep 1

echo "🚀 Starting LM Light..."

# Start API
./api &
API_PID=$!

# Start Web (Next.js standalone requires both HOSTNAME and PORT)
cd app && HOSTNAME="${WEB_HOST:-0.0.0.0}" PORT="${WEB_PORT:-3000}" node server.js &
WEB_PID=$!

echo "✅ Started - API: http://localhost:${API_PORT:-8000} | Web: http://localhost:${WEB_PORT:-3000}"

# Show LAN IP
LAN_IP=$(ip -4 addr show 2>/dev/null | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v '127.0.0.1' | head -n1)
[ -n "$LAN_IP" ] && echo "🌐 LAN access (from other PCs): $LAN_IP"

echo ""
echo "Press Ctrl+C to stop"

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
