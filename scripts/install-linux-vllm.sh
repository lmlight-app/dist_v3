#!/bin/bash
# LM Light Installer for Linux (vLLM Edition)
set -e

BASE_URL="${LMLIGHT_BASE_URL:-https://github.com/lmlight-app/dist_v3/releases/latest/download}"
INSTALL_DIR="${LMLIGHT_INSTALL_DIR:-$HOME/.local/lmlight-vllm}"
ARCH="$(uname -m)"
case "$ARCH" in x86_64|amd64) ARCH="amd64" ;; aarch64|arm64) ARCH="arm64" ;; esac

echo "Installing LM Light vLLM Edition ($ARCH) to $INSTALL_DIR"

mkdir -p "$INSTALL_DIR"/{app,logs}

[ -f "$INSTALL_DIR/stop.sh" ] && "$INSTALL_DIR/stop.sh" 2>/dev/null || true

curl -fSL "$BASE_URL/lmlight-vllm-linux-$ARCH" -o "$INSTALL_DIR/api"
chmod +x "$INSTALL_DIR/api"

curl -fSL "$BASE_URL/lmlight-app.tar.gz" -o "/tmp/lmlight-app.tar.gz"
rm -rf "$INSTALL_DIR/app" && mkdir -p "$INSTALL_DIR/app"
tar -xzf "/tmp/lmlight-app.tar.gz" -C "$INSTALL_DIR/app"
rm -f /tmp/lmlight-app.tar.gz

[ ! -f "$INSTALL_DIR/.env" ] && cat > "$INSTALL_DIR/.env" << EOF
# =============================================================================
# LM Light Configuration (vLLM Edition)
# =============================================================================

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
# VLLM_GPU_MEMORY_UTILIZATION: GPU memory ratio per server (0.0-1.0)
#   Use 0.45 when running both chat + embed on single GPU
#   Use 0.9 when running one server per GPU
# VLLM_MAX_MODEL_LEN: Max context length (empty = model default)
VLLM_TENSOR_PARALLEL=1
VLLM_GPU_MEMORY_UTILIZATION=0.45
VLLM_MAX_MODEL_LEN=4096

# =============================================================================
# Whisper Transcription (GPU auto-detect)
# Models are downloaded automatically on first use to ~/.cache/whisper/
# Available: tiny, base, small, medium, large
# =============================================================================
WHISPER_MODEL=base

# =============================================================================
# API Server Configuration
# =============================================================================
API_PORT=8000
API_HOST=0.0.0.0

# =============================================================================
# Web Frontend Configuration
# =============================================================================
WEB_PORT=3000
NEXT_PUBLIC_API_URL=http://localhost:8000

# =============================================================================
# NextAuth Configuration
# =============================================================================
NEXTAUTH_SECRET=randomsecret123
NEXTAUTH_URL=http://localhost:3000

# =============================================================================
# License Configuration
# =============================================================================
LICENSE_FILE_PATH=$INSTALL_DIR/license.lic
EOF

# Database setup
DB_USER="lmlight"
DB_PASS="lmlight"
DB_NAME="lmlight"

echo "Setting up database..."
if command -v psql &>/dev/null; then
    # Create user and database
    sudo -u postgres psql -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASS';" 2>/dev/null || true
    sudo -u postgres psql -c "CREATE DATABASE $DB_NAME OWNER $DB_USER;" 2>/dev/null || true
    sudo -u postgres psql -c "ALTER USER $DB_USER CREATEDB;" 2>/dev/null || true
    sudo -u postgres psql -d $DB_NAME -c "CREATE EXTENSION IF NOT EXISTS vector;" 2>/dev/null || true

    # Run migrations
    PGPASSWORD=$DB_PASS psql -q -U $DB_USER -d $DB_NAME -h localhost << 'SQLEOF'
-- Enums
DO $$ BEGIN CREATE TYPE "UserRole" AS ENUM ('ADMIN', 'SUPER', 'USER'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE "UserStatus" AS ENUM ('ACTIVE', 'INACTIVE'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE "MessageRole" AS ENUM ('USER', 'ASSISTANT', 'SYSTEM'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE "ShareType" AS ENUM ('PRIVATE', 'TAG'); EXCEPTION WHEN duplicate_object THEN null; END $$;
DO $$ BEGIN CREATE TYPE "DocumentType" AS ENUM ('PDF', 'WEB', 'TEXT', 'CSV', 'EXCEL', 'WORD', 'IMAGE', 'JSON'); EXCEPTION WHEN duplicate_object THEN null; END $$;

-- Tables
CREATE TABLE IF NOT EXISTS "User" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT,
    "email" TEXT NOT NULL UNIQUE,
    "emailVerified" TIMESTAMP(3),
    "image" TEXT,
    "hashedPassword" TEXT,
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "status" "UserStatus" NOT NULL DEFAULT 'ACTIVE',
    "lastLoginAt" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "UserSettings" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL UNIQUE,
    "defaultModel" TEXT,
    "customPrompt" TEXT,
    "historyLimit" INTEGER NOT NULL DEFAULT 2,
    "temperature" DOUBLE PRECISION NOT NULL DEFAULT 0.7,
    "maxTokens" INTEGER NOT NULL DEFAULT 2048,
    "numCtx" INTEGER NOT NULL DEFAULT 8192,
    "topP" DOUBLE PRECISION NOT NULL DEFAULT 0.9,
    "topK" INTEGER NOT NULL DEFAULT 40,
    "repeatPenalty" DOUBLE PRECISION NOT NULL DEFAULT 1.1,
    "reasoningMode" TEXT NOT NULL DEFAULT 'normal',
    "ragTopK" INTEGER NOT NULL DEFAULT 5,
    "ragMinSimilarity" DOUBLE PRECISION NOT NULL DEFAULT 0.45,
    "embeddingModel" TEXT NOT NULL DEFAULT 'embeddinggemma:latest',
    "chunkSize" INTEGER NOT NULL DEFAULT 500,
    "chunkOverlap" INTEGER NOT NULL DEFAULT 100,
    "visionModel" TEXT,
    "brandColor" TEXT NOT NULL DEFAULT 'default',
    "customLogoText" TEXT,
    "customLogoImage" TEXT,
    "customTitle" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Tag" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "name" TEXT NOT NULL UNIQUE,
    "description" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "UserTag" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "tagId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE ("userId", "tagId")
);

CREATE TABLE IF NOT EXISTS "Bot" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "url" TEXT,
    "shareType" "ShareType" NOT NULL DEFAULT 'PRIVATE',
    "shareTagId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Document" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "botId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "type" "DocumentType" NOT NULL DEFAULT 'PDF',
    "url" TEXT,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Chat" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "userId" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "botId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS "Message" (
    "id" TEXT NOT NULL PRIMARY KEY,
    "chatId" TEXT NOT NULL,
    "role" "MessageRole" NOT NULL,
    "content" TEXT NOT NULL,
    "metadata" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP
);

DO $$ BEGIN
    ALTER TABLE "Bot" ADD COLUMN IF NOT EXISTS "url" TEXT;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "Bot" ADD COLUMN IF NOT EXISTS "shareTagId" TEXT;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;

DO $$ BEGIN
    ALTER TABLE "Tag" ADD COLUMN IF NOT EXISTS "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN
    ALTER TABLE "Tag" ADD COLUMN IF NOT EXISTS "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;

-- Brand customization columns
DO $$ BEGIN
    ALTER TABLE "UserSettings" ADD COLUMN IF NOT EXISTS "brandColor" TEXT NOT NULL DEFAULT 'default';
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN
    ALTER TABLE "UserSettings" ADD COLUMN IF NOT EXISTS "customLogoText" TEXT;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN
    ALTER TABLE "UserSettings" ADD COLUMN IF NOT EXISTS "customLogoImage" TEXT;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;
DO $$ BEGIN
    ALTER TABLE "UserSettings" ADD COLUMN IF NOT EXISTS "customTitle" TEXT;
EXCEPTION WHEN undefined_table THEN null; WHEN duplicate_column THEN null; END $$;

-- pgvector schema
CREATE SCHEMA IF NOT EXISTS pgvector;
CREATE TABLE IF NOT EXISTS pgvector.embeddings (
    id SERIAL PRIMARY KEY,
    bot_id VARCHAR(255) NOT NULL,
    user_id VARCHAR(255) NOT NULL,
    document_id VARCHAR(255) NOT NULL,
    chunk_id INTEGER NOT NULL,
    content TEXT NOT NULL,
    embedding vector,
    metadata JSONB,
    created_at TIMESTAMP DEFAULT NOW()
);

-- Indexes
CREATE INDEX IF NOT EXISTS "UserTag_userId_idx" ON "UserTag"("userId");
CREATE INDEX IF NOT EXISTS "UserTag_tagId_idx" ON "UserTag"("tagId");
CREATE INDEX IF NOT EXISTS "Bot_userId_idx" ON "Bot"("userId");
CREATE INDEX IF NOT EXISTS "Bot_shareTagId_idx" ON "Bot"("shareTagId");
CREATE INDEX IF NOT EXISTS "Document_botId_idx" ON "Document"("botId");
CREATE INDEX IF NOT EXISTS "Chat_sessionId_idx" ON "Chat"("sessionId");
CREATE INDEX IF NOT EXISTS "Chat_userId_model_idx" ON "Chat"("userId", "model");
CREATE INDEX IF NOT EXISTS "Chat_userId_idx" ON "Chat"("userId");
CREATE INDEX IF NOT EXISTS "Chat_botId_idx" ON "Chat"("botId");
CREATE INDEX IF NOT EXISTS "Message_chatId_createdAt_idx" ON "Message"("chatId", "createdAt");
CREATE INDEX IF NOT EXISTS idx_bot_user ON pgvector.embeddings (bot_id, user_id);
CREATE INDEX IF NOT EXISTS idx_document ON pgvector.embeddings (document_id);

-- Admin user (admin@local / admin123)
INSERT INTO "User" ("id", "email", "name", "hashedPassword", "role", "status", "updatedAt")
VALUES (
    'admin-user-id',
    'admin@local',
    'Admin',
    '$2b$12$AIctg50Pbt418E7ir3HlUOP1HWKO4PSP01HfIsx8v6Ab.Td7G5h72',
    'ADMIN',
    'ACTIVE',
    CURRENT_TIMESTAMP
) ON CONFLICT ("id") DO NOTHING;

GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO lmlight;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO lmlight;
GRANT ALL PRIVILEGES ON SCHEMA pgvector TO lmlight;
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA pgvector TO lmlight;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA pgvector TO lmlight;
SQLEOF
    echo "✅ Database setup complete"
else
    echo "⚠️  psql not found. Please set up database manually."
fi

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
pkill -f "lmlight.*api" 2>/dev/null; pkill -f "node.*server.js" 2>/dev/null; sleep 1

echo "🚀 Starting LM Light (vLLM Edition)..."

# Start API (vLLM auto-start is handled by the API if VLLM_AUTO_START=true)
./api &
API_PID=$!

# Start Web
cd app && node server.js &
WEB_PID=$!

echo "✅ Started - API: http://localhost:${API_PORT:-8000} | Web: http://localhost:${WEB_PORT:-3000}"
if [ "${VLLM_AUTO_START:-false}" = "true" ]; then
    echo "   vLLM auto-start enabled (chat: ${VLLM_BASE_URL:-:8080}, embed: ${VLLM_EMBED_BASE_URL:-:8081})"
else
    echo "   ⚠️  vLLM auto-start disabled. Start vLLM servers manually."
fi
echo "   Press Ctrl+C to stop"

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
pkill -f "\./api$" 2>/dev/null
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